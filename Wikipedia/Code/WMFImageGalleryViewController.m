#import "WMFImageGalleryViewController.h"
@import WMF;
@import FLAnimatedImage;
@import NYTPhotoViewer;
#import "Wikipedia-Swift.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "UIViewController+WMFOpenExternalUrl.h"
#import "WMFImageGalleryDetailOverlayView.h"

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

- (NYTPhotoViewController *)currentPhotoViewController;

- (UIImageView *)currentImageView;

@property (nonatomic, strong) WMFTheme *theme;

@end

@interface WMFBasePhoto : NSObject

@property (nullable, nonatomic, strong) WMFTypedImageData *typedImageData;

@property (nullable, nonatomic, strong) NSString *imageDataUTType;

@property (nullable, nonatomic, strong) NSData *imageData;

//used for metadaata
@property (nonatomic, strong, nullable) MWKImageInfo *imageInfo;

@end

@interface WMFArticlePhoto : WMFBasePhoto <WMFPhoto>

//set to display a thumbnail during download
@property (nonatomic, strong, nullable) MWKImage *thumbnailImageObject;

//used to fetch the full size image
@property (nonatomic, strong, nullable) MWKImage *imageObject;

@end

@implementation WMFBasePhoto

- (nullable WMFTypedImageData *)typedImageData {
    @synchronized(self) {
        if (!_typedImageData) {
            NSURL *URL = self.imageInfo.canonicalFileURL;
            if (URL) {
                _typedImageData = [[WMFImageController sharedInstance] dataWithURL:URL];
            }
        }
        return _typedImageData;
    }
}

- (BOOL)isGIF {
    return [self.imageInfo.canonicalFileURL.absoluteString.lowercaseString hasSuffix:@".gif"];
}

- (nullable NSData *)imageData {
    return self.isGIF ? self.typedImageData.data : nil;
}

- (nullable NSString *)imageDataUTType {
    return self.isGIF ? (NSString *)kUTTypeGIF : nil;
}

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

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
        return [self.imageInfo imageURLForTargetWidth:[[UIScreen mainScreen] wmf_galleryImageWidthForScale]];
    } else {
        return nil;
    }
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

- (instancetype)initWithPhotos:(nullable NSArray<id<NYTPhoto>> *)photos initialPhoto:(nullable id<NYTPhoto>)initialPhoto delegate:(nullable id<NYTPhotosViewControllerDelegate>)delegate theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden {
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

        self.theme = theme;

        [self setOverlayViewTopBarHidden:overlayViewTopBarHidden];
    }
    return self;
}

- (void)setOverlayViewTopBarHidden:(BOOL)hidden {
    if (hidden) {
        self.overlayView.rightBarButtonItem = nil;
        self.overlayView.leftBarButtonItem = nil;
        self.overlayView.topCoverBackgroundColor = [UIColor clearColor];
    } else {
        self.overlayView.topCoverBackgroundColor = [UIColor blackColor];
        self.overlayView.navigationBar.backgroundColor = [UIColor clearColor];

        UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapShareButton)];
        share.tintColor = [UIColor whiteColor];
        self.overlayView.rightBarButtonItem = share;

        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapCloseButton)];
        close.tintColor = [UIColor whiteColor];
        close.accessibilityLabel = [WMFCommonStrings closeButtonAccessibilityLabel];
        self.overlayView.leftBarButtonItem = close;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
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
    if (!self.theme) {
        // don't do this elsewhere
        // self.theme needs to be set before the [super init] call
        // this is easiest way to do it for now
        self.theme = NSUserDefaults.wmf.wmf_appTheme;
    }
    vc.scalingImageView.imageView.alpha = self.theme.imageOpacity;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityIgnoresInvertColors = YES;
    // Very subtle gradient background so close and share buttons don't disappear when over white background parts of image.
    UIImage *gradientImage = [[UIImage imageNamed:@"gallery-top-gradient"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    [self.overlayView.navigationBar setBackgroundImage:gradientImage forBarMetrics:UIBarMetricsDefault];
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

            UIActivityViewController *vc = [[WMFShareActivityController alloc] initWithImageInfo:info imageDownload:download];
            vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList];
            UIPopoverPresentationController *presenter = [vc popoverPresentationController];
            presenter.barButtonItem = self.rightBarButtonItem;
            [self presentViewController:vc animated:YES completion:NULL];
        }];
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
    caption.imageDescriptionIsRTL = imageInfo.imageDescriptionIsRTL;

    caption.imageDescription =
        [imageInfo.imageDescription stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *ownerOrFallback = imageInfo.owner ? [imageInfo.owner stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                                : WMFLocalizedStringWithDefaultValue(@"image-gallery-unknown-owner", nil, nil, @"Author unknown.", @"Fallback text for when an item in the image gallery doesn't have a specified owner.");

    [caption setLicense:imageInfo.license owner:ownerOrFallback];

    @weakify(self)
    caption.ownerTapCallback = ^{
        @strongify(self)
        if (imageInfo.license.URL) {
            [self wmf_openExternalUrl:imageInfo.license.URL];
        }
    };
    caption.infoTapCallback = ^{
        @strongify(self)
        if (imageInfo.filePageURL) {
            [self wmf_openExternalUrl:imageInfo.filePageURL];
        }
    };
    @weakify(caption)
    caption.descriptionTapCallback = ^{
        [UIView animateWithDuration:0.3
                         animations:^{
                             @strongify(self)
                             @strongify(caption)
                             [caption toggleDescriptionOpenState];
                             [self.view layoutIfNeeded];
                         }
                         completion:NULL];
    };

    caption.maximumDescriptionHeight = self.view.frame.size.height;
    
    return caption;
}

- (void)updateImageForPhotoAfterUserInteractionIsFinished:(id<NYTPhoto> _Nullable)photo {
    //Exclude UITrackingRunLoopMode so the update doesn't happen while the user is pinching or scrolling
    [self performSelector:@selector(updateImageForPhoto:) withObject:photo afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    WMFImageGalleryDetailOverlayView *detailOverlayView = (WMFImageGalleryDetailOverlayView*)self.overlayView.captionView;
    detailOverlayView.maximumDescriptionHeight = size.height;
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
}

@end

#pragma clang diagnostic pop

@interface WMFArticleImageGalleryViewController ()

@property (nonatomic, strong) WMFImageInfoController *infoController;
@property (nonatomic, getter=areDownloadErrorAlertsDisabled) BOOL downloadErrorAlertsDisabled;
@end

@implementation WMFArticleImageGalleryViewController

- (nullable instancetype)initWithArticle:(MWKArticle *)article theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden {
    return [self initWithArticle:article selectedImage:nil theme:theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden];
}

- (nullable instancetype)initWithArticle:(MWKArticle *)article selectedImage:(nullable MWKImage *)image theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden {
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

    self = [super initWithPhotos:photos initialPhoto:selected delegate:nil theme:theme overlayViewTopBarHidden:overlayViewTopBarHidden];
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
                [self updateImageForPhotoAfterUserInteractionIsFinished:galleryImage];
            }];
    } else {
        [self updateImageForPhotoAfterUserInteractionIsFinished:galleryImage];
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
    if (self.areDownloadErrorAlertsDisabled) {
        return;
    }
    self.downloadErrorAlertsDisabled = YES; //only show one alert per gallery session
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    //display error image?
}

#pragma mark - Accessibility

- (BOOL)accessibilityPerformEscape {
    [self dismissViewControllerAnimated:YES completion:NULL];
    return YES;
}

#pragma mark - Peek & Pop

- (NSArray *)previewActionItems {
    UIPreviewAction *share = [UIPreviewAction actionWithTitle:[WMFCommonStrings shareActionTitle]
                                                        style:UIPreviewActionStyleDefault
                                                      handler:^(UIPreviewAction *_Nonnull action, UIViewController *_Nonnull previewViewController) {
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

                                                                  UIActivityViewController *vc = [[WMFShareActivityController alloc] initWithImageInfo:info imageDownload:download];
                                                                  vc.excludedActivityTypes = @[UIActivityTypeAddToReadingList];

                                                                  [self.imagePreviewingActionsDelegate shareImagePreviewActionSelectedWithImageController:(WMFImageGalleryViewController *)previewViewController shareActivityController:vc];
                                                              }];
                                                      }];
    return @[share];
}

@end

@interface WMFPOTDPhoto : WMFBasePhoto <WMFPhoto>

//used to fetch imageInfo
@property (nonatomic, strong, nullable) NSDate *potdDate;

//set to display a thumbnail during download
@property (nonatomic, strong, nullable) MWKImageInfo *thumbnailImageInfo;

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
    return self.imageURL;
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
    return [self.imageInfo imageURLForTargetWidth:[[UIScreen mainScreen] wmf_galleryImageWidthForScale]];
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

- (instancetype)initWithDates:(NSArray<NSDate *> *)imageDates theme:(WMFTheme *)theme overlayViewTopBarHidden:(BOOL)overlayViewTopBarHidden {
    NSParameterAssert(imageDates);
    NSArray *items = imageDates;
    NSArray<WMFPOTDPhoto *> *photos = [WMFPOTDPhoto photosWithDates:items];

    self = [super initWithPhotos:photos initialPhoto:nil delegate:nil theme:theme overlayViewTopBarHidden:overlayViewTopBarHidden];
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
                [self updateImageForPhotoAfterUserInteractionIsFinished:galleryImage];
            }];
    } else {
        [self updateImageForPhotoAfterUserInteractionIsFinished:galleryImage];
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
