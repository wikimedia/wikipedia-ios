#import "WMFRandomArticleViewController.h"
#import "WMFRandomArticleFetcher.h"
#import "MWKSite.h"
#import "MWKSearchResult.h"
#import "Wikipedia-Swift.h"

@interface WMFRandomArticleViewController ()

@property (nonatomic, strong) WMFRandomArticleFetcher* randomArticleFetcher;
@property (nonatomic, strong) MWKSite* site;

@property (nonatomic, strong) UIButton* randomButton;
@property (nonatomic, strong) UIView* emptyFadeView;

@property (nonatomic, getter = isRandomButtonHidden) BOOL randomButtonHidden;

@end

@implementation WMFRandomArticleViewController

- (instancetype)initWithRandomArticleFetcher:(WMFRandomArticleFetcher*)randomArticleFetcher site:(MWKSite*)site dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super initWithDataStore:dataStore];
    if (self) {
        self.site                 = site;
        self.randomArticleFetcher = randomArticleFetcher;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupEmptyFadeView];
    [self setupRandomButton];


    [self loadRandomArticle:self];
}

- (void)setupRandomButton {
    self.randomButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.randomButton.backgroundColor = [UIColor wmf_blueTintColor];
    [self.randomButton setTitle:@"!" forState:UIControlStateNormal];
    [self.randomButton addTarget:self action:@selector(loadRandomArticle:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.randomButton];
}

- (void)setupEmptyFadeView {
    self.emptyFadeView                  = [[UIView alloc] initWithFrame:self.view.bounds];
    self.emptyFadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.emptyFadeView.backgroundColor  = [UIColor whiteColor];
    self.emptyFadeView.alpha            = 0;
    [self.view addSubview:self.emptyFadeView];
}

#pragma mark - Loading

- (void)loadRandomArticle:(id)sender {
    [self configureViewsForRandomArticleLoading:true];
    [self.randomArticleFetcher fetchRandomArticleWithSite:self.site failure:^(NSError* error) {
        [[WMFAlertManager sharedInstance] showErrorAlert:error
                                                  sticky:NO
                                   dismissPreviousAlerts:NO
                                             tapCallBack:NULL];
        [self configureViewsForRandomArticleLoading:false];
    } success:^(MWKSearchResult* searchResult) {
        self.articleTitle = [self.site titleWithString:searchResult.displayTitle];
        [self fetchArticleForce:YES completion:^{
            [self configureViewsForRandomArticleLoading:false];
        }];
    }];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutRandomButtonForViewBounds:self.view.bounds hidden:self.isRandomButtonHidden];
}

- (void)layoutRandomButtonForViewBounds:(CGRect)bounds hidden:(BOOL)hidden {
    CGSize randomButtonSize     = CGSizeMake(44, 44);
    CGFloat randomButtonOriginX = (0.5 * bounds.size.width - 0.5 * randomButtonSize.width);
    CGFloat randomButtonOriginY = hidden ? bounds.size.height : bounds.size.height - 100;
    CGPoint randomButtonOrigin  = CGPointMake(randomButtonOriginX, randomButtonOriginY);
    self.randomButton.frame = (CGRect){randomButtonOrigin, randomButtonSize};
}

- (void)configureViewsForRandomArticleLoading:(BOOL)isRandomArticleLoading {
    self.randomButton.enabled = !isRandomArticleLoading;
    [UIView animateWithDuration:0.2 animations:^{
        self.emptyFadeView.alpha = isRandomArticleLoading ? 1 : 0;
    } completion:^(BOOL finished) {
        if (finished && isRandomArticleLoading) {
            [self showEmptyArticle];
        }
    }];
}

@end
