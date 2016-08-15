#import "WMFRecentPagesDataSource.h"
#import "MWKDataStore.h"
#import "MWKHistoryList.h"
#import "MWKHistoryEntry.h"
#import "MWKArticle.h"
#import "NSDate+Utilities.h"
#import "UIImageView+WMFImageFetching.h"
#import "NSDateFormatter+WMFExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFRecentPagesDataSource ()

@property(nonatomic, strong, readwrite) MWKHistoryList *recentPages;

@end

@implementation WMFRecentPagesDataSource

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nonnull instancetype)initWithRecentPagesList:(MWKHistoryList *)recentPages {
    NSParameterAssert(recentPages);
    self = [super initWithSections:[WMFRecentPagesDataSource sectionsFromHistoryList:recentPages]];
    if (self) {
        self.recentPages = recentPages;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildSections) name:MWKHistoryListDidUpdateNotification object:recentPages];

        self.tableDeletionBlock = ^(WMFRecentPagesDataSource *dataSource,
                                    UITableView *parentView,
                                    NSIndexPath *indexPath) {
          [[NSNotificationCenter defaultCenter] removeObserver:dataSource];
          [dataSource deleteArticleAtIndexPath:indexPath];
          [dataSource removeItemAtIndexPath:indexPath];
          [[NSNotificationCenter defaultCenter] addObserver:dataSource selector:@selector(rebuildSections) name:MWKHistoryListDidUpdateNotification object:recentPages];
        };

        [self.KVOController observe:self.recentPages
                            keyPath:WMF_SAFE_KEYPATH(self.recentPages, entries)
                            options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionPrior
                              block:^(WMFRecentPagesDataSource *observer, MWKHistoryList *object, NSDictionary *change) {
                                BOOL isPrior = [change[NSKeyValueChangeNotificationIsPriorKey] boolValue];
                                NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
                                NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];

                                if (isPrior) {
                                    if (changeKind == NSKeyValueChangeSetting) {
                                        [observer willChangeValueForKey:WMF_SAFE_KEYPATH(observer, urls)];
                                    } else {
                                        [observer willChange:changeKind valuesAtIndexes:indexes forKey:WMF_SAFE_KEYPATH(observer, urls)];
                                    }
                                } else {
                                    if (changeKind == NSKeyValueChangeSetting) {
                                        [observer didChangeValueForKey:WMF_SAFE_KEYPATH(observer, urls)];
                                    } else {
                                        [observer didChange:changeKind valuesAtIndexes:indexes forKey:WMF_SAFE_KEYPATH(observer, urls)];
                                    }
                                }
                              }];
    }
    return self;
}

+ (NSArray *)sectionsFromHistoryList:(MWKHistoryList *)list {
    NSArray *sortedEntriesToIterate = [list entries];
    NSMutableDictionary *entriesBydate = [NSMutableDictionary dictionary];

    [sortedEntriesToIterate enumerateObjectsUsingBlock:^(MWKHistoryEntry *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
      NSDate *date = [[obj date] dateAtStartOfDay];
      NSMutableArray *entries = entriesBydate[date];
      if (!entries) {
          entries = [NSMutableArray array];
          entriesBydate[date] = entries;
      }
      [entries addObject:obj];
    }];

    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:[entriesBydate count]];
    [[[entriesBydate allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSDate *_Nonnull obj1, NSDate *_Nonnull obj2) {
      return -[obj1 compare:obj2]; //by date decending
    }] enumerateObjectsUsingBlock:^(NSDate *_Nonnull date, NSUInteger idx, BOOL *_Nonnull stop) {
      NSMutableArray *entries = entriesBydate[date];
      SSSection *section = [SSSection sectionWithItems:entries];

      //HACK: Table views for some reason aren't adding padding to the left of the default headers. Injecting some manually.
      NSString *padding = @"    ";

      if ([date isToday]) {
          section.header = [padding stringByAppendingString:[MWLocalizedString(@"history-section-today", nil) uppercaseString]];
      } else if ([date isYesterday]) {
          section.header = [padding stringByAppendingString:[MWLocalizedString(@"history-section-yesterday", nil) uppercaseString]];
      } else {
          section.header = [padding stringByAppendingString:[[NSDateFormatter wmf_mediumDateFormatterWithoutTime] stringFromDate:date]];
      }

      section.sectionIdentifier = date;
      [sections addObject:section];
    }];

    return sections;
}

- (void)rebuildSections {
    [self removeAllSections];
    NSArray *sections = [[self class] sectionsFromHistoryList:self.recentPages];
    [self.tableView beginUpdates];
    [self insertSections:sections atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sections.count)]];
    [self.tableView endUpdates];
}

- (NSArray<NSURL *> *)urls {
    return [[self.recentPages entries] bk_map:^id(MWKHistoryEntry *obj) {
      return obj.url;
    }];
}

- (MWKDataStore *)dataStore {
    return self.recentPages.dataStore;
}

- (NSUInteger)titleCount {
    return [self.recentPages countOfEntries];
}

- (MWKHistoryEntry *)recentPageForIndexPath:(NSIndexPath *)indexPath {
    return (MWKHistoryEntry *)[self itemAtIndexPath:indexPath];
}

- (NSURL *)urlForIndexPath:(NSIndexPath *)indexPath {
    return [[self recentPageForIndexPath:indexPath] url];
}

- (BOOL)canDeleteItemAtIndexpath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)deleteArticleAtIndexPath:(NSIndexPath *)indexPath {
    MWKHistoryEntry *entry = [self recentPageForIndexPath:indexPath];
    if (entry) {
        [self.recentPages removeEntryWithListIndex:entry.url];
        [self.recentPages save];
    }
}

- (void)deleteAll {
    [self.recentPages removeAllEntries];
    [self.recentPages save];
}

@end

NS_ASSUME_NONNULL_END
