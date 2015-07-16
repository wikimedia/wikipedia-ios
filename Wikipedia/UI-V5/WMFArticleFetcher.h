
#import <Foundation/Foundation.h>

@class MWKSite;
@class MWKTitle;
@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const WMFArticleFetchedNotification;
extern NSString* const WMFArticleFetchedKey;

extern NSString* const WMFArticleFetchedNotification;
extern NSString* const WMFArticleFetchedKey;

@interface WMFArticleFetcher : NSObject

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (AnyPromise*)fetchArticleForPageTitle:(MWKTitle*)pageTitle progress:(WMFProgressHandler)progress;

@end

NS_ASSUME_NONNULL_END