
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@class MWKSite;

@interface AFHTTPRequestOperationManager (WMFDesktopRetry)

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
- (AFHTTPRequestOperation*)wmf_GETWithMobileURLString:(NSString*)mobileURLString
                                     desktopURLString:(NSString*)desktopURLString
                                           parameters:(id)parameters
                                                retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                              success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                              failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;


/**
 *  Same as above, but will get the mobile URL and Desktop URL from the MWKSite
 *
 *  @param site       The site to extract the urls from
 */
- (AFHTTPRequestOperation*)wmf_GETWithSite:(MWKSite*)site
                                parameters:(id)parameters
                                     retry:(void (^)(AFHTTPRequestOperation* retryOperation, NSError* error))retry
                                   success:(void (^)(AFHTTPRequestOperation* operation, id responseObject))success
                                   failure:(void (^)(AFHTTPRequestOperation* operation, NSError* error))failure;

@end
