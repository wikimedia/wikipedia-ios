//
//  WMFNetworkUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/// @name Constants

FOUNDATION_EXPORT NSString* const WMFNetworkingErrorDomain;

typedef NS_ENUM (NSInteger, WMFNetworkingError) {
    WMFNetworkingError_APIError
};


/// @name Functions

/**
 * Take an array of strings and concatenate them with "|" as a delimiter.
 * @return A string of the concatenated elements, or an empty string if @c props is empty or @c nil.
 */
FOUNDATION_EXPORT NSString* WMFJoinedPropertyParameters(NSArray* props);

FOUNDATION_EXPORT NSError* WMFErrorForApiErrorObject(NSDictionary* apiError);
