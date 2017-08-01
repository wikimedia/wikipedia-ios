#import <WMF/WMFNetworkUtilities.h>
#import <WMF/NSMutableDictionary+WMFMaybeSet.h>

NSString *const WMFNetworkingErrorDomain = @"WMFNetworkingErrorDomain";

NSString *const WMFNetworkRequestBeganNotification = @"WMFNetworkRequestBeganNotification";

NSString *const WMFNetworkRequestBeganNotificationMethodKey = @"method";
NSString *const WMFNetworkRequestBeganNotificationURLStringKey = @"URLString";


NSString *WMFJoinedPropertyParameters(NSArray *props) {
    return [props ?: @[] componentsJoinedByString:@"|"];
}

NSError *WMFErrorForApiErrorObject(NSDictionary *apiError) {
    if (!apiError) {
        return nil;
    }
    // build the dictionary this way to avoid early nil termination caused by missing keys in the error obj
    NSMutableDictionary *userInfoBuilder = [NSMutableDictionary dictionaryWithCapacity:3];
    void (^maybeMapApiToUserInfo)(NSString *, NSString *) = ^(NSString *userInfoKey, NSString *apiErrorKey) {
        [userInfoBuilder wmf_maybeSetObject:apiError[apiErrorKey] forKey:userInfoKey];
    };
    maybeMapApiToUserInfo(NSLocalizedFailureReasonErrorKey, @"code");
    maybeMapApiToUserInfo(NSLocalizedDescriptionKey, @"info");
    maybeMapApiToUserInfo(NSLocalizedRecoverySuggestionErrorKey, @"*");
    return [NSError errorWithDomain:WMFNetworkingErrorDomain code:WMFNetworkingError_APIError userInfo:userInfoBuilder];
}

NSString *WMFWikimediaRestAPIURLStringWithVersion(NSUInteger restAPIVersion) {
    return [NSString stringWithFormat:@"https://wikimedia.org/api/rest_v%lu", (unsigned long)restAPIVersion];
}

void wmf_postNetworkRequestBeganNotification(NSString *method, NSString *URLString) {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    if (method) {
        userInfo[WMFNetworkRequestBeganNotificationMethodKey] = method;
    }
    if (URLString) {
        userInfo[WMFNetworkRequestBeganNotificationURLStringKey] = URLString;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFNetworkRequestBeganNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

@implementation NSError (WMFFetchFinalStatus)

- (FetchFinalStatus)wmf_fetchStatus {
    return ([self.domain isEqual:NSURLErrorDomain] && self.code == NSURLErrorCancelled) ? FETCH_FINAL_STATUS_CANCELLED : FETCH_FINAL_STATUS_FAILED;
}

@end
