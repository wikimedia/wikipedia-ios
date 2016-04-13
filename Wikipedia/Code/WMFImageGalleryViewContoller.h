
#import <UIKit/UIKit.h>
@import NYTPhotoViewer;

#import "WMFImageInfoController.h"

NS_ASSUME_NONNULL_BEGIN


@interface WMFBaseImageGalleryViewContoller : NYTPhotosViewController

- (NSUInteger)indexOfCurrentImage;

- (UIImageView*)currentImageView;

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end

@interface WMFImageGalleryViewContoller : WMFBaseImageGalleryViewContoller<WMFImageInfoControllerDelegate>

- (instancetype)initWithArticle:(MWKArticle*)article;

- (instancetype)initWithArticle:(MWKArticle*)article selectedImageIndex:(NSUInteger)imageIndex;

- (instancetype)initWithArticle:(MWKArticle*)article selectedImage:(nullable MWKImage*)image;

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImageIndex:(NSUInteger)imageIndex;

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImage:(nullable MWKImage*)image NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto> >*)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

- (MWKImage*)currentImage;

- (MWKImage*)imageForPhoto:(id<NYTPhoto>)photo;

@end

@interface WMFPOTDImageGalleryViewContoller : WMFBaseImageGalleryViewContoller

- (instancetype)initWithDates:(NSArray<NSDate*>*)imageDates selectedImageInfo:(nullable MWKImageInfo*)imageInfo;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto> >*)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END