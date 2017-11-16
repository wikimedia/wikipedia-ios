#import <WMF/NSError+WMFExtensions.h>

NSString *const WMFErrorDomain = @"WMFErrorDomain";
NSString *const WMFRedirectTitleKey = @"WMFRedirectTitleKey";
NSString *const WMFFailingRequestParametersUserInfoKey = @"WMFFailingRequestParametersUserInfoKey";
NSString *const WMFErrorMissingTitle = @"missingtitle";

@implementation NSError (WMFExtensions)

+ (NSError *)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:WMFErrorDomain code:type userInfo:userInfo];
}

+ (NSError *)wmf_unableToSaveErrorWithReason:(NSString *)reason {
    return [self wmf_errorWithType:WMFErrorTypeUnableToSave userInfo:reason ? @{NSLocalizedDescriptionKey: reason} : nil];
}

+ (NSError *)wmf_serializeArticleErrorWithReason:(NSString *)reason {
    return [self wmf_errorWithType:WMFErrorTypeArticleResponseSerialization userInfo:reason ? @{NSLocalizedDescriptionKey: reason} : nil];
}

+ (NSError *)wmf_cancelledError {
    return [NSError errorWithDomain:WMFErrorDomain code:WMFErrorTypeCancelled userInfo:nil];
}

- (BOOL)wmf_isWMFErrorDomain {
    if ([self.domain isEqualToString:WMFErrorDomain]) {
        return YES;
    }
    return NO;
}

- (BOOL)wmf_isWMFErrorMissingTitle {
    if ([self.localizedFailureReason isEqualToString:WMFErrorMissingTitle]) {
        return YES;
    }
    return NO;
}

- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type {
    if (![self wmf_isWMFErrorDomain]) {
        return NO;
    }
    return [self code] == type;
}

@end

@implementation NSError (WMFNetworkConnectionError)

- (BOOL)wmf_isNetworkConnectionError {
    if ([self.domain isEqualToString:NSURLErrorDomain]) {
        switch (self.code) {
            case NSURLErrorTimedOut:
            //            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorNotConnectedToInternet:
                return YES;
                break;

            default:
                return NO;
                break;
        }
    }
    return NO;
}

@end
