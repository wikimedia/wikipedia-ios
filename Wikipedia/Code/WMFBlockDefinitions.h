//
//  WMFBlockDefinitions.h
//  Wikipedia
//
//  Created by Corey Floyd on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#ifndef Wikipedia_WMFBlockDefinitions_h
#define Wikipedia_WMFBlockDefinitions_h

@class MWKArticle;

typedef void (^ WMFArticleHandler)(MWKArticle* article);
typedef void (^ WMFProgressHandler)(CGFloat progress);
typedef void (^ WMFErrorHandler)(NSError* error);

typedef void (^ WMFSuccessHandler)();
typedef void (^ WMFSuccessIdHandler)(id object);
typedef void (^ WMFSuccessUIImageHandler)(UIImage* image);
typedef void (^ WMFSuccessNSValueHandler)(NSValue* value);


static WMFErrorHandler WMFIgnoreErrorHandler = ^(NSError* error) { };
static WMFSuccessHandler WMFIgnoreSuccessHandler = ^() { };

#endif
