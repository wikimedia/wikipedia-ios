
#import "WMFImageGalleryViewContoller.h"
#import "MWKArticle.h"
#import "MWKImageList.h"
#import "MWKImage.h"
#import "MWKImageInfo.h"
#import "MWKDataStore.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "Wikipedia-Swift.h"
#import "UIImage+WMFStyle.h"
#import "UIColor+WMFStyle.h"
@import FLAnimatedImage;

NS_ASSUME_NONNULL_BEGIN

@interface WMFGalleryImage : NSObject <NYTPhoto>

//set to display a thumbnail during download
@property (nonatomic, strong, nullable) MWKImage* thumbnailImageObject;

//used to fetch the full size image
@property (nonatomic, strong) MWKImage* imageObject;

//used for metadaata
@property (nonatomic, strong) MWKImageInfo* imageInfo;

@end

@implementation WMFGalleryImage

+ (NSArray<WMFGalleryImage*>*)galleryImagesWithImageObjects:(NSArray<MWKImage*>*)imageObjects {
    return [imageObjects bk_map:^id (MWKImage* obj) {
        return [[WMFGalleryImage alloc] initWithImage:obj];
    }];
}

- (instancetype)initWithImage:(MWKImage*)imageObject {
    self = [super init];
    if (self) {
        self.imageObject = imageObject;
    }
    return self;
}

- (nullable UIImage*)placeholderImage {
    if (!self.thumbnailImageObject) {
        return nil;
    }
    return [[WMFImageController sharedInstance] syncCachedImageWithURL:self.thumbnailImageObject.sourceURL];
}

- (nullable UIImage*)image {
    if (!self.imageObject) {
        return nil;
    }
    return [[WMFImageController sharedInstance] syncCachedImageWithURL:self.imageObject.sourceURL];
}

- (nullable NSData*)imageData {
    return nil;
}

- (nullable NSAttributedString*)attributedCaptionTitle {
    return nil;
}

- (nullable NSAttributedString*)attributedCaptionSummary {
    if (!self.imageInfo) {
        return nil;
    }
    return [[NSAttributedString alloc] initWithString:[self.imageInfo imageDescription]];
}

- (nullable NSAttributedString*)attributedCaptionCredit {
    if (!self.imageInfo) {
        return nil;
    }
    return [[NSAttributedString alloc] initWithString:[self.imageInfo owner]];
}

@end

@protocol WMFExposedDataSource <NYTPhotosViewControllerDataSource>

/**
 *  Exposing a private property of the data source
 *  In order to guarentee its existince, we assert photos
 *  on int in the VC
 */
@property (nonatomic, copy, readonly) NSArray* photos;

@end

@interface NYTPhotosViewController (WMFExposure)

@property (nonatomic, readonly) id <WMFExposedDataSource> dataSource;

- (void)updateOverlayInformation;

@property(nonatomic, assign) BOOL overlayViewHidden;

- (NYTPhotoViewController*)currentPhotoViewController;

- (UIImageView*)currentImageView;


@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation NYTPhotosViewController (WMFExposure)

@dynamic dataSource;

- (void)setOverlayViewHidden:(BOOL)overlayViewHidden {
    if (overlayViewHidden) {
        [self.overlayView removeFromSuperview];
    } else {
        [self.view addSubview:self.overlayView];
    }
}

- (BOOL)overlayViewHidden {
    return [self.overlayView superview] == nil;
}

- (UIImageView*)currentImageView {
    return [self currentPhotoViewController].scalingImageView.imageView;
}

@end

#pragma clang diagnostic pop

@interface WMFImageGalleryViewContoller ()

@property (nonatomic, strong) WMFImageInfoController* infoController;

@property (nonatomic, strong, readonly) NSArray<WMFGalleryImage*>* photos;


@end

@implementation WMFImageGalleryViewContoller

- (instancetype)initWithArticle:(MWKArticle*)article {
    return [self initWithArticle:article selectedImageIndex:0];
}

- (instancetype)initWithArticle:(MWKArticle*)article selectedImageIndex:(NSUInteger)imageIndex {
    NSArray* items = [article.images imagesForDisplayInGallery];
    return [self initWithDataStore:article.dataStore images:items selectedImageIndex:imageIndex];
}

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImageIndex:(NSUInteger)imageIndex {
    MWKImage* image = images[imageIndex];
    if (imageIndex < images.count) {
        image = images[imageIndex];
    }
    return [self initWithDataStore:store images:images selectedImage:image];
}

- (instancetype)initWithArticle:(MWKArticle*)article selectedImage:(nullable MWKImage*)image {
    NSArray* items = [article.images imagesForDisplayInGallery];
    return [self initWithDataStore:article.dataStore images:items selectedImage:image];
}

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImage:(nullable MWKImage*)image {
    NSArray* items = images;
    if ([[NSProcessInfo processInfo] wmf_isOperatingSystemVersionLessThan9_0_0]) {
        items = [items wmf_reverseArrayIfApplicationIsRTL];
    }
    NSArray<WMFGalleryImage*>* galleryImages = [WMFGalleryImage galleryImagesWithImageObjects:items];

    WMFGalleryImage* selected = nil;
    if (image) {
        selected = [[self class] galleryImageWithImage:image inGalleryImages:galleryImages];
    }

    self = [super initWithPhotos:galleryImages initialPhoto:selected delegate:nil];
    if (self) {
        NSParameterAssert(self.dataSource);
        NSParameterAssert(self.photos);
        NSParameterAssert(store);
        NSParameterAssert(images);
        NSAssert([self respondsToSelector:@selector(updateOverlayInformation)], @"NYTPhoto implementation changed!");
        self.infoController          = [[WMFImageInfoController alloc] initWithDataStore:store batchSize:50];
        self.infoController.delegate = self;
    }

    return self;
}

- (NSArray<WMFGalleryImage*>*)photos {
    return [(id < WMFExposedDataSource >)self.dataSource photos];
}

+ (nullable WMFGalleryImage*)galleryImageWithImage:(MWKImage*)image inGalleryImages:(NSArray<WMFGalleryImage*>*)images {
    NSUInteger index = [self indexOfImage:image inGalleryImages:images];
    if (index > images.count) {
        return nil;
    }
    return images[index];
}

+ (NSUInteger)indexOfImage:(MWKImage*)image inGalleryImages:(NSArray<WMFGalleryImage*>*)images {
    return [images
            indexOfObjectPassingTest:^BOOL (WMFGalleryImage* anImage, NSUInteger _, BOOL* stop) {
        if ([anImage.imageObject isEqualToImage:image] || [anImage.imageObject isVariantOfImage:image]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
}

- (NSUInteger)indexOfImage:(MWKImage*)image {
    return [[self class] indexOfImage:image inGalleryImages:self.photos];
}

- (NSUInteger)indexOfGalleryImage:(WMFGalleryImage*)image {
    return [[self class] indexOfImage:image.imageObject inGalleryImages:self.photos];
}

- (NSUInteger)indexOfCurrentImage {
    return [self indexOfGalleryImage:self.currentlyDisplayedPhoto];
}

- (MWKImage*)currentImage {
    NSUInteger current = [self indexOfCurrentImage];
    if (current > self.photos.count) {
        return nil;
    }
    return [self.photos[current] imageObject];
}

- (MWKImage*)imageForPhoto:(id<NYTPhoto>)photo {
    return [(WMFGalleryImage*)photo imageObject];
}

- (UIImageView*)currentImageView {
    return [super currentImageView];
}

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index > self.photos.count) {
        return;
    }

    id<NYTPhoto> photo = self.photos[index];

    [self displayPhoto:photo animated:animated];
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.currentlyDisplayedPhoto) {
        [self.infoController fetchBatchContainingIndex:[self indexOfGalleryImage:self.currentlyDisplayedPhoto]];
    }
}

#pragma mark - WMFImageInfoControllerDelegate

- (void)imageInfoController:(WMFImageInfoController*)controller didFetchBatch:(NSRange)range {
    NSIndexSet* fetchedIndexes = [NSIndexSet indexSetWithIndexesInRange:range];

    [self.photos enumerateObjectsAtIndexes:fetchedIndexes options:0 usingBlock:^(WMFGalleryImage* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        obj.imageInfo = [controller infoForImage:obj.imageObject];
    }];

    [self updateOverlayInformation];
}

- (void)imageInfoController:(WMFImageInfoController*)controller
         failedToFetchBatch:(NSRange)range
                      error:(NSError*)error {
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //display error image?
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    [self dismissViewControllerAnimated:YES completion:NULL];
    return YES;
}

@end

@implementation WMFHeaderImageGalleryViewContoller

@dynamic delegate;

- (instancetype)initWithDataStore:(MWKDataStore*)store images:(NSArray<MWKImage*>*)images selectedImage:(nullable MWKImage*)image {
    self = [super initWithDataStore:store images:images selectedImage:image];
    if (self) {
        self.overlayViewHidden = YES;
        [self.singleTapGestureRecognizer addTarget:self action:@selector(didTap:)];
    }
    return self;
}

- (void)didTap:(UITapGestureRecognizer*)tap {
    [self.delegate photosViewController:self handleTapForPhoto:[self currentlyDisplayedPhoto]];
}

@end



NS_ASSUME_NONNULL_END
