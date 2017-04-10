#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"
#import "WMFArticleDataStore.h"
#import "WMFRandomDiceButton.h"
#import "WMFArticleNavigationController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFArticleNavigationController.h"
#if WMF_TWEAKS_ENABLED
#import "MWKDataStore.h"
#import "MWKSavedPageList.h"
#endif

static const CGFloat WMFRandomAnimationDurationFade = 0.5;

@interface WMFRandomArticleViewController ()
@property (nonatomic, strong) WMFRandomDiceButton *diceButton;
@property (nonatomic, strong) UIBarButtonItem *diceButtonItem;
@property (nonatomic, strong) UIView *emptyFadeView;
@property (nonatomic, strong) WMFRandomArticleFetcher *randomArticleFetcher;
@property (nonatomic, getter=viewHasAppeared) BOOL viewAppeared;
@property (nonatomic) CGFloat previousContentOffsetY;
@end

@implementation WMFRandomArticleViewController

- (instancetype)initWithArticleURL:(NSURL *)articleURL dataStore:(MWKDataStore *)dataStore previewStore:(WMFArticleDataStore *)previewStore diceButtonItem:(UIBarButtonItem *)diceButtonItem {
    self = [super initWithArticleURL:articleURL dataStore:dataStore previewStore:previewStore];
    self.diceButtonItem = diceButtonItem;
    self.diceButton = (WMFRandomDiceButton *)diceButtonItem.customView;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.randomArticleFetcher = [[WMFRandomArticleFetcher alloc] init];

    [self setupSecondToolbar];
    [self setupEmptyFadeView];
}

- (void)setupSecondToolbar {
    if (!self.diceButtonItem) {
        self.diceButton = [[WMFRandomDiceButton alloc] initWithFrame:CGRectMake(0, 0, 184, 44)];
        self.diceButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.diceButton];
    }

    UIBarButtonItem *leftFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

    UIBarButtonItem *rightFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

    self.secondToolbarItems = @[leftFlexibleSpace, self.diceButtonItem, rightFlexibleSpace];
}

- (void)setupEmptyFadeView {
    self.emptyFadeView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.emptyFadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.emptyFadeView.backgroundColor = [UIColor whiteColor];
    self.emptyFadeView.alpha = 0;
    [self.view addSubview:self.emptyFadeView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.diceButton addTarget:self action:@selector(loadAndShowAnotherRandomArticle:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppeared = YES;

#if WMF_TWEAKS_ENABLED
    if (!self.permaRandomMode) {
        return;
    }
    [self.navigationController setViewControllers:@[self]];
    uint32_t rand = arc4random_uniform(100);
    if (rand < 34) {
        [self.dataStore.savedPageList addSavedPageWithURL:self.articleURL];
    }
    [self loadAndShowAnotherRandomArticle:self];
#endif
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.diceButton removeTarget:self action:@selector(loadAndShowAnotherRandomArticle:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self configureViewsForRandomArticleLoading:NO animated:NO];
}

- (void)configureViewsForRandomArticleLoading:(BOOL)isRandomArticleLoading animated:(BOOL)animated {
    if (isRandomArticleLoading) {
        [self.diceButton roll];
    }
    self.diceButton.enabled = !isRandomArticleLoading;

    dispatch_block_t animations = ^{
        self.emptyFadeView.alpha = isRandomArticleLoading ? 1 : 0;
    };

    if (animated) {
        [UIView animateWithDuration:WMFRandomAnimationDurationFade animations:animations completion:NULL];
    } else {
        animations();
    }
}

- (void)loadAndShowAnotherRandomArticle:(id)sender {
    [self configureViewsForRandomArticleLoading:YES animated:YES];
    NSURL *siteURL = self.articleURL.wmf_siteURL;
    [self.randomArticleFetcher fetchRandomArticleWithSiteURL:siteURL
        failure:^(NSError *error) {
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
        }
        success:^(MWKSearchResult *result) {
            NSURL *titleURL = [siteURL wmf_URLWithTitle:result.displayTitle];
            WMFRandomArticleViewController *randomArticleVC = [[WMFRandomArticleViewController alloc] initWithArticleURL:titleURL dataStore:self.dataStore previewStore:self.previewStore diceButtonItem:self.diceButtonItem];
#if WMF_TWEAKS_ENABLED
            randomArticleVC.permaRandomMode = YES;
#endif
            [self wmf_pushArticleViewController:randomArticleVC
                                       animated:YES];
        }];
}

#pragma mark - WebViewControllerDelegate

- (void)webViewController:(WebViewController *)controller scrollViewDidScroll:(UIScrollView *)scrollView {
    [super webViewController:controller scrollViewDidScroll:scrollView];

    if (!self.viewHasAppeared) {
        return;
    }

    WMFArticleNavigationController *articleNavgiationController = (WMFArticleNavigationController *)self.navigationController;
    if (![articleNavgiationController isKindOfClass:[WMFArticleNavigationController class]]) {
        return;
    }

    BOOL shouldHideRandomButton = YES;
    CGFloat newContentOffsetY = scrollView.contentOffset.y;

    if (articleNavgiationController.secondToolbarHidden) {
        BOOL shouldShowRandomButton = newContentOffsetY <= 0 || (!scrollView.tracking && scrollView.decelerating && newContentOffsetY < self.previousContentOffsetY && newContentOffsetY < (scrollView.contentSize.height - scrollView.bounds.size.height));
        shouldHideRandomButton = !shouldShowRandomButton;
    } else if (scrollView.tracking || scrollView.decelerating) {
        shouldHideRandomButton = newContentOffsetY > 0 && newContentOffsetY > self.previousContentOffsetY;
    } else {
        shouldHideRandomButton = articleNavgiationController.secondToolbarHidden;
    }

    if (articleNavgiationController.secondToolbarHidden != shouldHideRandomButton) {
        [articleNavgiationController setSecondToolbarHidden:shouldHideRandomButton animated:YES];
    }

    self.previousContentOffsetY = newContentOffsetY;
}

#if WMF_TWEAKS_ENABLED
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ([super respondsToSelector:@selector(motionEnded:withEvent:)]) {
        [super motionEnded:motion withEvent:event];
    }
    if (event.subtype != UIEventSubtypeMotionShake) {
        return;
    }
    self.permaRandomMode = !self.isPermaRandomMode;
    if (!self.permaRandomMode) {
        return;
    }
    [self loadAndShowAnotherRandomArticle:self];
}
#endif

@end
