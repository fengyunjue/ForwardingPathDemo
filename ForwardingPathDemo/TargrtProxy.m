//
//  TargrtProxy.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "TargrtProxy.h"

@implementation TargrtProxy

+ (id)allocWithTarget1:(id)t1 target2:(id)t2 {
    TargrtProxy *proxy = [TargrtProxy alloc];
    proxy.realObject1 = t1;
    proxy.realObject2 = t2;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [self.realObject1 methodSignatureForSelector:sel];
    if (sig) return sig;
    return [self.realObject2 methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    id target = [self.realObject1 methodSignatureForSelector:[invocation selector]] ? self.realObject1 : self.realObject2;
    [invocation invokeWithTarget:target];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.realObject1 respondsToSelector:aSelector]) return YES;
    if ([self.realObject2 respondsToSelector:aSelector]) return YES;
    return NO;
}

@end
