//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

typedef void (^JSListener)(NSString *, NSDictionary *);

@interface CommunicationBridge : NSObject <UIWebViewDelegate>

@property BOOL isDOMReady;

// Public methods
- (CommunicationBridge *)initWithWebView:(UIWebView *)webView;
- (void)addListener:(NSString *)messageType withBlock:(JSListener)block;
- (void)sendMessage:(NSString *)messageType withPayload:(NSDictionary *)payload;

// Methods reserved for internal and testing
- (NSMutableArray *)listenersForMessageType:(NSString *)messageType;
- (void)fireEvent:(NSString *)messageType withPayload:(NSDictionary *)payload;
- (BOOL)isBridgeURL:(NSURL *)url;
- (NSDictionary *)extractBridgePayload:(NSURL *)url;
- (NSString *)stringify:(id)obj;

@end
