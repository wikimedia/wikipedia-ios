@import Foundation;

extern NSString *const WMFNetworkingErrorDomain;

extern NSString *const WMFNetworkRequestBeganNotification;
extern NSString *const WMFNetworkRequestBeganNotificationRequestKey;

typedef NS_ENUM(NSInteger, WMFNetworkingError) {
    WMFNetworkingError_APIError,
    WMFNetworkingError_InvalidParameters
};

/// @name Functions

/**
 * Take an array of strings and concatenate them with "|" as a delimiter.
 * @return A string of the concatenated elements, or an empty string if @c props is empty or @c nil.
 */
extern NSString *WMFJoinedPropertyParameters(NSArray *props);

extern NSError *WMFErrorForApiErrorObject(NSDictionary *apiError);

/**
 *  Create a URL string for a specific REST API version endpoint.
 *
 *  @param restAPIVersion The verison of the REST API to use (e.g. `1` for "rest_v1").
 *
 *  @return The URL string for the "wikimedia.org" REST API endpoint verison.
 */
extern NSString *WMFWikimediaRestAPIURLStringWithVersion(NSUInteger restAPIVersion);

#import <WMF/FetcherBase.h>

extern void wmf_postNetworkRequestBeganNotification(NSURLRequest *request);

@interface NSError (WMFFetchFinalStatus)

- (FetchFinalStatus)wmf_fetchStatus;

@end
