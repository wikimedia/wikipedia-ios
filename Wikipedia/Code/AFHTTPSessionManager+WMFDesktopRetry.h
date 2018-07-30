#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFDesktopRetry)

/**
 *  Send a @c GET request to the mobile endpoint (see -[NSURL wmf_mobileAPIURL])
 *  for the given url, falling back to desktop endpoint (-[NSURL wmf_desktopAPIURL])
 *  if the mobile endpoint fails.
 *
 *  @param URL The URL to derive the endpoints from. First mobile, then desktop.
 *  @param parameters       The parameters for the request
 *  @param retry            The retry block - called if a retry is executed. Use this to get the new operation.
 *  @param success          The success block
 *  @param failure          The failure block
 *
 *  @return The operation which represents the state of the request.
 */
- (NSURLSessionDataTask *)wmf_GETAndRetryWithURL:(NSURL *)URL
                                      parameters:(id)parameters
                                           retry:(void (^)(NSURLSessionDataTask *retryOperation, NSError *error))retry
                                         success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                         failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure;

@end
