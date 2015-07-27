//
//  NSError+MWKErrors.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const MWKErrorDomain;

typedef NS_ENUM (NSInteger, MWKErrorCode) {
    MWKEmptyTitleError = 1
};

@interface NSError (MWKErrors)

+ (instancetype)mwk_emptyTitleError;

+ (instancetype)mwk_errorWithCode:(MWKErrorCode)code userInfo:(NSDictionary*)userInfo;

@end
