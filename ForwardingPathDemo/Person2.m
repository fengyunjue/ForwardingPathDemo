//
//  Person2.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "Person2.h"
#import <objc/message.h>

@interface Person2()

@end

@implementation Person2

void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@">> dynamicMethodIMP");
}

// 1.利用resolveInstanceMethod,如果方法不存在,给该类添加方法,建议只在这个方法里动态添加指定的几个不存在的方法,不建议所有未知方法都走这里
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *selStr = NSStringFromSelector(sel);
    if ([selStr isEqualToString:@"appendString:"]) {
        class_addMethod([self class], sel, (IMP) dynamicMethodIMP, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}

/*
 // 2. 利用快速消息转发实现,将该方法转发给StubProxy,由StubProxy动态添加这个不存在的方法
- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSString *selStr = NSStringFromSelector(aSelector);
    if ([selStr isEqualToString:@"appendString:"]) {
        return [StubProxy alloc];
    }
    return [super forwardingTargetForSelector:aSelector];
}
*/

/*
 // 3.利用标准消息转发实现,将该方法转发给StubProxy,由StubProxy动态添加这个不存在的方法
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [super methodSignatureForSelector:aSelector] ?: [[StubProxy sharedInstance] methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([super methodSignatureForSelector:anInvocation.selector]) {
        [super forwardInvocation:anInvocation];
    }
    if ([self methodSignatureForSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:[StubProxy sharedInstance]];
    }
}
*/
@end

