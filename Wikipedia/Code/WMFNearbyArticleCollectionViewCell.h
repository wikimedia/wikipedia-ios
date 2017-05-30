#import "WMFExploreCollectionViewCell.h"
@import CoreLocation;

@class MWKImage;

@interface WMFNearbyArticleCollectionViewCell : WMFExploreCollectionViewCell

@property (nonatomic, copy) NSString *titleText;

@property (nonatomic, copy) NSString *descriptionText;

@property (nonatomic, copy) CLLocation *articleLocation;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage *)image failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL *)imageURL failure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;

/**
 *  Set the recievers @c image using an MWKImage
 */
- (void)setImage:(MWKImage *)image;

/**
 *  Set the recievers @c image using a URL
 */
- (void)setImageURL:(NSURL *)imageURL;

- (void)configureForUnknownDistance;

- (void)setDistance:(CLLocationDistance)distance;

- (void)setBearing:(CLLocationDegrees)bearing;

+ (CGFloat)estimatedRowHeight;

@end
