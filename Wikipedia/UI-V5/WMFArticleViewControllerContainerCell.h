
#import <UIKit/UIKit.h>
#import <SSDataSources/SSDataSources.h>

@class WMFArticleViewController;

@interface WMFArticleViewControllerContainerCell : SSBaseCollectionCell

@property(nonatomic, strong, readonly) WMFArticleViewController* viewController;

- (void)setViewControllerAndAddViewToContentView:(WMFArticleViewController*)viewController;

@end
