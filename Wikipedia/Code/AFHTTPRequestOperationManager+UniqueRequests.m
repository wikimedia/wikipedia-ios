//
//  AFHTTPRequestOperationManager+UniqueRequests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "AFHTTPRequestOperationManager+UniqueRequests.h"
#import <BlocksKit/BlocksKit.h>

@implementation AFHTTPRequestOperationManager (UniqueRequests)

- (AFHTTPRequestOperation*)wmf_findOperationWithMethod:(NSString*)method
                                             URLString:(NSString*)URLString
                                            parameters:(id)parameters {
    NSURLRequest* request = [self.requestSerializer requestWithMethod:method
                                                            URLString:URLString
                                                           parameters:parameters
                                                                error:nil];
    if (!request) {
        return nil;
    }
    return [self.operationQueue.operations bk_match:^BOOL (AFHTTPRequestOperation* op) {
        return [op.request isEqual:request];
    }];
}

- (AFHTTPRequestOperation*)wmf_idempotentGET:(NSString*)URLString
                                  parameters:(id)parameters
                                     success:(void (^)(AFHTTPRequestOperation* op, id response))success
                                     failure:(void (^)(AFHTTPRequestOperation* op, NSError* error))failure {
    if ([self wmf_findOperationWithMethod:@"GET" URLString:URLString parameters:parameters]) {
        return nil;
    } else {
        return [self GET:URLString parameters:parameters success:success failure:failure];
    }
}

@end
