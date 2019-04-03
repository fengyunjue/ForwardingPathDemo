//
//  TargrtProxy.h
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TargrtProxy : NSProxy

@property (nonatomic, strong) id realObject1;
@property (nonatomic, strong) id realObject2;

+ (id)allocWithTarget1:(id)t1 target2:(id)t2;

@end
