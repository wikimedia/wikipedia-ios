@import WebKit;

@interface WKWebView (LoadAssetsHtml)

// Loads contents of fileName. Assumes the file is in the "assets" folder.
- (void)loadHTMLFromAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment;

// Loads html passed to it injected into html from fileName.
- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL withAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment padding:(UIEdgeInsets)padding;

- (void)cacheHTML:(NSString *)string baseURL:(NSURL *)baseURL withAssetsFile:(NSString *)fileName padding:(UIEdgeInsets)padding;

@end
