
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"
#import <Masonry/Masonry.h>

@interface WMFArticleViewControllerContainerCell ()

@property(nonatomic, strong, readwrite) WMFArticleViewController* viewController;

@end

@implementation WMFArticleViewControllerContainerCell

- (void)prepareForReuse {
    self.viewController.article = nil;
}

- (void)setViewControllerAndAddViewToContentView:(WMFArticleViewController*)viewController {
    self.viewController = viewController;
    [self.contentView addSubview:viewController.view];

    [viewController.view mas_makeConstraints:^(MASConstraintMaker* make) {
        make.edges.equalTo(self.contentView);
    }];
}

@end
