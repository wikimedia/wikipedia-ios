
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedSearchFetcher : NSObject

- (instancetype)initWithSearchSite:(MWKSite*)site;

@property (nonatomic, strong, readonly) MWKSite* searchSite;

@property (nonatomic, assign) NSUInteger maximumNumberOfResults;

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END