#import <WebKit/WebKit.h>

typedef NS_ENUM (NSInteger, WMFWKScriptMessageType) {
    WMFWKScriptMessagePeek,
    WMFWKScriptMessageConsoleMessage,
    WMFWKScriptMessageClickLink,
    WMFWKScriptMessageClickImage,
    WMFWKScriptMessageClickReference,
    WMFWKScriptMessageClickEdit,
    WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging,
    WMFWKScriptMessageLateJavascriptTransform,
    WMFWKScriptMessageArticleState,
    WMFWKScriptMessageUnknown
};

@interface WKScriptMessage (WMFScriptMessage)

+ (WMFWKScriptMessageType)wmf_typeForMessageName:(NSString*)name;
+ (Class)wmf_expectedMessageBodyClassForType:(WMFWKScriptMessageType)type;

@end
