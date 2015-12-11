
#import <Foundation/Foundation.h>

@class MWKTitle;

extern NSString* const WMFErrorDomain;

extern NSString* const WMFRedirectTitleKey;
extern NSString* const WMFRedirectTitleKey;

typedef NS_ENUM (NSInteger, WMFErrorType) {
    WMFErrorTypeStringLength,
    WMFErrorTypeStringMissingParameter,
    WMFErrorTypeRedirected,
    WMFErrorTypeUnableToSave,
    WMFErrorTypeArticleResponseSerialization,
    WMFErrorTypeUnexpectedResponseType
};

@interface NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo;

+ (NSError*)wmf_redirectedErrorWithTitle:(MWKTitle*)redirectedtitle;

//reason is specfied as NSLocalizedDescriptionKey
+ (NSError*)wmf_unableToSaveErrorWithReason:(NSString*)reason;

//reason is specfied as NSLocalizedDescriptionKey
+ (NSError*)wmf_serializeArticleErrorWithReason:(NSString*)reason;


- (BOOL)wmf_isWMFErrorDomain;
- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type;

@end

@interface NSError (WMFNetworkConnectionError)

- (BOOL)wmf_isNetworkConnectionError;

@end

@interface NSError (WMFConnectionFallback)

/*
 * If YES, this error indicates that we should attempt to resend the
 * request using the desktop URL.
 */
- (BOOL)wmf_shouldFallbackToDesktopURLError;

@end

@interface NSDictionary (WMFErrorExtensions)

- (MWKTitle*)wmf_redirectTitle;

@end

