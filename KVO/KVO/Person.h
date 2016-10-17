//
//  Person.h
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (strong, nonatomic) NSString* name;

- (void)changeName:(NSString*) n;
- (void)kvoChangeName:(NSString*) m;

@end
