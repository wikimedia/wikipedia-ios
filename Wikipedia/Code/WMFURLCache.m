//  Created by Monte Hurd on 12/10/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFURLCache.h"
#import "SessionSingleton.h"
#import "FBTweak+WikipediaZero.h"
#import "NSURL+WMFExtras.h"
#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MWKImage.h"
#import "Wikipedia-Swift.h"

static NSString* const WMFURLCacheWikipediaHost = @".m.wikipedia.org";
static NSString* const WMFURLCacheJsonMIMEType  = @"application/json";
static NSString* const WMFURLCache00000         = @"000-00";
static NSString* const WMFURLCacheState         = @"state";
static NSString* const WMFURLCacheXCS           = @"X-CS";

@implementation WMFURLCache

- (void)permanentlyCacheImagesForArticle:(MWKArticle*)article {
    [article.images.entries enumerateObjectsUsingBlock:^(NSString* _Nonnull imagePath, NSUInteger idx, BOOL* _Nonnull stop) {
        MWKImage* image = [article.images objectAtIndexedSubscript:idx];
        NSURL* url = image.sourceURL;
        if (!url) {
            return;
        }

        NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

        NSCachedURLResponse* response = [self cachedResponseForRequest:request];

        if (response.data.length > 0) {
            [[WMFImageController sharedInstance] cacheImageData:response.data url:url MIMEType:response.response.MIMEType];
        }
    }];
}

- (UIImage*)cachedImageForURL:(NSURL*)url {
    if (!url) {
        return nil;
    }

    NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

    NSCachedURLResponse* response = [self cachedResponseForRequest:request];

    if (response.data.length > 0) {
        return [UIImage imageWithData:response.data];
    } else if ([url wmf_isSchemeless]) {
        return [self cachedImageForURL:[url wmf_urlByPrependingSchemeIfSchemeless]];
    } else {
        return nil;
    }
}

- (BOOL)isMIMETypeImage:(NSString*)type {
    return [type hasPrefix:@"image"];
}

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request {
    NSString* mimeType = [request.URL wmf_mimeTypeForExtension];
    if ([self isMIMETypeImage:mimeType] && [[WMFImageController sharedInstance] hasDataOnDiskForImageWithURL:request.URL]) {
        WMFTypedImageData* typedData = [[WMFImageController sharedInstance] typedDiskDataForImageWithURL:request.URL];
        NSData* data                 = typedData.data;
        NSString* mimeType           = typedData.MIMEType;

        if (data.length > 0) {
            NSURLResponse* response             = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:data.length textEncodingName:nil];
            NSCachedURLResponse* cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            return cachedResponse;
        }
    }

    return [super cachedResponseForRequest:request];
}

- (void)storeCachedResponse:(NSCachedURLResponse*)cachedResponse forRequest:(NSURLRequest*)request {
    [super storeCachedResponse:cachedResponse forRequest:request];

    if ([self isJsonResponse:cachedResponse fromMDotRequest:request]) {
        //NSLog(@"Processing zero headers for cached repsonse from %@", request);
//TODO: should refactor a lot of this into ZeroConfigState itself and make it thread safe so we can do its work off the main thread.
        [self processZeroHeaders:cachedResponse.response];
    }
}

- (BOOL)isJsonResponse:(NSCachedURLResponse*)cachedResponse fromMDotRequest:(NSURLRequest*)request  {
    return ([[request URL].host hasSuffix:WMFURLCacheWikipediaHost] && [cachedResponse.response.MIMEType isEqualToString:WMFURLCacheJsonMIMEType]);
}

- (void)processZeroHeaders:(NSURLResponse*)response {
    NSHTTPURLResponse* httpUrlResponse = (NSHTTPURLResponse*)response;
    NSDictionary* headers              = httpUrlResponse.allHeaderFields;
    NSString* xZeroRatedHeader         = [headers objectForKey:WMFURLCacheXCS];
    BOOL zeroRatedHeaderPresent        = xZeroRatedHeader != nil;
    NSString* xcs                      = [SessionSingleton sharedInstance].zeroConfigState.partnerXcs;
    BOOL zeroProviderChanged           = zeroRatedHeaderPresent && ![xZeroRatedHeader isEqualToString:xcs];
    BOOL zeroDisposition               = [SessionSingleton sharedInstance].zeroConfigState.disposition;

    // enable this tweak to make the cache pretend it found W0 headers in the response
    if ([FBTweak wmf_shouldMockWikipediaZeroHeaders]) {
        zeroRatedHeaderPresent = YES;
        xZeroRatedHeader       = WMFURLCache00000;
    }

    if (zeroRatedHeaderPresent && (!zeroDisposition || zeroProviderChanged)) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = YES;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = xZeroRatedHeader;
    } else if (!zeroRatedHeaderPresent && zeroDisposition) {
        [SessionSingleton sharedInstance].zeroConfigState.disposition = NO;
        [SessionSingleton sharedInstance].zeroConfigState.partnerXcs  = nil;
    }
}

@end
