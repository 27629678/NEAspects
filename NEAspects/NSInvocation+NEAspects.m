//
//  NSInvocation+NEAspects.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NSInvocation+NEAspects.h"

#import <objc/runtime.h>

#define WRAP_AND_RETURN(type) \
do {\
    type val = 0;\
    [self getArgument:&val atIndex:(NSInteger)index];\
    return @(val);\
} while (0)

@implementation NSInvocation (NEAspects)

// Thanks to the ReactiveCocoa team for providing a generic solution for this.
- (id)aspect_argumentAtIndex:(NSUInteger)index
{
    const char *argType = [self.methodSignature getArgumentTypeAtIndex:index];
    
    // skip const argument type
    if (argType[0] == _C_CONST) argType ++;
    
    // id
    if (strcmp(argType, @encode(id)) == 0) {
        __autoreleasing id retObj = nil;
        [self getArgument:&retObj atIndex:index];
        
        return retObj;
    }
    // selector
    else if (strcmp(argType, @encode(SEL)) == 0) {
        SEL retSelector = 0;
        [self getArgument:&retSelector atIndex:index];
        
        return NSStringFromSelector(retSelector);
    }
    // class
    else if (strcmp(argType, @encode(Class)) == 0) {
        __autoreleasing Class retClass = Nil;
        [self getArgument:&retClass atIndex:index];
        
        return retClass;
    }
    // char
    else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    }
    // unsigned char
    else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    }
    // BOOL
    else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    }
    // bool
    else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(bool);
    }
    // int
    else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    }
    // short
    else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    }
    // unsinged short
    else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    }
    // unsigned int
    else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    }
    // long
    else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    }
    // unsigned long
    else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    }
    // long long
    else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    }
    // unsigned long long
    else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    }
    // fload
    else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    }
    // double
    else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    }
    // block
    else if (strcmp(argType, @encode(void(^)(void))) == 0) {
        __autoreleasing id block = nil;
        [self getArgument:&block atIndex:index];
        
        return [block copy];
    }
    
    NSUInteger valueSize = 0;
    NSGetSizeAndAlignment(argType, &valueSize, NULL);
    unsigned char* valueBytes[valueSize];
    [self getArgument:valueBytes atIndex:index];
    
    return [NSValue valueWithBytes:valueBytes objCType:argType];
}

- (NSArray *)aspects_arguments
{
    NSMutableArray* retArguments = [NSMutableArray array];
    
    // 1st of arguments is self
    // 2nd of arguments is __cmd
    // 3rd of arguments is first parameter
    for (NSUInteger idx = 2; idx < self.methodSignature.numberOfArguments; idx ++) {
        [retArguments addObject:[self aspect_argumentAtIndex:idx] ? : [NSNull null]];
    }
    
    return retArguments;
}

@end
