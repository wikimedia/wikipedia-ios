#import "WMFImageGalleryViewController.h"
#import "MWKArticle.h"
#import "MWKImage.h"
#import "MWKImageInfo.h"
#import "MWKDataStore.h"
#import "Wikipedia-Swift.h"
#import "UIImage+WMFStyle.h"
#import "UIColor+WMFStyle.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "WMFImageGalleryDetailOverlayView.h"
#import "UIView+WMFDefaultNib.h"
#import "WMFURLCache.h"
#import <FLAnimatedImage/FLAnimatedImage.h>
#import <FLAnimatedImage/FLAnimatedImageView.h>
#import <NYTPhotoViewer/NYTPhotosViewControllerDataSource.h>
#import <NYTPhotoViewer/NYTPhotoViewController.h>
#import <NYTPhotoViewer/NYTPhotosOverlayView.h>
#import <NYTPhotoViewer/NYTScalingImageView.h>
#import <NYTPhotoViewer/NYTPhoto.h>
#import <Masonry/Masonry.h>
#import "WMFGradientView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WMFPhoto <NYTPhoto>

- (nullable NSURL *)bestImageURL;

- (nullable MWKImageInfo *)bestImageInfo;

@end

@protocol WMFExposedDataSource <NYTPhotosViewControllerDataSource>

/**
 *  Exposing a private property of the data source
 *  In order to guarantee its existence, we assert photos
 *  on init in the VC
 */
@property (nonatomic, copy, readonly) NSArray *photos;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@interface NYTPhotosViewController (WMFExposure)

- (NYTPhotoViewController *)newPhotoViewControllerForPhoto:(id<NYTPhoto>)photo;

@end

@interface WMFImageGalleryViewController () <NYTPhotosViewControllerDelegate>

@property (nonatomic, strong, readonly) NSArray<id<NYTPhoto>> *photos;

@property (nonatomic, readonly) id<WMFExposedDataSource> dataSource;

- (void)updateOverlayInformation;

@property (nonatomic, assign) BOOL overlayViewHidden;

- (NYTPhotoViewController *)currentPhotoViewController;

- (UIImageView *)currentImageView;

@end

@interface WMFArticlePhoto : NSObject <WMFPhoto>

//set to display a thumbnail during download
@property (nonatomic, strong, nullable) MWKImage *thumbnailImageObject;

//used to fetch the full size image
@property (nonatomic, strong, nullable) MWKImage *imageObject;

//used for metadaata
@property (nonatomic, strong, nullable) MWKImageInfo *imageInfo;

@end

@implementation WMFArticlePhoto

+ (NSArray<WMFArticlePhoto *> *)photosWithThumbnailImageObjects:(NSArray<MWKImage *> *)imageObjects {
    return [imageObjects wmf_map:^id(MWKImage *obj) {
        return [[WMFArticlePhoto alloc] initWithThumbnailImage:obj];
    }];
}

- (instancetype)initWithImage:(MWKImage *)imageObject {
    self = [super init];
    if (self) {
        self.imageObject = imageObject;
    }
    return self;
}

- (instancetype)initWithThumbnailImage:(MWKImage *)imageObject {
    self = [super init];
    if (self) {
        self.thumbnailImageObject = imageObject;
    }
    return self;
}

- (nullable MWKImage *)bestImageObject {
    return self.imageObject ?: self.thumbnailImageObject;
}

- (nullable NSURL *)bestImageURL {
    if (self.imageObject) {
        return self.imageObject.sourceURL;
    } else if (self.imageInfo) {
        return self.imageInfo.imageThumbURL;
    } else if (self.thumbnailImageObject) {
        return self.thumbnailImageObject.sourceURL;
    } else {
        return nil;
    }
}

- (nullable MWKImageInfo *)bestImageInfo {
    return self.imageInfo;
}

- (nullable UIImage *)placeholderImage {
    NSURL *url = [self thumbnailImageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable NSURL *)thumbnailImageURL {
    return self.thumbnailImageObject.sourceURL ?: self.imageInfo.imageThumbURL;
}

- (nullable UIImage *)image {
    NSURL *url = [self imageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable UIImage *)memoryCachedImage {
    NSURL *url = [self imageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] sessionCachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable NSURL *)imageURL {
    if (self.imageObject) {
        return self.imageObject.sourceURL;
    } else if (self.imageInfo) {
        return self.imageInfo.imageThumbURL;
    } else {
        return nil;
    }
}

- (nullable NSData *)imageData {
    NSURL *URL = self.bestImageURL;
    return [URL.absoluteString.lowercaseString containsString:@".gif"] ? [[[WMFImageController sharedInstance] dataWithURL:URL] data] : nil;
}

- (nullable NSAttributedString *)attributedCaptionTitle {
    return nil;
}

- (nullable NSAttributedString *)attributedCaptionSummary {
    return nil;
}

- (nullable NSAttributedString *)attributedCaptionCredit {
    return nil;
}

@end

@implementation WMFImageGalleryViewController

@dynamic dataSource;

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate {
    self = [super initWithPhotos:photos initialPhoto:initialPhoto delegate:self];
    if (self) {
        /**
         *  We are performing the following asserts to ensure that the
         *  implmentation of of NYTPhotosViewController does not change.
         *  We exposed these properties and methods via a category
         *  in lieu of subclassing. (and then maintaining a separate fork)
         */
        NSParameterAssert(self.dataSource);
        NSParameterAssert(self.photos);
        NSAssert([self respondsToSelector:@selector(updateOverlayInformation)], @"NYTPhoto implementation changed!");
        NSAssert([self respondsToSelector:@selector(currentPhotoViewController)], @"NYTPhoto implementation changed!");
        NSAssert([self respondsToSelector:@selector(currentImageView)], @"NYTPhoto implementation changed!");
        NSAssert([self respondsToSelector:@selector(newPhotoViewControllerForPhoto:)], @"NYTPhoto implementation changed!");

        UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapShareButton)];
        share.tintColor = [UIColor whiteColor];
        self.rightBarButtonItem = share;

        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapCloseButton)];
        close.tintColor = [UIColor whiteColor];
        self.leftBarButtonItem = close;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
}

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

- (UIImageView *)currentImageView {
    return [self currentPhotoViewController].scalingImageView.imageView;
}

- (NSArray<id<NYTPhoto>> *)photos {
    return [(id<WMFExposedDataSource>)self.dataSource photos];
}

- (NSUInteger)indexOfCurrentImage {
    return [self indexOfPhoto:self.currentlyDisplayedPhoto];
}

- (NSUInteger)indexOfPhoto:(id<NYTPhoto>)photo {
    return [self.photos indexOfObject:photo];
}

- (nullable id<WMFPhoto>)photoAtIndex:(NSUInteger)index {
    if (index > self.photos.count) {
        return nil;
    }
    return (id<WMFPhoto>)self.photos[index];
}

- (MWKImageInfo *)imageInfoForPhoto:(id<WMFPhoto>)photo {
    return [photo bestImageInfo];
}

- (void)showImageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    id<NYTPhoto> photo = [self photoAtIndex:index];
    [self displayPhoto:photo animated:animated];
}

- (NYTPhotoViewController *)newPhotoViewControllerForPhoto:(id<NYTPhoto>)photo {
    NYTPhotoViewController *vc = [super newPhotoViewControllerForPhoto:photo];
    vc.scalingImageView.imageView.backgroundColor = [UIColor whiteColor];
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addGradientToGalleryNavigationBar];
}

- (void)addGradientToGalleryNavigationBar {
    WMFGradientView *gradientView = [WMFGradientView new];
    [gradientView.gradientLayer setLocations:@[@0, @.745, @1]];
    [gradientView.gradientLayer setColors:@[
        (id)[UIColor blackColor].CGColor,
        (id)[UIColor blackColor].CGColor,
        (id)[UIColor clearColor].CGColor
    ]];
    [gradientView.gradientLayer setStartPoint:CGPointMake(0.5, 0.0)];
    [gradientView.gradientLayer setEndPoint:CGPointMake(0.5, 1.0)];
    [self.overlayView.navigationBar addSubview:gradientView];
    [self.overlayView.navigationBar sendSubviewToBack:gradientView];
    [gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.overlayView.navigationBar);
        make.height.equalTo(self.overlayView.navigationBar).multipliedBy(1.34);
    }];
}

#pragma mark - Actions

- (void)didTapCloseButton {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didTapShareButton {
    id<WMFPhoto> photo = (id<WMFPhoto>)self.currentlyDisplayedPhoto;
    MWKImageInfo *info = [photo bestImageInfo];
    NSURL *url = [photo bestImageURL];

    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:url
        failure:^(NSError *_Nonnull error) {
            [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            @strongify(self);
            NSMutableArray *items = [NSMutableArray array];

            WMFImageTextActivitySource *textSource = [[WMFImageTextActivitySource alloc] initWithInfo:info];
            [items addObject:textSource];

            WMFImageURLActivitySource *imageSource = [[WMFImageURLActivitySource alloc] initWithInfo:info];
            [items addObject:imageSource];

            if (download.image) {
                [items addObject:download.image];
            }

            UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
            vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList];
            UIPopoverPresentationController *presenter = [vc popoverPresentationController];
            presenter.barButtonItem = self.rightBarButtonItem;
            [self presentViewController:vc animated:YES completion:NULL];
        }];
}

- (void)didTapInfoButton {
    id<WMFPhoto> photo = (id<WMFPhoto>)self.currentlyDisplayedPhoto;
    MWKImageInfo *info = [photo bestImageInfo];
    [self wmf_openExternalUrl:info.filePageURL];
}

#pragma mark NYTPhotosViewControllerDelegate

- (UIView *_Nullable)photosViewController:(NYTPhotosViewController *)photosViewController referenceViewForPhoto:(id<NYTPhoto>)photo {
    return nil; //TODO: remove this and re-enable animations when tickets for fixing anmimations are addressed
    return [self.referenceViewDelegate referenceViewForImageController:self];
}

- (CGFloat)photosViewController:(NYTPhotosViewController *)photosViewController maximumZoomScaleForPhoto:(id<NYTPhoto>)photo {
    return 2.0;
}

- (NSString *_Nullable)photosViewController:(NYTPhotosViewController *)photosViewController titleForPhoto:(id<NYTPhoto>)photo atIndex:(NSUInteger)photoIndex totalPhotoCount:(NSUInteger)totalPhotoCount {
    return @"";
}

- (UIView *_Nullable)photosViewController:(NYTPhotosViewController *)photosViewController captionViewForPhoto:(id<NYTPhoto>)photo {
    MWKImageInfo *imageInfo = [(id<WMFPhoto>)photo bestImageInfo];

    if (!imageInfo) {
        return nil;
    }

    WMFImageGalleryDetailOverlayView *caption = [WMFImageGalleryDetailOverlayView wmf_viewFromClassNib];

    caption.imageDescription =
        [imageInfo.imageDescription stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *ownerOrFallback = imageInfo.owner ? [imageInfo.owner stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                                : WMFLocalizedStringWithDefaultValue(@"image-gallery-unknown-owner", nil, nil, @"Author unknown.", @"Fallback text for when an item in the image gallery doesn't have a specified owner.");

    [caption setLicense:imageInfo.license owner:ownerOrFallback];

    @weakify(self)
        caption.ownerTapCallback = ^{
        @strongify(self)
            [self wmf_openExternalUrl:imageInfo.license.URL];
    };
    caption.infoTapCallback = ^{
        @strongify(self)
            [self wmf_openExternalUrl:imageInfo.filePageURL];
    };

    return caption;
}

@end

#pragma clang diagnostic pop

@interface WMFArticleImageGalleryViewController ()

@property (nonatomic, strong) WMFImageInfoController *infoController;

@end

@implementation WMFArticleImageGalleryViewController

- (nullable instancetype)initWithArticle:(MWKArticle *)article {
    return [self initWithArticle:article selectedImage:nil];
}

- (nullable instancetype)initWithArticle:(MWKArticle *)article selectedImage:(nullable MWKImage *)image {
    NSParameterAssert(article);
    NSParameterAssert(article.dataStore);

    NSArray *items = [article imagesForGallery];

    if ([items count] == 0) {
        return nil;
    }

    NSArray<WMFArticlePhoto *> *photos = [WMFArticlePhoto photosWithThumbnailImageObjects:items];

    id<NYTPhoto> selected = nil;
    if (image) {
        selected = [[self class] photoWithImage:image inPhotos:photos];
    }

    self = [super initWithPhotos:photos initialPhoto:selected delegate:nil];
    if (self) {
        self.infoController = [[WMFImageInfoController alloc] initWithDataStore:article.dataStore batchSize:50];
        [self.infoController setUniqueArticleImages:items forArticleURL:article.url];
        [self.photos enumerateObjectsUsingBlock:^(WMFArticlePhoto *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            obj.imageInfo = [self.infoController infoForImage:[obj bestImageObject]];
        }];
        self.infoController.delegate = self;
    }

    return self;
}

- (MWKImage *)imageForPhoto:(id<NYTPhoto>)photo {
    return [(WMFArticlePhoto *)photo bestImageObject];
}

- (MWKImage *)currentImage {
    return [self imageForPhoto:[self photoAtIndex:[self indexOfCurrentImage]]];
}

- (MWKImageInfo *)currentImageInfo {
    return [self imageInfoForPhoto:[self photoAtIndex:[self indexOfCurrentImage]]];
}

+ (nullable id<NYTPhoto>)photoWithImage:(MWKImage *)image inPhotos:(NSArray<id<NYTPhoto>> *)photos {
    NSUInteger index = [self indexOfImage:image inPhotos:photos];
    if (index > photos.count) {
        return nil;
    }
    return photos[index];
}

+ (NSUInteger)indexOfImage:(MWKImage *)image inPhotos:(NSArray<id<NYTPhoto>> *)photos {
    return [photos
        indexOfObjectPassingTest:^BOOL(WMFArticlePhoto *anImage, NSUInteger _, BOOL *stop) {
            if ([anImage.imageObject isVariantOfImage:image] || [anImage.thumbnailImageObject isVariantOfImage:image]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
}

- (NSUInteger)indexOfImage:(MWKImage *)image {
    return [[self class] indexOfImage:image inPhotos:self.photos];
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.currentlyDisplayedPhoto) {
        [self fetchCurrentImageInfo];
        [self fetchCurrentImage];
    }
}

#pragma mark - Fetch

- (void)fetchCurrentImageInfo {
    [self fetchImageInfoForPhoto:(WMFArticlePhoto *)self.currentlyDisplayedPhoto];
}

- (void)fetchImageInfoForPhoto:(WMFArticlePhoto *)galleryImage {
    [self.infoController fetchBatchContainingIndex:[self indexOfPhoto:galleryImage]];
}

- (void)fetchCurrentImage {
    [self fetchImageForPhoto:(WMFArticlePhoto *)self.currentlyDisplayedPhoto];
}

- (void)fetchImageForPhoto:(WMFArticlePhoto *)galleryImage {
    UIImage *memoryCachedImage = [galleryImage memoryCachedImage];
    if (memoryCachedImage == nil) {
        @weakify(self);
        [[WMFImageController sharedInstance] fetchImageWithURL:[galleryImage imageURL]
            failure:^(NSError *_Nonnull error) {
                //show error
            }
            success:^(WMFImageDownload *_Nonnull download) {
                @strongify(self);
                [self updateImageForPhoto:galleryImage];
            }];
    } else {
        [self updateImageForPhoto:galleryImage];
    }
}

#pragma mark NYTPhotosViewControllerDelegate

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(id<NYTPhoto>)photo atIndex:(NSUInteger)photoIndex {
    WMFArticlePhoto *galleryImage = (WMFArticlePhoto *)photo;
    [self fetchImageInfoForPhoto:galleryImage];
    [self fetchImageForPhoto:galleryImage];
}

#pragma mark - WMFImageInfoControllerDelegate

- (void)imageInfoController:(WMFImageInfoController *)controller didFetchBatch:(NSRange)range {
    NSIndexSet *fetchedIndexes = [NSIndexSet indexSetWithIndexesInRange:range];

    [self.photos enumerateObjectsAtIndexes:fetchedIndexes
                                   options:0
                                usingBlock:^(WMFArticlePhoto *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                    MWKImageInfo *info = [controller infoForImage:[obj imageObject]];
                                    if (!info) {
                                        info = [controller infoForImage:[obj thumbnailImageObject]];
                                    }
                                    NSParameterAssert(info);
                                    obj.imageInfo = info;
                                    if ([self.currentlyDisplayedPhoto isEqual:obj]) {
                                        [self fetchImageForPhoto:obj];
                                    }
                                }];

    [self updateOverlayInformation];
}

- (void)imageInfoController:(WMFImageInfoController *)controller
         failedToFetchBatch:(NSRange)range
                      error:(NSError *)error {
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //display error image?
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    [self dismissViewControllerAnimated:YES completion:NULL];
    return YES;
}

@end

@interface WMFPOTDPhoto : NSObject <WMFPhoto>

//used to fetch imageInfo
@property (nonatomic, strong, nullable) NSDate *potdDate;

//set to display a thumbnail during download
@property (nonatomic, strong, nullable) MWKImageInfo *thumbnailImageInfo;

//used for metadaata
@property (nonatomic, strong, nullable) MWKImageInfo *imageInfo;

@end

@implementation WMFPOTDPhoto

+ (NSArray<WMFPOTDPhoto *> *)photosWithDates:(NSArray<NSDate *> *)dates {
    return [dates wmf_map:^id(NSDate *obj) {
        return [[WMFPOTDPhoto alloc] initWithPOTDDate:obj];
    }];
}

- (instancetype)initWithPOTDDate:(NSDate *)date {
    self = [super init];
    if (self) {
        self.potdDate = date;
    }
    return self;
}

- (nullable MWKImageInfo *)bestImageInfo {
    return self.imageInfo;
}

- (nullable NSURL *)bestImageURL {
    if (self.imageInfo) {
        return self.imageInfo.imageThumbURL;
    } else if (self.thumbnailImageInfo) {
        return self.thumbnailImageInfo.imageThumbURL;
    } else {
        return nil;
    }
}

- (nullable UIImage *)placeholderImage {
    NSURL *url = [self thumbnailImageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable NSURL *)thumbnailImageURL {
    return self.thumbnailImageInfo.imageThumbURL;
}

- (nullable UIImage *)image {
    NSURL *url = [self imageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable UIImage *)memoryCachedImage {
    NSURL *url = [self imageURL];
    if (url) {
        return [[[WMFImageController sharedInstance] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable NSURL *)imageURL {
    return self.imageInfo.imageThumbURL;
}

- (nullable NSData *)imageData {
    return nil;
}

- (nullable NSAttributedString *)attributedCaptionTitle {
    return nil;
}

- (nullable NSAttributedString *)attributedCaptionSummary {
    return nil;
}

- (nullable NSAttributedString *)attributedCaptionCredit {
    return nil;
}

@end

@interface WMFPOTDImageGalleryViewController ()

@property (nonatomic, strong) MWKImageInfoFetcher *infoFetcher;

@end

@implementation WMFPOTDImageGalleryViewController

- (instancetype)initWithDates:(NSArray<NSDate *> *)imageDates {
    NSParameterAssert(imageDates);
    NSArray *items = imageDates;
    NSArray<WMFPOTDPhoto *> *photos = [WMFPOTDPhoto photosWithDates:items];

    self = [super initWithPhotos:photos initialPhoto:nil delegate:nil];
    if (self) {
        self.infoFetcher = [[MWKImageInfoFetcher alloc] init];
    }

    return self;
}

- (MWKImageInfo *)imageInfoForPhoto:(id<NYTPhoto>)photo {
    return [(WMFPOTDPhoto *)photo bestImageInfo];
}

- (MWKImageInfo *)currentImageInfo {
    return [self imageInfoForPhoto:[self photoAtIndex:[self indexOfCurrentImage]]];
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.currentlyDisplayedPhoto) {
        [self fetchCurrentImageInfo];
    }
}

#pragma mark - Fetch

- (void)fetchCurrentImageInfo {
    [self fetchImageInfoForPhoto:(WMFPOTDPhoto *)self.currentlyDisplayedPhoto];
}

- (void)fetchImageInfoForIndex:(NSUInteger)index {
    WMFPOTDPhoto *galleryImage = (WMFPOTDPhoto *)[self photoAtIndex:index];
    [self fetchImageInfoForPhoto:galleryImage];
}

- (void)fetchImageInfoForPhoto:(WMFPOTDPhoto *)galleryImage {
    NSDate *date = [galleryImage potdDate];

    @weakify(self);
    [self.infoFetcher fetchPicOfTheDayGalleryInfoForDate:date
        metadataLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]
        failure:^(NSError *_Nonnull error) {
            //show error
        }
        success:^(id _Nonnull info) {
            @strongify(self);
            galleryImage.imageInfo = info;
            [self updateOverlayInformation];
            [self fetchImageForPhoto:galleryImage];
        }];
}

- (void)fetchImageForPhoto:(WMFPOTDPhoto *)galleryImage {
    @weakify(self);
    UIImage *memoryCachedImage = [galleryImage memoryCachedImage];
    if (memoryCachedImage == nil) {
        [[WMFImageController sharedInstance] fetchImageWithURL:[galleryImage bestImageURL]
            failure:^(NSError *_Nonnull error) {
                //show error
            }
            success:^(WMFImageDownload *_Nonnull download) {
                @strongify(self);
                [self updateImageForPhoto:galleryImage];
            }];
    } else {
        [self updateImageForPhoto:galleryImage];
    }
}

#pragma mark NYTPhotosViewControllerDelegate

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(id<NYTPhoto>)photo atIndex:(NSUInteger)photoIndex {
    WMFPOTDPhoto *galleryImage = (WMFPOTDPhoto *)photo;
    if (![galleryImage imageURL]) {
        [self fetchImageInfoForPhoto:galleryImage];
    } else if (![galleryImage memoryCachedImage]) {
        [self fetchImageForPhoto:galleryImage];
    }
}

@end

NS_ASSUME_NONNULL_END
