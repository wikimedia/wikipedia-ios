
#import <UIKit/UIKit.h>

@class WMFArticleViewController;

@interface WMFArticleViewControllerContainerCell : UICollectionViewCell

@property(nonatomic, strong, readonly) WMFArticleViewController* viewController;

- (void)setViewControllerAndAddViewToContentView:(WMFArticleViewController*)viewController;

@end
