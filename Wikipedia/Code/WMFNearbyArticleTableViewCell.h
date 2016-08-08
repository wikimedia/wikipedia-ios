
#import <SSDataSources/SSDataSources.h>

@class WMFSearchResultBearingProvider;
@class WMFSearchResultDistanceProvider;
@class MWKImage;

@interface WMFNearbyArticleTableViewCell : SSBaseTableCell

@property (nonatomic, copy) NSString* titleText;

@property (nonatomic, copy) NSString* descriptionText;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage*)image failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL*)imageURL failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage*)image;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL*)imageURL;


- (void)setDistanceProvider:(WMFSearchResultDistanceProvider*)distanceProvider;

- (void)setBearingProvider:(WMFSearchResultBearingProvider*)bearingProvider;

+ (CGFloat)estimatedRowHeight;

@end
