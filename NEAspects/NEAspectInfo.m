//
//  NEAspectInfo.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspectInfo.h"

#import "NSInvocation+NEAspects.h"

@implementation NEAspectInfo
@synthesize arguments = _arguments;

- (instancetype)initWithTarget:(__unsafe_unretained id)target invocation:(NSInvocation *)invocation
{
    NSCParameterAssert(target);
    NSCParameterAssert(invocation);
    
    self = [super init];
    
    if (self) {
        _target = target;
        _originalInvocation = invocation;
    }
    
    return self;
}

- (NSArray *)arguments
{
    if (!_arguments) {
        _arguments = self.originalInvocation.aspects_arguments;
    }
    
    return _arguments;
}

@end
