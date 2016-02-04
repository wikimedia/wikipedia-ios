//
//  NSURLRequest+WMFUtilities.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSURLRequest+WMFUtilities.h"
#import "NSURL+WMFExtras.h"

/*
   HAX: We need to rely on the request's path extension for these checks since UIWebView doesn't set "Accept" headers
   when requesting data for an <img>'s src.
 */

@implementation NSURLRequest (WMFUtilities)

- (BOOL)wmf_isInterceptedImageType {
    static NSSet* interceptedImageTypes = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        interceptedImageTypes = [NSSet setWithObjects:@"jpeg", @"png", @"gif", nil];
    });
    NSString* imageType = [[[self.URL wmf_mimeTypeForExtension] componentsSeparatedByString:@"/"] lastObject];
    return imageType.length && [interceptedImageTypes containsObject:imageType];
}

- (BOOL)wmf_isImageMIMEType {
    return [[self.URL wmf_mimeTypeForExtension] hasPrefix:@"image"];
}

@end
