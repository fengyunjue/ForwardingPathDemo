//
//  Person4.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "MAProxy.h"

@implementation MAProxy

+ (id)allocWithObj:(id)obj {
    MAProxy *proxy = [MAProxy alloc];
    proxy.obj = obj;
    return proxy;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return _obj;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [self.obj methodSignatureForSelector:aSelector];
    if (sig == nil && self.timer != nil) {
        // 如果self.obj被释放，则暂停并释放NSTimer
        [self.timer invalidate];
        self.timer = nil;
        
        NSString *sel = NSStringFromSelector(aSelector);
        if ([sel hasSuffix:@":"]) {
            return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
        }else{
            return [NSMethodSignature signatureWithObjCTypes:"@@:"];
        }
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)invocation{
    [invocation invokeWithTarget:self.obj];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
