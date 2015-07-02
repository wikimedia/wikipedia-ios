
#import <Foundation/Foundation.h>

@class MWKTitle;

extern NSString* const WMFErrorDomain;
extern NSString* const WMFRedirectTitleKey;

typedef NS_ENUM(NSInteger, WMFErrorType) {
    
    WMFErrorTypeStringLength,
    WMFErrorTypeStringMissingParameter,
    WMFErrorTypeRedirected,

};

@interface NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo;

+ (NSError*)wmf_redirectedErrorWithTitle:(MWKTitle*)redirectedtitle;

- (BOOL)wmf_isWMFErrorDomain;

- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type;

@end


@interface NSDictionary (WMFErrorExtensions)

- (MWKTitle*)wmf_redirectTitle;

@end
