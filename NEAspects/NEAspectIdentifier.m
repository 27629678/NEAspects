//
//  NEAspectIdentifier.m
//  NEAspects
//
//  Created by H-YXH on 6/8/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspectIdentifier.h"

#import <objc/runtime.h>


static NSMethodSignature* aspect_blockSignature(id block, NSError **error)
{
    AspectBlockRef block_ref = (__bridge void *)block;
    
    if (!(block_ref->flags & AspectBlockFlagsHasSignature)) {
        // has no method signature
        return nil;
    }
    
    void* desc = block_ref->descriptor;
    desc += 2 * sizeof(unsigned long int);
    
    if (block_ref->flags & AspectBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    
    if (!desc) {
        // has no method signature
        return nil;
    }
    
    const char* signature = *((const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

static BOOL aspect_isCompatibleBlockSignature(NSMethodSignature *blockSignature, id object, SEL selector, NSError **error) {
    NSCParameterAssert(blockSignature);
    NSCParameterAssert(object);
    NSCParameterAssert(selector);
    
    BOOL signaturesMatch = YES;
    NSMethodSignature *methodSignature = [[object class] instanceMethodSignatureForSelector:selector];
    if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
        signaturesMatch = NO;
    }else {
        if (blockSignature.numberOfArguments > 1) {
            const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
            if (blockType[0] != '@') {
                signaturesMatch = NO;
            }
        }
        // Argument 0 is self/block, argument 1 is SEL or id<AspectInfo>. We start comparing at argument 2.
        // The block can have less arguments than the method, that's ok.
        if (signaturesMatch) {
            for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
                const char *methodType = [methodSignature getArgumentTypeAtIndex:idx];
                const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
                // Only compare parameter, not the optional type data.
                if (!methodType || !blockType || methodType[0] != blockType[0]) {
                    signaturesMatch = NO; break;
                }
            }
        }
    }
    
    if (!signaturesMatch) {
        // signature does not match
        return NO;
    }
    return YES;
}

@interface NEAspectIdentifier () <NEAspectInfo>

@end

@implementation NEAspectIdentifier

+ (instancetype)identifierWithTarget:(id)target
                            selector:(SEL)selector
                              option:(NEAspectOptions)option
                               block:(id)block
                               error:(NSError *__autoreleasing *)error
{
    NSCParameterAssert(block);
    NSCParameterAssert(selector);
    NSMethodSignature* aSignature = aspect_blockSignature(block, error);
    
    if (!aSignature) {
        return nil;
    }
    
    if (!aspect_isCompatibleBlockSignature(aSignature, target, selector, error)) {
        return nil;
    }
    
    NEAspectIdentifier* retIdentifier = [NEAspectIdentifier new];
    
    [retIdentifier setABlock:block];
    [retIdentifier setOption:option];
    [retIdentifier setATarget:target];
    [retIdentifier setASelector:selector];
    [retIdentifier setASignature:aSignature];
    
    return retIdentifier;
}

- (BOOL)invokeWithAspectInfo:(id<NEAspectInfo>)info
{
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:_aSignature];
    NSInvocation* orig_invoc = info.originalInvocation;
    NSUInteger argumentsCount= _aSignature.numberOfArguments;
    
    if (argumentsCount > orig_invoc.methodSignature.numberOfArguments) {
        return NO;
    }
    
    if (argumentsCount > 1) {
        [invocation setArgument:&info atIndex:1];
    }
    
    void* argBuf = NULL;
    for (NSUInteger idx = 2; idx < argumentsCount; idx ++) {
        const char *type = [orig_invoc.methodSignature getArgumentTypeAtIndex:idx];
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(type, &valueSize, NULL);
        
        if (!(argBuf = reallocf(argBuf, valueSize))) {
            return NO;
        }
        
        [orig_invoc getArgument:argBuf atIndex:idx];
        [invocation setArgument:argBuf atIndex:idx];
    }
    
    [invocation invokeWithTarget:_aBlock];
    
    if (argBuf != NULL) {
        free(argBuf);
    }
    
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, SEL:%@ object:%@ options:%tu block:%@ (#%tu args)>", self.class, self, NSStringFromSelector(self.aSelector), self.aTarget, self.option, self.aBlock, self.aSignature.numberOfArguments];
}

- (BOOL)remove
{
    // 未完成
    return YES;
}

@end
