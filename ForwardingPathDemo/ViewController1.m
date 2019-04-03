//
//  ViewController1.m
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "ViewController1.h"
#import "MAProxy.h"
#import "SafeTimer.h"

@interface ViewController1 ()

@property (nonatomic, weak) MAProxy *proxy;
@property (nonatomic, assign) NSInteger  count;

@end

@implementation ViewController1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MAProxy *proxy = [MAProxy allocWithObj:self];
    proxy.timer = [NSTimer timerWithTimeInterval:1 target:proxy selector:@selector(testTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:proxy.timer forMode:NSRunLoopCommonModes];

    NSTimer *timer = [SafeTimer timerWithTimeInterval:1 target:self selector:@selector(testTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)testTimer:(NSTimer *)timer {
    self.count += 1;
    NSLog(@"%ld--%@",self.count,timer);
}

- (void)dealloc {
//    [self.proxy.timer invalidate];
    NSLog(@"%s", __func__);
}

@end
