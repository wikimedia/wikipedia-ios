#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 *  Fetches a preview of the featured article for a given day from en.wikipedia.org.
 *
 *  This uses the TFA_title template which is (at time of writing and to the best of my knowledge) specific to EN wiki.
 */
@interface WMFEnglishFeaturedTitleFetcher : NSObject


- (void)fetchFeaturedArticlePreviewForDate:(NSDate *)date failure:(WMFErrorHandler)failure success:(WMFMWKSearchResultHandler)success;

@property (nonatomic, assign, readonly) BOOL isFetching;

@end

NS_ASSUME_NONNULL_END
