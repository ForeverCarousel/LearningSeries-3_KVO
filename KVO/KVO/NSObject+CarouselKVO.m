//
//  NSObject+CarouselKVO.m
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import "NSObject+CarouselKVO.h"

#import <objc/runtime.h>
#import <objc/message.h>

static const NSString* CarouselKVOClassPrefix = @"CarouselKVONotifying_";
const char * CarouselKVOAssociateKey;

@implementation NSObject (CarouselKVO)

/**
 
 自定义实现KVO的思路如下
 1.set方法检测  首先要判断传入的key或者keyPath是否实现了set方法  因为KVO本身是基于KVC实现的所以set方法是基础
 2.生成中间类    KVO的原理就是通过生成一个中间类的方式来重写set方法 以此获取值变化
 3.重写生成的中间类的setter方法
 
 */

- (void)addCarouselObserver:(id)observer keyPath:(NSString* )keyPath withNotifyBlock:(NotifyBlock)block;
{
    //1.首先检查传入的key有没有实现set方法
    SEL selector = [self setterFromKey:keyPath];

    //查看有没有实现set方法 因为如果没有实现set方法就没有机会发送值变化时的消息
    Method method  = class_getInstanceMethod([self class], selector);
    if (!method)
    {
        NSException* customException = [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@未实现set方法",keyPath] userInfo:nil ];
        @throw customException;//这里如果没有实现setter就抛出异常
    }
    //2.生成中间类 注册该类到运行时系统中
    Class midClass = [self intermediateClassFromOriginaClass:NSStringFromClass([self class])];
    
    //3.修改对象的类归属 将self的class由Person修改为CarouselKVONotifying_Person 所以以下self的类型就不在是Person类型了
    object_setClass(self, midClass);
    
    //4.重写中间类的setter
    [self rewriteSetterForClass:midClass withIntanceVar:keyPath];
    
    //5.添加观察者 其实就是在重写的setter方法中调用观察者的block以通知
    NotifyModel* model = [[NotifyModel alloc] initWithObserver:observer key:keyPath Block:block];
    objc_setAssociatedObject(self, CarouselKVOAssociateKey, model, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(SEL) setterFromKey:(NSString* )key
{
    NSString* setter = [NSString stringWithFormat:@"set%@:",[key capitalizedString]];
    SEL selector = NSSelectorFromString(setter);
    return selector;
}




#pragma mark - 生成中间类

-(Class)intermediateClassFromOriginaClass:(NSString* ) classString
{
    //获取被观察对象的类 用于中间类指向它
    Class originalClass = NSClassFromString(classString);
    
    //依照系统命名的规则拼接出中间类名
    NSString* intermediateClassName = [NSString stringWithFormat:@"%@%@",CarouselKVOClassPrefix,classString];
    
    /*
    利用runtime方法动态生成中间类
     
    Class objc_allocateClassPair ( Class superclass, const char *name, size_t extraBytes );
    
     参数解释
    return        返回新创建的类
    superclass    新建类的父类，如果传nil则创建新的根类 这儿要指向原来的类
    name          新建类的名称
    extraBytes    The number of bytes to allocate for indexed ivars at the end of the class and 
                  metaclass objects. This should usually be 0 具体作用不清楚 以后查清楚补上解释 字面意思
                  为为类和元类结尾的需要索引化的变量提供空间？总之文档就让传0
     */
   Class intermediateClass = objc_allocateClassPair(originalClass, intermediateClassName.UTF8String, 0);
    //这里一定要及时注册 不然后面可能会出现某些方法调用无效
    objc_registerClassPair(intermediateClass);

   //重写中间类的class方法 用于添加观察者之后 被观察对象调用class方法可以和未添加观察者之前返回同一个类型-，- 不敢确定有什么卵用 猜测系统之所以这么做应该是为了第一不想过度暴露KVO实现的细节  第二应该是防止调用class方法返回的对象在使用KVO之后不一致会造成一些问题 比如说判断是否属于某个类之类的 总之是为了隐藏KVO所带来的不必要变化
    BOOL result =   [self rewriteClassMethodForClass:intermediateClass];
    
    return result? intermediateClass : nil;
}





#pragma mark -  重写-(Class)class方法

-(BOOL)rewriteClassMethodForClass:(Class)targetClass
{
    //获取默认的class方法
    Method classMethod = class_getClassMethod([self class], @selector(class));
    const char* types = method_getTypeEncoding(classMethod);
    //添加新的class方法
    /*
     BOOL  class_addMethod(Class cls, SEL name, IMP imp,const char *types)
      cls  需要动态添加方法的类.
     name  需要添加的方法的方法名
      imp  新方法的实现  至少要包含两个参数 一个是self  一个是方法本身_cmd
    types  An array of characters that describe the types of the arguments to the method. For possible values, see Objective-C Runtime Programming Guide > Type Encodings. Since the function must take at least two arguments—self and _cmd, the second and third characters must be “@:” (the first character is the return type).
     */
    BOOL result = class_addMethod(targetClass, @selector(class) , (IMP)newClass, types);
    return result;
}

Class newClass(id self, SEL _cmd) {
 
    //中间类的class方法的具体实现指向此方法 所以要返回原始未添加观察者时的类即Person 但是这里的self已经是中间类了CarouselKVONotitying_Person 类了  所以要返回self的父类（Person）
    //1.获取当前的类型 不能调用class方法 因为这个方法本身就是重新实现的class方法
    Class midClass = object_getClass(self);
    return class_getSuperclass(midClass);

}






#pragma mark -  重写setter方法

-(BOOL)rewriteSetterForClass:(Class)targetClass withIntanceVar:(NSString*)var
{
    SEL orginalSetter = [self setterFromKey:var];
    
    /*
     当下面方法调用[self class]时 此时class方法实际上调用的newClass方法 返回的是原始类的类型 因为我们重写了该方法 虽然self的类型是CarouselKVONotifying_Person
     Log:
     (lldb) po [self class]
     Person
     */
    const char* types = method_getTypeEncoding(class_getInstanceMethod([self class], orginalSetter));

    BOOL result =  class_addMethod(targetClass, orginalSetter, (IMP)newSetter, types);
    if (result)
    {
        return  YES;
    }
    return NO;
}

void  newSetter(id  self, SEL _cmd, id newValue){
    
    NSString *setter = NSStringFromSelector(_cmd);
    NSString *getter = [self getterFromSetter:setter];
    
    if (!getter) {
        NSString *reason = [NSString stringWithFormat:@"找不到%@对应属性%@的setter", self, getter];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        return;
    }
    
    NSString *key = [[getter componentsSeparatedByString:@":"] firstObject];
    
    id oldValue = [self valueForKey:key];
    if (oldValue == nil)
    {
        oldValue = @"空值";
    }
    
//    struct objc_super supercls = {
//        .receiver = self,
//        .super_class = class_getSuperclass(object_getClass(self))
//    };
//    
//    objc_msgSendSuper(&supercls, _cmd, newValue);
//    objc_msgSendSuper();
    NotifyModel* obj  = objc_getAssociatedObject(self, CarouselKVOAssociateKey);
    if (obj && obj.key != newValue)
    {
        NSDictionary* changeDic = @{
                                    @"old" : oldValue,
                                    @"new" : newValue
                                    };
        obj.blcok (key,self,changeDic);
        
    }
    

}
- (NSString *)getterFromSetter:(NSString *)setter {
    
    NSString *getter = [setter substringFromIndex:3];
    NSString *firstLow = [getter substringToIndex:1].lowercaseString;
    
    return [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstLow];
}


- (void)removeCarouselObserver:(id)observer keyPath:(NSString* )keypath
{
    
}



@end



@implementation NotifyModel

-(instancetype)initWithObserver:(id)ob key:(NSString *)key Block:(NotifyBlock)blk
{
    if (self = [super init])
    {
        self.observer = ob;
        self.key = key;
        self.blcok = blk;
    }
    return self;
}

@end







