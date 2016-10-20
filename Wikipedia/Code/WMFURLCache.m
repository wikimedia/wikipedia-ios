#import "WMFURLCache.h"
#import "SessionSingleton.h"
#import "MWKArticle.h"
#import "MWKImage.h"
#import <WMFModel/WMFModel-Swift.h>

static NSString *const WMFURLCacheWikipediaHost = @".wikipedia.org";
static NSString *const WMFURLCacheJsonMIMEType = @"application/json";
static NSString *const WMFURLCacheZeroConfigQueryNameValue = @"action=zeroconfig";

@implementation WMFURLCache

- (void)permanentlyCacheImagesForArticle:(MWKArticle *)article {
    NSArray *imageURLsForSaving = [article imageURLsForSaving];
    for (NSURL *url in imageURLsForSaving) {
        @autoreleasepool {
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

            NSCachedURLResponse *response = [self cachedResponseForRequest:request];

            if (response.data.length > 0) {
                [[WMFImageController sharedInstance] cacheImageData:response.data url:url MIMEType:response.response.MIMEType];
            }
        }
    };
}

- (UIImage *)cachedImageForURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];

    NSCachedURLResponse *response = [self cachedResponseForRequest:request];

    if (response.data.length > 0) {
        return [UIImage imageWithData:response.data];
    } else if ([url wmf_isSchemeless]) {
        return [self cachedImageForURL:[url wmf_urlByPrependingSchemeIfSchemeless]];
    } else {
        return nil;
    }
}

- (BOOL)isMIMETypeImage:(NSString *)type {
    return [type hasPrefix:@"image"];
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSString *mimeType = [request.URL wmf_mimeTypeForExtension];
    if ([self isMIMETypeImage:mimeType] && [[WMFImageController sharedInstance] hasDataOnDiskForImageWithURL:request.URL]) {
        WMFTypedImageData *typedData = [[WMFImageController sharedInstance] typedDiskDataForImageWithURL:request.URL];
        NSData *data = typedData.data;
        NSString *mimeType = typedData.MIMEType;

        if (data.length > 0) {
            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:mimeType expectedContentLength:data.length textEncodingName:nil];
            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
            return cachedResponse;
        }
    }
    
    NSCachedURLResponse* response = [super cachedResponseForRequest:request];
     NSHTTPURLResponse* httpResponse = (id)(response.response);
    
    if(httpResponse.statusCode == 200 && httpResponse.allHeaderFields[@"ETAG"] != nil){
        
        //This is coming from the cache and has an ETAG, lets actually use the correct 304 response code
        NSHTTPURLResponse* newHTTPResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL statusCode:304 HTTPVersion:@"HTTP/1.1" headerFields:httpResponse.allHeaderFields];
        
        response = [[NSCachedURLResponse alloc] initWithResponse:newHTTPResponse data:response.data];
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
