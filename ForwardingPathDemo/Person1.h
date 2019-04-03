//
//  Person1.h
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person1 : NSObject

@property (nonatomic, copy) NSString *name;

@end

@interface Person1 (MA)

@property (nonatomic, copy) NSString *phone;

@end
