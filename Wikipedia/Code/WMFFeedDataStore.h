
#import "WMFBaseDataStore.h"
#import "WMFExploreSection.h"
#import "WMFDataSource.h"

@class WMFExploreSection;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedDataStore : WMFBaseDataStore


#pragma mark - Section Access

- (WMFExploreSection*)sectionForDate:(NSDate*)date siteURL:(NSURL*)siteURL type:(WMFExploreSectionType)type;

- (WMFExploreSection*)moreLikeSectionForArticleURL:(NSURL*)url;


- (void)enumerateSectionsWithBlock:(void (^)(WMFExploreSection *_Nonnull section, BOOL *stop))block;

- (void)enumerateSectionsOfType:(WMFExploreSectionType)type withBlock:(void (^)(WMFExploreSection *_Nonnull section, BOOL *stop))block;


#pragma mark - Content Access

- (nullable NSArray<NSURL*>*)contentURLsForSection:(WMFExploreSection*)section;


#pragma mark - Section Management

- (void)addSection:(WMFExploreSection*)section associatedContentURLs:(nullable NSArray<NSURL*>*)content;

- (void)removeSection:(WMFExploreSection*)section;



@end


@interface WMFFeedDataStore (WMFDataSources)

- (id<WMFDataSource>)feedDataSource;

@end

NS_ASSUME_NONNULL_END
