//
//  NEAspectContainer.h
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NEAspectsOptions.h"
#import "NEAspectIdentifier.h"

@interface NEAspectContainer : NSObject

@property (atomic, copy) NSArray* beforeAspects;

@property (atomic, copy) NSArray* insteadAspects;

@property (atomic, copy) NSArray* afterAspects;



- (BOOL)hasAspects;

- (BOOL)removeAspect:(id)aspect;

- (void)addAspect:(NEAspectIdentifier *)identifier useOption:(NEAspectOptions)option;

@end
