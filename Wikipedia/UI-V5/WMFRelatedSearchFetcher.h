
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedSearchFetcher : NSObject

@property (nonatomic, assign) NSUInteger maximumNumberOfResults;

- (AnyPromise*)fetchArticlesRelatedToTitle:(MWKTitle*)title numberOfExtactCharacters:(NSUInteger)extractChars;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END