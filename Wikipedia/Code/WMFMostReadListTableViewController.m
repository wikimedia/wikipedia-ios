#import "WMFMostReadListTableViewController.h"

#import "WMFArticlePreviewDataStore.h"

#import "WMFArticlePreview.h"

#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFMostReadListTableViewController ()

@property (nonatomic, strong, readwrite) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong, readwrite) WMFExploreSection* section;
@property (nonatomic, strong, readwrite) NSArray<NSURL*>* articleURLs;

@end

@implementation WMFMostReadListTableViewController

- (instancetype)initWithSection:(WMFExploreSection*)section articleURLs:(NSArray<NSURL*>*)urls userDataStore:(MWKDataStore*)userDataStore previewStore:(WMFArticlePreviewDataStore*)previewStore
{
    NSParameterAssert(urls);
    NSParameterAssert(section);
    NSParameterAssert(userDataStore);
    NSParameterAssert(previewStore);
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.userDataStore = userDataStore;
        self.previewStore = previewStore;
        self.section = section;
        self.articleURLs = urls;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self titleForDate:self.section.dateCreated];
    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib]
    forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.articleURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticleListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticleListTableViewCell identifier] forIndexPath:indexPath];
    
    NSURL* url = self.articleURLs[indexPath.row];
    WMFArticlePreview* preview = [self.previewStore itemForURL:url];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:preview.thumbnailURL];
    return cell;
}


#pragma mark - Utilities

- (NSString *)titleForDate:(NSDate *)date {
    return
    [MWLocalizedString(@"explore-most-read-more-list-title-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                     withString:
     [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date]];
}


#pragma mark - WMFAnalyticsContext

- (NSString *)analyticsContext {
    return @"More Most Read";
}

@end

NS_ASSUME_NONNULL_END
