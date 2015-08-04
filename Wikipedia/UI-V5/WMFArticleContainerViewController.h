
@import UIKit;

@class WMFArticleViewController;
@class MWKDataStore;
@class MWKSavedPageList;
@class MWKArticle;

@interface WMFArticleContainerViewController : UIViewController

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong) MWKArticle* article;

@property (nonatomic, strong, readonly) UINavigationController* containingNavigaionController;
@property (nonatomic, strong, readonly) WMFArticleViewController* articleViewController;

@end
