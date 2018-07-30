#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFDesktopRetry)

/**
 *  Sends a @c GET request to the mobile endpoint (see -[NSURL wmf_mobileAPIURL])
 *  if Wikipedia Zero is active or to the desktop endpoint (-[NSURL wmf_desktopAPIURL]) if not.
 *
 *  @param URL The URL to derive the endpoints from.
 *  @param parameters       The parameters for the request
 *  @param success          The success block
 *  @param failure          The failure block
 *
 *  @return The operation which represents the state of the request.
 */
- (NSURLSessionDataTask *)wmf_GETWithURL:(NSURL *)URL
                              parameters:(id)parameters
                                 success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                 failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure;

@end
