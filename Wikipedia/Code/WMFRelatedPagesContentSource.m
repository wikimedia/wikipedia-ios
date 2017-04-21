#import "WMFRelatedPagesContentSource.h"
#import "MWKDataStore.h"
#import "MWKSearchResult.h"
#import "WMFRelatedSearchFetcher.h"
#import "WMFRelatedSearchResults.h"
#import <WMF/WMF-Swift.h>

static const NSInteger WMFMaximumSavedOrReadDaysAgoForRelatedPages = 3;

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticle (WMFRelatedPages)

- (BOOL)needsRelatedPagesGroup {
    if (self.isExcludedFromFeed) {
        return NO;
    } else if (self.savedDate != nil) {
        return YES;
    } else if (self.wasSignificantlyViewed) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface WMFRelatedPagesContentSource ()

@property (nonatomic, strong) WMFRelatedSearchFetcher *relatedSearchFetcher;

@end

@implementation WMFRelatedPagesContentSource

#pragma mark - Accessors

- (WMFRelatedSearchFetcher *)relatedSearchFetcher {
    if (_relatedSearchFetcher == nil) {
        _relatedSearchFetcher = [[WMFRelatedSearchFetcher alloc] init];
    }
    return _relatedSearchFetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
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
            inManagedObjectContext:moc
                             force:force
                        completion:^{
                            [group leave];
                        }];
    }

    [group waitInBackgroundWithCompletion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:date inManagedObjectContext:moc force:force addNewContent:YES completion:completion];
}


- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion {
    NSParameterAssert(date);
    if (!date) {
        if (completion) {
            completion();
        }
        return;
    }

    [moc performBlock:^{
        NSDate *midnightUTCDate = [date wmf_midnightUTCDateFromLocalDate];
        NSFetchRequest *fetchRequest = [WMFContentGroup fetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"contentGroupKindInteger == %@", @(WMFContentGroupKindRelatedPages)];
        NSError *fetchError = nil;
        NSArray<WMFContentGroup *> *relatedPagesContentGroups = [moc executeFetchRequest:fetchRequest error:&fetchError];
        if (fetchError) {
            DDLogError(@"Error fetching content groups: %@", fetchError);
        }

        BOOL hasRelatedPageGroupForThisDate = false;
        NSMutableArray<NSString *> *articleKeys = [NSMutableArray arrayWithCapacity:relatedPagesContentGroups.count];
        NSMutableArray<WMFContentGroup *> *validGroups = [NSMutableArray arrayWithCapacity:relatedPagesContentGroups.count];

        for (WMFContentGroup *contentGroup in relatedPagesContentGroups) {
            NSString *articleKey = [[WMFContentGroup articleURLForRelatedPagesContentGroupURL:contentGroup.URL] wmf_articleDatabaseKey];
            if (!articleKey) {
                continue;
            }
            [articleKeys addObject:articleKey];
            [validGroups addObject:contentGroup];
            if (hasRelatedPageGroupForThisDate) {
                continue;
            }
            NSDate *contentGroupDate = contentGroup.midnightUTCDate;
            hasRelatedPageGroupForThisDate = [contentGroupDate isEqualToDate:midnightUTCDate];
        }

        NSMutableDictionary<NSString *, WMFContentGroup *> *relatedPagesContentGroupsByKey = [NSMutableDictionary dictionaryWithObjects:validGroups forKeys:articleKeys];

        NSFetchRequest *referencedArticlesRequest = [WMFArticle fetchRequest];
        referencedArticlesRequest.predicate = [NSPredicate predicateWithFormat:@"key IN %@", articleKeys];
        NSError *referencedArticlesRequestError = nil;
        NSArray *referencedArticles = [moc executeFetchRequest:referencedArticlesRequest error:&referencedArticlesRequestError];
        if (referencedArticlesRequestError) {
            DDLogError(@"Error fetching related pages referenced articles: %@", referencedArticlesRequestError);
        }

        NSMutableSet<NSString *> *remainingKeys = [NSMutableSet setWithArray:articleKeys];
        NSMutableSet<NSString *> *keysToDelete = [NSMutableSet setWithArray:articleKeys];
        for (WMFArticle *article in referencedArticles) {
            NSString *key = article.key;
            if (!key) {
                continue;
            }
            if (![article needsRelatedPagesGroup]) {
                [remainingKeys removeObject:key];
                continue;
            }
            [keysToDelete removeObject:key];
        }

        for (NSString *key in keysToDelete) {
            WMFContentGroup *group = relatedPagesContentGroupsByKey[key];
            if (!group) {
                continue;
            }
            [moc removeContentGroup:group];
        }
        
        if (!shouldAddNewContent) {
            if (completion) {
                completion();
            }
            return;
        }
        
        NSFetchRequest *relatedSeedRequest = [WMFArticle fetchRequest];
        relatedSeedRequest.predicate = [NSPredicate predicateWithFormat:@"isExcludedFromFeed == NO && (wasSignificantlyViewed == YES || savedDate != NULL) && !(key IN %@)", remainingKeys];
        relatedSeedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"viewedDate" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"savedDate" ascending:NO]];
        relatedSeedRequest.fetchLimit = 1;
        NSError *relatedSeedFetchError = nil;
        NSArray *relatedSeedResults = [moc executeFetchRequest:relatedSeedRequest error:&relatedSeedFetchError];
        if (relatedSeedFetchError) {
            DDLogError(@"Error fetching article for related page: %@", relatedSeedFetchError);
        }

        WMFArticle *article = relatedSeedResults.firstObject;
        if (!article) {
            if (completion) {
                completion();
            }
            return;
        }
        NSCalendar *calendar = [NSCalendar wmf_utcGregorianCalendar];
        BOOL isCurrent = NO;
        NSDate *viewedDate = article.viewedDate;
        if (viewedDate && [calendar wmf_daysFromDate:[viewedDate wmf_midnightUTCDateFromLocalDate] toDate:midnightUTCDate] <= WMFMaximumSavedOrReadDaysAgoForRelatedPages) {
            isCurrent = YES;
        }
        NSDate *savedDate = article.savedDate;
        if (savedDate && [calendar wmf_daysFromDate:[savedDate wmf_midnightUTCDateFromLocalDate] toDate:midnightUTCDate] <= WMFMaximumSavedOrReadDaysAgoForRelatedPages) {
            isCurrent = YES;
        }
        if (!article || !isCurrent) {
            if (completion) {
                completion();
            }
            return;
        }

        [self fetchAndSaveRelatedArticlesForArticle:article date:date inManagedObjectContext:moc completion:completion];
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindRelatedPages];
}

#pragma mark - Fetch

- (void)fetchAndSaveRelatedArticlesForArticle:(WMFArticle *)article date:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc completion:(nullable dispatch_block_t)completion {
    NSURL *groupURL = [WMFContentGroup relatedPagesContentGroupURLForArticleURL:article.URL];
    WMFContentGroup *existingGroup = [moc contentGroupForURL:groupURL];
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
            [moc performBlock:^{
                NSArray<NSURL *> *urls = [results.results wmf_map:^id(id obj) {
                    return [results urlForResult:obj];
                }];
                [results.results enumerateObjectsUsingBlock:^(MWKSearchResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    [moc fetchOrCreateArticleWithURL:urls[idx] updatedWithSearchResult:obj];
                }];
                [moc fetchOrCreateGroupForURL:groupURL
                                       ofKind:WMFContentGroupKindRelatedPages
                                      forDate:date
                                  withSiteURL:article.URL.wmf_siteURL
                            associatedContent:urls
                           customizationBlock:^(WMFContentGroup *_Nonnull group) {
                               group.articleURL = article.URL;
                           }];
                if (completion) {
                    completion();
                }
            }];
        }
        failureBlock:^(NSError *_Nonnull error) {
            //TODO: how to handle failure?
            if (completion) {
                completion();
            }
        }];
}

@end

NS_ASSUME_NONNULL_END
