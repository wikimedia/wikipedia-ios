//
//  WMFArticleProtocol.m
//  Wikipedia
//
//  Created by Corey Floyd on 5/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFArticleProtocol.h"
#import "SessionSingleton.h"
#import "NSURL+WMFRest.h"
#import "MediaWikiKit.h"

__attribute__((constructor)) static void WMFRegisterArticleProtocol() {
    [NSURLProtocol registerClass:[WMFArticleProtocol class]];
}

@implementation WMFArticleProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    return [[request URL] wmf_conformsToScheme:@"wmf" andHasHost:@"article"];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

- (void)startLoading {
    NSString* value = [self.request.URL wmf_getValue];
    if ([value isEqualToString:@"is-main-page"]) {
        BOOL isMainPage = [SessionSingleton sharedInstance].currentArticle.isMain;
        NSData* data    = [[@(isMainPage)stringValue] dataUsingEncoding:NSUTF8StringEncoding];

        [self sendResponseWithData:data];
    } else {
        [self sendResponseWithData:nil];
    }
}

- (void)sendResponseWithData:(NSData*)data {
    [self handleResponse:data];
    [self handleResponseData:data];
    [self handleRequestFinished];
}

- (void)handleResponse:(NSData*)data {
    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:@"text/plain"
                                           expectedContentLength:data.length
                                                textEncodingName:@"utf-8"];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)handleResponseData:(NSData*)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)handleRequestFinished {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
