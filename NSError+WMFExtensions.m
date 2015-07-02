
#import "NSError+WMFExtensions.h"

NSString* const WMFErrorDomain = @"WMFErrorDomain";
NSString* const WMFRedirectTitleKey = @"WMFRedirectTitleKey";

@implementation NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo{
    
    return [NSError errorWithDomain:WMFErrorDomain code:type userInfo:userInfo];
}

+ (NSError*)wmf_redirectedErrorWithTitle:(MWKTitle*)redirectedTitle{

    return [self wmf_errorWithType:WMFErrorTypeRedirected userInfo:redirectedTitle ? @{WMFRedirectTitleKey : redirectedTitle}: nil];
    
}

- (BOOL)wmf_isWMFErrorDomain{
    if([self.domain isEqualToString:WMFErrorDomain]){
        return YES;
    }
    return NO;
}

- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type{
    if(![self wmf_isWMFErrorDomain]){
        return NO;
    }
    return [self code] == type;
}

@end


@implementation NSDictionary (WMFErrorExtensions)

- (MWKTitle*)wmf_redirectTitle{
    return self[WMFRedirectTitleKey];
}

@end
