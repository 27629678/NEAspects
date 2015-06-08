//
//  NEAspects.h
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NEAspectsOptions.h"

@interface NSObject (NEAspects)

+ (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError **)error;

- (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError **)error;

@end
