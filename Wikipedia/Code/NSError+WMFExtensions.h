@import Foundation;

extern NSString *const WMFErrorDomain;

extern NSString *const WMFRedirectTitleKey;
extern NSString *const WMFRedirectTitleKey;

/**
 *  Key which can provide any failing request parameters for an error of type @c WMFErrorTypeInvalidRequestParameters.
 *
 *  The value set for this key varies depending on the kind of request, and is mosly provided for logging & diagnostic
 *  purposes.
 */
extern NSString *const WMFFailingRequestParametersUserInfoKey;

typedef NS_ENUM(NSInteger, WMFErrorType) {
    WMFErrorTypeStringLength,
    WMFErrorTypeStringMissingParameter,
    WMFErrorTypeRedirected,
    WMFErrorTypeUnableToSave,
    WMFErrorTypeArticleResponseSerialization,
    WMFErrorTypeUnexpectedResponseType,
    WMFErrorTypeInvalidRequestParameters,
    WMFErrorTypeFetchAlreadyInProgress,
    WMFErrorTypeCancelled
};

@interface NSError (WMFExtensions)

+ (NSError *)wmf_errorWithType:(WMFErrorType)type userInfo:(NSDictionary *)userInfo;

//reason is specfied as NSLocalizedDescriptionKey
+ (NSError *)wmf_unableToSaveErrorWithReason:(NSString *)reason;

//reason is specfied as NSLocalizedDescriptionKey
+ (NSError *)wmf_serializeArticleErrorWithReason:(NSString *)reason;

+ (NSError *)wmf_cancelledError;

- (BOOL)wmf_isWMFErrorDomain;
- (BOOL)wmf_isWMFErrorMissingTitle;
- (BOOL)wmf_isWMFErrorOfType:(WMFErrorType)type;

@end

@interface NSError (WMFNetworkConnectionError)

- (BOOL)wmf_isNetworkConnectionError;

@end
