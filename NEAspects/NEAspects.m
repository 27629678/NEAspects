//
//  NEAspects.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspects.h"

@implementation NSObject (NEAspects)

#pragma mark - public api

+ (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError *__autoreleasing *)error
{
    return aspect_add(self, aSelector, block, option, error);
}

- (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError *__autoreleasing *)error
{
    return aspect_add(self, aSelector, block, option, error);
}

static BOOL aspect_allowAddHook(NSObject *target, SEL aSelector, NEAspectOptions option, NSError **error)
{
    
    
    
    return YES;
}

static id aspect_add(id self, SEL aSelector, id block, NEAspectOptions option, NSError **error)
{
    NSCParameterAssert(self);
    NSCParameterAssert(block);
    NSCParameterAssert(aSelector);
    
    if (!aspect_allowAddHook(self, aSelector, option, error)) return nil;
    
    
    
    
    return nil;
}




@end
