#import "WMFRelatedTitleViewController.h"
#import "WMFArticlePreviewDataStore.h"

#import "WMFArticlePreview.h"

#import "WMFArticlePreviewTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFSaveButtonController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedTitleViewController ()

@property (nonatomic, strong, readwrite) WMFArticlePreviewDataStore *previewStore;
@property (nonatomic, strong, readwrite) WMFExploreSection* section;
@property (nonatomic, strong, readwrite) NSArray<NSURL*>* articleURLs;

@end

@implementation WMFRelatedTitleViewController

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

#pragma mark - Accessors

- (MWKSavedPageList *)savedPageList {
    return self.userDataStore.savedPageList;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.section.articleURL.wmf_title];

    [self.tableView registerNib:[WMFArticlePreviewTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticlePreviewTableViewCell identifier]];
    self.tableView.estimatedRowHeight = [WMFArticlePreviewTableViewCell estimatedRowHeight];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.articleURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WMFArticlePreviewTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[WMFArticlePreviewTableViewCell identifier] forIndexPath:indexPath];
    
    NSURL* url = self.articleURLs[indexPath.row];
    WMFArticlePreview* preview = [self.previewStore itemForURL:url];
    cell.titleText = preview.displayTitle;
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    cell.snippetText = preview.snippet;
    [cell setImageURL:preview.thumbnailURL];
    cell.saveButtonController.analyticsContext = self;
    [cell setSaveableURL:url savedPageList:self.userDataStore.savedPageList];

    return cell;
}

- (NSString *)analyticsContext {
    return @"More Recommended";
}


@end

NS_ASSUME_NONNULL_END
