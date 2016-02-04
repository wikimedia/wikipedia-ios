//  Created by Monte Hurd on 4/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleImageProtocol.h"
#import "SessionSingleton.h"
#import "Wikipedia-Swift.h"

#import "MWKImage.h"
#import "MWKArticle.h"

#import "UIImage+WMFSerialization.h"
#import "NSURLRequest+WMFUtilities.h"
#import "NSString+WMFExtras.h"
#import "NSURL+WMFExtras.h"
#import "NSURL+WMFRest.h"

// Set the level for logs in this file
#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFArticleImageProtocolLogLevel
static const int WMFArticleImageProtocolLogLevel = DDLogLevelInfo;

#pragma mark - Constants

NSString* const WMFArticleImageSectionImageRetrievedNotification = @"WMFSectionImageRetrieved";
static NSString* const WMFArticleImageProtocolHost               = @"upload.wikimedia.org";

@implementation WMFArticleImageProtocol

#pragma mark - Registration & Initialization

+ (void)load {
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    BOOL canInit = [request.URL wmf_isHTTP]
                   && [request.URL.host wmf_caseInsensitiveContainsString:WMFArticleImageProtocolHost]
                   && [request wmf_isInterceptedImageType]
                   && ![[WMFImageController sharedInstance] isDownloadingImageWithURL:request.URL];
    DDLogVerbose(@"%@ request: %@", canInit ? @"Intercepting" : @"Skipping", request);
    return canInit;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

#pragma mark - NSURLProtocol

- (void)stopLoading {
    [[WMFImageController sharedInstance] cancelFetchForURL:self.request.URL];
}

- (void)startLoading {
    DDLogVerbose(@"Fetching image %@", self.request.URL);
    [[WMFImageController sharedInstance] fetchImageWithURL:self.request.URL]
    .thenInBackground(^(WMFImageDownload* download) {
        [self respondWithDataFromDownload:download];
    })
    .catch(^(NSError* err) {
        [self respondWithError:err];
    });
}

#pragma mark - Callbacks

- (void)respondWithDataFromDownload:(WMFImageDownload*)download {
    UIImage* image     = download.image;
    NSString* mimeType = [self.request.URL wmf_mimeTypeForExtension];
    NSData* data       = [image wmf_dataRepresentationForMimeType:mimeType serializedMimeType:&mimeType];
    DDLogVerbose(@"Sending image response for %@", self.request.URL);
    NSURLResponse* response =
        [[NSURLResponse alloc] initWithURL:self.request.URL
                                  MIMEType:mimeType
                     expectedContentLength:data.length
                          textEncodingName:nil];

    // prevent browser from caching images (hopefully?)
    [[self client] URLProtocol:self
            didReceiveResponse:response
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)respondWithError:(NSError*)error {
    DDLogError(@"Failed to fetch image at %@ due to %@", self.request.URL, error);
    [self.client URLProtocol:self didFailWithError:error];
}

@end
