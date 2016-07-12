#import <WebKit/WebKit.h>

typedef NS_ENUM (NSInteger, WMFWKScriptMessageType) {
    WMFWKScriptMessageUnknown,
    WMFWKScriptMessagePeek,
    WMFWKScriptMessageConsoleMessage,
    WMFWKScriptMessageClickLink,
    WMFWKScriptMessageClickImage,
    WMFWKScriptMessageClickReference,
    WMFWKScriptMessageClickEdit,
    WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging,
    WMFWKScriptMessageLateJavascriptTransform,
    WMFWKScriptMessageArticleState
};

@interface WKScriptMessage (WMFScriptMessage)

+ (WMFWKScriptMessageType)wmf_typeForMessageName:(NSString*)name;
+ (Class)wmf_expectedMessageBodyClassForType:(WMFWKScriptMessageType)type;

@end
