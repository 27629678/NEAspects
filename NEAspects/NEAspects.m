//
//  NEAspects.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspects.h"

#import <objc/runtime.h>
#import "NEAspectIdentifier.h"
#import "NEAspectContainer.h"
#import <libkern/OSAtomic.h>

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

static id aspect_add(id self, SEL aSelector, id block, NEAspectOptions option, NSError **error)
{
    NSCParameterAssert(self);
    NSCParameterAssert(block);
    NSCParameterAssert(aSelector);
    
    __block NEAspectIdentifier *retIdentifier = nil;
    aspect_executeInLock(^{
        if (!aspect_allowAddHook(self, aSelector, option, error)) {
            return;
        }
        
        NEAspectContainer* container = aspect_getContainer(self, aSelector);
        retIdentifier = [NEAspectIdentifier identifierWithTarget:self
                                                        selector:aSelector
                                                          option:option
                                                           block:block
                                                           error:error];
        if (retIdentifier) {
            [container addAspect:retIdentifier useOption:option];
            
            // hook selector
        }
    });
    
    
    
    
    return retIdentifier;
}

#pragma mark - private

static BOOL aspect_allowAddHook(NSObject *target, SEL aSelector, NEAspectOptions option, NSError **error)
{
    static NSSet* disallowedSelectorSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        disallowedSelectorSet = [NSSet setWithObjects:@"retain", @"release", @"autorelease", @"forwardInvocation:", nil];
    });
    
    NSString* selectorName = NSStringFromSelector(aSelector);
    if ([disallowedSelectorSet containsObject:selectorName]) {
        return NO;
    }
    
    NEAspectOptions position = option & 0x07;
    if ([selectorName isEqualToString:@"dealloc"] && position != NEAspectPositionBefore) {
        return NO;
    }
    
    if (class_isMetaClass(object_getClass(target))) {
        return NO;
    }
    
    return YES;
}

static void aspect_prepareClassAndHookSelector(NSObject* obj, SEL aSelector, NSError **error)
{
    NSCParameterAssert(obj);
    NSCParameterAssert(aSelector);
    
    
}


static NSMutableDictionary* aspect_getSwizzledClassesDict()
{
    static NSMutableDictionary* retDict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        retDict = [NSMutableDictionary dictionary];
    });
    
    return retDict;
}

static void aspect_executeInLock(dispatch_block_t block)
{
    static OSSpinLock aspect_lock = OS_SPINLOCK_INIT;
    
    OSSpinLockLock(&aspect_lock);
    if (block) block();
    OSSpinLockUnlock(&aspect_lock);
}

static SEL aspect_aliasForSelector(SEL selector) {
    NSCParameterAssert(selector);
    return NSSelectorFromString([@"aspects" stringByAppendingFormat:@"_%@", NSStringFromSelector(selector)]);
}

static NEAspectContainer* aspect_getContainer(NSObject* obj, SEL selector)
{
    NSCParameterAssert(obj);
    
    SEL aliasSelector = aspect_aliasForSelector(selector);
    NEAspectContainer* retContainer = objc_getAssociatedObject(obj, aliasSelector);
    
    if (!retContainer) {
        retContainer = [NEAspectContainer new];
        objc_setAssociatedObject(obj, aliasSelector, retContainer, OBJC_ASSOCIATION_RETAIN);
    }
    
    return retContainer;
}

@end
