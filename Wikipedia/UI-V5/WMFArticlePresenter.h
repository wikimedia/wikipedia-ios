
@interface WMFArticlePresenter : NSObject

+ (WMFArticlePresenter*)sharedInstance;

// Loads article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentArticleWithTitle:(MWKTitle*)title
                discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
                           then:(void (^)())block;

// Loads random article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentRandomArticleThen:(void (^)())block;

// Loads todays article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentTodaysArticleThen:(void (^)())block;

// Ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentWebViewThen:(void (^)())block;

// Loads todays article without moving the web view to the front. Does not add web view to nav stack if none found.
- (void)loadTodaysArticle;

// Pop to and return first view controller of class found. Returns nil if no view controller of class found.
+ (UIViewController*)popToFirstViewControllerOfClass:(Class)class;

// Return first view controller of class found anywhere on nav stack. Return nil if not found.
+ (UIViewController*)firstViewControllerOnNavStackOfClass:(Class)class;

// Return first view controller of class found in navigation controller's view controllers. Return nil if not found.
+ (UIViewController*)firstViewControllerOfClass:(Class)class shownByNavigationController:(UINavigationController*)navController;

@end
