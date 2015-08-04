
@import UIKit;

#import "WMFArticleListTranstion.h"

@class WMFArticleViewController;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKArticle;

@interface WMFArticleContainerViewController : UIViewController<WMFArticleListTranstionEnabling>

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong) MWKArticle* article;
@property (nonatomic, strong, readonly) WMFArticleViewController* articleViewController;

@end

