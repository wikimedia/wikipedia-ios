
#import "WMFFeaturedArticleSectionController.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFEnglishFeaturedTitleFetcher.h"

#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKSearchResult.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "WMFArticlePlaceholderTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFFeaturedArticleSectionIdentifier = @"WMFFeaturedArticleSectionIdentifier";

@interface WMFFeaturedArticleSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@property (nonatomic, strong) WMFEnglishFeaturedTitleFetcher* featuredTitlePreviewFetcher;

@property (nonatomic, strong) MWKSearchResult* featuredArticlePreview;

@end

@implementation WMFFeaturedArticleSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    self = [super init];
    if (self) {
        self.site          = site;
        self.savedPageList = savedPageList;
        [self fetchData];
    }
    return self;
}

#pragma mark - Accessors

- (WMFEnglishFeaturedTitleFetcher*)featuredTitlePreviewFetcher {
    if (_featuredTitlePreviewFetcher == nil) {
        _featuredTitlePreviewFetcher = [[WMFEnglishFeaturedTitleFetcher alloc] init];
    }
    return _featuredTitlePreviewFetcher;
}

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return dateFormatter;
}

#pragma mark - HomeSectionController

- (id)sectionIdentifier {
    return WMFFeaturedArticleSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (NSAttributedString*)headerText {
    NSString* featuredDate = [[[self class] dateFormatter] stringFromDate:[NSDate date]];
    return [[NSAttributedString alloc] initWithString:featuredDate attributes:nil];
}

- (NSArray*)items {
    if (self.featuredArticlePreview) {
        return @[self.featuredArticlePreview];
    } else {
        return @[@1];
    }
}

- (nullable MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [[MWKTitle alloc] initWithSite:self.site normalizedTitle:self.featuredArticlePreview.displayTitle fragment:nil];
}

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    [tableView registerNib:[WMFArticlePlaceholderTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePlaceholderTableViewCell identifier]];
}

- (UITableViewCell*)dequeueCellForTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if (self.featuredArticlePreview) {
        return [WMFArticlePreviewTableViewCell cellForTableView:tableView];
    } else {
        return [WMFArticlePlaceholderTableViewCell cellForTableView:tableView];
    }
}

- (void)configureCell:(UITableViewCell*)cell withObject:(id)object inTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewTableViewCell class]]) {
        WMFArticlePreviewTableViewCell* previewCell = (WMFArticlePreviewTableViewCell*)cell;
        previewCell.titleText       = self.featuredArticlePreview.displayTitle;
        previewCell.descriptionText = self.featuredArticlePreview.wikidataDescription;
        previewCell.snippetText     = self.featuredArticlePreview.extract;
        [previewCell setImageURL:self.featuredArticlePreview.thumbnailURL];
        [previewCell setSaveableTitle:[self titleForItemAtIndex:indexPath.row] savedPageList:self.savedPageList];
    }
}

- (BOOL)shouldSelectItemAtIndex:(NSUInteger)index {
    return self.featuredArticlePreview != nil;
}

#pragma mark - Fetching

- (void)fetchData {
    if (self.featuredTitlePreviewFetcher.isFetching) {
        DDLogInfo(@"Fetch is already pending, skipping redundant call.");
        return;
    }

    @weakify(self);
    [self.featuredTitlePreviewFetcher fetchFeaturedArticlePreviewForDate:[NSDate date]].then(^(MWKSearchResult* data) {
        @strongify(self);
        self.featuredArticlePreview = data;
        [self.delegate controller:self didSetItems:self.items];
    }).catch(^(NSError* error){
        @strongify(self);
        [self.delegate controller:self didFailToUpdateWithError:error];
    });
}

@end

NS_ASSUME_NONNULL_END
