#import <WMF/WMFURLCache.h>
#import <WMF/SessionSingleton.h>
#import <WMF/MWKArticle.h>
#import <WMF/MWKImage.h>
#import <WMF/WMF-Swift.h>

static NSString *const WMFURLCacheWikipediaHost = @".wikipedia.org";
static NSString *const WMFURLCacheJsonMIMEType = @"application/json";
static NSString *const WMFURLCacheZeroConfigQueryNameValue = @"action=zeroconfig";

@implementation WMFURLCache

- (BOOL)isMIMETypeImage:(NSString *)type {
    return [type hasPrefix:@"image"];
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSCachedURLResponse *response = [super cachedResponseForRequest:request];
    if (!response && [self isMIMETypeImage:[request.URL wmf_mimeTypeForExtension]]) {
        WMFTypedImageData *typedData = [[WMFImageController sharedInstance] permanentlyCachedTypedDiskDataForImageWithURL:request.URL];
        NSData *data = typedData.data;
        NSString *mimeType = typedData.MIMEType;
        if (data.length > 0) {
            NSURLResponse *typedDataResponse = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:data.length textEncodingName:nil];
            NSCachedURLResponse *cachedTypedDataResponse = [[NSCachedURLResponse alloc] initWithResponse:typedDataResponse data:data];
            [self storeCachedResponse:cachedTypedDataResponse forRequest:request];
            response = cachedTypedDataResponse;
        }
    }

    NSURLResponse *maybeHTTPResponse = response.response;

    if (![maybeHTTPResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        if (!response) {
            wmf_postNetworkRequestBeganNotification(request);
        }
        return response;
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)maybeHTTPResponse;

    if (httpResponse.statusCode == 200 && httpResponse.allHeaderFields[@"ETAG"] != nil) {

        //This is coming from the cache and has an ETAG, lets actually use the correct 304 response code
        NSHTTPURLResponse *newHTTPResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL statusCode:304 HTTPVersion:@"HTTP/1.1" headerFields:httpResponse.allHeaderFields];

        response = [[NSCachedURLResponse alloc] initWithResponse:newHTTPResponse data:response.data];
    }

    if (!response) {
        wmf_postNetworkRequestBeganNotification(request);
    }
    return response;
}

- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    // Workaround for action=zeroconfig's legacy 60 second caching
    // For details, see https://phabricator.wikimedia.org/T139615#2659569
    if (![[request URL].query containsString:WMFURLCacheZeroConfigQueryNameValue]) {
        [super storeCachedResponse:cachedResponse forRequest:request];
    }
    if ([self isJsonResponse:cachedResponse fromWikipediaAPIRequest:request]) {
        [[SessionSingleton sharedInstance].zeroConfigurationManager updateZeroRatingAndZeroConfigurationForResponseHeadersIfNecessary:((NSHTTPURLResponse *)cachedResponse.response).allHeaderFields];
    }
}

- (BOOL)isJsonResponse:(NSCachedURLResponse *)cachedResponse fromWikipediaAPIRequest:(NSURLRequest *)request {
    return ([[request URL].host hasSuffix:WMFURLCacheWikipediaHost] && [cachedResponse.response.MIMEType isEqualToString:WMFURLCacheJsonMIMEType]);
}

@end
