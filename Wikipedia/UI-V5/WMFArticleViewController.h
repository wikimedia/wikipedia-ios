
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, WMFArticleControllerMode) {
    WMFArticleControllerModeNormal = 0,
    WMFArticleControllerModeList,
    WMFArticleControllerModePopup,
};

@interface WMFArticleViewController : UITableViewController

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages;

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;
@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;

@property (nonatomic, assign, readonly) WMFArticleControllerMode mode;
- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated;

@property (nonatomic, strong, nullable) MWKArticle* article;

- (void)updateUI;

@property (nonatomic, strong, readonly) UIButton* saveButton;
@property (nonatomic, strong, readonly) UIButton* readButton;



@end

NS_ASSUME_NONNULL_END
