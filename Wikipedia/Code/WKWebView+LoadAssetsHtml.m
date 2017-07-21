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

- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL withAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment padding:(UIEdgeInsets)padding theme:(WMFTheme *)theme {
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

    NSAssert([fileContents componentsSeparatedByString:@"%@"].count == (5 + 1), @"\nHTML template file does not have required number of percent-ampersand occurences (5).\nNumber of percent-ampersands must match number of values passed to 'stringWithFormat:'");

    NSString *stringToInjectIntoHeadTag = [self stringToInjectIntoHeadTagWithFontSize:fontSize baseURL:baseURL theme:theme];

    // index.html and preview.html have 5 "%@" subsitition markers. Replace these with actual content.
    NSString *templateAndContent = [NSString stringWithFormat:fileContents, stringToInjectIntoHeadTag, @(padding.top), @(padding.left), @(padding.right), string];

    NSUInteger hash = [[baseURL wmf_articleDatabaseKey] hash];
    NSString *requestPath = [NSString stringWithFormat:@"%lu-%@", (unsigned long)hash, fileName];
    [proxyServer setResponseData:[templateAndContent dataUsingEncoding:NSUTF8StringEncoding] withContentType:@"text/html; charset=utf-8" forPath:requestPath];

    [self loadHTMLFromAssetsFile:requestPath scrolledToFragment:fragment];
}

- (NSString *)getAssetsPath {
    return [WikipediaAppUtils assetsPath];
}

- (NSString *)stringToInjectIntoHeadTagWithFontSize:(NSNumber *)fontSize baseURL:(NSURL *)baseURL theme:(WMFTheme *)theme {

    // The 'theme' and 'compatibility' calls are deliberately injected specifically into the head tag via an inline script because:
    //      "... inline scripts are fetched and executed immediately, before the browser continues to parse the page"
    //      https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script
    //
    //  This ensures all theme settings are in place before any page rendering occurs.
    //
    // 'compatibility.enableSupport()'
    //      Needs to happen only once but *before* body elements are present and before
    //      calling 'themes.setTheme()'.
    //
    // 'themes.setTheme()'
    //      Needs to happen before body elements are present so these will appear with
    //      correct theme colors already set. (This method is also used to changes themes,
    //      but changing themes doesn't require 'compatibility.enableSupport()' or
    //      'themes.classifyElements()' be called again.)
    //
    // Reminder:
    //      We don't want to use 'addUserScript:' with WKUserScriptInjectionTimeAtDocumentEnd for this because
    //      it happens too late - at 'DocumentEnd'. We want the colors to be set before this so there is never
    //      a flickering color change visible to the user. We can't use WKUserScriptInjectionTimeAtDocumentBegin
    //      because this fires before any of the head tag contents are resolved, including references to our JS
    //      libraries - we'd have to make a larger set of changes to make this work.

    return [NSString stringWithFormat:@""
                                       "\n<style type='text/css'>"
                                       "\n    body {"
                                       "\n        -webkit-text-size-adjust: %@;"
                                       "\n    }"
                                       "\n</style>"
                                       "\n<base href=\"%@\">"
                                       "\n<script type='text/javascript'>"
                                       "\n    window.wmf.compatibility.enableSupport(document);"
                                       "\n    %@"
                                       "\n</script>",
                                      [NSString stringWithFormat:@"%ld%%", (long)fontSize.integerValue], baseURL.absoluteString, [WKWebView wmf_themeApplicationJavascriptWith:theme]];
}

@end
