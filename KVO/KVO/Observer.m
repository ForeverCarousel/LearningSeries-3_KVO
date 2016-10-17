//
//  Observer.m
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import "Observer.h"

@implementation Observer


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSString* newValue = [change valueForKey:@"new"];
    NSString* oldValue = [change valueForKey:@"old"];
    NSString* objClass = NSStringFromClass([object class]);
    
    NSLog(@"%@对象的%@值发生改变 %@ --> %@",objClass,keyPath,oldValue,newValue);
}

@end
