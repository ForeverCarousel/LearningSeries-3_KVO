//
//  NSObject+CarouselKVO.h
//  KVO
//
//  Created by Carouesl on 2016/10/17.
//  Copyright © 2016年 Carouesl. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void(^NotifyBlock)(NSString* keyPath,id obj, NSDictionary* change);

@interface NSObject (CarouselKVO)


- (void)addCarouselObserver:(id)observer keyPath:(NSString* )keyPath withNotifyBlock:(NotifyBlock)block;

- (void)removeCarouselObserver:(id)observer keyPath:(NSString* )keypath;




@end
