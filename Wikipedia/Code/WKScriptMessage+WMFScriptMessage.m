#import "WKScriptMessage+WMFScriptMessage.h"

@implementation WKScriptMessage (WMFScriptMessage)

+ (WMFWKScriptMessageType)wmf_typeForMessageName:( NSString* _Nonnull )name {
    if ([name isEqualToString:@"nonAnchorTouchEndedWithoutDragging"]) {
        return WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging;
    } else if ([name isEqualToString:@"linkClicked"]) {
        return WMFWKScriptMessageClickLink;
    } else if ([name isEqualToString:@"imageClicked"]) {
        return WMFWKScriptMessageClickImage;
    } else if ([name isEqualToString:@"peek"]) {
        return WMFWKScriptMessagePeek;
    } else if ([name isEqualToString:@"referenceClicked"]) {
        return WMFWKScriptMessageClickReference;
    } else if ([name isEqualToString:@"editClicked"]) {
        return WMFWKScriptMessageClickEdit;
    } else if ([name isEqualToString:@"lateJavascriptTransform"]) {
        return WMFWKScriptMessageLateJavascriptTransform;
    } else if ([name isEqualToString:@"articleState"]) {
        return WMFWKScriptMessageArticleState;
    } else if ([name isEqualToString:@"sendJavascriptConsoleLogMessageToXcodeConsole"]) {
        return WMFWKScriptMessageConsoleMessage;
    }else if ([name isEqualToString:@"findInPageMatchesFound"]) {
        return WMFWKScriptMessageFindInPageMatchesFound;
    } else{
        return WMFWKScriptMessageUnknown;
    }
}

+ (Class)wmf_expectedMessageBodyClassForType:(WMFWKScriptMessageType)type {
    switch (type) {
        case WMFWKScriptMessageNonAnchorTouchEndedWithoutDragging:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageClickLink:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageClickImage:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessagePeek:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageClickReference:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageClickEdit:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageLateJavascriptTransform:
            return [NSString class];
            break;
        case WMFWKScriptMessageArticleState:
            return [NSString class];
            break;
        case WMFWKScriptMessageConsoleMessage:
            return [NSDictionary class];
            break;
        case WMFWKScriptMessageFindInPageMatchesFound:
            return [NSArray class];
            break;
        case WMFWKScriptMessageUnknown:
            return [NSNull class];
            break;
    }
}

- (nullable id) wmf_safeMessageBodyForType:(WMFWKScriptMessageType)messageType {
    Class class = [WKScriptMessage wmf_expectedMessageBodyClassForType:messageType];
    if ([self.body isKindOfClass:class]) {
        if (class == [NSDictionary class]) {
            return [self.body wmf_dictionaryByRemovingNullObjects];
        } else {
            return self.body;
        }
    }else{
        NSAssert(NO, @"Unexpected script message body kind of class!");
        return nil;
    }
}

@end
