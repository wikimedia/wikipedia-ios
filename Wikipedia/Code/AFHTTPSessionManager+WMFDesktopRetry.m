
#import "AFHTTPSessionManager+WMFDesktopRetry.h"
#import "NSError+WMFExtensions.h"
#import "MWKSite.h"
#import "SessionSingleton.h"

@implementation AFHTTPSessionManager (WMFDesktopRetry)


- (NSURLSessionDataTask*)wmf_GETWithMobileURLString:(NSString*)mobileURLString
                                   desktopURLString:(NSString*)desktopURLString
                                         parameters:(id)parameters
                                              retry:(void (^)(NSURLSessionDataTask* retryOperation, NSError* error))retry
                                            success:(void (^)(NSURLSessionDataTask* operation, id responseObject))success
                                            failure:(void (^)(NSURLSessionDataTask* operation, NSError* error))failure {
    // If Zero rated try mobile domain first if Zero rated, with desktop fallback.
    BOOL isZeroRated = [SessionSingleton sharedInstance].zeroConfigState.disposition;
    if (isZeroRated) {
        return [self GET:mobileURLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask* _Nonnull operation, id _Nonnull responseObject) {
            if (success) {
                success(operation, responseObject);
            }
        } failure:^(NSURLSessionDataTask* _Nonnull operation, NSError* _Nonnull error) {
            if ([error wmf_shouldFallbackToDesktopURLError]) {
                NSURLSessionDataTask* operation = [self GET:desktopURLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask* _Nonnull operation, id _Nonnull responseObject) {
                    if (success) {
                        success(operation, responseObject);
                    }
                } failure:^(NSURLSessionDataTask* _Nonnull operation, NSError* _Nonnull error) {
                    if (failure) {
                        failure(operation, error);
                    }
                }];
                if (retry) {
                    retry(operation, error);
                }
            } else {
                if (failure) {
                    failure(operation, error);
                }
            }
        }];
    } else {
        // If not Zero rated use desktop domain only.
        return [self GET:desktopURLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask* _Nonnull operation, id _Nonnull responseObject) {
            if (success) {
                success(operation, responseObject);
            }
        } failure:^(NSURLSessionDataTask* _Nonnull operation, NSError* _Nonnull error) {
            if (failure) {
                failure(operation, error);
            }
        }];
    }
}

- (NSURLSessionDataTask*)wmf_GETWithSite:(MWKSite*)site
                              parameters:(id)parameters
                                   retry:(void (^)(NSURLSessionDataTask* retryOperation, NSError* error))retry
                                 success:(void (^)(NSURLSessionDataTask* operation, id responseObject))success
                                 failure:(void (^)(NSURLSessionDataTask* operation, NSError* error))failure {
    return [self wmf_GETWithMobileURLString:[site apiEndpoint:YES].absoluteString
                           desktopURLString:[site apiEndpoint:NO].absoluteString
                                 parameters:parameters
                                      retry:retry
                                    success:success
                                    failure:failure];
}

- (AnyPromise*)wmf_GETWithSite:(MWKSite*)site
                    parameters:(id)parameters {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        [self wmf_GETWithSite:site parameters:parameters retry:nil success:^(NSURLSessionDataTask* operation, id responseObject) {
            resolve(responseObject);
        } failure:^(NSURLSessionDataTask* operation, NSError* error) {
            resolve(error);
        }];
    }];
}

- (NSURLSessionDataTask*)wmf_POSTWithMobileURLString:(NSString*)mobileURLString
                                    desktopURLString:(NSString*)desktopURLString
                                          parameters:(id)parameters
                                               retry:(void (^)(NSURLSessionDataTask* retryOperation, NSError* error))retry
                                             success:(void (^)(NSURLSessionDataTask* operation, id responseObject))success
                                             failure:(void (^)(NSURLSessionDataTask* operation, NSError* error))failure {
    return [self POST:mobileURLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask* _Nonnull operation, id _Nonnull responseObject) {
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(NSURLSessionDataTask* _Nonnull operation, NSError* _Nonnull error) {
        if ([error wmf_shouldFallbackToDesktopURLError]) {
            NSURLSessionDataTask* operation = [self POST:desktopURLString parameters:parameters progress:NULL success:^(NSURLSessionDataTask* _Nonnull operation, id _Nonnull responseObject) {
                if (success) {
                    success(operation, responseObject);
                }
            } failure:^(NSURLSessionDataTask* _Nonnull operation, NSError* _Nonnull error) {
                if (failure) {
                    failure(operation, error);
                }
            }];
            if (retry) {
                retry(operation, error);
            }
        } else {
            if (failure) {
                failure(operation, error);
            }
        }
    }];
}

- (NSURLSessionDataTask*)wmf_POSTWithSite:(MWKSite*)site
                               parameters:(id)parameters
                                    retry:(void (^)(NSURLSessionDataTask* retryOperation, NSError* error))retry
                                  success:(void (^)(NSURLSessionDataTask* operation, id responseObject))success
                                  failure:(void (^)(NSURLSessionDataTask* operation, NSError* error))failure {
    return [self wmf_POSTWithMobileURLString:[site apiEndpoint:YES].absoluteString
                            desktopURLString:[site apiEndpoint:NO].absoluteString
                                  parameters:parameters
                                       retry:retry
                                     success:success
                                     failure:failure];
}

- (AnyPromise*)wmf_POSTWithSite:(MWKSite*)site
                     parameters:(id)parameters {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver _Nonnull resolve) {
        [self wmf_POSTWithSite:site parameters:parameters retry:nil success:^(NSURLSessionDataTask* operation, id responseObject) {
            resolve(responseObject);
        } failure:^(NSURLSessionDataTask* operation, NSError* error) {
            resolve(error);
        }];
    }];
}

@end
