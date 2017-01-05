#import "WKWebView+LoadAssetsHtml.h"
#import "WMFProxyServer.h"
#import "Wikipedia-Swift.h"

static const NSTimeInterval WKWebViewLoadAssetsHTMLRequestTimeout = 60; //60s is the default NSURLRequest timeout interval

@implementation WKWebView (LoadAssetsHtml)

- (void)loadHTMLFromAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment {
    if (!fileName) {
        DDLogError(@"attempted to load nil file");
        return;
    }

    fragment = fragment ? fragment : @"top";
    NSURL *requestURL = [[WMFProxyServer sharedProxyServer] proxyURLForRelativeFilePath:fileName fragment:fragment];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:WKWebViewLoadAssetsHTMLRequestTimeout];
    [self loadRequest:request];
}

- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL withAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment padding:(UIEdgeInsets)padding {
    if (!string) {
        string = @"";
    }

    WMFProxyServer *proxyServer = [WMFProxyServer sharedProxyServer];

    if (!proxyServer.isRunning) {
        [proxyServer start];
    }

    string = [proxyServer stringByReplacingImageURLsWithProxyURLsInHTMLString:string withBaseURL:baseURL targetImageWidth:self.window.screen.wmf_articleImageWidthForScale];

    NSString *localFilePath = [[self getAssetsPath] stringByAppendingPathComponent:fileName];

    if (!localFilePath) {
        return;
    }

    NSString *fileContents = [NSMutableString stringWithContentsOfFile:localFilePath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];

    NSNumber *fontSize = [[NSUserDefaults wmf_userDefaults] wmf_articleFontSizeMultiplier];
    NSString *fontString = [NSString stringWithFormat:@"%ld%%", (long)fontSize.integerValue];

    NSAssert([fileContents componentsSeparatedByString:@"%@"].count == (7 + 1), @"\nHTML template file does not have required number of percent-ampersand occurences (7).\nNumber of percent-ampersands must match number of values passed to  'stringWithFormat:'");

    // index.html and preview.html have four "%@" subsitition markers. Replace both of these with actual content.
    NSString *templateAndContent = [NSString stringWithFormat:fileContents, fontString, baseURL.absoluteString, @(padding.top), @(padding.right), @(padding.bottom), @(padding.left), string];

    NSUInteger hash = [[baseURL wmf_articleDatabaseKey] hash];
    NSString *requestPath = [NSString stringWithFormat:@"%lu-%@", (unsigned long)hash, fileName];
    [proxyServer setResponseData:[templateAndContent dataUsingEncoding:NSUTF8StringEncoding] withContentType:@"text/html; charset=utf-8" forPath:requestPath];

    [self loadHTMLFromAssetsFile:requestPath scrolledToFragment:fragment];
}

- (NSString *)getAssetsPath {
    return [WikipediaAppUtils assetsPath];
}

@end
