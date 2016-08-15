//
//  WMFHTTPHangingProtocol.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/25/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFHTTPHangingProtocol.h"

@implementation WMFHTTPHangingProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme hasPrefix:@"http"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // Nope
}

- (void)stopLoading {
    // Double nope
}

@end
