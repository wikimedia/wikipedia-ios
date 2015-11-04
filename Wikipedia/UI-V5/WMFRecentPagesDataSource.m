
#import "WMFRecentPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "WMFArticleListTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import "NSString+Extras.h"
#import "NSDate-Utilities.h"
#import "UIImageView+WMFImageFetching.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRecentPagesDataSource ()

@property (nonatomic, strong, readwrite) MWKHistoryList* recentPages;
@property (nonatomic, strong, readwrite) MWKSavedPageList* savedPageList;

@end

@implementation WMFRecentPagesDataSource

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull instancetype)initWithRecentPagesList:(MWKHistoryList*)recentPages savedPages:(MWKSavedPageList*)savedPages {
    NSParameterAssert(recentPages);
    NSParameterAssert(savedPages);
    self = [super initWithSections:[WMFRecentPagesDataSource sectionsFromHistoryList:recentPages]];
    if (self) {
        self.recentPages   = recentPages;
        self.savedPageList = savedPages;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildSections) name:MWKHistoryListDidUpdateNotification object:recentPages];

        self.cellClass = [WMFArticleListTableViewCell class];

        @weakify(self);
        self.cellConfigureBlock = ^(WMFArticleListTableViewCell* cell,
                                    MWKHistoryEntry* entry,
                                    UITableView* tableView,
                                    NSIndexPath* indexPath) {
            @strongify(self);
            MWKArticle* article = [[self dataStore] articleWithTitle:entry.title];
            cell.titleLabel.text       = article.displaytitle;
            cell.descriptionLabel.text = [article.entityDescription wmf_stringByCapitalizingFirstCharacter];
            [cell.articleImageView wmf_setImageWithMetadata:[article bestThumbnailImage] detectFaces:YES];
        };
    }
    return self;
}

+ (NSArray*)sectionsFromHistoryList:(MWKHistoryList*)list {
    NSArray* sortedEntriesToIterate    = [list entries];
    NSMutableDictionary* entriesBydate = [NSMutableDictionary dictionary];

    [sortedEntriesToIterate enumerateObjectsUsingBlock:^(MWKHistoryEntry* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        NSDate* date = [[obj date] dateAtStartOfDay];
        NSMutableArray* entries = entriesBydate[date];
        if (!entries) {
            entries = [NSMutableArray array];
            entriesBydate[date] = entries;
        }
        [entries addObject:obj];
    }];

    NSMutableArray* sections = [NSMutableArray arrayWithCapacity:[entriesBydate count]];
    [[[entriesBydate allKeys] sortedArrayUsingComparator:^NSComparisonResult (NSDate* _Nonnull obj1, NSDate* _Nonnull obj2) {
        return -[obj1 compare:obj2];
    }] enumerateObjectsUsingBlock:^(NSDate* _Nonnull date, NSUInteger idx, BOOL* _Nonnull stop) {
        NSMutableArray* entries = entriesBydate[date];
        SSSection* section = [SSSection sectionWithItems:entries];
        section.header = [date isToday] ? @"Today" : [self.dateFormatter stringFromDate:date];
        section.sectionIdentifier = date;
        [sections addObject:section];
    }];

    return sections;
}

+ (NSDateFormatter*)dateFormatter {
    static NSDateFormatter* _dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return _dateFormatter;
}

- (void)rebuildSections {
    [self removeAllSections];
    NSArray* sections = [[self class] sectionsFromHistoryList:self.recentPages];
    [self.tableView beginUpdates];
    [self insertSections:sections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sections.count)]];
    [self.tableView endUpdates];
}

- (void)setTableView:(nullable UITableView*)tableView {
    [super setTableView:tableView];
    [self.tableView registerNib:[WMFArticleListTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFArticleListTableViewCell identifier]];
}

- (NSArray*)titles {
    return [[self.recentPages entries] bk_map:^id (MWKHistoryEntry* obj) {
        return obj.title;
    }];
}

- (MWKDataStore*)dataStore {
    return self.recentPages.dataStore;
}

- (nullable NSString*)displayTitle {
    return @"Recent";
}

- (NSUInteger)titleCount {
    return [self.recentPages countOfEntries];
}

- (MWKHistoryEntry*)recentPageForIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* entry = [self.recentPages entryAtIndex:indexPath.row];
    return entry;
}

- (MWKTitle*)titleForIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* savedEntry = [self recentPageForIndexPath:indexPath];
    return savedEntry.title;
}

- (NSIndexPath*)indexPathForTitle:(MWKTitle*)title {
    NSUInteger index = [[self.recentPages entries] indexOfObjectPassingTest:^BOOL (MWKHistoryEntry* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        if ([obj.title isEqualToTitle:title]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (index == NSNotFound) {
        return nil;
    }
    return [NSIndexPath indexPathForItem:index inSection:0];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath*)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath*)indexPath {
    MWKHistoryEntry* entry = [self recentPageForIndexPath:indexPath];
    if (entry) {
        [self.recentPages removeEntryWithListIndex:entry.title];
        [self.recentPages save];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodUnknown;
}

@end

NS_ASSUME_NONNULL_END

