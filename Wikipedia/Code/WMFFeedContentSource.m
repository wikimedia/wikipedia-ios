
#import "WMFFeedContentSource.h"
#import "WMFContentGroupDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "WMFFeedContentFetcher.h"
#import "WMFContentGroup.h"

#import "WMFFeedDayResponse.h"
#import "WMFFeedArticlePreview.h"
#import "WMFFeedImage.h"
#import "WMFFeedTopReadResponse.h"
#import "WMFFeedNewsStory.h"

#import "WMFArticlePreview.h"

@import NSDate_Extensions;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedContentSource ()

@property (readwrite, nonatomic, strong) NSURL *siteURL;

@property (readwrite, nonatomic, strong) WMFContentGroupDataStore *contentStore;
@property (readwrite, nonatomic, strong) WMFArticlePreviewDataStore *previewStore;

@property (nonatomic, strong) WMFFeedContentFetcher *fetcher;

@end

@implementation WMFFeedContentSource

- (instancetype)initWithSiteURL:(NSURL*)siteURL contentGroupDataStore:(WMFContentGroupDataStore*)contentStore articlePreviewDataStore:(WMFArticlePreviewDataStore*)previewStore{
    NSParameterAssert(siteURL);
    NSParameterAssert(contentStore);
    NSParameterAssert(previewStore);
    self = [super init];
    if (self) {
        self.siteURL = siteURL;
        self.contentStore = contentStore;
        self.previewStore = previewStore;
        self.updateInterval = 30*60;
    }
    return self;
}

#pragma mark - Accessors

- (WMFFeedContentFetcher*)fetcher{
    if(_fetcher == nil){
        _fetcher = [[WMFFeedContentFetcher alloc] init];
    }
    return _fetcher;
}

#pragma mark - WMFContentSource

- (void)loadNewContentForce:(BOOL)force completion:(nullable dispatch_block_t)completion{
    [self loadContentForDate:[NSDate date] completion:completion];
}

- (void)preloadContentForNumberOfDays:(NSInteger)days completion:(nullable dispatch_block_t)completion{
    NSDate* dateToLoad = [[NSDate date] dateByAddingDays:-days];
    [self loadContentForDate:dateToLoad completion:^{
        NSInteger numberOfDays = days-1;
        if(numberOfDays > 0){
            [self preloadContentForNumberOfDays:numberOfDays completion:completion];
        }else{
            if(completion){
                completion();
            }
        }
    }];
}

- (void)loadContentForDate:(NSDate*)date completion:(nullable dispatch_block_t)completion{
    
    WMFTopReadContentGroup* topRead = [self topReadForDate:date];
    
    //TODO: check which languages support most read???
    if(topRead != nil){
        //Safe to assume we have everything since Top Read comes in last
        if(completion){
            completion();
        }
        return;
    }
    
    [self.fetcher fetchFeedContentForURL:self.siteURL date:date failure:^(NSError * _Nonnull error) {
        if(completion){
            completion();
        }
        
    } success:^(WMFFeedDayResponse * _Nonnull feedDay) {
        [self saveContentForFeedDay:feedDay onDate:date completion:completion];
    }];
}

- (void)removeAllContent{
    [self.contentStore removeAllContentGroupsOfKind:[WMFFeaturedArticleContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFPictureOfTheDayContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFTopReadContentGroup kind]];
    [self.contentStore removeAllContentGroupsOfKind:[WMFNewsContentGroup kind]];
}

#pragma mark - Save Groups

- (void)saveContentForFeedDay:(WMFFeedDayResponse*)feedDay onDate:(NSDate*)date completion:(dispatch_block_t)completion{
    
    [self saveGroupForFeaturedPreview:feedDay.featuredArticle date:date];
    [self saveGroupForTopRead:feedDay.topRead date:date];
    [self saveGroupForPictureOfTheDay:feedDay.pictureOfTheDay date:date];
//    [self saveGroupForNews:feedDay.newsStories date:date];
    
    if(completion){
        completion();
    }

}

- (void)saveGroupForFeaturedPreview:(WMFFeedArticlePreview*)preview date:(NSDate*)date{
    
    WMFFeaturedArticleContentGroup* featured = [self featuredForDate:date];
    
    if(featured == nil){
        featured = [[WMFFeaturedArticleContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }
    
    NSURL* featuredURL = [preview articleURL];
    
    [self.previewStore addPreviewWithURL:featuredURL updatedWithFeedPreview:preview];
    [self.contentStore addContentGroup:featured associatedContent:@[featuredURL]];
    
}

- (void)saveGroupForTopRead:(WMFFeedTopReadResponse*)topRead date:(NSDate*)date{
    
    WMFTopReadContentGroup* group = [self topReadForDate:date];
    
    if(group == nil){
        group = [[WMFTopReadContentGroup alloc] initWithDate:date mostReadDate:topRead.date siteURL:self.siteURL];
    }
    
    [topRead.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedTopReadArticlePreview * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSURL* url = [obj articleURL];
        [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj];
    }];
    
    [self.contentStore addContentGroup:group associatedContent:topRead.articlePreviews];
    
}


- (void)saveGroupForPictureOfTheDay:(WMFFeedImage*)image date:(NSDate*)date{
    
    WMFPictureOfTheDayContentGroup* group = [self pictureOfTheDayForDate:date];
    
    if(group == nil){
        group = [[WMFPictureOfTheDayContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }
    
    [self.contentStore addContentGroup:group associatedContent:@[image]];
}

- (void)saveGroupForNews:(NSArray<WMFFeedNewsStory*>*)news date:(NSDate*)date{
    
    WMFNewsContentGroup* group = [self newsForDate:date];
    
    if(group == nil){
        group = [[WMFNewsContentGroup alloc] initWithDate:date siteURL:self.siteURL];
    }
    
    [news enumerateObjectsUsingBlock:^(WMFFeedNewsStory * _Nonnull story, NSUInteger idx, BOOL * _Nonnull stop) {
        [story.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSURL* url = [obj articleURL];
            [self.previewStore addPreviewWithURL:url updatedWithFeedPreview:obj];
        }];
    }];
    
    [self.contentStore addContentGroup:group associatedContent:news];
    
}

#pragma mark - Find Groups

- (nullable WMFFeaturedArticleContentGroup*)featuredForDate:(NSDate*)date{

    return (id)[self.contentStore firstGroupOfKind:[WMFFeaturedArticleContentGroup kind] forDate:date];
}

- (nullable WMFPictureOfTheDayContentGroup*)pictureOfTheDayForDate:(NSDate*)date{
    return (id)[self.contentStore firstGroupOfKind:[WMFPictureOfTheDayContentGroup kind] forDate:date];
}

- (nullable WMFTopReadContentGroup*)topReadForDate:(NSDate*)date{
    return (id)[self.contentStore firstGroupOfKind:[WMFTopReadContentGroup kind] forDate:date];
}

- (nullable WMFNewsContentGroup*)newsForDate:(NSDate*)date{
    return (id)[self.contentStore firstGroupOfKind:[WMFNewsContentGroup kind] forDate:date];
}


@end

NS_ASSUME_NONNULL_END
