#import "WMFMainPageContentSource.h"

@import YapDatabase;
@import NSDate_Extensions;

#import "WMFContentGroupDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "WMFContentGroup+WMFDatabaseStorable.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

@interface WMFMainPageContentSource ()

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, strong) MWKSiteInfoFetcher *siteInfoFetcher;
@property (nonatomic, strong) WMFArticlePreviewFetcher *previewFetcher;

@end

@implementation WMFMainPageContentSource

- (instancetype)initWithSiteURL:(NSURL *)siteURL contentGroupDataStore:(WMFContentGroupDataStore *)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore *)previewStore {
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
    }
    return self;
}

#pragma mark - Accessors

- (MWKSiteInfoFetcher *)siteInfoFetcher {
    if (_siteInfoFetcher == nil) {
        _siteInfoFetcher = [[MWKSiteInfoFetcher alloc] init];
    }
    return _siteInfoFetcher;
}

- (WMFArticlePreviewFetcher *)previewFetcher {
    if (_previewFetcher == nil) {
        _previewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _previewFetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion {
    WMFContentGroup *section = [self getMainPageForSiteURL:self.siteURL];
    [self fetchAndSaveMainPageForSection:section completion:completion];
}

- (void)removeAllContent {
    [self.contentStore removeAllContentGroupsOfKind:[WMFMainPageContentGroup kind]];
}

#pragma mark - Add / Remove Sections

- (WMFContentGroup *)getMainPageForSiteURL:(NSURL *)siteURL {
    WMFContentGroup *section = [self.contentStore contentGroupForURL:[WMFMainPageContentGroup urlForSiteURL:siteURL]];
    if (![section.date isToday]) {
        section = [[WMFMainPageContentGroup alloc] initWithSiteURL:self.siteURL];
    }
    return section;
}

- (void)cleanupOldSections {
    NSMutableArray *oldSectionKeys = [NSMutableArray array];
    [self.contentStore enumerateContentGroupsOfKind:[WMFMainPageContentGroup kind]
                                          withBlock:^(WMFContentGroup *_Nonnull section, BOOL *_Nonnull stop) {
                                              if (![section.date isToday]) {
                                                  [oldSectionKeys addObject:[section databaseKey]];
                                              }
                                          }];
    [self.contentStore asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        [transaction removeObjectsForKeys:oldSectionKeys inCollection:[WMFContentGroup databaseCollectionName]];
    }];
}

#pragma mark - Fetch

- (void)fetchAndSaveMainPageForSection:(WMFContentGroup *)section completion:(nullable dispatch_block_t)completion {
    if ([section.date isToday] && [self.contentStore contentForContentGroup:section] != nil) {
        if (completion) {
            completion();
        }
    }

    [self.siteInfoFetcher fetchSiteInfoForSiteURL:self.siteURL
        completion:^(MWKSiteInfo *_Nonnull data) {
            if(data.mainPageURL == nil){
                if (completion) {
                    completion();
                }
                return;
            }
            

            [self.previewFetcher fetchArticlePreviewResultsForArticleURLs:@[data.mainPageURL]
                siteURL:self.siteURL
                completion:^(NSArray<MWKSearchResult *> *_Nonnull results) {
                    if([results count] == 0){
                        if (completion) {
                            completion();
                        }
                        return;
                    }
                    
                    
                    [self.previewStore addPreviewWithURL:data.mainPageURL updatedWithSearchResult:[results firstObject]];
                    [self.contentStore addContentGroup:section associatedContent:@[data.mainPageURL]];
                    [self cleanupOldSections];
                    [self.contentStore notifyWhenWriteTransactionsComplete:completion];

                }
                failure:^(NSError *_Nonnull error) {
                    //TODO??
                    if (completion) {
                        completion();
                    }

                }];

        }
        failure:^(NSError *_Nonnull error) {
            //TODO??
            if (completion) {
                completion();
            }
        }];
}

@end
