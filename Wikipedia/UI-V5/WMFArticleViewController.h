
#import <UIKit/UIKit.h>

@interface WMFArticleViewController : UIViewController

+ (instancetype)articleViewControllerFromDefaultStoryBoard;

@property (nonatomic, assign) CGFloat contentTopInset;

@property (nonatomic, strong) MWKSavedPageList* savedPages;
@property (nonatomic, strong) MWKArticle* article;

@end
