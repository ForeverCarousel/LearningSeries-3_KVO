//
//  NSObject+CarouselKVO.m
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import "NSObject+CarouselKVO.h"

#import <objc/runtime.h>

static const NSString* CarouselKVOClassPrefix = @"CarouselKVOClassPrefix";

@implementation NSObject (CarouselKVO)



- (void)addCarouselObserver:(id)observer keyPath:(NSString* )keyPath withNotifyBlock:(NotifyBlock)block;
{
    //1.首先检查传入的key有没有实现set方法 
    NSString* setter = [NSString stringWithFormat:@"set%@:",[keyPath capitalizedString]];
    SEL selector = NSSelectorFromString(setter);
    //查看有没有实现set方法
    Method method  = class_getInstanceMethod([self class], selector);
    if (!method)
    {
        NSException* customException = [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@未实现set方法",keyPath] userInfo:nil ];
        @throw customException;//这里抛出异常 可以在控制台查看具体错误信息
    }
    //2.生成中间类
    
}

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
    superclass    新建类的父类，如果传nil则创建新的根类
    name          新建类的名称
    extraBytes    The number of bytes to allocate for indexed ivars at the end of the class and 
                  metaclass objects. This should usually be 0 具体作用不清楚 以后查清楚补上解释 字面意思
                  为为类和元类结尾的需要索引化的变量提供空间？总之文档就让传0
     */
   Class intermediateClass = objc_allocateClassPair(originalClass, intermediateClassName.UTF8String, 0);
    
   //重写中间类的class方法 用于添加观察者之后 被观察对象调用class方法可以和未添加观察者之前返回同一个类型-，- 不敢确定有什么卵用 猜测系统之所以这么做应该是为了第一不想过度暴露KVO实现的细节  第二应该是防止调用class方法返回的对象在使用KVO之后不一致会造成一些问题 比如说判断是否属于某个类之类的 总之是为了隐藏KVO所带来的不必要变化
    [self rewriteClassMethod];
    
    
    
    return nil;
}


-(void)rewriteClassMethod
{
    //获取默认的class方法
    Method classMethod = class_getClassMethod([self class], @selector(class));
    
}


- (void)removeCarouselObserver:(id)observer keyPath:(NSString* )keypath
{
    
}



@end
