//
//  Person.m
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import "Person.h"

@implementation Person

- (void)changeName:(NSString*) n
{
    _name = n;
}

- (void)kvoChangeName:(NSString*) m
{
    [self willChangeValueForKey:@"name"];
    _name = m;
    [self didChangeValueForKey:@"name"];
}

+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"name"])
    {
//        return NO; //返回NO时将不会自动触发KVO
        return YES;

    }
    return [super automaticallyNotifiesObserversForKey: key];
}



@end
