#import "WMFRelatedPagesContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKHistoryEntry.h"
#import "MWKSearchResult.h"
#import "WMFRelatedSearchFetcher.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "WMFRelatedSearchResults.h"
@import NSDate_Extensions;
#import <WMFModel/WMFModel-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryEntry (WMFRelatedPages)

- (BOOL)needsRelatedPagesGroupForDate:(NSDate *)date;

@end

@implementation MWKHistoryEntry (WMFRelatedPages)

- (BOOL)needsRelatedPagesGroupForDate:(NSDate *)date {
    NSDate *beginingOfDay = [date dateAtStartOfDay];
    if (self.isBlackListed) {
        return NO;
    } else if ([self.dateSaved isLaterThanDate:beginingOfDay]) {
        return YES;
    } else if (self.titleWasSignificantlyViewed && [self.dateViewed isLaterThanDate:beginingOfDay]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)needsRelatedPagesGroup {
    if (self.isBlackListed) {
        return NO;
    } else if (self.isSaved) {
        return YES;
    } else if (self.titleWasSignificantlyViewed && self.isInHistory) {
        return YES;
    } else {
        return NO;
    }
}

- (NSDate *)dateForGroup {
    if (self.dateSaved && self.dateViewed) {
        return [self.dateViewed earlierDate:self.dateSaved];
    } else if (self.dateSaved) {
        return self.dateSaved;
    } else {
        return self.dateViewed;
    }
}

@end

@interface WMFRelatedPagesContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, strong) WMFRelatedSearchFetcher *relatedSearchFetcher;

@end

@implementation WMFRelatedPagesContentSource

- (instancetype)initWithContentGroupDataStore:(WMFContentGroupDataStore *)contentStore userDataStore:(MWKDataStore *)userDataStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore {

    NSParameterAssert(contentStore);
    NSParameterAssert(userDataStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.contentStore = contentStore;
        self.userDataStore = userDataStore;
        self.previewStore = previewStore;
    }
    return self;
}

#pragma mark - Accessors

- (WMFRelatedSearchFetcher *)relatedSearchFetcher {
    if (_relatedSearchFetcher == nil) {
        _relatedSearchFetcher = [[WMFRelatedSearchFetcher alloc] init];
    }
    return _relatedSearchFetcher;
}

#pragma mark - WMFContentSource

- (void)startUpdating {
    [self observeSavedPages];
    [self loadNewContentForce:NO completion:NULL];
}

- (void)stopUpdating {
    [self unobserveSavedPages];
}

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[self lastDateAdded] completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days completion:(nullable dispatch_block_t)completion {
    NSDate *dateToLoad = [[NSDate date] dateByAddingDays:-days];
    [self loadContentForDate:dateToLoad
                  completion:^{
                      NSInteger numberOfDays = days - 1;
                      if (numberOfDays > 0) {
                          [self preloadContentForNumberOfDays:numberOfDays completion:completion];
                      } else {
                          if (completion) {
                              completion();
                          }
                      }
                  }];
}

- (void)loadContentForDate:(NSDate *)date completion:(nullable dispatch_block_t)completion {
    WMFTaskGroup *group = [WMFTaskGroup new];

    [group enter];
    [self.userDataStore enumerateItemsWithBlock:^(MWKHistoryEntry *_Nonnull entry, BOOL *_Nonnull stop) {
        [group enter];
        [self updateRelatedGroupForReference:entry
                                        date:date
                                  completion:^{
                                      [group leave];
                                  }];
    }];
    [group leave];

    [group waitInBackgroundWithCompletion:^{
        [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToNewFeed:YES];
        if (completion) {
            completion();
        }
    }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFRelatedPagesContentGroup kind]];
}

#pragma mark - Observing

- (void)itemWasUpdated:(NSNotification *)note {
    NSURL *url = note.userInfo[MWKURLKey];
    if (url) {
        [self updateMoreLikeSectionForURL:url date:[NSDate date] completion:NULL];
    }
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdated:) name:MWKItemUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Process Changes

- (void)updateMoreLikeSectionForURL:(NSURL *)url date:(NSDate *)date completion:(nullable dispatch_block_t)completion {
    MWKHistoryEntry *reference = [self.userDataStore entryForURL:url];
    [self updateRelatedGroupForReference:reference date:date completion:completion];
}

- (void)updateRelatedGroupForReference:(MWKHistoryEntry *)reference date:(NSDate *)date completion:(nullable dispatch_block_t)completion {
    if ([reference needsRelatedPagesGroupForDate:date]) {
        WMFRelatedPagesContentGroup *section = [self addSectionForReference:reference];
        [self fetchAndSaveRelatedArticlesForSection:section completion:completion];
    } else if (![reference needsRelatedPagesGroup]) {
        [self removeSectionForReference:reference];
        if (completion) {
            completion();
        }
    } else {
        if (completion) {
            completion();
        }
    }
}

- (void)removeSectionForReference:(MWKHistoryEntry *)reference {
    WMFContentGroup *group = [self.contentStore contentGroupForURL:[WMFRelatedPagesContentGroup urlForArticleURL:reference.url]];
    if (group) {
        [self.contentStore removeContentGroup:group];
    }
}

- (WMFRelatedPagesContentGroup *)addSectionForReference:(MWKHistoryEntry *)reference {
    WMFRelatedPagesContentGroup *group = (id)[self.contentStore contentGroupForURL:[WMFRelatedPagesContentGroup urlForArticleURL:reference.url]];
    if (!group) {
        group = [[WMFRelatedPagesContentGroup alloc] initWithArticleURL:reference.url date:[reference dateForGroup]];
    }
    return group;
}

#pragma mark - Fetch

- (void)fetchAndSaveRelatedArticlesForSection:(WMFRelatedPagesContentGroup *)group completion:(nullable dispatch_block_t)completion {
    NSArray<NSURL *> *related = [self.contentStore contentForContentGroup:group];
    if ([related count] > 0) {
        if (completion) {
            completion();
        }
        return;
    }
    [self.relatedSearchFetcher fetchArticlesRelatedArticleWithURL:group.articleURL
        resultLimit:WMFMaxRelatedSearchResultLimit
        completionBlock:^(WMFRelatedSearchResults *_Nonnull results) {

            NSArray<NSURL *> *urls = [results.results bk_map:^id(id obj) {
                return [results urlForResult:obj];
            }];
            [results.results enumerateObjectsUsingBlock:^(MWKSearchResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [self.previewStore addPreviewWithURL:urls[idx] updatedWithSearchResult:obj];
            }];
            [self.contentStore addContentGroup:group associatedContent:urls];
            [self.contentStore notifyWhenWriteTransactionsComplete:completion];

        }
        failureBlock:^(NSError *_Nonnull error) {
            //TODO: how to handle failure?
            if (completion) {
                completion();
            }
        }];
}

#pragma mark - Date

- (NSDate *)lastDateAdded {
    __block NSDate *date = nil;
    [self.contentStore enumerateContentGroupsOfKind:[WMFRelatedPagesContentGroup kind]
                                          withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                              if (date == nil || [group.date isLaterThanDate:date]) {
                                                  date = group.date;
                                              }
                                          }];

    if (date == nil) {
        date = [NSDate date];
    }
    return date;
}

@end

NS_ASSUME_NONNULL_END
