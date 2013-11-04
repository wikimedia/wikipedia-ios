//
//  CommunicationBridgeTests.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CommunicationBridge.h"
#import "NSRunLoop+TimeOutAndFlag.h"

@interface CommunicationBridgeTests : XCTestCase

@end

@implementation CommunicationBridgeTests {
    UIWindow *window;
    UIWebView *webView;
    CommunicationBridge *bridge;
}

- (void)setUp
{
    [super setUp];

    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.screen = [UIScreen mainScreen];
    webView = [[UIWebView alloc] initWithFrame:window.frame];
    [window addSubview:webView];
    [window makeKeyAndVisible]; // ???
    bridge = [[CommunicationBridge alloc] initWithWebView:webView];
}

- (void)tearDown
{
    [window resignKeyWindow];
    window = nil;
    [super tearDown];
}

- (void)testCreated
{
    XCTAssertNotNil(bridge);
}

- (void)testAddListener
{
    JSListener listener = [^(NSString *messageType, NSDictionary *payload) {
        // whee!
    } copy];
    [bridge addListener:@"DOMLoaded" withBlock:listener];
    NSArray *listeners = [bridge listenersForMessageType:@"DOMLoaded"];
    XCTAssertNotNil(listeners);
    XCTAssert(listeners.count > 0);
    // note: can't check for the actual object as it gets automatically copied due to ARC oddities
}

- (void)testFireEvent
{
    __block NSString *foundMessageType = @"<failed to fire>";
    __block NSDictionary *foundPayload;
    JSListener listener = [^(NSString *messageType, NSDictionary *payload) {
        foundMessageType = messageType;
        foundPayload = payload;
    } copy];
    [bridge addListener:@"TestEvent" withBlock:listener];
    [bridge fireEvent:@"TestEvent" withPayload:@{}];
    XCTAssertEqualObjects(foundMessageType, @"TestEvent");
    XCTAssertNotNil(foundPayload);
}

- (void)testIsBridgeURL
{
    XCTAssertFalse([bridge isBridgeURL:[NSURL URLWithString:@"http://en.wikipedia.org/wiki/Foo"]]);
    XCTAssertTrue([bridge isBridgeURL:[NSURL URLWithString:@"x-wikipedia-bridge:%7B%7D"]]);
}

- (void)testExtractBridgePayload
{
    NSDictionary *payload = [bridge extractBridgePayload:[NSURL URLWithString:@"x-wikipedia-bridge:%7B%7D"]];
    XCTAssertNotNil(payload);

    payload = [bridge extractBridgePayload:[NSURL URLWithString:@"x-wikipedia-bridge:%7B%22key%22%3A%22value%22%7D"]];
    XCTAssertNotNil(payload);
    XCTAssertEqualObjects(payload[@"key"], @"value");
}

- (void)testDOMLoaded
{
    __block NSString *foundMessageType = @"<failed to fire>";
    __block BOOL found = NO;
    
    NSLog(@"QQQ WAITING");
    [bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"QQQ HEY");
        foundMessageType = messageType;
        found = YES;
    }];
    [[NSRunLoop mainRunLoop] runUntilTimeout:5 orFinishedFlag:&found];
    NSLog(@"QQQ DONE WAITING");

    XCTAssertEqualObjects(foundMessageType, @"DOMLoaded");
}

@end
