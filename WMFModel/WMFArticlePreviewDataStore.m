#import "WMFArticlePreviewDataStore.h"
#import "WMFArticlePreview+WMFDatabaseStorable.h"
#import "YapDatabaseReadWriteTransaction+WMFCustomNotifications.h"
#import "MWKSearchResult.h"
#import "MWKLocationSearchResult.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFArticlePreviewDataStore

- (instancetype)initWithDatabase:(YapDatabase *)database
{
    self = [super initWithDatabase:database];
    if (self) {
    }
    return self;
}

- (nullable WMFArticlePreview *)itemForURL:(NSURL *)url{
    NSParameterAssert(url.wmf_title);
    return [self readAndReturnResultsWithBlock:^id _Nonnull(YapDatabaseReadTransaction *_Nonnull transaction) {
        WMFArticlePreview *item = [transaction objectForKey:[WMFArticlePreview databaseKeyForURL:url] inCollection:[WMFArticlePreview databaseCollectionName]];
        return item;
    }];
}

- (void)enumerateItemsWithBlock:(void (^)(WMFArticlePreview *_Nonnull item, BOOL *stop))block{
    if (!block) {
        return;
    }
    [self readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[WMFExploreSection databaseCollectionName] usingBlock:^(NSString * _Nonnull key, id  _Nonnull object, BOOL * _Nonnull stop) {
            block(object, stop);
        }];
    }];
}

- (nullable WMFArticlePreview *)addPreviewWithURL:(NSURL *)url updatedWithSearchResult:(MWKSearchResult*)searchResult{
    NSParameterAssert(url.wmf_title);
    WMFArticlePreview* existing = [[self itemForURL:url] copy];
    if(!existing){
        existing = [WMFArticlePreview new];
        existing.url = url;
    }
    [self updatePreview:existing withSearchResult:searchResult];

    [self readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction setObject:existing forKey:[existing databaseKey] inCollection:[WMFArticlePreview databaseCollectionName]];
    }];
    
    return existing;
    
}

- (void)updatePreview:(WMFArticlePreview*)preview withSearchResult:(MWKSearchResult*)searchResult{
    
    if([searchResult.displayTitle length] > 0){
        preview.displayTitle = searchResult.displayTitle;
    }
    if([searchResult.wikidataDescription length] > 0){
        preview.wikidataDescription = searchResult.wikidataDescription;
    }
    if([searchResult.extract length] > 0){
        preview.snippet = searchResult.extract;
    }
    if(searchResult.thumbnailURL != nil){
        preview.thumbnailURL = searchResult.thumbnailURL;
    }
}

- (void)updatePreview:(WMFArticlePreview*)preview withLocationSearchResult:(MWKLocationSearchResult*)searchResult{
    [self updatePreview:preview withSearchResult:searchResult];
    if(searchResult.location != nil){
        preview.location = searchResult.location;
    }
}


@end

NS_ASSUME_NONNULL_END
