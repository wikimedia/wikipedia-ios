//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

typedef void (^ JSListener)(NSString*, NSDictionary*);

@interface CommunicationBridge : NSObject <UIWebViewDelegate>

- (CommunicationBridge*)initWithWebView:(UIWebView*)targetWebView;

- (void)addListener:(NSString*)messageType
          withBlock:(JSListener)block;

- (void)sendMessage:(NSString*)messageType
        withPayload:(NSDictionary*)payload;

// This method calls the "loadHTML:withAssetsFile:" category method on
// UIWebView, but first it enables message queueing so subsequent calls
// to "sendMessage:withPayload:" are queued until the html load completes.
- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName;

WMF_TECH_DEBT_TODO(add error handling for HTML loading)

@end
