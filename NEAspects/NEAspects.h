//
//  NEAspects.h
//  NEAspects
//
//  Created by H-YXH on 5/29/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, NEAspectOptions) {
    NEAspectPositionAfter   = 0,
    NEAspectPositionInstead = 1,
    NEAspectPositionBefore  = 2,
    
    NEAspectOptionAutomaticRemoval = 1 << 3,
};

@interface NSObject (NEAspects)

+ (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError **)error;

- (id)aspect_hookSelector:(SEL)aSelector withOption:(NEAspectOptions)option usingBlock:(id)block error:(NSError **)error;

@end
