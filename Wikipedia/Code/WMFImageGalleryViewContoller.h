
#import <UIKit/UIKit.h>
@import NYTPhotoViewer;

#import "WMFImageInfoController.h"

NS_ASSUME_NONNULL_BEGIN


@interface WMFImageGalleryViewContoller : NYTPhotosViewController<WMFImageInfoControllerDelegate>

- (instancetype)initWithArticle:(MWKArticle*)article;

- (instancetype)initWithArticle:(MWKArticle*)article selectedImageIndex:(NSUInteger)imageIndex;

- (instancetype)initWithArticle:(MWKArticle*)article selectedImage:(nullable MWKImage*)image;

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImageIndex:(NSUInteger)imageIndex;

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImage:(nullable MWKImage*)image NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto> >*)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate NS_UNAVAILABLE;


- (NSUInteger)indexOfCurrentImage;

- (MWKImage*)currentImage;

- (MWKImage*)imageForPhoto:(id<NYTPhoto>)photo;

- (UIImageView*)currentImageView;

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated;

@end


@protocol WMFHeaderImageGalleryViewContollerDelegate <NYTPhotosViewControllerDelegate>

- (void)photosViewController:(NYTPhotosViewController*)photosViewController handleTapForPhoto:(id <NYTPhoto>)photo;

@end

@interface WMFHeaderImageGalleryViewContoller : WMFImageGalleryViewContoller

@property(nonatomic, weak) id<WMFHeaderImageGalleryViewContollerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END