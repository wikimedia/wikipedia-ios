#import <UIKit/UIKit.h>

@interface UIScreen (WMFImageWidth)

/**
 *  @see WMFArticleListTableViewCell
 *
 *  @return The thumbnail width to request for article list cells, according to the receiver's @c scale.
 */
- (NSNumber *)wmf_listThumbnailWidthForScale;

/**
 *  @see WMFNearbyArticleTableViewCell
 *
 *  @return The thumbnail width to request for nearby cells, according to the receiver's @c scale.
 */
- (NSNumber *)wmf_nearbyThumbnailWidthForScale;

/**
 *  @see WMFArticlePreviewCell
 *
 *  @return The thumbnail width to request according to the receiver's @c scale.
 */
- (NSNumber *)wmf_leadImageWidthForScale;

/**
 *  @see WMFPicOfTheDayTableViewCell
 *
 *  @return The thumbnail width to request for POTD cells, according ot the receiver's @c scale.
 */
- (NSNumber *)wmf_potdImageWidthForScale;

/**
 *  @see WMFImageGalleryCollectionViewCell
 *
 *  @return The thumbnail width to request for the modal image gallery, according to the receiver's @c scale.
 */
- (NSNumber *)wmf_galleryImageWidthForScale;

/**
 *  @return The thumbnail width to request for the article, according to the receiver's @c scale.
 */
- (NSInteger)wmf_articleImageWidthForScale;

@end
