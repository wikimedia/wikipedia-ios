#import "WMFRelatedPagesContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticleDataStore.h"
#import "MWKSearchResult.h"
#import "WMFRelatedSearchFetcher.h"
#import "WMFRelatedSearchResults.h"
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticle (WMFRelatedPages)

- (BOOL)needsRelatedPagesGroupForDate:(NSDate *)date {
    NSDate *beginingOfDay = [date wmf_midnightDate];
    if (self.isExcludedFromFeed) {
        return NO;
    } else if ([self.savedDate compare:beginingOfDay] == NSOrderedDescending) {
        return YES;
    } else if (self.wasSignificantlyViewed && [self.viewedDate compare:beginingOfDay] == NSOrderedDescending) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)needsRelatedPagesGroup {
    if (self.isExcludedFromFeed) {
        return NO;
    } else if (self.savedDate != nil) {
        return YES;
    } else if (self.wasSignificantlyViewed && (self.viewedDate != nil)) {
        return YES;
    } else {
        return NO;
    }
}

- (NSDate *)dateForGroup {
    if (self.savedDate && self.viewedDate) {
        return [self.viewedDate earlierDate:self.savedDate];
    } else if (self.savedDate) {
        return self.savedDate;
    } else {
        return self.viewedDate;
    }
}

@end

@interface WMFRelatedPagesContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFArticleDataStore *previewStore;

@property (nonatomic, strong) WMFRelatedSearchFetcher *relatedSearchFetcher;

@end

@implementation WMFRelatedPagesContentSource

- (instancetype)initWithContentGroupDataStore:(WMFContentGroupDataStore *)contentStore userDataStore:(MWKDataStore *)userDataStore articlePreviewDataStore:(WMFArticleDataStore *)previewStore {

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

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[self lastDateAdded] force:force completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    if (days < 1) {
        if (completion) {
            completion();
        }
        return;
    }

    NSDate *now = [NSDate date];

    NSCalendar *calendar = [NSCalendar wmf_gregorianCalendar];

    WMFTaskGroup *group = [WMFTaskGroup new];

    for (NSUInteger i = 0; i < days; i++) {
        [group enter];
        NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:-i toDate:now options:NSCalendarMatchStrictly];
        [self loadContentForDate:date
                           force:force
                      completion:^{
                          [group leave];
                      }];
    }

    [group waitInBackgroundWithCompletion:completion];
}

- (void)loadContentForDate:(NSDate *)date force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    WMFTaskGroup *group = [WMFTaskGroup new];

    NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
    fetchRequest.propertiesToFetch = @[@"key"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(WMFContentGroupKindRelatedPages)];
    NSError *fetchError = nil;
    NSArray<WMFContentGroup *> *relatedPagesContentGroups = [self.userDataStore.viewContext executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError || !relatedPagesContentGroups) {
        DDLogError(@"Error fetching content groups: %@", fetchError);
    }
    NSArray<NSString *> *keys = [relatedPagesContentGroups valueForKey:@"key"];
    NSMutableDictionary<NSString *, WMFContentGroup *> *relatedPagesContentGroupsByKey = [NSMutableDictionary dictionaryWithObjects:relatedPagesContentGroups forKeys:keys];

    [self.userDataStore enumerateArticlesWithBlock:^(WMFArticle *_Nonnull reference, BOOL *_Nonnull stop) {
        if ([reference needsRelatedPagesGroupForDate:date]) {
            [group enter];
            [self fetchAndSaveRelatedArticlesForArticle:reference completion:^{
                [group leave];
            }];
        } else if (reference && ![reference needsRelatedPagesGroup]) {
            NSURL *URL = reference.URL;
            if (!URL) {
                return;
            }
            NSURL *contentGroupURL = [WMFContentGroup relatedPagesContentGroupURLForArticleURL:URL];
            if (!contentGroupURL) {
                return;
            }
            NSString *key = [WMFContentGroup databaseKeyForURL:contentGroupURL];
            if (!key) {
                return;
            }
            WMFContentGroup *group = relatedPagesContentGroupsByKey[key];
            if (!group) {
                return;
            }
            
            [self.contentStore removeContentGroup:group];
            [relatedPagesContentGroupsByKey removeObjectForKey:key];
        }
    }];
    
    [group waitInBackgroundWithCompletion:^{
        if (completion) {
            completion();
        }
    }];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:WMFContentGroupKindRelatedPages];
}

#pragma mark - Fetch

- (void)fetchAndSaveRelatedArticlesForArticle:(WMFArticle *)article completion:(nullable dispatch_block_t)completion {
    NSURL *groupURL = [WMFContentGroup relatedPagesContentGroupURLForArticleURL:article.URL];
    WMFContentGroup *existingGroup = [self.contentStore contentGroupForURL:groupURL];
    NSArray<NSURL *> *related = (NSArray<NSURL *> *)existingGroup.content;
    if ([related count] > 0) {
        if (completion) {
            completion();
        }
        return;
    }
    [self.relatedSearchFetcher fetchArticlesRelatedArticleWithURL:article.URL
        resultLimit:WMFMaxRelatedSearchResultLimit
        completionBlock:^(WMFRelatedSearchResults *_Nonnull results) {
            if ([results.results count] == 0) {
                if (completion) {
                    completion();
                }
                return;
            }
            NSArray<NSURL *> *urls = [results.results wmf_map:^id(id obj) {
                return [results urlForResult:obj];
            }];
            [results.results enumerateObjectsUsingBlock:^(MWKSearchResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                [self.previewStore addPreviewWithURL:urls[idx] updatedWithSearchResult:obj];
            }];
            [self.contentStore fetchOrCreateGroupForURL:groupURL
                                                 ofKind:WMFContentGroupKindRelatedPages
                                                forDate:[article dateForGroup]
                                            withSiteURL:article.URL.wmf_siteURL
                                      associatedContent:urls
                                     customizationBlock:^(WMFContentGroup *_Nonnull group) {
                                         group.articleURL = article.URL;
                                     }];
            if (completion) {
                completion();
            }
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
    [self.contentStore enumerateContentGroupsOfKind:WMFContentGroupKindRelatedPages
                                          withBlock:^(WMFContentGroup *_Nonnull group, BOOL *_Nonnull stop) {
                                              if (date == nil || [group.midnightUTCDate compare:date] == NSOrderedDescending) {
                                                  date = group.midnightUTCDate;
                                              }
                                          }];

    if (date == nil) {
        date = [NSDate date];
    }
    return date;
}

@end

NS_ASSUME_NONNULL_END
