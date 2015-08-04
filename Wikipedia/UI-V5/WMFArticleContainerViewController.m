
#import "WMFArticleContainerViewController.h"
#import <Masonry/Masonry.h>
#import "WMFArticleViewController.h"

@interface WMFArticleContainerViewController ()<UINavigationControllerDelegate>

@property (nonatomic, strong, readwrite) UINavigationController* containingNavigaionController;
@property (nonatomic, strong, readwrite) WMFArticleViewController* articleViewController;

@end

@implementation WMFArticleContainerViewController

+ (instancetype)articleContainerViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages {
    WMFArticleViewController* vc = [WMFArticleViewController articleViewControllerWithDataStore:dataStore savedPages:savedPages];
    return [[[self class] alloc] initWithArticleViewController:vc];
}

- (instancetype)initWithArticleViewController:(WMFArticleViewController*)articleViewController {
    self = [super init];
    if (self) {
        self.articleViewController = articleViewController;
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:self.articleViewController];
        nc.navigationBarHidden = YES;
        [self.view addSubview:nc.view];
        [nc.view mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.trailing.top.bottom.equalTo(self.view);
        }];
        [self addChildViewController:nc];
        [nc didMoveToParentViewController:self];
        self.containingNavigaionController = nc;
    }
    return self;
}

- (void)setArticle:(MWKArticle*)article {
    self.articleViewController.article = article;
}

- (MWKArticle*)article {
    return self.articleViewController.article;
}

#pragma mark - WMFArticleListTranstionEnabling

- (BOOL)transitionShouldBeEnabled:(WMFArticleListTranstion*)transition {
    if ([[self.containingNavigaionController viewControllers] count] > 1) {
        return NO;
    }
    return YES;
}

@end
