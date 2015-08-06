
#import <UIKit/UIKit.h>
#import "WMFArticleNavigationDelegate.h"
#import "WMFArticleContentController.h"
#import "WMFArticleListItemController.h"

@class MWKDataStore;
@class MWKSavedPageList;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController : UITableViewController
    <WMFArticleContentController, WMFArticleListItemController>

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;

@property (nonatomic, weak) id<WMFArticleNavigationDelegate> articleNavigationDelegate;

- (void)updateUI;

/*
   Only exposed to allow save & read button to be selectable in popup.
 */
@property (nonatomic, strong, readonly) UIButton* saveButton;

@end

NS_ASSUME_NONNULL_END
