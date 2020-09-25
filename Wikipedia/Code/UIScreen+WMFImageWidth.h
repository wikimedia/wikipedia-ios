@import UIKit;

/**
 *  Image width buckets used to ensure image sizes don't vary too wildly.
 *
 *  This prevents us from fragmenting the image thumbnail caches on the back-end.
 */
typedef NS_ENUM(NSInteger, WMFImageWidth) {
    /**
     *  The smallest image width we will show, e.g. in search cell thumbnails.
     *
     *  There's no guarantee about image aspect ratio, so we fetch a little more and use aspect fill.
     */
    WMFImageWidthExtraSmall = 60,
    /**
     *  The next-smallest thumbnail we'll show, e.g. in nearby cell thumbnails.
     */
    WMFImageWidthSmall = 120,
    /**
     *  A medium width, e.g. POTD & lead images.
     */
    WMFImageWidthMedium = 320,
    /**
     *  A slightly larger width, e.g. modal gallery.
     */
    WMFImageWidthLarge = 640,

    WMFImageWidthExtraLarge = 1280,
    
    WMFImageWidthExtraExtraLarge = 1920
};

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
- (NSInteger)wmf_galleryImageWidthForScale;

/**
 *  @return The thumbnail width to request for the article, according to the receiver's @c scale.
 */
- (NSInteger)wmf_articleImageWidthForScale;

@end

@interface UITraitCollection (WMFImageWidth)

@property (nonatomic, readonly) NSInteger wmf_listThumbnailWidth;
@property (nonatomic, readonly) NSInteger wmf_nearbyThumbnailWidth;
@property (nonatomic, readonly) NSInteger wmf_leadImageWidth;
@property (nonatomic, readonly) NSInteger wmf_potdImageWidth;
@property (nonatomic, readonly) NSInteger wmf_galleryImageWidth;
@property (nonatomic, readonly) NSInteger wmf_articleImageWidth;

@end
