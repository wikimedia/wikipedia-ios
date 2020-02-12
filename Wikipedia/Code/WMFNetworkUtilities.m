#import <WMF/WMFNetworkUtilities.h>

NSString *const WMFNetworkingErrorDomain = @"WMFNetworkingErrorDomain";

NSString *const WMFNetworkRequestBeganNotificationRequestKey = @"WMFNetworkRequestBeganNotificationRequestKey";
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
        [userInfoBuilder setValue:apiError[apiErrorKey] forKey:userInfoKey];
    };
    maybeMapApiToUserInfo(NSLocalizedFailureReasonErrorKey, @"code");
    maybeMapApiToUserInfo(NSLocalizedDescriptionKey, @"info");
    maybeMapApiToUserInfo(NSLocalizedRecoverySuggestionErrorKey, @"*");
    return [NSError errorWithDomain:WMFNetworkingErrorDomain code:WMFNetworkingError_APIError userInfo:userInfoBuilder];
}

void wmf_postNetworkRequestBeganNotification(NSURLRequest *request) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    if (request) {
        userInfo[WMFNetworkRequestBeganNotificationRequestKey] = request;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFNetworkRequestBeganNotification
                                                        object:nil
                                                      userInfo:userInfo];
}
