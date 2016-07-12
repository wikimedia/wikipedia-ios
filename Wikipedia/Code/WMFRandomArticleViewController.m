#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSite.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"
#import "WMFRandomDiceButton.h"
#import "WMFArticleNavigationController.h"
#import "UIViewController+WMFArticlePresentation.h"
#import "WMFArticleNavigationController.h"

static const CGFloat WMFRandomAnimationDurationFade = 0.5;

@interface WMFRandomArticleViewController ()
@property (nonatomic, strong) WMFRandomDiceButton* diceButton;
@property (nonatomic, strong) UIButton* anotherRandomArticleButton;
@property (nonatomic, strong) UIBarButtonItem* diceButtonItem;
@property (nonatomic, strong) UIView* emptyFadeView;
@property (nonatomic, strong) WMFRandomArticleFetcher* randomArticleFetcher;
@property (nonatomic, getter = viewHasAppeared) BOOL viewAppeared;
@property (nonatomic) CGFloat previousContentOffsetY;
@end

@implementation WMFRandomArticleViewController

- (instancetype)initWithArticleTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore diceButtonItem:(UIBarButtonItem*)diceButtonItem {
    self                = [super initWithArticleTitle:title dataStore:dataStore];
    self.diceButtonItem = diceButtonItem;
    self.diceButton     = (WMFRandomDiceButton*)diceButtonItem.customView;
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
        self.diceButton     = [[WMFRandomDiceButton alloc] initWithFrame:CGRectMake(0, 0, 57, 57)];
        self.diceButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.diceButton];
    }
    
    UIBarButtonItem* leftFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];

    self.anotherRandomArticleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.anotherRandomArticleButton setTitle:MWLocalizedString(@"explore-another-random", nil) forState:UIControlStateNormal];
    CGSize size = [self.anotherRandomArticleButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, 57)];
    self.anotherRandomArticleButton.frame = (CGRect){CGPointZero, size};
    [self.anotherRandomArticleButton addTarget:self action:@selector(loadAndShowAnotherRandomArticle:) forControlEvents:UIControlEventTouchUpInside];
    [self.anotherRandomArticleButton setTintColor:[UIColor wmf_blueTintColor]];
    UIBarButtonItem* anotherRandomItem  = [[UIBarButtonItem alloc] initWithCustomView:self.anotherRandomArticleButton];
    
    UIBarButtonItem* rightFlexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    self.secondToolbarItems = @[leftFlexibleSpace, self.diceButtonItem, anotherRandomItem, rightFlexibleSpace];
}

- (void)setupEmptyFadeView {
    self.emptyFadeView                  = [[UIView alloc] initWithFrame:self.view.bounds];
    self.emptyFadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.emptyFadeView.backgroundColor  = [UIColor whiteColor];
    self.emptyFadeView.alpha            = 0;
    [self.view addSubview:self.emptyFadeView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.diceButton addTarget:self action:@selector(loadAndShowAnotherRandomArticle:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppeared = YES;
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
    MWKSite* site = self.articleTitle.site;
    [self.randomArticleFetcher fetchRandomArticleWithSite:site failure:^(NSError* error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    } success:^(MWKSearchResult* result) {
        MWKTitle* title = [site titleWithString:result.displayTitle];
        WMFRandomArticleViewController* randomArticleVC = [[WMFRandomArticleViewController alloc] initWithArticleTitle:title dataStore:self.dataStore diceButtonItem:self.diceButtonItem];
        [self wmf_pushArticleViewController:randomArticleVC animated:YES];
    }];
}


#pragma mark - WebViewControllerDelegate

- (void)webViewController:(WebViewController*)controller scrollViewDidScroll:(UIScrollView*)scrollView {
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
    } else {
        shouldHideRandomButton =  newContentOffsetY > 0 && newContentOffsetY > self.previousContentOffsetY;
    }
    
    if (articleNavgiationController.secondToolbarHidden != shouldHideRandomButton) {
        [articleNavgiationController setSecondToolbarHidden:shouldHideRandomButton animated:YES];
    }
    
    self.previousContentOffsetY = newContentOffsetY;
}


@end
