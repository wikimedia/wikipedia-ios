
#import "AFHTTPRequestOperationManager+WMFDesktopRetry.h"
#import "NSError+WMFExtensions.h"
#import "MWKSite.h"

@implementation AFHTTPRequestOperationManager (WMFDesktopRetry)


- (AFHTTPRequestOperation*)wmf_GETWithMobileURLString:(NSString*)mobileURLString
                                     desktopURLString:(NSString*)desktopURLString
                                           parameters:(id)parameters
                                                retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                              success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                              failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
    return [self GET:mobileURLString parameters:parameters success:^(AFHTTPRequestOperation* _Nonnull operation, id _Nonnull responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation* _Nonnull operation, NSError* _Nonnull error) {
        if ([error wmf_shouldFallbackToDesktopURLError]) {
            AFHTTPRequestOperation* operation = [self GET:desktopURLString parameters:parameters success:^(AFHTTPRequestOperation* _Nonnull operation, id _Nonnull responseObject) {
                if (success) {
                    success(operation, responseObject);
                }
            } failure:^(AFHTTPRequestOperation* _Nonnull operation, NSError* _Nonnull error) {
                if (failure) {
                    success(operation, error);
                }
            }];
            if (retry) {
                retry(operation, error);
            }
        } else {
            if (failure) {
                success(operation, error);
            }
        }
    }];
}

- (AFHTTPRequestOperation*)wmf_GETWithSite:(MWKSite*)site
                                parameters:(id)parameters
                                     retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                   success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                   failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure {
    return [self wmf_GETWithMobileURLString:[site apiEndpoint:YES].absoluteString
                           desktopURLString:[site apiEndpoint:NO].absoluteString
                                 parameters:parameters
                                      retry:retry
                                    success:success
                                    failure:failure];
}

@end
