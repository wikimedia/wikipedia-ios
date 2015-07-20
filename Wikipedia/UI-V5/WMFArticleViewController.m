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
#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"
#import "WMFArticleReadMoreCell.h"
#import "UIView+WMFDefaultNib.h"

typedef NS_ENUM (NSInteger, WMFArticleSectionType) {
    WMFArticleSectionTypeSummary,
    WMFArticleSectionTypeTOC,
    WMFArticleSectionTypeReadMore
};

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPages;
@property (nonatomic, assign, readwrite) WMFArticleControllerMode mode;

@property (nonatomic, strong) WMFArticleFetcher* articleFetcher;

@property (nonatomic, strong) WMFSearchFetcher* readMoreFetcher;
@property (nonatomic, strong) WMFSearchResults* readMoreResults;

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

    [self unobserveArticleUpdates];
    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:[_article bestThumbnailImageURL]]];

    _article = article;

    DDLogVerbose(@"\n");
    DDLogVerbose(@"%@", article.title.text);
    DDLogVerbose(@"%@", article.entityDescription); //not saved? only seeing it in search results not saved panels
    DDLogVerbose(@"%@", article.thumbnailURL);
    DDLogVerbose(@"%lu", [article.sections count]);

    [self updateUI];
    [self observeAndFetchArticleIfNeeded];
}

- (void)setMode:(WMFArticleControllerMode)mode animated:(BOOL)animated {
    if (_mode == mode) {
        return;
    }

    _mode = mode;

    [self updateUIForMode:mode animated:animated];
    [self observeAndFetchArticleIfNeeded];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleUpdatedWithNotification:) name:MWKArticleSavedNotification object:nil];
}

- (void)unobserveArticleUpdates {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MWKArticleSavedNotification object:nil];
}

- (void)articleUpdatedWithNotification:(NSNotification*)note {
    MWKArticle* article = note.userInfo[MWKArticleKey];
    if ([self.article.title isEqualToTitle:article.title]) {
        self.article = article;
    }
}

#pragma mark - Article Fetching

- (void)observeAndFetchArticleIfNeeded {
    if (!self.article) {
        // nothing to fetch or observe
        return;
    }

    if (self.mode == WMFArticleControllerModeList) {
        // don't update or fetch while in list mode
        return;
    }

    if ([self.article isCached]) {
        // observe immediately
        [self observeArticleUpdates];
    } else {
        // fetch then observe
        [self fetchArticle];
    }
}

- (void)fetchArticle {
    [self fetchArticleForTitle:self.article.title];
}

- (void)fetchArticleForTitle:(MWKTitle*)title {
    [self.articleFetcher fetchArticleForPageTitle:title progress:nil].then(^(MWKArticle* article) {
        // re-entry, should result in being article being observed
        self.article = article;
    }).catch(^(NSError* error) {
        if ([error wmf_isWMFErrorOfType:WMFErrorTypeRedirected]) {
            [self fetchArticleForTitle:[[error userInfo] wmf_redirectTitle]];
        } else {
            NSLog(@"Article Fetch Error: %@", [error localizedDescription]);
        }
    });
}

- (void)fetchReadMoreForTitle:(MWKTitle*)title {
    // Note: can't set the readMoreFetcher when the article changes because the article changes *a lot* because the
    // card collection view controller sets it a lot as you scroll through the cards. "fetchReadMoreForTitle:" however
    // is only called when the card is expanded, so self.readMoreFetcher is set here as well so it's not needlessly
    // repeatedly set.
    self.readMoreFetcher                  = [[WMFSearchFetcher alloc] initWithSearchSite:self.article.title.site dataStore:self.dataStore];
    self.readMoreFetcher.maxSearchResults = 3;

    @weakify(self)
    [self.readMoreFetcher searchFullArticleTextForSearchTerm :[@"morelike:" stringByAppendingString:title.text] appendToPreviousResults : nil]
    .then(^(WMFSearchResults* results) {
        @strongify(self)
        self.readMoreResults = results;
        [self.tableView reloadData];
    })
    .catch(^(NSError* err) {
        DDLogError(@"Failed to fetch readmore: %@", err);
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
            [self observeAndFetchArticleIfNeeded];
            break;
        }
        default: {
            [self.tableView setContentOffset:CGPointZero animated:animated];
            self.tableView.scrollEnabled = NO;
            [self unobserveArticleUpdates];
            break;
        }
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

    // Note: do not call "fetchReadMoreForTitle:" in updateUI! Because we don't save the read more results to the data store, we need to fetch
    // them, but not every time the card controller causes the ui to be updated (ie on scroll as it recycles article views).
    if (self.mode != WMFArticleControllerModeList) {
        if (self.article.title) {
            [self fetchReadMoreForTitle:self.article.title];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case WMFArticleSectionTypeSummary:
            return 1;
            break;
        case WMFArticleSectionTypeTOC:
            return self.article.sections.count - 1;
            break;
        case WMFArticleSectionTypeReadMore:
            return self.readMoreResults.articleCount;
            break;
    }
    return 0;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    switch ((WMFArticleSectionType)indexPath.section) {
        case WMFArticleSectionTypeSummary: return [self textExtractCellAtIndexPath:indexPath];
        case WMFArticleSectionTypeTOC: return [self tocSectionCellAtIndexPath:indexPath];
        case WMFArticleSectionTypeReadMore: return [self readMoreCellAtIndexPath:indexPath];
    }
}

- (WMFArticleExtractCell*)textExtractCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleExtractCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleExtractCell wmf_nibName]];
    [cell setExtractText:[self.article shareSnippet]];
    return cell;
}

- (WMFArticleSectionCell*)tocSectionCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleSectionCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleSectionCell wmf_nibName]];
    cell.level           = self.article.sections[indexPath.row + 1].level;
    cell.titleLabel.text = [self.article.sections[indexPath.row + 1].line wmf_stringByRemovingHTML];
    return cell;
}

- (WMFArticleReadMoreCell*)readMoreCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleReadMoreCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleReadMoreCell wmf_nibName]];
    MWKArticle* readMoreArticle  = self.readMoreResults.articles[indexPath.row];
    cell.titleLabel.text       = readMoreArticle.title.text;
    cell.descriptionLabel.text = readMoreArticle.entityDescription;

    // Not sure why long titles won't wrap without this... the TOC cells seem to...
    [cell setNeedsDisplay];
    [cell layoutIfNeeded];

    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:readMoreArticle.thumbnailURL]].then(^(UIImage* image){
        cell.thumbnailImageView.image = image;
    }).catch(^(NSError* error){
        NSLog(@"Image Fetch Error: %@", [error localizedDescription]);
    });
    return cell;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    static NSString* cellID           = @"WMFArticleSectionHeaderCell";
    WMFArticleSectionHeaderCell* cell = (WMFArticleSectionHeaderCell*)[tableView dequeueReusableCellWithIdentifier:cellID];
    [self configureHeaderCell:cell inSection:section];
    return cell;
}

- (void)configureHeaderCell:(WMFArticleSectionHeaderCell*)cell inSection:(NSInteger)section {
//TODO(5.0): localize these!
    switch (section) {
        case WMFArticleSectionTypeSummary:
            cell.sectionHeaderLabel.text = @"Summary";
            break;
        case WMFArticleSectionTypeTOC:
            cell.sectionHeaderLabel.text = @"Table of contents";
            break;
        case WMFArticleSectionTypeReadMore:
            cell.sectionHeaderLabel.text = @"Read more";
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [self presentArticleScrolledToSectionForIndexPath:indexPath];
}

- (void)presentArticleScrolledToSectionForIndexPath:(NSIndexPath*)indexPath {
    WebViewController* webVC = [WebViewController wmf_initialViewControllerFromClassStoryboard];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webVC] animated:YES completion:^{
        [webVC navigateToPage:[self titleForSelectedIndexPath:indexPath] discoveryMethod:MWKHistoryDiscoveryMethodUnknown];
    }];
}

- (MWKTitle*)titleForSelectedIndexPath:(NSIndexPath*)indexPath {
    switch ((WMFArticleSectionType)indexPath.section) {
        case WMFArticleSectionTypeSummary:
            return [[MWKTitle alloc] initWithSite:self.article.title.site normalizedTitle:self.article.title.text fragment:@""];
        case WMFArticleSectionTypeTOC:
            return [[MWKTitle alloc] initWithSite:self.article.title.site normalizedTitle:self.article.title.text fragment:self.article.sections[indexPath.row + 1].anchor];
        case WMFArticleSectionTypeReadMore: {
            MWKArticle* readMoreArticle = ((MWKArticle*)self.readMoreResults.articles[indexPath.row]);
            return [[MWKTitle alloc] initWithSite:readMoreArticle.site normalizedTitle:readMoreArticle.title.text fragment:@""];
        }
    }
}

@end

NS_ASSUME_NONNULL_END
