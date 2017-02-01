#import <AFNetworking/AFNetworking.h>

@interface AFHTTPSessionManager (WMFDesktopRetry)

/**
 *  Executes a GET using a mobile url.
 *  If the request fails with the mobile URL for a known reason,
 *  the request will automatically be re-attempted with the desktop URL
 *
 *  @param mobileURLString  The mobile URL
 *  @param desktopURLString The desktop URL
 *  @param parameters       The parameters for the request (same as normal GET:)
 *  @param success          The retry block - called if a retry is executed. Use this to get the new operation.
 *  @param success          The success block (same as normal GET:)
 *  @param failure          The failure block (same as normal GET:)
 *
 *  @return The operation
 */
- (NSURLSessionDataTask *)wmf_GETWithMobileURLString:(NSString *)mobileURLString
                                    desktopURLString:(NSString *)desktopURLString
                                          parameters:(id)parameters
                                               retry:(void (^)(NSURLSessionDataTask *retryOperation, NSError *error))retry
                                             success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                             failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure;

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

/**
 *  Executes a POST using a mobile url.
 *  If the request fails with the mobile URL for a known reason,
 *  the request will automatically be re-attempted with the desktop URL
 *
 *  @param mobileURLString  The mobile URL
 *  @param desktopURLString The desktop URL
 *  @param parameters       The parameters for the request (same as normal POST:)
 *  @param success          The retry block - called if a retry is executed. Use this to get the new operation.
 *  @param success          The success block (same as normal POST:)
 *  @param failure          The failure block (same as normal POST:)
 *
 *  @return The operation
 */
- (NSURLSessionDataTask *)wmf_POSTWithMobileURLString:(NSString *)mobileURLString
                                     desktopURLString:(NSString *)desktopURLString
                                           parameters:(id)parameters
                                                retry:(void (^)(NSURLSessionDataTask *retryOperation, NSError *error))retry
                                              success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                              failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure;

- (NSURLSessionDataTask *)wmf_apiPOSTWithURL:(NSURL *)URL
                                  parameters:(id)parameters
                                     success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
                                     failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure;

@end
