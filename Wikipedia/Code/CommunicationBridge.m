//  Created by Brion on 11/4/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CommunicationBridge.h"
#import "WKWebView+LoadAssetsHtml.h"

@interface CommunicationBridge ()

@property (strong, nonatomic) WKWebView* webView;

@end

@implementation CommunicationBridge

- (CommunicationBridge*)initWithWebView:(WKWebView*)targetWebView {
    self = [super init];
    if (self) {
        self.webView             = targetWebView;
    }
    return self;
}

- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName {
    [self.webView loadHTML:string withAssetsFile:fileName];
}

@end
