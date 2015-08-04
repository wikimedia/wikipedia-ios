
#import "WMFArticleContainerViewController.h"
#import <Masonry/Masonry.h>
#import "WMFArticleViewController.h"

@interface WMFArticleContainerViewController ()

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
        nc.delegate            = self.articleViewController;
        [self.view addSubview:nc.view];
        [nc.view mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.trailing.top.bottom.equalTo(self.view);
        }];
        [self addChildViewController:nc];
        [nc didMoveToParentViewController:self];
    }
    return self;
}

- (void)setArticle:(MWKArticle*)article {
    self.articleViewController.article = article;
}

- (MWKArticle*)article {
    return self.articleViewController.article;
}

@end
