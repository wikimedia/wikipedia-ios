#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import "WMFImageInfoController.h"

@class MWKArticle;

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

/**
 *  This is an abstract base class do not use it directly.
 *  Instead use either the concrete article or POTD version below.
 */
@interface WMFImageGalleryViewController : NYTPhotosViewController

@property (nonatomic, weak) id<WMFImageGalleryViewControllerReferenceViewDelegate> referenceViewDelegate;

/**
 *  Do not use the deelgate from NYTPhotosViewController
 *  Instead use the referenceViewDelegate above.
 */
- (void)setDelegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (NSUInteger)indexOfCurrentImage;

- (UIImageView *)currentImageView;

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end

@interface WMFArticleImageGalleryViewController : WMFImageGalleryViewController <WMFImageInfoControllerDelegate>

- (nullable instancetype)initWithArticle:(MWKArticle *)article;

- (nullable instancetype)initWithArticle:(MWKArticle *)article selectedImage:(nullable MWKImage *)image NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImage *)currentImage;

- (MWKImageInfo *)currentImageInfo;

@end

@interface WMFPOTDImageGalleryViewController : WMFImageGalleryViewController

- (instancetype)initWithDates:(NSArray<NSDate *> *)imageDates NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImageInfo *)imageInfoForPhoto:(id<NYTPhoto>)photo;

- (MWKImageInfo *)currentImageInfo;

@end

NS_ASSUME_NONNULL_END
