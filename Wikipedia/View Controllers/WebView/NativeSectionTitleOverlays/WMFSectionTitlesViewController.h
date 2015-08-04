//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@interface WMFSectionTitlesViewController : NSObject

- (instancetype)initWithWebView:(UIWebView*)webView webViewController:(UIViewController*)webViewController;

- (void)resetOverlays;
- (void)updateTopOverlayForScrollOffsetY:(CGFloat)offsetY;
- (void)hideTopOverlay;

- (UIView*)topHeader;

@end
