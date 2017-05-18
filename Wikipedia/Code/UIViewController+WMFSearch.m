#import "UIViewController+WMFSearch.h"
#import "WMFSearchViewController.h"
#import "SessionSingleton.h"
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFSearchButton

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 30, 30);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    self = [super initWithCustomView:button];
    return self;
}

- (void)setAlpha:(CGFloat)alpha
{
    self.customView.alpha = alpha;
}

- (CGFloat)alpha
{
    return self.customView.alpha;
}


@end

@implementation UIViewController (WMFSearchButton)

static MWKDataStore *_dataStore = nil;

static WMFSearchViewController *_Nullable _sharedSearchViewController = nil;

+ (void)wmf_setSearchButtonDataStore:(MWKDataStore *)dataStore {
    NSParameterAssert(dataStore);
    _dataStore = dataStore;
    [self wmf_clearSearchViewController];
}

+ (void)wmf_clearSearchViewController {
    _sharedSearchViewController = nil;
}

+ (WMFSearchViewController *)wmf_sharedSearchViewController {
    return _sharedSearchViewController;
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wmfSearchButton_applicationDidEnterBackgroundWithNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wmfSearchButton_applicationDidReceiveMemoryWarningWithNotification:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

+ (void)wmfSearchButton_applicationDidEnterBackgroundWithNotification:(NSNotification *)note {
    [self wmf_clearSearchViewController];
}

+ (void)wmfSearchButton_applicationDidReceiveMemoryWarningWithNotification:(NSNotification *)note {
    [self wmf_clearSearchViewController];
}

- (WMFSearchButton *)wmf_searchBarButtonItem {
    return [[WMFSearchButton alloc] initWithTarget:self action:@selector(wmf_showSearch)];
}

- (void)wmf_showSearch {
    [self wmf_showSearchAnimated:YES];
}

- (void)wmf_showSearchAnimated:(BOOL)animated {
    NSParameterAssert(_dataStore);

    if (!_sharedSearchViewController) {
        WMFSearchViewController *searchVC =
            [WMFSearchViewController searchViewControllerWithDataStore:_dataStore];
        _sharedSearchViewController = searchVC;
    }
    [self presentViewController:_sharedSearchViewController animated:animated completion:nil];
}

@end

NS_ASSUME_NONNULL_END
