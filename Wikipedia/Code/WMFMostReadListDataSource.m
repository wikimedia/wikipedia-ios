#import "WMFMostReadListDataSource.h"
#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKSearchResult.h"

@interface WMFMostReadListDataSource ()

@property (nonatomic, strong) NSURL *siteURL;
@property (nonatomic, strong, readwrite) NSArray<NSURL *> *urls;

@end

@implementation WMFMostReadListDataSource

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult *> *)previews fromSiteURL:(NSURL *)siteURL {
    self = [super initWithItems:previews];
    if (self) {
        self.siteURL = siteURL;

        self.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticleListTableViewCell *cell,
                                    MWKSearchResult *preview,
                                    UITableView *tableView,
                                    NSIndexPath *indexPath) {
            @strongify(self);
            NSURL *articleURL = [self urlForIndexPath:indexPath];
            NSParameterAssert([articleURL.wmf_siteURL isEqual:self.siteURL]);

            cell.titleText = articleURL.wmf_title;
            cell.descriptionText = preview.wikidataDescription;
            [cell setImageURL:preview.thumbnailURL];
        };
    }
    return self;
}

- (void)setTableView:(UITableView *)tableView {
    [tableView registerNib:[WMFArticleListTableViewCell wmf_classNib]
        forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
    tableView.estimatedRowHeight = [WMFArticleListTableViewCell estimatedRowHeight];
    [super setTableView:tableView];
}

#pragma mark - Utils

- (NSURL *)articleURLForPreview:(MWKSearchResult *)preview {
    return [self.siteURL wmf_URLWithTitle:preview.displayTitle];
}

#pragma mark - WMFTitleListDataSource

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath {
    return [self articleURLForPreview:[self itemAtIndexPath:indexPath]];
}

- (NSUInteger)titleCount {
    return self.allItems.count;
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSArray<NSURL *> *)urls {
    if (!_urls) {
        self.urls = [self.allItems bk_map:^NSURL *(MWKSearchResult *preview) {
            return [self articleURLForPreview:preview];
        }];
    }
    return _urls;
}

@end
