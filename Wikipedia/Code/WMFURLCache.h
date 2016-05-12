//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class MWKArticle;

@interface WMFURLCache : NSURLCache

- (void)permanentlyCacheImagesForArticle:(MWKArticle*)article;

- (UIImage*)cachedImageForURL:(NSURL*)url;

@end
