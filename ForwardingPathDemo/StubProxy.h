//
//  StubProxy.h
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StubProxy : NSProxy

+ (instancetype)sharedInstance;

@end
