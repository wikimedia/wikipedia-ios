//
//  AFHTTPRequestOperationManager+UniqueRequests.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@interface AFHTTPRequestOperationManager (UniqueRequests)

/**
 * Find an <b>executing</b> operation matching the specified criteria.
 * @param method        The HTTP method, e.g. @c @"GET".
 * @param URLString     The URL, sans any query parameters.
 * @param parameters    Any request parameters which would be passed to the receiver's @c requestSerializer.
 * @return An operation with a request which matches the output of the receiver's @c requestSerializer when given the
 *         specified arguments, or @c nil if none is found.
 */
- (AFHTTPRequestOperation*)wmf_findOperationWithMethod:(NSString*)method
                                             URLString:(NSString *)URLString
                                            parameters:(id)parameters;

/**
 * Send a @c GET request, if there isn't a similar operation already in flight.
 * @see -wmf_findOperationWithMethod:URLString:parameters
 * @see -GET:parameters:success:failure
 */
- (AFHTTPRequestOperation*)wmf_idempotentGET:(NSString*)URLString
                                  parameters:(id)parameters
                                     success:(void(^)(AFHTTPRequestOperation* op, id response))success
                                     failure:(void(^)(AFHTTPRequestOperation* op, NSError* error))failure;

@end
