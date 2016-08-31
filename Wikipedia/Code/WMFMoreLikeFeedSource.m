
#import "WMFMoreLikeFeedSource.h"
#import "WMFFeedDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKHistoryEntry.h"
#import "MWKSearchResult.h"
#import "WMFRelatedSearchFetcher.h"
#import "WMFExploreSection.h"
#import "WMFRelatedSearchResults.h"



@interface MWKHistoryEntry (WMFMoreLike)

- (BOOL)needsMoreLikeSection;

@end

@implementation MWKHistoryEntry (WMFMoreLike)

- (BOOL)needsMoreLikeSection{
    if(self.isBlackListed){
        return NO;
    }else if(self.isSaved || (self.isInHistory && self.titleWasSignificantlyViewed)){
        return YES;
    }else {
        return NO;
    }
}

@end

@interface WMFMoreLikeFeedSource ()

@property (readwrite, nonatomic, strong) WMFFeedDataStore *feedStore;
@property (readwrite, nonatomic, strong) MWKDataStore *userDataStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, strong) WMFRelatedSearchFetcher *relatedSearchFetcher;

@end

@implementation WMFMoreLikeFeedSource

- (instancetype)initWithFeedDataStore:(WMFFeedDataStore*)feedStore userDataStore:(MWKDataStore*)userDataStore articlePreviewDataStore:(WMFArticlePreviewDataStore*)previewStore{

    NSParameterAssert(feedStore);
    NSParameterAssert(userDataStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.feedStore = feedStore;
        self.userDataStore = userDataStore;
        self.previewStore = previewStore;
    }
    return self;
}

#pragma mark - Accessors

- (WMFRelatedSearchFetcher*)relatedSearchFetcher{
    if(_relatedSearchFetcher == nil){
        _relatedSearchFetcher = [[WMFRelatedSearchFetcher alloc] init];
    }
    return _relatedSearchFetcher;
}

#pragma mark - WMFFeedSource


- (void)startUpdating{
    [self observeSavedPages];
}

- (void)stopUpdating{
    [self unobserveSavedPages];
}

- (void)updateForce:(BOOL)force{
    [self.userDataStore enumerateItemsWithBlock:^(MWKHistoryEntry * _Nonnull entry, BOOL * _Nonnull stop) {
        [self updateMoreLikeSectionForReference:entry];
    }];
}

#pragma mark - Observing

- (void)itemWasUpdated:(NSNotification *)note {
    NSURL *url = note.userInfo[MWKURLKey];
    if (url) {
        [self updateMoreLikeSectionForURL:url];
    }
}

- (void)observeSavedPages {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemWasUpdated:) name:MWKItemUpdatedNotification object:nil];
}

- (void)unobserveSavedPages {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Process Changes

- (void)updateMoreLikeSectionForURL:(NSURL*)url{
    MWKHistoryEntry* reference = [self.userDataStore entryForURL:url];
    [self updateMoreLikeSectionForReference:reference];
}

- (void)updateMoreLikeSectionForReference:(MWKHistoryEntry*)reference{
    if([reference needsMoreLikeSection]){
        WMFExploreSection* section = [self addSectionForReference:reference];
        [self fetchAndSaveRelatedArticlesForSection:section];
    }else {
        [self removeSectionForReference:reference];
    }
}

- (void)removeSectionForReference:(MWKHistoryEntry*)reference{
    WMFExploreSection* section = [self.feedStore moreLikeSectionForArticleURL:reference.url];
    if(section){
        [self.feedStore removeSection:section];
    }
}

- (WMFExploreSection* )addSectionForReference:(MWKHistoryEntry*)reference{
    WMFExploreSection* section = [self.feedStore moreLikeSectionForArticleURL:reference.url];
    if(!section){
        section = [WMFExploreSection historySectionWithHistoryEntry:reference];
        [self.feedStore addSection:section associatedContentURLs:nil];
    }
    return section;
}

#pragma mark - Fetch

- (void)fetchAndSaveRelatedArticlesForSection:(WMFExploreSection *)section {
    NSArray<NSURL*>* related = [self.feedStore contentURLsForSection:section];
    if(related){
        return;
    }
    [self.relatedSearchFetcher fetchArticlesRelatedArticleWithURL:section.articleURL resultLimit:WMFMaxRelatedSearchResultLimit completionBlock:^(WMFRelatedSearchResults * _Nonnull results) {

        NSArray<NSURL*>* urls = [results.results bk_map:^id(id obj) {
            return [results urlForResult:obj];
        }];
        [results.results enumerateObjectsUsingBlock:^(MWKSearchResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.previewStore addPreviewWithURL:urls[idx] updatedWithSearchResult:obj];
        }];
        [self.feedStore addSection:section associatedContentURLs:urls];
    } failureBlock:^(NSError * _Nonnull error) {
        //TODO: how to handle failure?
    }];
}

@end
