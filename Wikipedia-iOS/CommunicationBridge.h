//
//  CommunicationBridge.h
//  Wikipedia-iOS
//
//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JSListener)(NSString *, NSDictionary *);

@interface CommunicationBridge : NSObject <UIWebViewDelegate>

@property BOOL isDOMReady;

// Public methods
- (CommunicationBridge *)initWithWebView:(UIWebView *)webView;
- (void)addListener:(NSString *)messageType withBlock:(JSListener)block;

// Methods reserved for internal and testing
- (NSMutableArray *)listenersForMessageType:(NSString *)messageType;
- (void)fireEvent:(NSString *)messageType withPayload:(NSDictionary *)payload;
- (BOOL)isBridgeURL:(NSURL *)url;
- (NSDictionary *)extractBridgePayload:(NSURL *)url;

@end
