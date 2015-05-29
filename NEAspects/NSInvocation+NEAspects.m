//
//  NSInvocation+NEAspects.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NSInvocation+NEAspects.h"

@implementation NSInvocation (NEAspects)

- (NSArray *)aspects_arguments
{
    NSMutableArray* retArguments = [NSMutableArray array];
    
    // 1st of arguments is self
    // 2nd of arguments is __cmd
    // 3rd of arguments is first parameter
    for (NSUInteger idx = 2; idx < self.methodSignature.numberOfArguments; idx ++) {
        [retArguments addObject:nil ? : [NSNull null]];
    }
    
    return retArguments;
}

@end
