//
//  WMFNetworkUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFNetworkUtilities.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

NSString* const WMFNetworkingErrorDomain = @"WMFNetworkingErrorDomain";

NSString* WMFJoinedPropertyParameters(NSArray* props){
    return [props ? : @[] componentsJoinedByString:@"|"];
}

NSError* WMFErrorForApiErrorObject(NSDictionary* apiError){
    if (!apiError) {
        return nil;
    }
    // build the dictionary this way to avoid early nil termination caused by missing keys in the error obj
    NSMutableDictionary* userInfoBuilder = [NSMutableDictionary dictionaryWithCapacity:3];
    void (^ maybeMapApiToUserInfo)(NSString*, NSString*) = ^(NSString* userInfoKey, NSString* apiErrorKey) {
        [userInfoBuilder wmf_maybeSetObject:apiError[apiErrorKey] forKey:userInfoKey];
    };
    maybeMapApiToUserInfo(NSLocalizedDescriptionKey, @"code");
    maybeMapApiToUserInfo(NSLocalizedFailureReasonErrorKey, @"info");
    maybeMapApiToUserInfo(NSLocalizedRecoverySuggestionErrorKey, @"*");
    return [NSError errorWithDomain:WMFNetworkingErrorDomain code:WMFNetworkingError_APIError userInfo:userInfoBuilder];
}