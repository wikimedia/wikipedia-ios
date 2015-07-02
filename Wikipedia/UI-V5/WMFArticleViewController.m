#import "WMFArticleViewController.h"
#import <Masonry/Masonry.h>
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "UIButton+WMFButton.h"
#import "WebViewController.h"
#import "UIStoryboard+WMFExtensions.h"
#import "UIViewController+WMFStoryboardUtilities.h"

#import "WMFArticleTableHeaderView.h"
#import "WMFArticleSectionCell.h"
#import "PaddedLabel.h"
#import "WMFArticleSectionHeaderCell.h"
#import "WMFArticleExtractCell.h"
#import "NSString+Extras.h"

#import "MWKArticle+WMFSharing.h"
#import "WMFArticleFetcher.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, assign, readwrite) WMFArticleControllerMode mode;

@property (nonatomic, strong) WMFArticleFetcher* articleFetcher;

@end

@implementation WMFArticleViewController

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore savedPages:(MWKSavedPageList*)savedPages {
    WMFArticleViewController* vc = (id)[[UIStoryboard wmf_storyBoardForViewControllerClass:[WMFArticleViewController class]] instantiateInitialViewController];
    vc.dataStore  = dataStore;
    vc.savedPages = savedPages;
    return vc;
}

#pragma - Tear Down

- (void)dealloc {
    [self unobserveArticleUpdates];
}

#pragma mark - Accessors

- (void)setArticle:(MWKArticle* __nullable)article {
    if ([_article isEqual:article]) {
        return;
    }

    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:[_article bestThumbnailImageURL]]];

    _article = article;

    NSLog(@"\n");
    NSLog(@"%@", article.title.text);
    NSLog(@"%@", article.entityDescription); //not saved? only seeing it in search results not saved panels
    NSLog(@"%@", article.thumbnailURL);
    NSLog(@"%lu", [article.sections count]);

    [self updateUI];
    [self fetchArticleIfNeeded];
}

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated {
    if (_mode == mode) {
        return;
    }

    _mode = mode;

    [self updateUIForMode:mode animated:animated];
    [self fetchArticleIfNeeded];
}

- (BOOL)isSaved {
    return [self.savedPages isSaved:self.article.title];
}

- (WMFArticleTableHeaderView*)headerView {
    return (WMFArticleTableHeaderView*)self.tableView.tableHeaderView;
}

- (UIButton*)saveButton {
    return [[self headerView] saveButton];
}

- (UIButton*)readButton {
    return [[self headerView] readButton];
}

- (WMFArticleFetcher*)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return _articleFetcher;
}

#pragma mark - Article Notifications

- (void)observeArticleUpdates {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:WMFArticleFetchedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WMFArticleFetchedNotification object:nil];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[WMFArticleFetchedKey];
    if ([self.article.title isEqualToTitle:article.title]) {
        dispatchOnMainQueue(^{
            self.article = article;
        });
    }
}

#pragma mark - Article Fetching

- (void)fetchArticleIfNeeded {
    if (!self.article) {
        return;
    }

    if (self.mode == WMFArticleControllerModeList) {
        return;
    }

    if ([self.article bestThumbnailImageURL] && [self.article isCached]) {
        return;
    }

    [self fetchArticle];
}

- (void)fetchArticle {
    [self fetchArticleForTitle:self.article.title];
}

- (void)fetchArticleForTitle:(MWKTitle*)title {
    [self unobserveArticleUpdates];
    [self.articleFetcher fetchArticleForPageTitle:title progress:^(CGFloat progress){
    }].then(^(MWKArticle* article){
        self.article = article;
    }).catch(^(NSError* error){
        if ([error wmf_isWMFErrorOfType:WMFErrorTypeRedirected]) {
            [self fetchArticleForTitle:[[error userInfo] wmf_redirectTitle]];
        } else {
            NSLog(@"Article Fetch Error: %@", [error localizedDescription]);
        }
    }).then(^(){
        [self observeArticleUpdates];
    });
}

#pragma mark - View Updates

- (void)updateUI {
    if (![self isViewLoaded]) {
        return;
    }

    if (self.article) {
        [self updateHeaderView];
    } else {
        [self clearHeaderView];
    }

    [self updateSavedButtonState];
    [self.tableView reloadData];
}

- (void)updateHeaderView {
    WMFArticleTableHeaderView* headerView = [self headerView];

//TODO: progressively reduce title/description font to some floor size based on length of string
//      see old LeadImageTitleAttributedString.m for example from old native lead image
    headerView.titleLabel.text       = [self.article.title.text wmf_stringByRemovingHTML];
    headerView.descriptionLabel.text = [self.article.entityDescription wmf_stringByCapitalizingFirstCharacter];

    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:[self.article bestThumbnailImageURL]]].then(^(UIImage* image){
        headerView.image.image = image;
    }).catch(^(NSError* error){
        NSLog(@"Image Fetch Error: %@", [error localizedDescription]);
    });
}

- (void)clearHeaderView {
    WMFArticleTableHeaderView* headerView = [self headerView];
    headerView.titleLabel.attributedText = nil;
    headerView.image.image               = [UIImage imageNamed:@"lead-default"];
}

- (void)updateSavedButtonState {
    [self headerView].saveButton.selected = [self isSaved];
}

- (void)updateUIForMode:(WMFArticleControllerMode)mode animated:(BOOL)animated {
    switch (mode) {
        case WMFArticleControllerModeNormal: {
            self.tableView.scrollEnabled = YES;
        }
        break;
        case WMFArticleControllerModeList: {
            [self.tableView setContentOffset:CGPointZero animated:animated];
            self.tableView.scrollEnabled = NO;
        }
        break;
        case WMFArticleControllerModePopup: {
            [self.tableView setContentOffset:CGPointZero animated:animated];
            self.tableView.scrollEnabled = NO;
        }
        break;
    }
}

#pragma mark - Actions

- (IBAction)readButtonTapped:(id)sender {
    WebViewController* webVC   = [WebViewController wmf_initialViewControllerFromClassStoryboard];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:webVC];
    [self presentViewController:nc animated:YES completion:^{
        [webVC navigateToPage:self.article.title discoveryMethod:MWKHistoryDiscoveryMethodUnknown];
    }];
}

- (IBAction)toggleSave:(id)sender {
    if (![self.article isCached]) {
        [self fetchArticle];
    }

    [self.savedPages toggleSavedPageForTitle:self.article.title];
    [self.savedPages save];
    [self updateSavedButtonState];
}

#pragma mark - Configuration

- (void)configureForDynamicCellHeight {
    self.tableView.rowHeight                    = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight           = 80;
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 80;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self clearHeaderView];
    [self configureForDynamicCellHeight];
    [self updateUI];
    [self updateUIForMode:self.mode animated:NO];
    [self observeArticleUpdates];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateUI];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        return self.article.sections.count - 1;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.section == 0) {
        static NSString* cellID     = @"WMFArticleExtractCell";
        WMFArticleExtractCell* cell = (WMFArticleExtractCell*)[tableView dequeueReusableCellWithIdentifier:cellID];

        [cell setExtractText:[self.article shareSnippet]];

        return cell;
    } else {
        static NSString* cellID     = @"WMFArticleSectionCell";
        WMFArticleSectionCell* cell = (WMFArticleSectionCell*)[tableView dequeueReusableCellWithIdentifier:cellID];

        cell.level           = self.article.sections[indexPath.row + 1].level;
        cell.titleLabel.text = [self.article.sections[indexPath.row + 1].line wmf_stringByRemovingHTML];

        return cell;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString* cellID           = @"WMFArticleSectionHeaderCell";
    WMFArticleSectionHeaderCell* cell = (WMFArticleSectionHeaderCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    [self configureHeaderCell:cell inSection:section];
    return cell;
}

- (void)configureHeaderCell:(WMFArticleSectionHeaderCell*)cell inSection:(NSInteger)section {
    switch (section) {
        case 0:
            cell.sectionHeaderLabel.text = @"Summary";
            break;
        case 1:
            cell.sectionHeaderLabel.text = @"Table of Contents";
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self presentArticleScrolledToSectionForIndexPath:indexPath];
}

- (void)presentArticleScrolledToSectionForIndexPath:(NSIndexPath*)indexPath {
    NSString* fragment = (indexPath.section == 0) ? @"" : self.article.sections[indexPath.row + 1].anchor;
    MWKTitle* title    = [[MWKTitle alloc] initWithSite:self.article.title.site normalizedTitle:self.article.title.text fragment:fragment];

    WebViewController* webVC   = [WebViewController wmf_initialViewControllerFromClassStoryboard];
    UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:webVC];
    [self presentViewController:nc animated:YES completion:^{
        [webVC navigateToPage:title discoveryMethod:MWKHistoryDiscoveryMethodUnknown];
    }];
}

@end

NS_ASSUME_NONNULL_END
