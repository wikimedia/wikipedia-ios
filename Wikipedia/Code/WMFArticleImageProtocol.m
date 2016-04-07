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
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:self.request.URL]
    .thenInBackground(^id(WMFImageDownload* download) {
        @strongify(self);
        if(!self){
            return nil;
        }
        
        UIImage* image     = download.image;
        NSString* mimeType = [self.request.URL wmf_mimeTypeForExtension];
        NSData* data       = [image wmf_dataRepresentationForMimeType:mimeType serializedMimeType:&mimeType];
        
        NSURLResponse* response =
        [[NSURLResponse alloc] initWithURL:self.request.URL
                                  MIMEType:mimeType
                     expectedContentLength:data.length
                          textEncodingName:nil];
        
        return (response && data) ? @[response, data]: nil;
    })
    .then(^(NSArray* responseAndDataArray) {
        @strongify(self);
        if(!self){
            return;
        }

        if (!responseAndDataArray || (responseAndDataArray.count != 2)) {
            return;
        }
        NSURLResponse* response = responseAndDataArray[0];
        NSData* data = responseAndDataArray[1];
        
        [self respondWithDataFromDownload:data response:response];
    })
    .catch(^(NSError* err) {
        @strongify(self);
        if(!self){
            return;
        }
        [self respondWithError:err];
    });
}

#pragma mark - Callbacks

- (void)respondWithDataFromDownload:(NSData*)data response:(NSURLResponse*)response{
    if(!self){
        return;
    }
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
