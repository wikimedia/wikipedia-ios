#import "WMFDatabaseHouseKeeper.h"
#import "YapDatabase+WMFExtensions.h"
@import NSDate_Extensions;

@implementation WMFDatabaseHouseKeeper

- (BOOL)performHouseKeepingOnManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)outError {
    BOOL (^done)(NSError *) = ^BOOL(NSError *blockError) {
        if (outError) {
            *outError = blockError;
        }
        return blockError == nil;
    };

    NSError *error = nil;
    
    NSDate *midnightTodayUTC = [[NSDate date] midnightUTCDate];
    NSCalendar *utcCalendar = [NSCalendar wmf_utcGregorianCalendar];
    NSDate *thirtyDaysAgoMidnightUTC = [utcCalendar dateByAddingUnit:NSCalendarUnitDay value:-30 toDate:midnightTodayUTC options:NSCalendarMatchStrictly];

    
    NSFetchRequest *allContentGroupFetchRequest = [WMFContentGroup fetchRequest];
    allContentGroupFetchRequest.propertiesToFetch = @[@"key", @"midnightUTCDate", @"content", @"articleURLString"];
    NSArray *allContentGroups = [moc executeFetchRequest:allContentGroupFetchRequest error:&error];
    if (error) {
        return done(error);
    }
    
    NSMutableSet *referencedArticleKeys = [NSMutableSet setWithCapacity:allContentGroups.count*5 + 1];
    for (WMFContentGroup *group in allContentGroups) {
        if ([group.midnightUTCDate isEarlierThanDate:thirtyDaysAgoMidnightUTC]) {
            [moc deleteObject:group];
            continue;
        }
        
        NSString *articleURLDatabaseKey = group.articleURL.wmf_articleDatabaseKey;
        if (articleURLDatabaseKey) {
            [referencedArticleKeys addObject:articleURLDatabaseKey];
        }
        
        NSArray *content = group.content;
        if (![content isKindOfClass:[NSArray class]]) {
            NSAssert(NO, @"Unknown Content Type");
            continue;
        }
        
        switch (group.contentType) {
            case WMFContentTypeURL: {
                [content enumerateObjectsUsingBlock:^(NSURL *_Nonnull URL, NSUInteger idx, BOOL *_Nonnull stop) {
                    if (![URL isKindOfClass:[NSURL class]]) {
                        return;
                    }
                    NSString *key = URL.wmf_articleDatabaseKey;
                    if (!key) {
                        return;
                    }
                    [referencedArticleKeys addObject:key];
                }];
            } break;
            case WMFContentTypeTopReadPreview: {
                [content enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    if (![obj isKindOfClass:[WMFFeedTopReadArticlePreview class]]) {
                        return;
                    }
                    NSString *key = obj.articleURL.wmf_articleDatabaseKey;
                    if (!key) {
                        return;
                    }
                    [referencedArticleKeys addObject:key];
                }];

            } break;
            case WMFContentTypeStory: {
                [content enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    if (![obj isKindOfClass:[WMFFeedNewsStory class]]) {
                        return;
                    }
                    [obj.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                        NSString *key = obj.articleURL.wmf_articleDatabaseKey;
                        if (!key) {
                            return;
                        }
                        [referencedArticleKeys addObject:key];
                    }];
                }];
            } break;
            case WMFContentTypeImage: {
                //Nothing to do
            } break;
            case WMFContentTypeAnnouncement: {
                
            }
                break;
            default:
                NSAssert(NO, @"Unknown Content Type");
                break;
        }
    }
    
    NSFetchRequest *articlesToDeleteFetchRequest = [WMFArticle fetchRequest];
    NSPredicate *articlesToDeletePredicate = [NSPredicate predicateWithFormat:@"viewedDate == NULL && savedDate == NULL && isExcludedFromFeed == %@",  @(NO)];
    if (referencedArticleKeys.count > 0) {
        NSPredicate *referencedKeysPredicate = [NSPredicate predicateWithFormat:@"!(key IN %@)", referencedArticleKeys];
        articlesToDeletePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[articlesToDeletePredicate, referencedKeysPredicate]];
    }
    articlesToDeleteFetchRequest.predicate = articlesToDeletePredicate;
    articlesToDeleteFetchRequest.propertiesToFetch = @[@"key", @"viewedDate", @"savedDate", @"isExcludedFromFeed"];
    NSArray *articlesToDelete = [moc executeFetchRequest:articlesToDeleteFetchRequest error:&error];
    if (error) {
        return done(error);
    }
    
    for (WMFArticle *article in articlesToDelete) {
        [moc deleteObject:article];
    }
    
    if ([moc hasChanges]) {
        [moc save:&error];
    }
    
    if (error) {
        return done(error);
    }
    
    return done(nil);
}

@end
