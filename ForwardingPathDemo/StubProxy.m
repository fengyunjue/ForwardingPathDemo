//
//  StubProxy.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "StubProxy.h"
#import <objc/message.h>

@implementation StubProxy

+ (instancetype)sharedInstance {
    static StubProxy *proxy;
    static dispatch_once_t  once_token;
    dispatch_once(&once_token, ^{
        proxy = [StubProxy alloc];
    });
    return proxy;
}

id autoAddMethod(id self, SEL _cmd) {
    //可以在此加入日志信息，栈信息的获取等，方便后面分析和改进原来的代码。
    NSLog(@"unrecognized selector: %@",NSStringFromSelector(_cmd));
    return 0;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    // 向类中动态的添加方法，第三个参数为函数指针，指向待添加的方法。最后一个参数表示待添加方法的“类型编码”
    class_addMethod([self class], sel,(IMP)autoAddMethod,"v@:@");
    return YES;
}
@end
