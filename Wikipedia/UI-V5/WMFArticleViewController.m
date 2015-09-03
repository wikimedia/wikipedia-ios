#import "WMFArticleViewController_Private.h"

#import "SessionSingleton.h"

// Frameworks
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Wikipedia-Swift.h"
#import "PromiseKit.h"

//Analytics
#import <PiwikTracker/PiwikTracker.h>
#import "MWKArticle+WMFAnalyticsLogging.h"

// Models & Controllers
#import "WMFArticleHeaderImageGalleryViewController.h"
#import "WMFArticleFetcher.h"
#import "WMFSearchFetcher.h"
#import "WMFSearchResults.h"
#import "MWKArticlePreview.h"
#import "MWKArticle.h"
#import "WMFImageGalleryViewController.h"
#import "MWKCitation.h"

// Views
#import "WMFArticleTableHeaderView.h"
#import "WMFArticleSectionCell.h"
#import "WMFArticleSectionHeaderView.h"
#import "WMFMinimalArticleContentCell.h"
#import "WMFArticleReadMoreCell.h"
#import "WMFArticleNavigationDelegate.h"

// Categories
#import "NSString+Extras.h"
#import "UIButton+WMFButton.h"
#import "UIStoryboard+WMFExtensions.h"
#import "UIViewController+WMFStoryboardUtilities.h"
#import "MWKArticle+WMFSharing.h"
#import "UIView+WMFDefaultNib.h"
#import "NSAttributedString+WMFHTMLForSite.h"
#import "NSURL+WMFLinkParsing.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleViewController ()
<UITableViewDataSource,
 UITableViewDelegate,
 WMFArticleHeaderImageGalleryViewControllerDelegate,
 WMFImageGalleryViewControllerDelegate,
 UITextViewDelegate>

#pragma mark Data Properties

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;
@property (nonatomic, assign, readwrite) WMFArticleControllerMode mode;
@property (nonatomic, strong) NSArray* topLevelSections;
@property (nonatomic, strong, readonly) NSIndexSet* indexSetOfTOCSections;

#pragma mark Fetcher Properties

@property (nonatomic, strong) WMFArticlePreviewFetcher* articlePreviewFetcher;
@property (nonatomic, strong) WMFArticleFetcher* articleFetcher;
@property (nonatomic, strong, nullable) AnyPromise* articleFetcherPromise;

@property (nonatomic, strong) WMFSearchFetcher* readMoreFetcher;
@property (nonatomic, strong) WMFSearchResults* readMoreResults;

#pragma mark Header Properties

@property (nonatomic, weak) IBOutlet WMFArticleTableHeaderView* headerView;
@property (nonatomic, weak) IBOutlet UIView* galleryContainerView;
@property (nonatomic, strong) WMFArticleHeaderImageGalleryViewController* headerGalleryViewController;
@property (nonatomic, weak) IBOutlet UITapGestureRecognizer* expandGalleryTapRecognizer;

@end

@implementation WMFArticleViewController
@synthesize article               = _article;
@synthesize mode                  = _mode;
@synthesize indexSetOfTOCSections = _indexSetOfTOCSections;

+ (instancetype)articleViewControllerWithDataStore:(MWKDataStore*)dataStore {
    WMFArticleViewController* vc = [self wmf_initialViewControllerFromClassStoryboard];
    vc.dataStore = dataStore;
    return vc;
}

#pragma mark - Accessors

- (void)setTopLevelSections:(NSArray* __nonnull)topLevelSections {
    _topLevelSections      = [topLevelSections copy];
    _indexSetOfTOCSections = nil;
}

- (NSIndexSet*)indexSetOfTOCSections {
    if (!_indexSetOfTOCSections) {
        _indexSetOfTOCSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, self.topLevelSections.count)];
    }
    return _indexSetOfTOCSections;
}

- (void)setHeaderGalleryViewController:(WMFArticleHeaderImageGalleryViewController* __nonnull)galleryViewController {
    _headerGalleryViewController = galleryViewController;
    [_headerGalleryViewController setImagesFromArticle:self.article];
}

- (void)setArticle:(MWKArticle* __nullable)article {
    if (WMF_EQUAL(_article, isEqualToArticle:, article)) {
        return;
    }

    [self unobserveArticleUpdates];
    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:[_article bestThumbnailImageURL]]];

    // TODO cancel
    [self.articlePreviewFetcher cancelFetchForPageTitle:_article.title];
    [self.articleFetcher cancelFetchForPageTitle:_article.title];

    _article = article;

    [self.headerGalleryViewController setImagesFromArticle:article];
    self.topLevelSections = [_article.sections.topLevelSections wmf_tail];

    [self updateUI];

    // Note: do not call "fetchReadMoreForTitle:" in updateUI! Because we don't save the read more results to the data store, we need to fetch
    // them, but not every time the card controller causes the ui to be updated (ie on scroll as it recycles article views).
    if (self.mode != WMFArticleControllerModeList) {
        if (self.article.title) {
            [self fetchReadMoreForTitle:self.article.title];
        }
    }

    if ([self isViewLoaded]) {
        [self.tableView reloadData];
    }

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

- (WMFArticlePreviewFetcher*)articlePreviewFetcher {
    if (!_articlePreviewFetcher) {
        _articlePreviewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _articlePreviewFetcher;
}

- (WMFArticleFetcher*)articleFetcher {
    if (!_articleFetcher) {
        _articleFetcher = [[WMFArticleFetcher alloc] initWithDataStore:self.dataStore];
    }
    return _articleFetcher;
}

#pragma mark - Section Hierarchy Accessors

- (BOOL)isLeadSection:(NSUInteger)section {
    // TODO: check summary length > 0?
    return section == 0;
}

- (BOOL)isTOCSection:(NSUInteger)section {
    return [self.indexSetOfTOCSections containsIndex:section];
}

- (BOOL)isReadMoreSection:(NSUInteger)section {
    return ![self isLeadSection:section] && ![self isTOCSection:section];
}

- (BOOL)isIndexPathForParentSection:(NSIndexPath*)indexPath {
    return [self isTOCSection:indexPath.section] && indexPath.item == 0;
}

- (BOOL)isIndexPathForChildSection:(NSIndexPath*)indexPath {
    return [self isTOCSection:indexPath.section] && indexPath.item != 0;
}

- (MWKSection*)sectionForIndexPath:(NSIndexPath*)indexPath {
    NSParameterAssert([self isTOCSection:indexPath.section]);
    return [self isIndexPathForParentSection:indexPath] ?
           [self parentSectionForTableSection : indexPath.section]
           :[self childSectionForIndexPath:indexPath];
}

- (MWKSection*)parentSectionForTableSection:(NSUInteger)section {
    NSParameterAssert([self isTOCSection:section]);
    NSParameterAssert(self.indexSetOfTOCSections.count > 0);
    return self.topLevelSections[section - self.indexSetOfTOCSections.firstIndex];
}

- (MWKSection*)childSectionForIndexPath:(NSIndexPath*)indexPath {
    NSParameterAssert([self isTOCSection:indexPath.section]);
    MWKSection* parentSection = [self parentSectionForTableSection:indexPath.section];
    NSParameterAssert(parentSection);
    // first item is always the parent section
    return parentSection.children[indexPath.item - 1];
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

#pragma mark - Analytics

- (NSString*)analyticsName {
    NSParameterAssert(self.article);
    if (self.article == nil) {
        return @"";
    }
    return [self.article analyticsName];
}

- (void)logPreview {
    if (self.mode == WMFArticleControllerModePopup && self.article.title.text) {
        [[PiwikTracker sharedInstance] sendViewsFromArray:@[@"Article-Preview", [self analyticsName]]];
    }
}

- (void)logPageView {
    if (self.mode == WMFArticleControllerModeNormal && self.article.title.text) {
        [[PiwikTracker sharedInstance] sendViewsFromArray:@[@"Article", [self analyticsName]]];
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
    @weakify(self);
    [self.articlePreviewFetcher fetchArticlePreviewForPageTitle:title progress:NULL].then(^(MWKArticlePreview* articlePreview){
        @strongify(self);
        AnyPromise* fullArticlePromise = [self.articleFetcher fetchArticleForPageTitle:title progress:NULL];
        self.articleFetcherPromise = fullArticlePromise;
        return fullArticlePromise;
    }).then(^(MWKArticle* article){
        @strongify(self);
        self.article = article;
    }).catch(^(NSError* error){
        @strongify(self);
        if ([error wmf_isWMFErrorOfType:WMFErrorTypeRedirected]) {
            [self fetchArticleForTitle:[[error userInfo] wmf_redirectTitle]];
        } else if (!self.presentingViewController) {
            // only do error handling if not presenting gallery
            DDLogError(@"Article Fetch Error: %@", [error localizedDescription]);
        }
    }).finally(^{
        @strongify(self);
        self.articleFetcherPromise = nil;
    });
}

- (void)fetchReadMoreForTitle:(MWKTitle*)title {
    // Note: can't set the readMoreFetcher when the article changes because the article changes *a lot* because the
    // card collection view controller sets it a lot as you scroll through the cards. "fetchReadMoreForTitle:" however
    // is only called when the card is expanded, so self.readMoreFetcher is set here as well so it's not needlessly
    // repeatedly set.
    self.readMoreFetcher =
        [[WMFSearchFetcher alloc] initWithSearchSite:self.article.title.site dataStore:self.dataStore];
    self.readMoreFetcher.maxSearchResults = 3;

    @weakify(self)
    [self.readMoreFetcher searchFullArticleTextForSearchTerm :[@"morelike:" stringByAppendingString:title.text] appendToPreviousResults : nil]
    .then(^(WMFSearchResults* results) {
        @strongify(self)
        self.readMoreResults = results;

        if (self.isViewLoaded) {
            [self.tableView reloadData];
        }
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
}

- (void)updateHeaderView {
    WMFArticleTableHeaderView* headerView = [self headerView];

    [headerView setTitle:[self.article.title.text wmf_stringByRemovingHTML]
             description:[self.article.entityDescription wmf_stringByCapitalizingFirstCharacter]];
}

- (void)clearHeaderView {
    WMFArticleTableHeaderView* headerView = [self headerView];
    [headerView setTitle:nil description:nil];
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
    self.headerGalleryViewController.view.userInteractionEnabled = mode == WMFArticleControllerModeNormal;
}

#pragma mark - Configuration

- (void)configureForDynamicCellHeight {
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    // estimatedRowHeight returned in delegate method
    self.tableView.sectionHeaderHeight          = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 80;
}

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.destinationViewController isKindOfClass:[WMFArticleHeaderImageGalleryViewController class]]) {
        self.headerGalleryViewController          = segue.destinationViewController;
        self.headerGalleryViewController.delegate = self;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.scrollsToTop               = YES;

    UICollectionViewFlowLayout* galleryLayout = (UICollectionViewFlowLayout*)_headerGalleryViewController.collectionViewLayout;
    galleryLayout.minimumInteritemSpacing = 0;
    galleryLayout.minimumLineSpacing      = 0;
    galleryLayout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;

    [self clearHeaderView];
    [self configureForDynamicCellHeight];
    [self updateUI];
    [self.tableView reloadData];
    [self updateUIForMode:self.mode animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self logPreview];
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self logPageView];
}

#pragma mark - UITableViewDataSource

- (BOOL)hasArticlePreviewBeenRetrieved {
// TODO: update this to actually check if MWKArticlePreview has returned!
// Presently it's checking if the article is cached because at this time
// we're not actually using the article preview data we're fetching, so
// it's difficult to check it.
    return self.article.isCached;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Hide all sections until article preview data is retrieved.
    if (![self hasArticlePreviewBeenRetrieved]) {
        return 0;
    }

    // TODO: check summary length?
    return 2 + self.topLevelSections.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLeadSection:section]) {
        return 1;
    } else if ([self isTOCSection:section]) {
        // parent + children
        return [[[self parentSectionForTableSection:section] children] count] + 1;
    } else {
        return self.readMoreResults.articleCount;
    }
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([self isLeadSection:indexPath.section]) {
        return [self contentCellAtIndexPath:indexPath];
    } else if ([self isTOCSection:indexPath.section]) {
        return [self tocSectionCellAtIndexPath:indexPath];
    } else {
        return [self readMoreCellAtIndexPath:indexPath];
    }
}

- (WMFMinimalArticleContentCell*)contentCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFMinimalArticleContentCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFMinimalArticleContentCell wmf_nibName]];
    [cell setAttributedText:[self.article summaryHTML]];
    return cell;
}

- (UITableViewCell*)tocSectionCellAtIndexPath:(NSIndexPath*)indexPath {
    if ([self isIndexPathForParentSection:indexPath]) {
        return [self parentSectionCellForSection:indexPath.section];
    } else {
        return [self childSectionCellForIndexPath:indexPath];
    }
}

- (UITableViewCell*)parentSectionCellForSection:(NSUInteger)section {
    WMFArticleSectionCell* parentCell = [self.tableView dequeueReusableCellWithIdentifier:@"ParentSectionCell"];
    parentCell.titleLabel.text = [[[self parentSectionForTableSection:section] line] wmf_stringByRemovingHTML];
    return parentCell;
}

- (UITableViewCell*)childSectionCellForIndexPath:(NSIndexPath*)indexPath {
    WMFArticleSectionCell* childCell = [self.tableView dequeueReusableCellWithIdentifier:@"ChildSectionCell"];
    childCell.titleLabel.text = [[[self childSectionForIndexPath:indexPath] line] wmf_stringByRemovingHTML];
    return childCell;
}

- (WMFArticleReadMoreCell*)readMoreCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleReadMoreCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleReadMoreCell wmf_nibName]];
    MWKArticle* readMoreArticle  = self.readMoreResults.articles[indexPath.row];
    cell.titleLabel.text       = readMoreArticle.title.text;
    cell.descriptionLabel.text = readMoreArticle.entityDescription;

    // Not sure why long titles won't wrap without this... the TOC cells seem to...
    [cell setNeedsDisplay];
    [cell layoutIfNeeded];

    NSURL* url = [NSURL wmf_optionalURLWithString:readMoreArticle.thumbnailURL];
    [[WMFImageController sharedInstance] fetchImageWithURL:url].then(^(WMFImageDownload* download){
        cell.thumbnailImageView.image = download.image;
    }).catch(^(NSError* error){
        NSLog(@"Image Fetch Error: %@", [error localizedDescription]);
    });

    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self isLeadSection:section]
        || ([self isTOCSection:section] && section != self.indexSetOfTOCSections.firstIndex)
        || ![self tableView:tableView viewForHeaderInSection:section]
        ) {
        // omit headers for lead section & all but the first TOC section
        return 0;
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    //TODO(5.0): localize these!
    if (section == 0
        || (section != 1 && section < tableView.numberOfSections - 1)
        || ([self tableView:tableView numberOfRowsInSection:section] == 0)
        ) {
        return nil;
    } else {
        WMFArticleSectionHeaderView* header =
            [tableView dequeueReusableCellWithIdentifier:[WMFArticleSectionHeaderView wmf_nibName]];
        if (section == tableView.numberOfSections - 1) {
            header.sectionHeaderLabel.text = @"Read more";
        } else {
            header.sectionHeaderLabel.text = @"Table of contents";
        }
        return header;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView*)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([self isLeadSection:indexPath.section]) {
        return UITableViewAutomaticDimension;
    } else if ([self isIndexPathForParentSection:indexPath]) {
        return 48.f;
    } else if ([self isIndexPathForChildSection:indexPath]) {
        return 37.f;
    } else {
        return 80.f;
    }
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:indexPath.section != 0];
    if (indexPath.section == 0) {
        return;
    } else if ([self isTOCSection:indexPath.section]) {
        [self.delegate articleViewController:self
                   didTapSectionWithFragment:[[self sectionForIndexPath:indexPath] anchor]];
    } else {
        MWKTitle* readMoreTitle = [(MWKArticle*)self.readMoreResults.articles[indexPath.item] title];
        [self.delegate articleNavigator:nil didTapLinkToPage:readMoreTitle];
    }
}

#pragma mark - WMFArticleHeadermageGalleryViewControllerDelegate

- (void)headerImageGallery:(WMFArticleHeaderImageGalleryViewController* __nonnull)gallery
     didSelectImageAtIndex:(NSUInteger)index {
    NSParameterAssert(![self.presentingViewController isKindOfClass:[WMFImageGalleryViewController class]]);
    WMFImageGalleryViewController* detailGallery = [[WMFImageGalleryViewController alloc] initWithArticle:nil];
    detailGallery.delegate = self;
    if (self.article.isCached) {
        detailGallery.article     = self.article;
        detailGallery.currentPage = index;
    } else {
        if (![self.articleFetcher isFetchingArticleForTitle:self.article.title]) {
            [self fetchArticle];
        }
        [detailGallery setArticleWithPromise:self.articleFetcherPromise];
    }
    [self presentViewController:detailGallery animated:YES completion:nil];
}

#pragma mark - WMFImageGalleryViewControllerDelegate

- (void)willDismissGalleryController:(WMFImageGalleryViewController* __nonnull)gallery {
    self.headerGalleryViewController.currentPage = gallery.currentPage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WMFArticleNavigation

- (void)scrollToFragment:(NSString* __nonnull)fragment animated:(BOOL)animated {
}

- (void)scrollToLink:(NSURL* __nonnull)linkURL animated:(BOOL)animated {
}

- (BOOL)textView:(UITextView*)textView shouldInteractWithURL:(NSURL*)URL inRange:(NSRange)characterRange {
    [URL wmf_informNavigationDelegate:self.delegate withSender:nil];
    return NO;
}

@end

NS_ASSUME_NONNULL_END
