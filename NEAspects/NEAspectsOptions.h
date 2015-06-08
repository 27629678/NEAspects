//
//  NEAspectsOptions.h
//  NEAspects
//
//  Created by H-YXH on 6/8/15.
//  Copyright (c) 2015 NetEase (hangzhou) Network Co.,Ltd. All rights reserved.
//

#ifndef NEAspects_NEAspectsOptions_h
#define NEAspects_NEAspectsOptions_h

typedef NS_OPTIONS(NSUInteger, NEAspectOptions) {
    NEAspectPositionAfter   = 0,
    NEAspectPositionInstead = 1,
    NEAspectPositionBefore  = 2,
    
    NEAspectOptionAutomaticRemoval = 1 << 3,
};

// Block internals.
typedef NS_OPTIONS(int, AspectBlockFlags) {
    AspectBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    AspectBlockFlagsHasSignature          = (1 << 30)
};

typedef struct _AspectBlock {
    __unused Class isa;
    AspectBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct _AspectBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires AspectBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires AspectBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *AspectBlockRef;

#endif
