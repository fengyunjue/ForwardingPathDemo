//
//  Person1.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "Person1.h"
#import <objc/message.h>

@interface Person1()

@property (nonatomic, strong) NSMutableDictionary *data;

@end

@implementation Person1
// 标记的作用是告诉编译器,我们将手动实现name的getter和setter方法
@dynamic name;

// 代码中没有创建name的getter和setter方法,所以会走这个方法
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSString *sel = NSStringFromSelector(aSelector);
    if ([sel hasPrefix:@"set"]) {
        // 动态创建一个setter方法
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    } else {
        // 动态创建一个getter方法
        return [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    //拿到函数名
    NSString *key = NSStringFromSelector([anInvocation selector]);
    if ([key rangeOfString:@"set"].location == 0) {
        //setter函数形如 setXXX: 拆掉 set和冒号
        key = [[key substringWithRange:NSMakeRange(3, [key length]-4)] lowercaseString];
        NSString *obj;
        //从参数列表中找到值
        [anInvocation getArgument:&obj atIndex:2];
        [self.data setObject:obj forKey:key];
    } else {
        //getter函数就相对简单了，直接把函数名做 key就好了。
        NSString *obj = [self.data objectForKey:key];
        [anInvocation setReturnValue:&obj];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [self.data setObject:value forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key{
    return [self.data valueForKey:key];
}

- (NSMutableDictionary *)data {
    if (_data == nil) {
        _data = [NSMutableDictionary dictionary];
    }
    return _data;
}

@end
