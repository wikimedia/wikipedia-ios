#import "WMFImageGalleryViewController.h"
@import WMF;
#import "Wikipedia-Swift.h"
#import "MWKImageInfoFetcher+PicOfTheDayInfo.h"
#import "WMFImageGalleryDetailOverlayView.h"
@import CoreServices;

// SINGLETONTODO - this whole file, find [MWKDataStore shared]

NS_ASSUME_NONNULL_BEGIN

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

@interface WMFImageGalleryViewController ()

@property (nonatomic, strong, readonly) NSArray<id<NYTPhoto>> *photos;

@property (nonatomic, readonly) id<WMFExposedDataSource> dataSource;

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

//@interface WMFArticlePhoto : WMFBasePhoto <WMFPhoto>
//
////set to display a thumbnail during download
//@property (nonatomic, strong, nullable) NSURL *thumbnailImageURL;
//
////used to fetch the full size image
//@property (nonatomic, strong, nullable) NSURL *imageURL;
//
//@end

@implementation WMFBasePhoto

- (nullable WMFTypedImageData *)typedImageData {
    @synchronized(self) {
        if (!_typedImageData) {
            NSURL *URL = self.imageInfo.canonicalFileURL;
            if (URL) {
                _typedImageData = [[[MWKDataStore shared] cacheController] imageDataWithURL:URL];
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
        self.theme = [NSUserDefaults.standardUserDefaults themeCompatibleWith:self.traitCollection];
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
    NSInteger targetWidth = [self.traitCollection wmf_galleryImageWidth];
    NSURL *url = [info imageURLForTargetWidth:targetWidth];

    @weakify(self);
    [[[MWKDataStore shared] cacheController] fetchImageWithURL:url
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

    @weakify(self);
    caption.ownerTapCallback = ^{
        @strongify(self);
        if (imageInfo.license.URL) {
            [self wmf_navigateToURL:imageInfo.license.URL.wmf_urlByPrependingSchemeIfSchemeless];
        } else if (imageInfo.filePageURL) {
            [self wmf_navigateToURL:imageInfo.filePageURL.wmf_urlByPrependingSchemeIfSchemeless];
        } else {
            // There should always be a file page URL, but log an error anyway
            DDLogError(@"No license URL or file page URL for %@", imageInfo);
        }
    };
    caption.infoTapCallback = ^{
        @strongify(self);
        if (imageInfo.filePageURL) {
            [self wmf_navigateToURL:imageInfo.filePageURL.wmf_urlByPrependingSchemeIfSchemeless];
        }
    };
    @weakify(caption);
    caption.descriptionTapCallback = ^{
        [UIView animateWithDuration:0.3
                         animations:^{
                             @strongify(self);
                             @strongify(caption);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(updateImageForPhoto:) withObject:photo afterDelay:0 inModes:@[NSDefaultRunLoopMode]];
    });
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIView *maybeDetailOverlayView = self.overlayView.captionView;
    if (![maybeDetailOverlayView isKindOfClass:[WMFImageGalleryDetailOverlayView class]]) {
        return;
    }
    WMFImageGalleryDetailOverlayView *detailOverlayView = (WMFImageGalleryDetailOverlayView *)maybeDetailOverlayView;
    detailOverlayView.maximumDescriptionHeight = size.height;
}

#pragma mark - WMFThemeable

- (void)applyTheme:(WMFTheme *)theme {
    self.theme = theme;
}

@end

#pragma clang diagnostic pop

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
        return [[[[MWKDataStore shared] cacheController] cachedImageWithURL:url] staticImage];
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
        return [[[[MWKDataStore shared] cacheController] cachedImageWithURL:url] staticImage];
    } else {
        return nil;
    }
}

- (nullable UIImage *)memoryCachedImage {
    NSURL *url = [self imageURL];
    if (url) {
        return [[[[MWKDataStore shared] cacheController] cachedImageWithURL:url] staticImage];
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
        // SINGLETONTODO
        self.infoFetcher = [[MWKImageInfoFetcher alloc] initWithDataStore:[MWKDataStore shared]];
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
            UIViewController *vcToPresentError = [self presentingViewController];
            [self dismissViewControllerAnimated:true completion:^{
                [vcToPresentError wmf_showAlertWithError:error];
            }];
        }
        success:^(id _Nonnull info) {
            @strongify(self);
            galleryImage.imageInfo = info;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateOverlayInformation];
                [self fetchImageForPhoto:galleryImage];
            });
        }];
}

- (void)fetchImageForPhoto:(WMFPOTDPhoto *)galleryImage {
    @weakify(self);
    UIImage *memoryCachedImage = [galleryImage memoryCachedImage];
    if (memoryCachedImage == nil) {
        
        [[[MWKDataStore shared] cacheController] fetchImageWithURL:[galleryImage bestImageURL]
        failure:^(NSError *_Nonnull error) {
            if (error) {
                //show error
                return;
            }
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
