//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@import WebKit;
#import "WMFOpenExternalLinkDelegateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface PreviewWebView : WKWebView <WKNavigationDelegate>

@property (nonatomic, weak) id <WMFOpenExternalLinkDelegate> externalLinksOpenerDelegate;

@end

NS_ASSUME_NONNULL_END