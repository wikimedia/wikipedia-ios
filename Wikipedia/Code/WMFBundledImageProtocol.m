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
    return [[request URL] wmf_conformsToScheme:kWMF andHasHost:kBundledImage];
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest {
    return theRequest;
}

- (void)startLoading {
    NSString* fileName = [self.request.URL wmf_getValue];

    UIImage* image = [UIImage imageNamed:fileName];
    if (!image) {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:nil]];
        return;
    }

    NSData* data = UIImagePNGRepresentation(image);
    NSAssert(data.length, @"Image \"%@\" is empty!", fileName);

    NSURLResponse* response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:@"image/png"
                                           expectedContentLength:data.length
                                                textEncodingName:@"binary"];

    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end
