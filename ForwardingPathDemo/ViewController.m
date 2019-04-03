//
//  ViewController.m
//  ForwardingPathDemo
//
//  Created by admin on 3/29/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "Person1.h"
#import "Person2.h"
#import "TargrtProxy.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self test];
    [self test1];
    [self test2];
    [self test3];
}
// 强制子类重写某个方法
- (void)test {
    //    下面代码会崩溃,提示-[Man legCount]: unrecognized selector sent to instance 0x60000201cb60
    Man *man = [[Man alloc] init];
    @try {
        NSString *sex = [man sex];
        NSLog(@"%@",sex);
    } @catch (NSException *exception) {
    }
}
// KVC和动态添加属性
- (void)test1 {
    Person1 *person = [[Person1 alloc] init];
    person.name = @"Jhon";
    person.phone = @"112345435345";
    [person performSelector:NSSelectorFromString(@"setUrl:") withObject:@"http://www.baidu.com"];
    [person setValue:@"23" forKey:@"age"];
    NSLog(@"name:%@ phone:%@ url:%@ age:%@",person.name, person.phone, [person performSelector:NSSelectorFromString(@"url")] , [person valueForKey:@"age"]);
}
// 动态添加方法,避免崩溃
- (void)test2 {
    Person2 *person = [[Person2 alloc]init];
    NSMutableString *str = (NSMutableString *)person;
    [str appendString:@"123"];
    NSLog(@"%@--%@", person, str);
}

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




@end
