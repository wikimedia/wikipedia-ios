#import "WMFHTTPHangingProtocol.h"

@implementation WMFHTTPHangingProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme hasPrefix:@"http"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    // Nope
}

- (void)stopLoading {
    // Double nope
}

@end
