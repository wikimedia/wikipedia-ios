
#import "MWKHistoryEntry.h"
@import UIKit;

@interface WMFArticlePresenter : NSObject

+ (WMFArticlePresenter*)sharedInstance;

// Loads current article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentCurrentArticle;

// Loads random article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentRandomArticle;

// Loads todays article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentTodaysArticle;

// Loads article and ensures the web view is foremost. Adds web view to nav stack if none found.
- (void)presentArticleWithTitle:(MWKTitle*)title
                discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;

// Loads todays article without moving the web view to the front. Does not add web view to nav stack if none found.
- (void)loadTodaysArticle;

// Reloads current article without moving the web view to the front. Does not add web view to nav stack if none found.
- (void)reloadCurrentArticleFromNetwork;

// Return first view controller of class found anywhere on nav stack. Return nil if not found.
+ (UIViewController*)firstViewControllerOnNavStackOfClass:(Class)class;

@end
