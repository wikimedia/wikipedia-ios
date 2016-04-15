
#import <UIKit/UIKit.h>
@import NYTPhotoViewer;

#import "WMFImageInfoController.h"

NS_ASSUME_NONNULL_BEGIN

@class WMFImageGalleryViewContoller;

@protocol WMFImageGalleryViewContollerReferenceViewDelegate <NSObject>

/**
 *  Provide a reference view for which to orgiginate and
 *  terminate the transiton animations to and from the gallery.
 *
 *  @param controller The controller requesting the view
 *
 *  @return The view
 */
- (UIImageView*)referenceViewForImageController:(WMFImageGalleryViewContoller*)controller;

@end

/**
 *  This is an abstract base class do not use it directly.
 *  Instead use either the concrete article or POTD version below.
 */
@interface WMFImageGalleryViewContoller : NYTPhotosViewController

@property (nonatomic, weak) id<WMFImageGalleryViewContollerReferenceViewDelegate> referenceViewDelegate;

/**
 *  Do not use the deelgate from NYTPhotosViewController
 *  Instead use the referenceViewDelegate above.
 */
- (void)setDelegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (NSUInteger)indexOfCurrentImage;

- (UIImageView*)currentImageView;

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end

@interface WMFArticleImageGalleryViewContoller : WMFImageGalleryViewContoller<WMFImageInfoControllerDelegate>

- (instancetype)initWithArticle:(MWKArticle*)article;

- (instancetype)initWithArticle:(MWKArticle*)article selectedImage:(nullable MWKImage*)image NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto> >*)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImage*)currentImage;

- (MWKImageInfo*)currentImageInfo;

@end

@interface WMFPOTDImageGalleryViewContoller : WMFImageGalleryViewContoller

- (instancetype)initWithDates:(NSArray<NSDate*>*)imageDates selectedImageInfo:(nullable MWKImageInfo*)imageInfo NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto> >*)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImageInfo*)imageInfoForPhoto:(id<NYTPhoto>)photo;

- (MWKImageInfo*)currentImageInfo;

@end


NS_ASSUME_NONNULL_END