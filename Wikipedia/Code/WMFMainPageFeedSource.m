
#import "WMFMainPageFeedSource.h"

@import YapDatabase;
@import NSDate_Extensions;

#import "WMFFeedDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "WMFExploreSection+WMFDatabaseStorable.h"
#import "MWKSiteInfoFetcher.h"
#import "WMFArticlePreviewFetcher.h"
#import "MWKSiteInfo.h"
#import "MWKSearchResult.h"

@interface WMFMainPageFeedSource ()

@property (readwrite, nonatomic, strong) WMFFeedDataStore *feedStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (nonatomic, strong) MWKSiteInfoFetcher *siteInfoFetcher;
@property (nonatomic, strong) WMFArticlePreviewFetcher *previewFetcher;

@end

@implementation WMFMainPageFeedSource

- (instancetype)initWithSiteURL:(NSURL*)siteURL feedDataStore:(WMFFeedDataStore*)feedStore articlePreviewDataStore:(WMFArticlePreviewDataStore*)previewStore{
    NSParameterAssert(feedStore);
    NSParameterAssert(previewStore);
    NSParameterAssert(siteURL);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.feedStore = feedStore;
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

- (WMFArticlePreviewFetcher *)titleSeapreviewFetcherrchFetcher {
    if (_previewFetcher == nil) {
        _previewFetcher = [[WMFArticlePreviewFetcher alloc] init];
    }
    return _previewFetcher;
}


#pragma mark - WMFFeedSource

- (void)updateForce:(BOOL)force{
    WMFExploreSection* section = [self getMainPageForSiteURL:self.siteURL date:[NSDate date]];
    [self fetchAndSaveMainPageForSection:section];
}


#pragma mark - Add / Remove Sections

- (WMFExploreSection* )getMainPageForSiteURL:(NSURL*)siteURL date:(NSDate*)date{
    WMFExploreSection* section = [self.feedStore mainPageSectionForDate:date];
    if(!section){
        section = [WMFExploreSection mainPageSectionWithSiteURL:self.siteURL];
        [self.feedStore addSection:section associatedContent:nil];
    }
    return section;
}

- (void)cleanupOldSections{
    NSMutableArray* oldSectionKeys = [NSMutableArray array];
    [self.feedStore enumerateSectionsOfType:WMFExploreSectionTypeMainPage withBlock:^(WMFExploreSection * _Nonnull section, BOOL * _Nonnull stop) {
        if(![section.dateCreated isToday]){
            [oldSectionKeys addObject:[section databaseKey]];
        }
    }];
    [self.feedStore readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction removeObjectsForKeys:oldSectionKeys inCollection:[WMFExploreSection databaseCollectionName]];
    }];
}

#pragma mark - Fetch

- (void)fetchAndSaveMainPageForSection:(WMFExploreSection *)section{
    [self.siteInfoFetcher fetchSiteInfoForSiteURL:self.siteURL completion:^(MWKSiteInfo * _Nonnull data) {
        
        [self.previewFetcher fetchArticlePreviewResultsForArticleURLs:@[data.mainPageURL] siteURL:self.siteURL completion:^(NSArray<MWKSearchResult *> * _Nonnull results) {
            [self.previewStore addPreviewWithURL:data.mainPageURL updatedWithSearchResult:[results firstObject]];
            [self.feedStore addSection:section associatedContentURLs:@[data.mainPageURL]];
            [self cleanupOldSections];

        } failure:^(NSError * _Nonnull error) {
            //TODO??
        }];
        
    } failure:^(NSError * _Nonnull error) {
        //TODO??
    }];
}




@end
