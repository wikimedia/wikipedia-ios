//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CommunicationBridge.h"
#import "UIWebView+LoadAssetsHtml.h"
#import "UIWebView+WMFJavascriptToXcodeConsoleLogging.h"

@interface CommunicationBridge ()

@property (strong, nonatomic) WKWebView* webView;
@property (strong, nonatomic) NSMutableDictionary* listenersByEvent;
@property (strong, nonatomic) NSMutableArray* queuedMessages;
@property BOOL shouldQueueMessages;

@end

@implementation CommunicationBridge

- (CommunicationBridge*)initWithWebView:(WKWebView*)targetWebView;
{
    self = [super init];
    if (self) {
        self.shouldQueueMessages = YES;
        self.webView             = targetWebView;
        self.listenersByEvent    = @{}.mutableCopy;
        self.queuedMessages = @[].mutableCopy;

        __weak CommunicationBridge* weakSelf = self;
        [self addListener:@"DOMContentLoaded" withBlock:^(NSString* type, NSDictionary* payload) {
            //[weakSelf.webView wmf_enableJavascriptToXcodeConsoleLogging];
            [weakSelf sendQueuedMessages];
        }];
        targetWebView.navigationDelegate = self;
    }
    return self;
}

- (void)addListener:(NSString*)messageType
          withBlock:(JSListener)block {
    NSMutableArray* listeners = [self listenersForMessageType:messageType];
    if (listeners == nil) {
        self.listenersByEvent[messageType] = [NSMutableArray arrayWithObject:block];
    } else {
        [listeners addObject:block];
    }
}

- (void)sendMessage:(NSString*)messageType
        withPayload:(NSDictionary*)payload {
    if (!payload) {
        payload = @{};
    }

    NSString* js = [NSString stringWithFormat:@"bridge.handleMessage(%@,%@)",
                    [self stringify:messageType],
                    [self stringify:payload]];
    if (self.shouldQueueMessages) {
        [self.queuedMessages addObject:js];
    } else {
        [self sendRawMessage:js];
    }
}

- (NSMutableArray*)listenersForMessageType:(NSString*)messageType {
    return self.listenersByEvent[messageType];
}

- (void)fireEvent:(NSString*)messageType withPayload:(NSDictionary*)payload {
    NSArray* listeners = [self listenersForMessageType:messageType];
    for (JSListener listener in listeners) {
        listener(messageType, payload);
    }
}

- (NSString*)stringify:(id)obj {
    BOOL needsWrapper = ![NSJSONSerialization isValidJSONObject:obj];
    id payload;
    if (needsWrapper) {
        payload = @[obj];
    } else {
        payload = obj;
    }
    NSData* data  = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (needsWrapper) {
        // Remove the '['...']' wrapper
        return [str substringWithRange:NSMakeRange(1, str.length - 2)];
    } else {
        return str;
    }
}

static NSString* bridgeURLPrefix = @"x-wikipedia-bridge:";

- (BOOL)isBridgeURL:(NSURL*)url {
    return [[url absoluteString] hasPrefix:bridgeURLPrefix];
}

- (NSDictionary*)extractBridgePayload:(NSURL*)url {
    NSString* encodedStr = [[url absoluteString] substringFromIndex:bridgeURLPrefix.length];
    NSString* str        = [encodedStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData* data         = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError* err;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        NSLog(@"JSON ERROR %@", err);
    }
    return dict;
}

- (void)sendRawMessage:(NSString*)js {
    [self.webView evaluateJavaScript:js completionHandler:NULL];
}

- (void)sendQueuedMessages {
    for (NSString* js in self.queuedMessages.copy) {
        [self sendRawMessage:js];
    }
    [self disableQueueingAndRemoveQueuedMessages];
}

- (void)disableQueueingAndRemoveQueuedMessages {
    self.shouldQueueMessages = NO;
    [self.queuedMessages removeAllObjects];
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName {
    self.shouldQueueMessages = YES;
    [self.webView loadHTML:string withAssetsFile:fileName];
}

#pragma mark - WKnavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSURLRequest* request = navigationAction.request;
    if ([self isBridgeURL:request.URL]) {
        NSDictionary* message = [self extractBridgePayload:request.URL];
        NSString* messageType = message[@"type"];
        NSDictionary* payload = message[@"payload"];
        [self fireEvent:messageType withPayload:payload];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    self.shouldQueueMessages = YES;
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"webView failed to load: %@", error);
    [self disableQueueingAndRemoveQueuedMessages];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    NSLog(@"webView failed to load: %@", error);
    [self disableQueueingAndRemoveQueuedMessages];
}



@end
