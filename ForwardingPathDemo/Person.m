//
//  Person.m
//  ForwardingPathDemo
//
//  Created by admin on 3/29/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "Person.h"

@implementation Person

- (NSString *)sex {
    // 强制子类重写此方法,否则子类调用时会崩溃
    // -[subClass legCount]: unrecognized selector sent to instance 0x00000000
    if (![self isMemberOfClass:[Person class]]) {
        NSLog(@"if you not override this method, you will get a exception");
        [self doesNotRecognizeSelector:_cmd];
    }
    return @"未知";
}



@end


@implementation Man

@end
