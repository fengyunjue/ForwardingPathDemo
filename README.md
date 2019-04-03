# [简书：关于iOS消息转发--动态调用方法的问题](https://www.jianshu.com/p/f8e12f2d29f5)

iOS中有个一个错误经常会遇到```unrecognized selector sent to instance```，这个错误究竟是怎么触发的，它的具体流程是什么？我们今天来探究下。

## 一、消息转发介绍
当向某个Object发送消息，但runtime system在当前类和父类中找不到对应的方法的实现时，runtime system并不会立即报错使程序崩溃，而是依次执行下列步骤：
![](https://upload-images.jianshu.io/upload_images/1429831-0d003d4dd3a18dd9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)
![代码流程](https://upload-images.jianshu.io/upload_images/1429831-148ade22d3847832.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)
1、对于实例方法的完整的处理流程如下：
![实例方法的完整的处理流程](http://upload-images.jianshu.io/upload_images/1429831-82664188d9aede4a?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)
2、对于类方法的完整的处理流程如下：
![类方法的完整的处理流程](http://upload-images.jianshu.io/upload_images/1429831-3e63800f3ac04aa5?imageMogr2/auto-orient/strip%7CimageView2/2/w/800)

###### 1.动态方法解析（Dynamic Method Resolution）
向当前类发送```resolveInstanceMethod:```(对于类方法则为```resolveClassMethod:```)消息，如果返回YES,则系统认为请求的方法已经加入到类中，则会重新向当前类发送selector消息；如果返回NO，则进入快速消息转发流程。
###### 2.快速消息转发(Fast forwarding path)
向当前类发送```forwardingTargetForSelector:```，如果返回一个不是nil或self的对象，则向该返回的对象发送selector消息；如果nil或self，则进入标准消息转发。   
###### 3.标准消息转发(Normal forwarding path)     
首先runtime发送```methodSignatureForSelector:```消息查看Selector对应的方法签名，即参数与返回值的类型信息。如果有方法签名返回，runtime则根据方法签名创建描述该消息的```NSInvocation```，向当前对象发送```forwardInvocation:```消息，以创建的NSInvocation对象作为参数；若```methodSignatureForSelector:```无方法签名返回，则向当前对象发送```doesNotRecognizeSelector:```消息,程序抛出异常退出。

> __两种消息转发方式比较__：
>    快速消息转发：简单、快速、但仅能转发给一个对象。
>    标准消息转发：稍复杂、较慢、但转发操作实现可控，可以实现多对象转发

```
// 实例方法动态方法解析
+ (BOOL)resolveClassMethod:(SEL)sel{
    return [super resolveClassMethod:sel];
}
// 类方法动态方法解析
+ (BOOL)resolveInstanceMethod:(SEL)sel{
    return [super resolveInstanceMethod:sel];
}
// 快速消息转发
- (id)forwardingTargetForSelector:(SEL)aSelector{
   return [super forwardingTargetForSelector:aSelector];
}
// 标准消息转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    return [super methodSignatureForSelector:aSelector];
}
// 重定向消息
- (void)forwardInvocation:(NSInvocation *)anInvocation{
}
// 崩溃方法，可以重载这个方法在崩溃前做一些事情，但必须保证要抛出异常，苹果文档着重提到了这一点。
- (void)doesNotRecognizeSelector:(SEL)aSelector{
}
```
## 二、消息转发的使用场景
##### 一、强制要求子类重写某个方法

```
@interface Animal : NSObject
- (NSInteger)legCount;
@end

@implementation Animal
- (NSInteger)legCount {
    // 强制子类重写此方法,否则子类调用时会崩溃
    // -[subClass legCount]: unrecognized selector sent to instance 0x00000000
    if (![self isMemberOfClass:[Animal class]]) {
        [self doesNotRecognizeSelector:_cmd];
    }
    return 4;
}
@end

@interface Chicken : Animal
@end

@implementation Chicken
@end
```
##### 二、避免NSTimer添加到UIViewController导致UIViewController不能释放的问题

```
/*官方说明：

　　NSProxy is an abstract superclass defining an API for objects that act as stand-ins for other objects or for objects that don’t exist yet. Typically, a message to a proxy is forwarded to the real object or causes the proxy to load (or transform itself into) the real object. Subclasses of NSProxy can be used to implement transparent distributed messaging (for example, NSDistantObject) or for lazy instantiation of objects that are expensive to create.

　　由此可见，这个代理类可以让一个实例执行它本身未定义的方法，它可以通过设置"real object"（通过子类定义）来让NSProxy执行"real object"的方法。
*/
@interface MAProxy : NSProxy

@property (nonatomic, weak) id obj;
@property (nonatomic, strong) NSTimer *timer;

+ (id)allocWithObj:(id)obj;

@end
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
@end

// ----------------------------使用方法--------------------------
// NSTimer会在MAProxy里释放，这里可以不用手动释放
@implementation ViewController1
- (void)viewDidLoad {
    [super viewDidLoad];
    
    MAProxy *proxy = [MAProxy allocWithObj:self];
    proxy.timer = [NSTimer timerWithTimeInterval:1 target:proxy selector:@selector(testTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:proxy.timer forMode:NSRunLoopCommonModes];
}
@end
```
#####三、当方法找不到时，避免程序崩溃
1、调用```resolveInstanceMethod:```给个机会让类添加这个实现这个函数
2、调用```forwardingTargetForSelector:```让别的对象去执行这个函数
3、调用```methodSignatureForSelector:```（函数符号制造器）和```forwardInvocation```（函数执行器）灵活的将目标函数以其他形式执行。
如果都不中，调用```doesNotRecognizeSelector:```抛出异常。
```
@interface Person2 : NSObject

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

@interface StubProxy : NSProxy

+ (instancetype)sharedInstance;

@end

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

// ----------------------------使用方法--------------------------
// 动态添加方法,避免崩溃
- (void)test2 {
    Person2 *person = [[Person2 alloc]init];
    NSMutableString *str = (NSMutableString *)person;
    [str appendString:@"123"];
    NSLog(@"%@--%@", person, str);
}
```
##### 四、动态添加属性

```
@interface Person1 : NSObject
@property (nonatomic, copy) NSString *name;
@end

@interface Person1 (MA)
@property (nonatomic, copy) NSString *phone;
@end

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
// ----------------------------使用方法--------------------------
// KVC和动态添加属性
- (void)test1 {
    Person1 *person = [[Person1 alloc] init];
    person.name = @"Jhon";
    person.phone = @"112345435345";
    [person performSelector:NSSelectorFromString(@"setUrl:") withObject:@"http://www.baidu.com"];
    [person setValue:@"23" forKey:@"age"];
    NSLog(@"name:%@ phone:%@ url:%@ age:%@",person.name, person.phone, [person performSelector:NSSelectorFromString(@"url")] , [person valueForKey:@"age"]);
}
```
##### 五、多继承的实现

```
@interface TargrtProxy : NSProxy

@property (nonatomic, strong) id realObject1;
@property (nonatomic, strong) id realObject2;
+ (id)allocWithTarget1:(id)t1 target2:(id)t2;

@end

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
// ----------------------------使用方法--------------------------
// 多继承
- (void)test3 {
    NSMutableString *string = [[NSMutableString alloc] init];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    id proxy = [TargrtProxy allocWithTarget1:string target2:array];
    
    // Note that we can't use appendFormat:, because vararg methods
    // cannot be forwarded!
    [proxy appendString:@"This "];
    [proxy appendString:@"is "];
    [proxy addObject:string];
    [proxy appendString:@"a "];
    [proxy appendString:@"test!"];
    
    NSLog(@"count should be 1 15, it is: %lu  %lu", (unsigned long)[proxy count], (unsigned long)[proxy length]);
    
    if ([[proxy objectAtIndex:0] isEqualToString:@"This is a test!"]) {
        NSLog(@"Appending successful. %@", proxy);
    } else {
        NSLog(@"Appending failed, got: '%@'", proxy);
    }
    
    NSLog(@"Example finished without errors.");
}

```
##### 六、多代理的实现

```
@interface AIMultiDelegate : NSObject

/**
 The array of registered delegates.
 */
@property (readonly, nonatomic) NSPointerArray* delegates;

- (void)addDelegate:(id)delegate;

@end

@implementation AIMultiDelegate {
    NSPointerArray* _delegates;
}

- (void)addDelegate:(id)delegate {
    [_delegates addPointer:(__bridge void*)delegate];
}


- (BOOL)respondsToSelector:(SEL)selector {
    if ([super respondsToSelector:selector])
        return YES;

    for (id delegate in _delegates) {
        if (delegate && [delegate respondsToSelector:selector])
            return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature* signature = [super methodSignatureForSelector:selector];
    if (signature)
        return signature;
    
    [_delegates compact];
    if (self.silentWhenEmpty && _delegates.count == 0) {
        // return any method signature, it doesn't really matter
        return [self methodSignatureForSelector:@selector(description)];
    }

    for (id delegate in _delegates) {
        if (!delegate)
            continue;

        signature = [delegate methodSignatureForSelector:selector];
        if (signature)
            break;
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL selector = [invocation selector];
    BOOL responded = NO;
    
    NSArray *copiedDelegates = [_delegates copy];
    for (id delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:selector]) {
            [invocation invokeWithTarget:delegate];
            responded = YES;
        }
    }
    
    if (!responded && !self.silentWhenEmpty)
        [self doesNotRecognizeSelector:selector];
}

@end
```
参考文章：
[iOS unrecognized selector sent to instance 到底发生了什么](https://www.jianshu.com/p/9980d8879c57)
[ios之“多代理”，“多继承”,以及动态调用类方法实例方法](https://www.jianshu.com/p/cf3590fdc3a1)
[避免 NSTimer定时器 未调用 invalidate 而导致的内存泄露](https://www.jianshu.com/p/5fefc764fb83)
[拯救即将崩溃代码之Objective-C消息转发](https://blog.csdn.net/cooldragon/article/details/52497064)
[iOS如何实现多代理模式--OC](https://www.jianshu.com/p/fed580fa45eb)