//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CommunicationBridge.h"
#import "UIWebView+LoadAssetsHtml.h"

@interface CommunicationBridge (){

}

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSMutableDictionary *listenersByEvent;
@property (strong, nonatomic) NSMutableArray *queuedMessages;

@end

@implementation CommunicationBridge {
}

#pragma mark Public methods

- (CommunicationBridge *)initWithWebView: (UIWebView *)targetWebView
                            htmlFileName: (NSString *)htmlFileName
{
    self = [super init];
    if (self) {
        self.webView = targetWebView;
        self.listenersByEvent = [[NSMutableDictionary alloc] init];
        self.queuedMessages = [[NSMutableArray alloc] init];

        __weak CommunicationBridge *weakSelf = self;
        [self addListener:@"DOMLoaded" withBlock:^(NSString *type, NSDictionary *payload) {
            [weakSelf onDOMReady];
        }];
        [self setupWebView:targetWebView htmlFileName:htmlFileName];
    }
    return self;
}

- (void)addListener: (NSString *)messageType
          withBlock: (JSListener)block
{
    NSMutableArray *listeners = [self listenersForMessageType:messageType];
    if (listeners == nil) {
        self.listenersByEvent[messageType] = [NSMutableArray arrayWithObject:block];
    } else {
        [listeners addObject:block];
    }
}

- (void)sendMessage: (NSString *)messageType
        withPayload: (NSDictionary *)payload
{
    NSString *js = [NSString stringWithFormat:@"bridge.handleMessage(%@,%@)",
                    [self stringify:messageType],
                    [self stringify:payload]];
    //NSLog(@"QQQ sending: %@", js);
    if (self.isDOMReady) {
        [self sendRawMessage:js];
    } else {
        [self.queuedMessages addObject:js];
    }
}

#pragma mark Internal and testing methods

// Methods reserved for internal and testing
- (NSMutableArray *)listenersForMessageType:(NSString *)messageType
{
    return self.listenersByEvent[messageType];
}

- (void)fireEvent:(NSString *)messageType withPayload:(NSDictionary *)payload
{
    NSArray *listeners = [self listenersForMessageType:messageType];
    for (JSListener listener in listeners) {
        listener(messageType, payload);
    }
}

- (NSString *)stringify:(id)obj
{
    BOOL needsWrapper = ![NSJSONSerialization isValidJSONObject:obj];
    id payload;
    if (needsWrapper) {
        payload = @[obj];
    } else {
        payload = obj;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (needsWrapper) {
        // Remove the '['...']' wrapper
        return [str substringWithRange:NSMakeRange(1, str.length - 2)];
    } else {
        return str;
    }
}


#pragma mark Private methods

- (void)setupWebView: (UIWebView *)webView
        htmlFileName: (NSString *)htmlFileName
{
    webView.delegate = self;

    [webView loadHTMLFromAssetsFile:htmlFileName];
}

static NSString *bridgeURLPrefix = @"x-wikipedia-bridge:";

- (BOOL)isBridgeURL:(NSURL *)url
{
    return [[url absoluteString] hasPrefix:bridgeURLPrefix];
}

- (NSDictionary *)extractBridgePayload:(NSURL *)url
{
    NSString *encodedStr = [[url absoluteString] substringFromIndex:bridgeURLPrefix.length];
    NSString *str = [encodedStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        NSLog(@"JSON ERROR %@", err);
    }
    return dict;
}

- (void)sendRawMessage:(NSString *)js
{
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //NSLog(@"QQQ %@", request.URL);
    if ([self isBridgeURL:request.URL]) {
        NSDictionary *message = [self extractBridgePayload:request.URL];
        NSString *messageType = message[@"type"];
        NSDictionary *payload = message[@"payload"];
        [self fireEvent:messageType withPayload:payload];
        return NO;
    }
    return YES;
}

- (void)onDOMReady
{
    self.isDOMReady = YES;
    for (NSString *js in self.queuedMessages) {
        [self sendRawMessage:js];
    }
    [self.queuedMessages removeAllObjects];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webView failed to load: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //NSLog(@"webView finished load");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WebViewFinishedLoading" object:self userInfo:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    //NSLog(@"webView started load");
}

@end
