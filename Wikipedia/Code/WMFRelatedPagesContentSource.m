#import <WMF/WMFRelatedPagesContentSource.h>
#import <WMF/MWKDataStore.h>
#import <WMF/MWKSearchResult.h>
#import <WMF/WMF-Swift.h>
@import WMFData;

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

@implementation WMFRelatedPagesContentSource

#pragma mark - WMFContentSource

- (void)loadNewContentInManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:[NSDate date] inManagedObjectContext:moc force:force completion:completion];
}

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force completion:(nullable dispatch_block_t)completion {
    [self loadContentForDate:date inManagedObjectContext:moc force:force addNewContent:YES completion:completion];
}

// The Home tab replaces the Explore feed's related pages cards ("Because you read" lives in For You),
// so this source only clears any related pages groups left over from earlier versions.
- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion {
    NSParameterAssert(date);
    if (!date) {
        if (completion) {
            completion();
        }
        return;
    }

    [moc performBlock:^{
        [self removeAllContentInManagedObjectContext:moc];
        if (completion) {
            completion();
        }
    }];
}

- (void)removeAllContentInManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc removeAllContentGroupsOfKind:WMFContentGroupKindRelatedPages];
}

@end

NS_ASSUME_NONNULL_END
