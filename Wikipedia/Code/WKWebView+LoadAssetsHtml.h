//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

@import WebKit;

@interface WKWebView (LoadAssetsHtml)

// Loads contents of fileName. Assumes the file is in the "assets" folder.
- (void)loadHTMLFromAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment;

// Loads html passed to it injected into html from fileName.
- (void)loadHTML:(NSString*)string withAssetsFile:(NSString*)fileName scrolledToFragment:(NSString*)fragment topPadding:(NSUInteger)topPadding;

@end
