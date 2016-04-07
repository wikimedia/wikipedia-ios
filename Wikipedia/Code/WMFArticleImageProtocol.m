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
static NSString* const WMFArticleImageProtocolResponseAndDataErrorDomain = @"WMFArticleImageProtocolResponseAndDataErrorDomain";

@interface WMFArticleImageProtocolResponseAndData: NSObject
@property (strong) NSURLResponse* response;
@property (strong) NSData* data;
@end

@implementation WMFArticleImageProtocolResponseAndData
- (instancetype)initWithResponse:(NSURLResponse*)response data:(NSData *)data{
    if (self = [super init]) {
        _response = response;
        _data     = data;
    }
    return self;
}
@end

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
    .thenInBackground(^WMFArticleImageProtocolResponseAndData*(WMFImageDownload* download) {
        @strongify(self);
        if(!self){
            return nil;
        }
        return [self getResponseAndDataForDownload:download];
    })
    .then(^id(WMFArticleImageProtocolResponseAndData* responseAndData) {
        @strongify(self);
        if(!self){
            return nil;
        }

        if (!responseAndData.response) {
            return [[NSError alloc] initWithDomain:WMFArticleImageProtocolResponseAndDataErrorDomain
                                              code:0
                                          userInfo:@{
                                                     NSLocalizedDescriptionKey: @"Response for image not found",
                                                     NSURLErrorKey: self.request.URL
                                                     }];
        }else if (!responseAndData.data) {
            return [[NSError alloc] initWithDomain:WMFArticleImageProtocolResponseAndDataErrorDomain
                                              code:1
                                          userInfo:@{
                                                     NSLocalizedDescriptionKey: @"Data for image not found",
                                                     NSURLErrorKey: self.request.URL
                                                     }];
        }else if (responseAndData.data.length == 0) {
            return [[NSError alloc] initWithDomain:WMFArticleImageProtocolResponseAndDataErrorDomain
                                              code:2
                                          userInfo:@{
                                                     NSLocalizedDescriptionKey: @"Data for image was zero length",
                                                     NSURLErrorKey: self.request.URL
                                                     }];
        }else{
            [self respondWithResponseAndData:responseAndData];
        }
        return nil;
    })
    .catch(^(NSError* err) {
        @strongify(self);
        if(!self){
            return;
        }
        [self respondWithError:err];
    });
}

- (WMFArticleImageProtocolResponseAndData*)getResponseAndDataForDownload:(WMFImageDownload*)download {
    UIImage* image     = download.image;
    NSString* mimeType = [self.request.URL wmf_mimeTypeForExtension];
    NSData* data       = [image wmf_dataRepresentationForMimeType:mimeType serializedMimeType:&mimeType];
    
    NSURLResponse* response =
    [[NSURLResponse alloc] initWithURL:self.request.URL
                              MIMEType:mimeType
                 expectedContentLength:data.length
                      textEncodingName:nil];
    
    return [[WMFArticleImageProtocolResponseAndData alloc] initWithResponse:response data:data];
}

#pragma mark - Callbacks

- (void)respondWithResponseAndData:(WMFArticleImageProtocolResponseAndData*)responseAndData{
    if(!self){
        return;
    }
    NSAssert(responseAndData, @"No response and data!");
    NSAssert(responseAndData.response, @"No response!");
    NSAssert(responseAndData.data, @"No data!");
    NSAssert(responseAndData.data.length > 0, @"Data was zero length!");

    // prevent browser from caching images (hopefully?)
    [[self client] URLProtocol:self
            didReceiveResponse:responseAndData.response
            cacheStoragePolicy:NSURLCacheStorageNotAllowed];

    [[self client] URLProtocol:self didLoadData:responseAndData.data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)respondWithError:(NSError*)error {
    DDLogError(@"Failed to fetch image at %@ due to %@", self.request.URL, error);
    [self.client URLProtocol:self didFailWithError:error];
}

@end
