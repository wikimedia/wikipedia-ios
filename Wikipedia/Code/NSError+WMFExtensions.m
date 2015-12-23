
#import "NSError+WMFExtensions.h"

NSString* const WMFErrorDomain      = @"WMFErrorDomain";
NSString* const WMFRedirectTitleKey = @"WMFRedirectTitleKey";

@implementation NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo {
    return [NSError errorWithDomain:WMFErrorDomain code:type userInfo:userInfo];
}

+ (NSError*)wmf_redirectedErrorWithTitle:(MWKTitle*)redirectedTitle {
    return [self wmf_errorWithType:WMFErrorTypeRedirected userInfo:redirectedTitle ? @{WMFRedirectTitleKey : redirectedTitle}:nil];
}

+ (NSError*)wmf_unableToSaveErrorWithReason:(NSString*)reason {
    return [self wmf_errorWithType:WMFErrorTypeUnableToSave userInfo:reason ? @{NSLocalizedDescriptionKey : reason}:nil];
}

+ (NSError*)wmf_serializeArticleErrorWithReason:(NSString*)reason {
    return [self wmf_errorWithType:WMFErrorTypeArticleResponseSerialization userInfo:reason ? @{NSLocalizedDescriptionKey : reason}:nil];
}

- (BOOL)wmf_isWMFErrorDomain {
    if ([self.domain isEqualToString:WMFErrorDomain]) {
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


@implementation NSError (WMFConnectionFallback)

- (BOOL)wmf_shouldFallbackToDesktopURLError {
    if (self.domain == NSStreamSocketSSLErrorDomain ||
        (self.domain == NSURLErrorDomain &&
         (self.code == NSURLErrorSecureConnectionFailed ||
          self.code == NSURLErrorServerCertificateHasBadDate ||
          self.code == NSURLErrorServerCertificateUntrusted ||
          self.code == NSURLErrorServerCertificateHasUnknownRoot ||
          self.code == NSURLErrorServerCertificateNotYetValid)
         //error.code == NSURLErrorCannotLoadFromNetwork) //TODO: check this out later?
        )
        ) {
        return YES;
    }
    return NO;
}

@end


@implementation NSDictionary (WMFErrorExtensions)

- (MWKTitle*)wmf_redirectTitle {
    return self[WMFRedirectTitleKey];
}

@end
