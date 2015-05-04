//  Created by Monte Hurd on 4/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

// Based on: http://stackoverflow.com/a/8288359/135557

#import "WMFBundledImageProtocol.h"
#import "NSURL+WMFRest.h"

NSString* const kBundledImage = @"bundledImage";
NSString* const kWMF          = @"wmf";
NSString* const kImageSlash   = @"image/";

__attribute__((constructor)) static void WMFRegisterBundledImageProtocol() {
    [NSURLProtocol registerClass:[WMFBundledImageProtocol class]];
}

@implementation WMFBundledImageProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
    return [[request URL] wmf_conformsToScheme:kWMF andHasKey:kBundledImage];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest {
    return theRequest;
}

- (void)startLoading {
    NSString* fileName = [self.request.URL wmf_getValue];

    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:[kImageSlash stringByAppendingString:[fileName pathExtension]]
                                           expectedContentLength:-1
                                                textEncodingName:nil];

    NSString* imagePath = [[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension]
                                                          ofType:[fileName pathExtension]];

    NSData* data = [NSData dataWithContentsOfFile:imagePath];

    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
