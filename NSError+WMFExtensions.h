
#import <Foundation/Foundation.h>

@class MWKTitle;

extern NSString* const WMFErrorDomain;
extern NSString* const WMFRedirectTitleKey;
extern NSString* const WMFRedirectTitleKey;

typedef NS_ENUM(NSInteger, WMFErrorType) {
    
    WMFErrorTypeStringLength,
    WMFErrorTypeStringMissingParameter,
    WMFErrorTypeRedirected,
    WMFErrorTypeUnableToSave
};

@interface NSError (WMFExtensions)

+ (NSError*)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary*)userInfo;

+ (NSError*)wmf_redirectedErrorWithTitle:(MWKTitle*)redirectedtitle;

+ (NSError*)wmf_unableToSaveErrorWithReason:(NSString*)reason; //reason is specfied as NSLocalizedDescriptionKey

- (BOOL)wmf_isWMFErrorDomain;

- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type;

@end


@interface NSDictionary (WMFErrorExtensions)

- (MWKTitle*)wmf_redirectTitle;

@end
