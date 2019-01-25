#import <WMF/NSError+WMFExtensions.h>

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
