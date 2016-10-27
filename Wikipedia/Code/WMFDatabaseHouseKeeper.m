#import "WMFDatabaseHouseKeeper.h"
#import "YapDatabase+WMFExtensions.h"
@import NSDate_Extensions;

@implementation WMFDatabaseHouseKeeper

- (void)performHouseKeepingWithCompletion:(dispatch_block_t)completion {

    YapDatabaseConnection *connection = [[YapDatabase sharedInstance] wmf_newWriteConnection];

    //Remove User Data that is unneeded
    [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        YapDatabaseViewTransaction *view = [transaction ext:WMFNotInHistorySavedOrBlackListSortedByURLUngroupedView];
        if ([view numberOfItemsInAllGroups] == 0) {
            return;
        }
        NSMutableArray *keysToRemove = [NSMutableArray array];
        [view enumerateKeysInGroup:[[view allGroups] firstObject]
                        usingBlock:^(NSString *_Nonnull collection, NSString *_Nonnull key, NSUInteger index, BOOL *_Nonnull stop) {
                            [keysToRemove addObject:key];
                        }];
        [transaction removeObjectsForKeys:keysToRemove inCollection:[MWKHistoryEntry databaseCollectionName]];
    }];

    //Remove all content groups older than 30 days
    [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {

        NSDate *thirtyDays = [[NSDate date] dateBySubtractingDays:30];

        NSMutableArray *keysToRemove = [NSMutableArray array];

        [transaction enumerateKeysAndObjectsInCollection:[WMFContentGroup databaseCollectionName]
                                              usingBlock:^(NSString *_Nonnull key, WMFContentGroup *_Nonnull object, BOOL *_Nonnull stop) {

                                                  if ([object.date isEarlierThanDate:thirtyDays]) {
                                                      [keysToRemove addObject:key];
                                                  }
                                              }];

        [transaction removeObjectsForKeys:keysToRemove inCollection:[WMFContentGroup databaseCollectionName]];
    }];

    //Remove previews that are uneeded
    [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {

        NSMutableArray *keysToRemove = [NSMutableArray array];

        //add keys for all previews
        [transaction enumerateKeysInCollection:[WMFArticlePreview databaseCollectionName]
                                    usingBlock:^(NSString *_Nonnull key, BOOL *_Nonnull stop) {
                                        [keysToRemove addObject:key];
                                    }];

        //remove anything with a matching key in history
        [transaction enumerateKeysInCollection:[MWKHistoryEntry databaseCollectionName]
                                    usingBlock:^(NSString *_Nonnull key, BOOL *_Nonnull stop) {
                                        [keysToRemove removeObject:key];
                                    }];

        //remove anything not in the content group store
        [transaction enumerateRowsInCollection:[WMFContentGroup databaseCollectionName]
                                    usingBlock:^(NSString *_Nonnull key, WMFContentGroup *_Nonnull object, NSArray *_Nullable metadata, BOOL *_Nonnull stop) {

                                        //keep any sources of related pages
                                        if ([object isKindOfClass:[WMFRelatedPagesContentGroup class]]) {
                                            NSString *key = ((WMFRelatedPagesContentGroup *)object).articleURL.wmf_databaseKey;
                                            if (key) {
                                                [keysToRemove removeObject:key];
                                            }
                                        }

                                        if (![metadata isKindOfClass:[NSArray class]]) {
                                            NSAssert(NO, @"Unknown Content Type");
                                            return;
                                        }

                                        //keep previews for any linked content
                                        switch (object.contentType) {
                                            case WMFContentTypeURL: {
                                                [metadata enumerateObjectsUsingBlock:^(NSURL *_Nonnull URL, NSUInteger idx, BOOL *_Nonnull stop) {
                                                    NSString *key = URL.wmf_databaseKey;
                                                    if (!key) {
                                                        return;
                                                    }
                                                    [keysToRemove removeObject:key];
                                                }];
                                            } break;
                                            case WMFContentTypeTopReadPreview: {
                                                [metadata enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                                    NSString *key = obj.articleURL.wmf_databaseKey;
                                                    if (!key) {
                                                        return;
                                                    }
                                                    [keysToRemove removeObject:key];
                                                }];

                                            } break;
                                            case WMFContentTypeStory: {
                                                [metadata enumerateObjectsUsingBlock:^(WMFFeedNewsStory *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                                    [obj.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                                        NSString *key = obj.articleURL.wmf_databaseKey;
                                                        if (!key) {
                                                            return;
                                                        }
                                                        [keysToRemove removeObject:key];
                                                    }];
                                                }];
                                            } break;
                                            case WMFContentTypeImage: {
                                                //Nothing to do
                                            } break;

                                            default:
                                                NSAssert(NO, @"Unknown Content Type");
                                                break;
                                        }

                                    }];

        [transaction removeObjectsForKeys:keysToRemove inCollection:[WMFArticlePreview databaseCollectionName]];
    }];

    [connection flushTransactionsWithCompletionQueue:dispatch_get_main_queue()
                                     completionBlock:^{

                                         if (completion) {
                                             completion();
                                         }

                                     }];
}

@end
