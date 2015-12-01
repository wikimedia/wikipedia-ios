//
//  CIContext+WMFImageProcessing.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/21/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "CIContext+WMFImageProcessing.h"

@implementation CIContext (WMFImageProcessing)

+ (instancetype)wmf_sharedBackgroundContext {
    static CIContext* sharedBackgroundContext;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedBackgroundContext = [self wmf_backgroundContext];
    });
    return sharedBackgroundContext;
}

+ (instancetype)wmf_backgroundContext {
    return [CIContext contextWithOptions:[self wmf_backgroundContextOptions]];
}

+ (NSDictionary*)wmf_backgroundContextOptions {
    static NSDictionary* backgroundContextOptions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* options = [NSMutableDictionary new];
        options[kCIContextUseSoftwareRenderer] = @YES;
        options[kCIContextPriorityRequestLow] = @YES;
        backgroundContextOptions = [options copy];
    });
    return backgroundContextOptions;
}

@end
