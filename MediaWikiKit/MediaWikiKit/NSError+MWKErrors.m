//
//  NSError+MWKErrors.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSError+MWKErrors.h"

NSString* const MWKErrorDomain = @"MWKErrorDomain";

@implementation NSError (MWKErrors)

+ (instancetype)mwk_emptyTitleError {
    return [self mwk_errorWithCode:MWKEmptyTitleError userInfo:@{
                NSLocalizedDescriptionKey: MWLocalizedString(@"mwk-empty-title-error", nil)
            }];
}

+ (instancetype)mwk_errorWithCode:(MWKErrorCode)code userInfo:(NSDictionary*)userInfo {
    return [NSError errorWithDomain:MWKErrorDomain code:code userInfo:userInfo];
}

@end
