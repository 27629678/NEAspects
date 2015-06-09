//
//  NEAspects.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspects.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import "NEAspectIdentifier.h"
#import "NEAspectContainer.h"
#import <libkern/OSAtomic.h>

static NSString* const Aspect_SubclassSuffix = @"_ne_aspect_";
static NSString* const Aspect_MessagePrefix  = @"_aspect_";

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

static SEL aspect_aliasSelector(SEL selector)
{
    NSString* selectorName = NSStringFromSelector(selector);
    NSString* aliasSelectorName = [Aspect_MessagePrefix stringByAppendingString:selectorName];
    return NSSelectorFromString(aliasSelectorName);
}

#define aspect_invoke(aspects, info) \
for (NEAspectIdentifier* identifier in aspects) { \
[identifier invokeWithAspectInfo:info]; \
} \

static void __aspect_are_being_called__(__unsafe_unretained NSObject *obj, SEL selector, NSInvocation *invocation)
{
    NSCParameterAssert(obj);
    NSCParameterAssert(selector);
    NSCParameterAssert(invocation);
    
    SEL originSelector = invocation.selector;
    SEL aliasSelector = aspect_aliasForSelector(originSelector);
    [invocation setSelector:aliasSelector];
    
    NEAspectContainer* objContainer = objc_getAssociatedObject(obj, aliasSelector);
    NEAspectContainer* clsContainer = objc_getAssociatedObject(object_getClass(obj), aliasSelector);
    
    NEAspectInfo* info = [[NEAspectInfo alloc] initWithTarget:obj invocation:invocation];
    
    // before
    aspect_invoke(objContainer.beforeAspects, info);
    aspect_invoke(clsContainer.beforeAspects, info);
    
    // instead
    BOOL responseToAlias = YES;
    if (objContainer.insteadAspects.count || clsContainer.insteadAspects.count) {
        aspect_invoke(objContainer.insteadAspects, info);
        aspect_invoke(clsContainer.insteadAspects, info);
    }
    else {
        Class class = object_getClass(invocation.target);
        do {
            if ((responseToAlias = [class instancesRespondToSelector:aliasSelector])) {
                [invocation invoke];
                break;
            }
        } while (!responseToAlias && (class = class_getSuperclass(class)));
    }
    
    // after
    aspect_invoke(objContainer.afterAspects, info);
    aspect_invoke(clsContainer.afterAspects, info);
    
    // no respond to selector
    if (!responseToAlias) {
        [invocation setSelector:originSelector];
        
        SEL originSelector = NSSelectorFromString(@"__aspect_forwardInvocation:");
        if ([obj respondsToSelector:originSelector]) {
            ((void(*)(NSObject *, SEL, NSInvocation *))objc_msgSend)(obj, originSelector, invocation);
        }
        else {
            [obj doesNotRecognizeSelector:invocation.selector];
        }
    }
}

static Class aspect_hookClass(NSObject *obj)
{
    NSCParameterAssert(obj);
    
    Class statedClass = [obj class];
    Class baseClass = object_getClass(obj);
    NSString* className = NSStringFromClass(baseClass);
    
    // has subclassed
    if ([className hasSuffix:Aspect_SubclassSuffix]) {
        return baseClass;
    }
    
    const char* subclassName = [[className stringByAppendingString:Aspect_SubclassSuffix] UTF8String];
    Class subclass = objc_getClass(subclassName);
    
    if (!subclass) {
        subclass = objc_allocateClassPair(baseClass, subclassName, 0);
        
        if (!subclass) {
            // failed to allocate a new subclass
            return nil;
        }
        
        // swizzle subclass' forward invocation method
        IMP originIMP = class_replaceMethod(subclass, @selector(forwardInvocation:), (IMP)__aspect_are_being_called__, "v@:@");
        if (originIMP) {
            class_addMethod(subclass, NSSelectorFromString(@"__aspect_forwardInvocation:"), originIMP, "v@:@");
        }
        
        NSLog(@"<Aspects:%@ now avalable.>", NSStringFromClass(subclass));
        
        // swizzle [subclass class]
        Method method = class_getInstanceMethod(subclass, @selector(class));
        IMP aIMP = imp_implementationWithBlock(^(id obj) {
            return statedClass;
        });
        
        class_replaceMethod(subclass, @selector(class), aIMP, method_getTypeEncoding(method));
        
        Class baseSubclass = object_getClass(subclass);
        method = class_getInstanceMethod(baseSubclass, @selector(class));
        class_replaceMethod(baseSubclass, @selector(class), aIMP, method_getTypeEncoding(method));
        
        objc_registerClassPair(subclass);
    }
    
    object_setClass(obj, subclass);
    
    return subclass;
}

static void aspect_prepareClassAndHookSelector(NSObject *obj, SEL selector, NSError **error)
{
    NSCParameterAssert(obj);
    NSCParameterAssert(selector);
    
    // construct a subclass
    Class subclass = aspect_hookClass(obj);
    
    // add hook to selector
    Method method = class_getInstanceMethod(subclass, selector);
    IMP imp = method_getImplementation(method);
    
    const char* typeEncoding = method_getTypeEncoding(method);
    SEL aliasSelector = aspect_aliasForSelector(selector);
    
    if (![subclass instancesRespondToSelector:aliasSelector]) {
        class_addMethod(subclass, aliasSelector, imp, typeEncoding);
    }
    
    imp = class_replaceMethod(subclass, selector, (IMP)_objc_msgForward, typeEncoding);
    NSLog(@"<Aspects:Installed hook for - [%@ %@]>", subclass, NSStringFromSelector(selector));
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
            
            aspect_prepareClassAndHookSelector(self, aSelector, error);
        }
    });
    
    return retIdentifier;
}

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

@end


