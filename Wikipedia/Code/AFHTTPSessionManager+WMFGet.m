#import <WMF/AFHTTPSessionManager+WMFGet.h>
#import <WMF/SessionSingleton.h>
#import <WMF/NSURL+WMFLinkParsing.h>

@implementation AFHTTPSessionManager (WMFGet)

- (NSURLSessionDataTask *)wmf_GETWithURL:(NSURL *)URL
                              parameters:(id)parameters
                                 success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                 failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure {
    
    // If Zero rated use mobile domain, else use desktop domain.
    NSURL *url = [SessionSingleton sharedInstance].zeroConfigurationManager.isZeroRated ? [NSURL wmf_mobileAPIURLForURL:URL] : [NSURL wmf_desktopAPIURLForURL:URL];
    
    return [self GET:url.absoluteString
          parameters:parameters
            progress:NULL
             success:^(NSURLSessionDataTask *_Nonnull operation, id _Nonnull responseObject) {
                 if (success) {
                     success(operation, responseObject);
                 }
             }
             failure:^(NSURLSessionDataTask *_Nonnull operation, NSError *_Nonnull error) {
                 if (failure) {
                     failure(operation, error);
                 }
             }];
}

@end
