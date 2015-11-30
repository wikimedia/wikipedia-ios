//
//  NSURLRequest+WMFUtilities.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (WMFUtilities)

- (BOOL)wmf_isInterceptedImageType;

- (BOOL)wmf_isImageMIMEType;

@end
