//
//  CommunicationBridge.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import "CommunicationBridge.h"

@implementation CommunicationBridge {
    UIWebView *webView;
    NSMutableDictionary *listenersByEvent;
}

#pragma mark Public methods

- (CommunicationBridge *)initWithWebView:(UIWebView *)targetWebView
{
    self = [super init];
    if (self) {
        webView = targetWebView;
        listenersByEvent = [[NSMutableDictionary alloc] init];
    }
    [self setupWebView];
    return self;
}

- (void)addListener:(NSString *)messageType withBlock:(JSListener)block
{
    NSMutableArray *listeners = [self listenersForMessageType:messageType];
    if (listeners == nil) {
        listenersByEvent[messageType] = [NSMutableArray arrayWithObject:block];
    } else {
        [listeners addObject:block];
    }
}


#pragma mark Internal and testing methods

// Methods reserved for internal and testing
- (NSMutableArray *)listenersForMessageType:(NSString *)messageType
{
    return listenersByEvent[messageType];
}

- (void)fireEvent:(NSString *)messageType withPayload:(NSDictionary *)payload
{
    NSArray *listeners = [self listenersForMessageType:messageType];
    for (JSListener listener in listeners) {
        listener(messageType, payload);
    }
}

#pragma mark Private methods

- (void)setupWebView
{
    webView.delegate = self;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bridge-index" ofType:@"html"];
    NSURL *baseURL = [NSURL URLWithString:@"https://wikipedia-ios.wikipedia.org"]; // fake path
    NSData *data = [NSData dataWithContentsOfFile:path];
    [webView loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
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
    // fixme throw an exception?
    return dict;
}

#pragma mark UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"QQQ %@", request.URL);
    if ([self isBridgeURL:request.URL]) {
        NSDictionary *message = [self extractBridgePayload:request.URL];
        NSString *messageType = message[@"type"];
        NSDictionary *payload = message[@"payload"];
        [self fireEvent:messageType withPayload:payload];
        return NO;
    }
    return YES;
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webView failed to load: %@", error);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webView finished load");
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webView started load");
}

@end
