#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSite.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"
#import "WMFRandomDiceButton.h"
#import "WMFArticleNavigationController.h"
#import "UIViewController+WMFArticlePresentation.h"

static const CGFloat WMFRandomAnimationDurationFade = 0.5;

@interface WMFRandomArticleViewController ()
@property (nonatomic, strong) WMFRandomDiceButton* diceButton;
@property (nonatomic, strong) UIButton* anotherRandomArticleButton;
@property (nonatomic, strong) UIBarButtonItem* diceButtonItem;
@property (nonatomic, strong) UIView* emptyFadeView;
@property (nonatomic, strong) WMFRandomArticleFetcher* randomArticleFetcher;
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
    [self.anotherRandomArticleButton addTarget:self action:@selector(anotherOne:) forControlEvents:UIControlEventTouchUpInside];
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
    
    if (!self.articleTitle) {
        [self configureViewsForRandomArticleLoading:YES animated:NO];
        [self anotherOne:self];
    }
    
    [self.diceButton addTarget:self action:@selector(anotherOne:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.diceButton removeTarget:self action:@selector(anotherOne:) forControlEvents:UIControlEventTouchUpInside];
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

- (void)anotherOne:(id)sender {
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

@end
