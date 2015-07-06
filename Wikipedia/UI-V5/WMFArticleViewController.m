#import "WMFArticleViewController.h"
#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "UIButton+WMFButton.h"
#import "WebViewController.h"
#import "UIStoryboard+WMFExtensions.h"
#import "UIViewController+WMFStoryboardUtilities.h"


@interface WMFArticleViewController ()

@property (strong, nonatomic) IBOutlet UIView* cardBackgroundView;
@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIButton* saveButton;

@end

@implementation WMFArticleViewController

+ (instancetype)articleViewControllerFromDefaultStoryBoard {
    return [[UIStoryboard wmf_appRootStoryBoard] wmf_instantiateViewControllerWithIdentifierFromClass:[WMFArticleViewController class]];
}

- (IBAction)readButtonTapped:(id)sender {
    WebViewController* webVC   = [WebViewController wmf_initialViewControllerFromClassStoryboard];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:webVC];
    [self presentViewController:nc animated:YES completion:^{
        [webVC navigateToPage:self.article.title discoveryMethod:MWKHistoryDiscoveryMethodUnknown];
    }];
}

- (void)setContentTopInset:(CGFloat)contentTopInset {
    if (contentTopInset == _contentTopInset) {
        return;
    }

    _contentTopInset = contentTopInset;

    [self updateContentForTopInset];
}

- (void)updateContentForTopInset {
    if (![self isViewLoaded]) {
        return;
    }

    [self.cardBackgroundView mas_updateConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.view.mas_top).with.offset(self.contentTopInset);
    }];
}

#pragma mark - Accessors

- (void)setArticle:(MWKArticle*)article {
    if ([_article isEqual:article]) {
        return;
    }

    _article = article;

    if ([self isViewLoaded]) {
        [self updateUIAnimated:YES];
    }
}

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.saveButton wmf_setButtonType:WMFButtonTypeHeart];
    self.view.backgroundColor = [UIColor clearColor];
    [self updateContentForTopInset];
    [self updateUIAnimated:NO];

    // Do any additional setup after loading the view.
}

#pragma mark UI Updates

- (void)updateUIAnimated:(BOOL)animated {
    self.titleLabel.text = self.article.title.text;
    [self updateSavedButtonState];
}

- (IBAction)toggleSave:(id)sender {
    [self.savedPages toggleSavedPageForTitle:self.article.title];

    [self.savedPages save].then(^{
        [self updateSavedButtonState];
    });
}

- (void)updateSavedButtonState {
    self.saveButton.selected = [self.savedPages isSaved:self.article.title];
}

@end
