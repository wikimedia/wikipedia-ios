#import "NYTPhotosViewController.h"
@class MWKImageInfo;
@import WMF.Swift;

@protocol WMFPhoto <NYTPhoto>

- (nullable NSURL *)bestImageURL;

- (nullable MWKImageInfo *)bestImageInfo;

@end

NS_ASSUME_NONNULL_BEGIN

@class WMFImageGalleryViewController;

@protocol WMFImageGalleryViewControllerReferenceViewDelegate <NSObject>

/**
 *  Provide a reference view for which to orgiginate and
 *  terminate the transiton animations to and from the gallery.
 *
 *  @param controller The controller requesting the view
 *
 *  @return The view
 */
- (UIImageView *)referenceViewForImageController:(WMFImageGalleryViewController *)controller;

@end

@protocol WMFImagePreviewingActionsDelegate <NSObject>

- (void)shareImagePreviewActionSelectedWithImageController:(WMFImageGalleryViewController *)imageController
                                   shareActivityController:(UIActivityViewController *)shareActivityController;

@end

/**
 *  This is an abstract base class do not use it directly.
 *  Instead use either the concrete article or POTD version below.
 */
@interface WMFImageGalleryViewController : NYTPhotosViewController <WMFThemeable, NYTPhotosViewControllerDelegate>

@property (nonatomic, weak) id<WMFImageGalleryViewControllerReferenceViewDelegate> referenceViewDelegate;

- (instancetype)initWithPhotos:(nullable NSArray<id<WMFPhoto>> *)photos initialPhoto:(nullable id<WMFPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden;
/**
 *  Do not use the deelgate from NYTPhotosViewController
 *  Instead use the referenceViewDelegate above.
 */
- (void)setDelegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (NSUInteger)indexOfCurrentImage;

- (UIImageView *)currentImageView;

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (void)setOverlayViewTopBarHidden:(BOOL)hidden;

- (void)updateImageForPhotoAfterUserInteractionIsFinished:(id<NYTPhoto> _Nullable)photo;

- (void)updateOverlayInformation;

@property (weak, nonatomic, nullable) id<WMFImagePreviewingActionsDelegate> imagePreviewingActionsDelegate;

@end

@interface WMFPOTDImageGalleryViewController : WMFImageGalleryViewController

- (instancetype)initWithDates:(NSArray<NSDate *> *)imageDates theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImageInfo *)imageInfoForPhoto:(id<NYTPhoto>)photo;

- (MWKImageInfo *)currentImageInfo;

@end

NS_ASSUME_NONNULL_END
