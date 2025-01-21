@import WebKit;
@import WMF.Swift;
@import UIKit;

@interface AboutViewController : UIViewController <WKNavigationDelegate>

- (instancetype)initWithTheme:(WMFTheme *)theme;

@end
