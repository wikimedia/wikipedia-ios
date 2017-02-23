#import "WMFExternalUrlViewController.h"

// Frameworks
@import WebKit;
#import <Masonry/Masonry.h>

// Other
#import "UIViewController+WMFStoryboardUtilities.h"
#import "UIBarButtonItem+WMFButtonConvenience.h"

@interface WMFExternalUrlViewController ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) WKWebView *webview;
@property (nonatomic, strong) UIBarButtonItem *buttonX;

@end

@implementation WMFExternalUrlViewController

+ (instancetype)externalUrlViewControllerWithUrl:(NSURL *)url localizedTitleKey:(NSString *)localizedTitleKey {
    NSParameterAssert(url);
    NSParameterAssert(localizedTitleKey);
    WMFExternalUrlViewController *vc = [WMFExternalUrlViewController wmf_initialViewControllerFromClassStoryboard];
    vc.url = url;
    vc.title = MWLocalizedString(localizedTitleKey, nil);
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    WKWebView *wv = [[WKWebView alloc] initWithFrame:CGRectZero];
    wv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:wv];
    [wv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.and.trailing.top.and.bottom.equalTo(wv.superview);
    }];
    [wv loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webview = wv;

    @weakify(self)
        self.buttonX = [UIBarButtonItem wmf_buttonType:WMFButtonTypeX
                                               handler:^(id sender) {
                                                   @strongify(self)
                                                       [self dismissViewControllerAnimated:YES
                                                                                completion:nil];
                                               }];

    self.buttonX.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish(@"menu-cancel-accessibility-label");

    [self updateNavigationBar];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Navigation Bar Configuration

- (void)updateNavigationBar {
    self.navigationItem.leftBarButtonItem = self.buttonX;
}

@end
