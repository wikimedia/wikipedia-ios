@import WebKit;
@import WMF.Swift;

@interface AboutViewController : UIViewController <WKNavigationDelegate, WMFThemeable>

- (instancetype)initWithTheme:(WMFTheme *)theme;

@end
