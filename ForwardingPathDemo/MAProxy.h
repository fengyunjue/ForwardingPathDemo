//
//  MAProxy.h
//  ForwardingPathDemo
//
//  Created by admin on 4/1/19.
//  Copyright © 2019 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

/*官方说明：

　　NSProxy is an abstract superclass defining an API for objects that act as stand-ins for other objects or for objects that don’t exist yet. Typically, a message to a proxy is forwarded to the real object or causes the proxy to load (or transform itself into) the real object. Subclasses of NSProxy can be used to implement transparent distributed messaging (for example, NSDistantObject) or for lazy instantiation of objects that are expensive to create.

　　由此可见，这个代理类可以让一个实例执行它本身未定义的方法，它可以通过设置"real object"（通过子类定义）来让NSProxy执行"real object"的方法。
*/
@interface MAProxy : NSProxy

@property (nonatomic, weak) id obj;
@property (nonatomic, strong) NSTimer *timer;

+ (id)allocWithObj:(id)obj;

@end
