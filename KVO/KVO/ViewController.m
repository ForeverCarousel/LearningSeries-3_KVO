//
//  ViewController.m
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import "ViewController.h"
#import "Observer.h"
#import "Person.h"
#import "NSObject+CarouselKVO.h"


@interface ViewController ()
@property (strong, nonatomic) Person* person;
@property (strong, nonatomic) Observer* obs;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.person = [[Person alloc] init];
    self.obs = [[Observer alloc] init];
    
    [_person addObserver:_obs forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    _person.name = @"Carousel";//会触发kvo
    _person.name = @"Carousel";//即使两次对某一个key赋同一个值也会再次触发kvo 所以可以重写set方法然后加判断相同值时返回 否则手动调用个kvo方法

    [_person setValue:@"Tom" forKey:@"name"];//kvc也会触发KVO 因为kvc首先也会去调用set方法
    [_person changeName:@"Jerry"];//直接修改实例变量的值是不会触发KVO的
    
    [_person kvoChangeName:@"Lucy"];//这里通过手动调用 willChangeValueForKey: 和 didChangeValueForKey: 就会触发KVO
    /**
     通过以上的例子我们可以得出以下结论
     1.添加了观察者的对象会被重写set方法 ARC
     -(void)setName:(NSString* ) name
     {
         [self willChangeValueForKey:@"name"];
         _name = name;
         [self didChangeValueForKey:@"name"];
     }
     
     2.kvoChangeValueForkey:方法中通过手动调用 will 和did 也可以成功触发KVO
     
     3.如果被观察者实现了automaticallyNotifiesObserversForKey:(NSString* ) key 方法并且对指定的key返回了NO则不会自动触发KVO 也就是通过set方法和kvc赋值的方法都不会触发kvo 但是手动调用了willchange 和didchange方法的就可以
     */
    
    [_person removeObserver:_obs forKeyPath:@"name"];
    
    [self somethingInteresting];
    
}









/**
 自定义实现KVO 通过为根类NSObject写一个category的方式以便所有子类都可以调用
 
 
 简述KVO的实现：
    当你观察一个对象时，一个新的类会动态被创建。这个类继承自该对象的原本的类，并重写了被观察属性的 setter 方法。自然，重写的 setter 方法会负责在调用原 setter 方法之前和之后，通知所有观察对象值的更改。最后把这个对象的 isa 指针 ( isa 指针告诉 Runtime 系统这个对象的类是什么 ) 指向这个新创建的子类，对象就神奇的变成了新创建的子类的实例。
    原来，这个中间类，继承自原本的那个类。不仅如此，Apple 还重写了 -class 方法，企图欺骗我们这个类没有变，就是原本那个类。
    下面的Log可以看到具体的变化：
 
 
 */
-(void)somethingInteresting
{
    self.person = [[Person alloc] init];
    NSLog(@"初始化状态：Class : %@    isa :%@",[_person class],[_person valueForKey:@"isa"]);
    self.obs = [[Observer alloc] init];
    [_person addObserver:_obs forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    NSLog(@"添加观察者之后状态：Class : %@   isa : %@",[_person class],[_person valueForKey:@"isa"]);
    Class currentClass = [[_person valueForKey:@"isa"] superclass];
    NSLog(@"添加观察者之后状态：isa superClass : %@",currentClass);

    /**
     2016-10-18 17:48:41.817 初始化状态:        Class : Person    isa :Person
     2016-10-18 17:48:41.818 添加观察者之后状态： Class : Person    isa :NSKVONotifying_Person
     2016-10-18 18:50:48.318 添加观察者之后状态： isa superClass : Person

     可以看到和上面所说的一样会生成一个中间类 NSKVONotifying_Person -->Person   - -但是很明显Apple重写了中间类的class方法  所以返回的class仍然是Person
     然后会重写其set方法 在修改值的方法前后 添加willchange 和 didchange方法 用来通知观察者 被观察对象的属性的值的变化 具体可以看下36-44行处的代码
    */
    
    Person* carousel = [[Person alloc] init];
    [carousel addCarouselObserver:self keyPath:@"name" withNotifyBlock:^(NSString *keyPath, id obj, NSDictionary *change) {
        
    }];
    
    
    
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
