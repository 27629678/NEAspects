//
//  NEAspectIdentifier.h
//  NEAspects
//
//  Created by H-YXH on 6/8/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NEAspectInfo.h"
#import "NEAspectsOptions.h"

@interface NEAspectIdentifier : NSObject

@property (nonatomic, weak) id aTarget;

@property (nonatomic, strong) id aBlock;

@property (nonatomic, assign) SEL aSelector;

@property (nonatomic, assign) NEAspectOptions option;

@property (nonatomic, strong) NSMethodSignature* aSignature;

+ (instancetype)identifierWithTarget:(id)target
                            selector:(SEL)selector
                              option:(NEAspectOptions)option
                               block:(id)block
                               error:(NSError **)error;

- (BOOL)invokeWithAspectInfo:(id<NEAspectInfo>)info;

@end
