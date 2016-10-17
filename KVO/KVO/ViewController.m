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
    
    
    
    [self somethingInteresting];
    
}



/**
 自定义实现KVO 通过为根类写一个category的方式以便所有子类都可以调用
 */
-(void)somethingInteresting
{
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
