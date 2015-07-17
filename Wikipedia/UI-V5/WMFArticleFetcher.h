
#import <Foundation/Foundation.h>

@class MWKSite;
@class MWKTitle;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFetcher : NSObject

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

- (AnyPromise*)fetchSectionTitlesAndFirstSectionForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler __nullable)progress;

@end

NS_ASSUME_NONNULL_END