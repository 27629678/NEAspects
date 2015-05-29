//
//  NEAspectInfo.h
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NEAspectInfo <NSObject>

- (id)target;

- (NSInvocation *)originalInvocation;

- (NSArray *)arguments;

@end

@interface NEAspectInfo : NSObject <NEAspectInfo>

- (instancetype)initWithTarget:(__unsafe_unretained id)target invocation:(NSInvocation *)invocation;

@property (nonatomic, unsafe_unretained, readonly) id target;

@property (nonatomic, strong, readonly) NSArray *arguments;

@property (nonatomic, strong, readonly) NSInvocation *originalInvocation;

@end
