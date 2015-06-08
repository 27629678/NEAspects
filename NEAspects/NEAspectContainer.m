//
//  NEAspectContainer.m
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import "NEAspectContainer.h"

@implementation NEAspectContainer

- (BOOL)hasAspects
{
    return _beforeAspects.count > 0 || _insteadAspects.count > 0 || _afterAspects.count > 0;
}

- (BOOL)removeAspect:(id)aspect {
    for (NSString *aspectArrayName in @[NSStringFromSelector(@selector(beforeAspects)),
                                        NSStringFromSelector(@selector(insteadAspects)),
                                        NSStringFromSelector(@selector(afterAspects))])
    {
        NSArray *array = [self valueForKey:aspectArrayName];
        NSUInteger index = [array indexOfObjectIdenticalTo:aspect];
        
        if (!array || index == NSNotFound) {
            return YES;
        }
        
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:array];
        [newArray removeObjectAtIndex:index];
        [self setValue:newArray forKey:aspectArrayName];
        
        return YES;
    }
    
    return NO;
}

- (void)addAspect:(NEAspectIdentifier *)identifier useOption:(NEAspectOptions)option
{
    NSCParameterAssert(identifier);
    
    NEAspectOptions position = option & 0x07;
    
    switch (position) {
        case NEAspectPositionBefore:
            _beforeAspects = [(_beforeAspects ? : @[]) arrayByAddingObject:identifier];
            break;
            
        case NEAspectPositionInstead:
            _insteadAspects = [(_insteadAspects ? : @[]) arrayByAddingObject:identifier];
            break;

        case NEAspectPositionAfter:
            _afterAspects = [(_afterAspects ? : @[]) arrayByAddingObject:identifier];
            break;
            
        case NEAspectOptionAutomaticRemoval:
            
            break;
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, before:%@, instead:%@, after:%@>", self.class, self, self.beforeAspects, self.insteadAspects, self.afterAspects];
}

@end
