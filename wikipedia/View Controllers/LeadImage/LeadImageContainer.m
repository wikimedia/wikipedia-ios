//  Created by Monte Hurd on 12/4/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageContainer.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "MWKSection+DisplayHtml.h"
#import "CommunicationBridge.h"
#import "NSObject+ConstraintsScale.h"
#import "LeadImageTitleLabel.h"
#import "UIScreen+Extras.h"
#import "QueuesSingleton.h"
#import "WMFFaceDetector.h"
#import "MWKArticle+isMain.h"
#import "UIView+Debugging.h"
#import "WebViewController.h"
#import "URLCache.h"
#import "WMFGeometry.h"
#import "UIImage+WMFFocalImageDrawing.h"
#import "MWKArticle+Convenience.h"

static const CGFloat kPlaceHolderImageAlpha                   = 0.3f;
static const CGFloat kMinimumAcceptableCachedVariantThreshold = 0.6f;

/*
   When YES this causes lead image faces to be highlighted in green and
   simulator "Command-Shift-M" taps to cycle through the faces, shifting
   the image to best center the currently hightlighted face.
   Do *not* leave this set to YES for release.
 */
#if DEBUG
#define ENABLE_FACE_DETECTION_DEBUGGING 0
#else
// disable in release builds
#define ENABLE_FACE_DETECTION_DEBUGGING 0
#endif

@interface LeadImageContainer ()

#pragma mark - Private properties

@property (weak, nonatomic) IBOutlet UIView* titleDescriptionContainer;
@property (weak, nonatomic) IBOutlet LeadImageTitleLabel* titleLabel;
@property (strong, nonatomic) UIImage* image;
@property(strong, nonatomic) MWKArticle* article;
@property (nonatomic) BOOL isPlaceholder;
@property(strong, nonatomic) id rotationObserver;
@property (nonatomic) CGFloat height;
@property (nonatomic) BOOL isFaceDetectionNeeded;
@property (strong, nonatomic) WMFFaceDetector* faceDetector;
@property (strong, nonatomic) NSData* placeholderImageData;
@property (nonatomic, strong) dispatch_queue_t serialFaceDetectionQueue;
@property (nonatomic) CGRect focalFaceBounds;
@property (nonatomic) BOOL shouldHighlightFace;

@end

@implementation LeadImageContainer

#pragma mark - Setup

- (void)awakeFromNib {
    [self setupSerialFaceDetectionQueue];

    self.focalFaceBounds       = CGRectZero;
    self.shouldHighlightFace   = ENABLE_FACE_DETECTION_DEBUGGING;
    self.image                 = nil;
    self.faceDetector          = [[WMFFaceDetector alloc] init];
    self.isFaceDetectionNeeded = NO;
    self.height                = LEAD_IMAGE_CONTAINER_HEIGHT;
    self.isPlaceholder         = NO;
    self.clipsToBounds         = YES;
    self.backgroundColor       = [UIColor clearColor];
    self.placeholderImageData  = UIImagePNGRepresentation([UIImage imageNamed:@"lead-default"]);
    [self adjustConstraintsScaleForViews:@[self.titleLabel]];

    self.rotationObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* notification) {
        [self updateNonImageElements];
    }];

    #if ENABLE_FACE_DETECTION_DEBUGGING
    [self debugSetupToggle];
    #endif

    // Important! "clipsToBounds" must be "NO" so super long titles lay out properly!
    self.clipsToBounds = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewRetrievedAnImage:) name:@"SectionImageRetrieved" object:nil];

    //[self randomlyColorSubviews];
}

- (void)setupSerialFaceDetectionQueue {
    // Low priority serial dispatch queue. From http://stackoverflow.com/a/17690878/135557
    // Images intercepted from web view need to have face detection ran
    // serially to avoid running face detection more than necessary.
    self.serialFaceDetectionQueue = dispatch_queue_create("org.wikimedia.wikipedia.LeadImageContainer.faceDetector.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t low = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_set_target_queue(self.serialFaceDetectionQueue, low);
}

#pragma mark - WebView image retrieval interception

- (void)webViewRetrievedAnImage:(NSNotification*)notification {
    // Notification received each time the web view retrieves an image.

    if (![NAV.topViewController isMemberOfClass:[WebViewController class]]) {
        return;
    }

    BOOL (^ notificationContainsImage)(NSNotification*) = ^BOOL (NSNotification* n) {
        return (
            n.userInfo[kURLCacheKeyFileNameNoSizePrefix]
            &&
            n.userInfo[kURLCacheKeyWidth]
            &&
            n.userInfo[kURLCacheKeyData]
            );
    };

    if (notificationContainsImage(notification)) {
        if ([self isRetrievedImageVariantOfLeadImage:notification.userInfo[kURLCacheKeyFileNameNoSizePrefix]]) {
            if (self.isPlaceholder || [self isRetrievedImageWiderThanLeadImage:notification.userInfo[kURLCacheKeyWidth]]) {
                NSLog(@"INTERCEPTED WEBVIEW IMAGE of width: %@", notification.userInfo[kURLCacheKeyWidth]);
                [self showImage:notification.userInfo[kURLCacheKeyData] isPlaceHolder:NO];
            }
        }
    }
}

- (BOOL)isRetrievedImageWiderThanLeadImage:(NSString*)retrievedImageWidth {
    return (retrievedImageWidth.floatValue > self.image.size.width);
}

- (BOOL)isRetrievedImageVariantOfLeadImage:(NSString*)retrievedImageNameNoSizePrefix {
    return ([self.article.image.fileNameNoSizePrefix isEqualToString:retrievedImageNameNoSizePrefix]);
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if ([self shouldHideImage]) {
        return;
    }
    if ((self.image.size.width == 0) || (self.image.size.height == 0)) {
        return;
    }

    // Draw gradient first so when image is drawn with kCGBlendModeMultiply
    // the gradient will look smooth.
    [self drawGradientBackground];

    CGFloat alpha = self.isPlaceholder ? kPlaceHolderImageAlpha : 1.0;

    // Draw lead image, aspect fill, align top, vertically centering
    // focalFaceBounds face if necessary.
    [self.image wmf_drawInRect:rect
                   focalBounds:WMFRectFromUnitRectForReferenceSize(self.focalFaceBounds, self.image.size)
                focalHighlight:self.shouldHighlightFace
                     blendMode:kCGBlendModeMultiply
                         alpha:alpha];
}

- (void)drawGradientBackground {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context       = UIGraphicsGetCurrentContext();

    void (^ drawGradient)(CGFloat, CGFloat, CGRect) = ^void (CGFloat upperAlpha, CGFloat bottomAlpha, CGRect rect) {
        CGFloat locations[] = {
            0.0,  // Upper color stop.
            1.0   // Bottom color stop.
        };
        CGFloat colorComponents[8] = {
            0.0, 0.0, 0.0, upperAlpha,  // Upper color.
            0.0, 0.0, 0.0, bottomAlpha  // Bottom color.
        };
        CGGradientRef gradient =
            CGGradientCreateWithColorComponents(colorSpace, colorComponents, locations, 2);
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGPoint endPoint   = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGGradientRelease(gradient);
    };

    // Note: the gradient is purposely drawn in 2 parts. One part for the label, and one
    // for the part above the label. This is done instead of adding multiple locations
    // to a single gradient because it allows the part above the label to fade to
    // transparent at the top in a way that doesn't darken the part above the label as
    // much as a single multiple location gradient. If you tweak anything about this, be
    // sure to test before/after w/ light background images to make sure things aren't
    // darkened too much.

    CGFloat alphaTop    = 0.0;
    CGFloat alphaMid    = 0.1;
    CGFloat alphaBottom = 0.5;

    CGFloat aboveLabelY = self.frame.size.height - self.titleDescriptionContainer.frame.size.height;

    // Shift the meeting point of the 2 gradients up a bit.
    CGFloat centerlineDrift = -aboveLabelY / 3.0;

    CGFloat meetingY = aboveLabelY + centerlineDrift;

    // Draw gradient fading black of alpha 0.0 at top of image to black at alpha 0.4 at top of label.
    CGRect topGradientRect =
        (CGRect){
        {0, 0},
        {self.titleDescriptionContainer.frame.size.width, meetingY}
    };
    drawGradient(alphaTop, alphaMid, topGradientRect);

    // Draw gradient fading black of alpha 0.4 at top of label to black at alpha 1.0 at bottom of label.
    CGRect bottomGradientRect =
        (CGRect){
        {self.titleDescriptionContainer.frame.origin.x, meetingY},
        {self.titleDescriptionContainer.frame.size.width, self.titleDescriptionContainer.frame.size.height - centerlineDrift}
    };
    drawGradient(alphaMid, alphaBottom, bottomGradientRect);

    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Layout

- (void)updateNonImageElements {
    // Updates title/description text color.
    [self updateTitleColors];

    // Updates height of this view and of the webView's placeholer div.
    [self updateHeights];

    [self setNeedsDisplay];
}

- (void)updateHeights {
    // First update title/description and container layout so correct
    // dimensions are available for current title and description text.
    [self.titleLabel layoutIfNeeded];
    [self.titleDescriptionContainer layoutIfNeeded];

    self.height = ([self shouldHideImage]) ? self.titleDescriptionContainer.frame.size.height : LEAD_IMAGE_CONTAINER_HEIGHT;

    // Notify the layout system that the height has changed.
    [self invalidateIntrinsicContentSize];

    // Now notify the web view of the height change.
    [self.delegate leadImageHeightChangedTo:@(self.height)];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, self.height);
}

- (void)updateTitleColors {
    UIColor* textColor   = [UIColor whiteColor];
    UIColor* shadowColor = [UIColor colorWithWhite:0.0f alpha:0.08];
    //shadowColor = [UIColor redColor]; // Use for testing shadow

    if ([self shouldHideImage]) {
        textColor   = [UIColor blackColor];
        shadowColor = [UIColor clearColor];
    }

    self.titleLabel.textColor   = textColor;
    self.titleLabel.shadowColor = shadowColor;
}

#pragma mark - Flags

- (BOOL)shouldHideImage {
    return
        UIInterfaceOrientationIsLandscape([[UIScreen mainScreen] interfaceOrientation])
        ||
        ![self imageExists];
}

- (BOOL)imageExists {
    return (!self.article.isMain && self.article.imageURL && ![self isGifUrl:self.article.imageURL]) ? YES : NO;
}

- (BOOL)isGifUrl:(NSString*)url {
    return (url.pathExtension && [url.pathExtension isEqualToString:@"gif"]) ? YES : NO;
}

#pragma mark - Show

- (void)showForArticle:(MWKArticle*)article {
    self.article                = article;
    self.focalFaceBounds        = CGRectZero;
    self.titleLabel.imageExists = [self imageExists];
    self.image                  = nil;
    self.isFaceDetectionNeeded  = YES;

    if (self.article.isMain) {
        [self.titleLabel setTitle:@"" description:@""];
        [self updateNonImageElements];
        return;
    } else {
        NSString* title = [self.article.displaytitle getStringWithoutHTML];
        [self.titleLabel setTitle:title description:[self getCurrentArticleDescription]];
    }

    // Show largest cached variant of lead image, or placeholder, immediately.
    // This image is shown until the webview (potentially) retrieves higher resolution variants.
    MWKImage* largestCachedVariant = self.article.image.largestCachedVariant;
    if (largestCachedVariant) {
        NSLog(@"SHOWING LARGEST CACHED VARIANT of width: %f", largestCachedVariant.width.floatValue);
        [self showImage:[largestCachedVariant asNSData] isPlaceHolder:NO];
    } else {
        [self showImage:self.placeholderImageData isPlaceHolder:YES];
    }

    if (![self isLargestCachedVariantSufficient:largestCachedVariant]) {
        (void)[[ThumbnailFetcher alloc] initAndFetchThumbnailFromURL:[@"http:" stringByAppendingString:self.article.imageURL]
                                                         withManager:[QueuesSingleton sharedInstance].articleFetchManager
                                                  thenNotifyDelegate:self];
    }
}

- (BOOL)isLargestCachedVariantSufficient:(MWKImage*)largestCachedVariant {
    if (![largestCachedVariant isEqualToImage:self.article.image]) {
        CGFloat okMinimumWidth = LEAD_IMAGE_WIDTH * kMinimumAcceptableCachedVariantThreshold;
        if (largestCachedVariant.width.floatValue < okMinimumWidth) {
            if (self.article.imageURL) {
                NSInteger widestExpectedImageWidth = [self widthOfWidestVariantWebViewWillDownload];
                if (widestExpectedImageWidth < okMinimumWidth) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (void)showImage:(NSData*)retrievedImageData isPlaceHolder:(BOOL)isPlaceHolder {
    self.isPlaceholder = isPlaceHolder;

    // Face detection is faster if the UIImage has CIImage backing.
    CIImage* ciImage = [[CIImage alloc] initWithData:retrievedImageData];
    self.image = [UIImage imageWithCIImage:ciImage];

    [self detectFaceWithCompletionBlock:^{
        [self updateNonImageElements];
    }];
}

- (NSInteger)widthOfWidestVariantWebViewWillDownload {
    MWKImage* widestUncachedVariant = nil;
    NSArray* arr                    = [self.article.images imageSizeVariants:self.article.imageURL];
    for (NSString* variantURL in [arr reverseObjectEnumerator]) {
        MWKImage* image = [self.article imageWithURL:variantURL];
        // Must exclude article.image because it is not retrieved by the web view
        // (it's the thing we're deciding if we need to download!)
        if (![image isEqualToImage:self.article.image]) {
            if (!image.isCached) {
                widestUncachedVariant = image;
                break;
            }
        }
    }
    if (widestUncachedVariant) {
        // Parse the width out of the url - necessary because the image probably hasn't been
        // retrieved yet, so width and height properties won't be set yet.
        // Note: occasionally images don't have size prefix in their file name, so for these
        // images we won't be able to divine ahead of time whether among the images to be
        // downloaded by the webview there will be one of sufficient resolution. In these
        // cases it's ok because the higher res image will be fetched with the ThumbnailFetcher.
        return [MWKImage fileSizePrefix:widestUncachedVariant.sourceURL];
    }
    return -1;
}

#pragma mark - Fetch finished

- (void)fetchFinished:(id)sender
          fetchedData:(id)fetchedData
               status:(FetchFinalStatus)status
                error:(NSError*)error {
    if ([sender isKindOfClass:[ThumbnailFetcher class]]) {
        switch (status) {
            case FETCH_FINAL_STATUS_SUCCEEDED:
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    // Associate the image retrieved with article.image.
                    ThumbnailFetcher* fetcher = (ThumbnailFetcher*)sender;

                    MWKImage* articleImage = [self.article importImageURL:fetcher.url
                                                                imageData:fetchedData];

                    NSLog(@"FETCHED HIGHER RES VARIANT of width: %f", articleImage.width.floatValue);

                    [self showImage:[articleImage asNSData] isPlaceHolder:NO];
                });
            }
            break;
            case FETCH_FINAL_STATUS_FAILED:
            {
            }
            break;
            case FETCH_FINAL_STATUS_CANCELLED:
            {
            }
            break;
        }
    }
}

#pragma mark - Description

- (NSString*)getCurrentArticleDescription {
    NSString* description = self.article.entityDescription;
    if (description) {
        description = [self.article.entityDescription getStringWithoutHTML];
        description = [description capitalizeFirstLetter];
    }
    return description;
}

#pragma mark - Face detection

- (void)detectFaceWithCompletionBlock:(void (^)())block {
    if (!self.isFaceDetectionNeeded || self.isPlaceholder) {
        [self asyncDispatchBlockToMainQueue:block];
        return;
    }

    UIImage* imageToDetect = self.image; // Ensure async block is working on this size variant.
    dispatch_async(self.serialFaceDetectionQueue, ^{
        if (self.isFaceDetectionNeeded) { // Re-check in case it changed since block was dispatched.
            self.faceDetector.image = imageToDetect;
            CGRect faceBounds = [self.faceDetector detectFace];

            BOOL faceDetected = !CGRectIsEmpty(faceBounds);

            // Store as unit rect so we don't have to re-run face detection on subsequently retrieved size variants
            self.focalFaceBounds = WMFUnitRectFromRectForReferenceSize(faceBounds, imageToDetect.size);

            if (faceDetected) {
                self.isFaceDetectionNeeded = NO;
            }
        }
        [self asyncDispatchBlockToMainQueue:block];
    });
}

- (void)asyncDispatchBlockToMainQueue:(void (^)())block {
#warning TODO: - this should live in a "dispatch utilities" file, and not an ObjC instance method

    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

#pragma mark - Easy face detection debugging

- (void)debugSetupToggle {
    // Testing code so we can hit "Command-Shift-M" to toggle through focal images.
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* notification) {
        [self debugDetectNextFace];
    }];
}

- (void)debugDetectNextFace {
    // Ensure detector is set to last image retrieved. Detector may have
    // successfully detected large face in an earlier low res image, but
    // current image may be higher res. See "Madonna del Granduca" enwiki
    // article. Without this only the mother's face available in cycle as
    // it is the only one detected when the first low-res variant is
    // retrieved.
    if (self.faceDetector.image != self.image) {
        self.faceDetector.image = self.image;
    }

    // Repeated calls to detectNextFace returns next face bounds each time.
    self.focalFaceBounds = WMFUnitRectFromRectForReferenceSize([self.faceDetector detectFace], self.faceDetector.image.size);
    [self setNeedsDisplay];
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.rotationObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
