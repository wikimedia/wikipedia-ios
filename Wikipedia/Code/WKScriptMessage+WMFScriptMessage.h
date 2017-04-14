#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, WMFWKScriptMessageType) {
    WMFWKScriptMessageUnknown,
    WMFWKScriptMessageConsoleMessage,
    WMFWKScriptMessageClickLink,
    WMFWKScriptMessageClickImage,
    WMFWKScriptMessageClickReference,
    WMFWKScriptMessageClickEdit,
    WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging,
    WMFWKScriptMessageLateJavascriptTransform,
    WMFWKScriptMessageArticleState,
    WMFWKScriptMessageFindInPageMatchesFound,
    WMFWKScriptMessageReadMoreFooterSaveClicked
};

@interface WKScriptMessage (WMFScriptMessage)

/*
 *
 * Returns the message body if it is of the expected type, or nil it is not.
 *
 */
- (nullable id)wmf_safeMessageBodyForType:(WMFWKScriptMessageType)messageType;

+ (WMFWKScriptMessageType)wmf_typeForMessageName:(NSString *_Nonnull)name;

@end
