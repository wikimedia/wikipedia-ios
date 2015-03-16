//
//  WMFImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageGalleryViewController.h"

// Utils
#import <BlocksKit/BlocksKit.h>
#import "NSArray+BKIndex.h"
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"

// View
#import <Masonry/Masonry.h>
#import "WMFImageGalleryCollectionViewCell.h"
#import "WMFImageGalleryDetailOverlayView.h"
#import "UIFont+WMFStyle.h"
#import "WikiGlyph_Chars.h"
#import "UICollectionViewFlowLayout+NSCopying.h"
#import "UICollectionViewFlowLayout+WMFItemSizeThatFits.h"
#import "UIViewController+Alert.h"
#import "UICollectionViewFlowLayout+AttributeUtils.h"
#import "UILabel+WMFStyling.h"
#import "UIButton+FrameUtils.h"
#import "UIView+WMFFrameUtils.h"
#import "WMFGradientView.h"

// Model
#import "MWKDataStore.h"
#import "MWKImage.h"
#import "MWKLicense+ToGlyph.h"
#import "MWKImageInfo+MWKImageComparison.h"
#import "MWKArticle+Convenience.h"

// Networking
#import <AFNetworking/AFNetworking.h>
#import "AFHTTPRequestOperationManager+WMFConfig.h"
#import "AFHTTPRequestOperationManager+UniqueRequests.h"
#import "MWKImageInfoFetcher.h"
#import "MWKImageInfoResponseSerializer.h"

#if 1
#define ImgGalleryLog(...) NSLog(__VA_ARGS__)
#else
#define ImgGalleryLog(...)
#endif

static double const WMFImageGalleryTopGradientHeight = 150.0;

NSDictionary* WMFIndexImageInfo(NSArray* imageInfo){
    return [imageInfo bk_index:^id < NSCopying > (MWKImageInfo* info) {
        return info.imageAssociationValue ? : [NSNull null];
    }];
}

@interface WMFImageGalleryViewController ()
<UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) BOOL didApplyInitialVisibleImageIndex;
@property (nonatomic, getter = isChromeHidden) BOOL chromeHidden;

@property (nonatomic, weak, readonly) UICollectionViewFlowLayout* collectionViewFlowLayout;
@property (nonatomic, weak, readonly) UIButton* closeButton;
@property (nonatomic, weak, readonly) WMFGradientView* topGradientView;

@property (nonatomic, weak, readonly) UITapGestureRecognizer* chromeTapGestureRecognizer;

@property (nonatomic, strong, readonly) AFHTTPRequestOperationManager* imageFetcher;
@property (nonatomic, strong, readonly) MWKImageInfoFetcher* imageInfoFetcher;

/// Array of the article's images without duplicates in order of appearance.
@property (nonatomic, strong, readonly) NSArray* uniqueArticleImages;

/// Map of canonical filenames to image info objects.
@property (nonatomic, strong, readonly) NSDictionary* indexedImageInfo;

/// Map of URLs to bitmaps, serves as a simple cache for uncompressed images.
// !!!: This means we're store image data in 2 different memory locations, but we save a lot of time by not decoding
@property (nonatomic, strong, readonly) NSMutableDictionary* bitmapsForImageURL;

- (MWKDataStore*)dataStore;

@end

static NSString* const WMFImageGalleryCollectionViewCellReuseId = @"WMFImageGalleryCollectionViewCellReuseId";

@implementation WMFImageGalleryViewController
@synthesize imageInfoFetcher    = _imageInfoFetcher;
@synthesize imageFetcher        = _imageFetcher;
@synthesize indexedImageInfo    = _indexedImageInfo;
@synthesize uniqueArticleImages = _uniqueArticleImages;

- (instancetype)initWithArticle:(MWKArticle*)article {
    // TODO(bgerstle): use non-zero inset, disable bouncing, and customize scroll target to land images in center
    UICollectionViewFlowLayout* defaultLayout = [[UICollectionViewFlowLayout alloc] init];
    defaultLayout.sectionInset            = UIEdgeInsetsZero;
    defaultLayout.minimumInteritemSpacing = 0.f;
    defaultLayout.minimumLineSpacing      = 0.f;
    defaultLayout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
    // itemSize is based on view bounds, so we need to wait until it is about to appear to set it

    self = [super initWithCollectionViewLayout:defaultLayout];
    if (self) {
        _article            = article;
        _bitmapsForImageURL = [NSMutableDictionary dictionaryWithCapacity:[_uniqueArticleImages count]];
        _chromeHidden       = NO;
    }
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.bitmapsForImageURL removeAllObjects];
}

#pragma mark - Getters

- (NSArray*)uniqueArticleImages {
    if (!_uniqueArticleImages) {
        _uniqueArticleImages = [WikipediaAppUtils isDeviceLanguageRTL] ?
                               [[[self.article.images uniqueLargestVariants] reverseObjectEnumerator] allObjects]
                               : [self.article.images uniqueLargestVariants];
    }
    return _uniqueArticleImages;
}

- (NSDictionary*)indexedImageInfo {
    if (!_indexedImageInfo) {
        _indexedImageInfo = WMFIndexImageInfo([self.dataStore imageInfoForArticle:self.article]);
    }
    return _indexedImageInfo;
}

- (AFHTTPRequestOperationManager*)imageFetcher {
    if (!_imageFetcher) {
        _imageFetcher                    = [AFHTTPRequestOperationManager wmf_createDefaultManager];
        _imageFetcher.responseSerializer = [AFImageResponseSerializer serializer];
    }
    return _imageFetcher;
}

- (MWKImageInfoFetcher*)imageInfoFetcher {
    if (!_imageInfoFetcher) {
        _imageInfoFetcher = [[MWKImageInfoFetcher alloc] initWithDelegate:nil];
    }
    return _imageInfoFetcher;
}

- (MWKDataStore*)dataStore {
    return self.article.dataStore;
}

- (UICollectionViewFlowLayout*)collectionViewFlowLayout {
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    if ([flowLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return flowLayout;
    } else if (flowLayout) {
        [NSException raise:@"InvalidCollectionViewLayoutSubclass"
                    format:@"%@ expected %@ to be a subclass of %@",
         self, flowLayout, NSStringFromClass([UICollectionViewFlowLayout class])];
    }
    return nil;
}

- (NSUInteger)mostVisibleItemIndex {
    return [self.collectionViewFlowLayout wmf_indexPathClosestToContentOffset].item;
}

#pragma mark - Networking & Persistence

- (void)fetchImageInfo {
    [[MWNetworkActivityIndicatorManager sharedManager] push];
    AFHTTPRequestOperation* requestOperation = [self.imageInfoFetcher fetchInfoForArticle:self.article];
    requestOperation.completionQueue = dispatch_get_main_queue();

    __weak WMFImageGalleryViewController* weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation* operation, id responseObject) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        WMFImageGalleryViewController* strSelf = weakSelf;
        if (!strSelf) {
            return;
        }
        // persist to disk then update UI
        [[strSelf dataStore] saveImageInfo:operation.responseObject forArticle:strSelf.article];
        [strSelf updateImageInfo:operation.responseObject];
    } failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        [[MWNetworkActivityIndicatorManager sharedManager] pop];
        WMFImageGalleryViewController* strSelf = weakSelf;
        BOOL wasCancelled = [operation.error.domain isEqualToString:NSURLErrorDomain]
                            && operation.error.code == NSURLErrorCancelled;
        if (strSelf && !wasCancelled) {
            [strSelf showAlert:error.localizedDescription type:ALERT_TYPE_TOP duration:-1];
        }
    }];
}

- (void)updateImageInfo:(NSArray*)imageInfo {
    _indexedImageInfo = WMFIndexImageInfo(imageInfo);
    [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
}

#pragma mark - View event handling

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    NSUInteger const currentImageIndex = [self mostVisibleItemIndex];
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
        [self.collectionViewFlowLayout invalidateLayout];
    }
                     completion:^(BOOL finished) {
        [self setVisibleImageIndex:currentImageIndex animated:NO forceViewUpdate:YES];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    /*
       only apply visible image index once the collection view has been populated with cells, otherwise calls to get
       layout attributes of the item at `visibleImageIndex` will return `nil` (on iOS 6, at least)
     */
    if (!self.didApplyInitialVisibleImageIndex && self.collectionView.visibleCells.count) {
        [self applyVisibleImageIndex:NO];
        /*
           only set the flag *after* the visible index has been updated, to make sure UICollectionViewDelegate callbacks
           don't override it
         */
        self.didApplyInitialVisibleImageIndex = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // fetch after appearing so we don't do work while the animation is rendering
    [self fetchImageInfo];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    WMFGradientView* topGradientView = [WMFGradientView new];
    topGradientView.userInteractionEnabled = NO;
    [topGradientView.gradientLayer setLocations:@[@0, @1]];
    [topGradientView.gradientLayer setColors:@[(id)[UIColor colorWithWhite:0.0 alpha:1.0].CGColor,
                                               (id)[UIColor clearColor].CGColor]];
    // default start/end points, to be adjusted w/ image size
    [topGradientView.gradientLayer setStartPoint:CGPointMake(0.5, 0.0)];
    [topGradientView.gradientLayer setEndPoint:CGPointMake(0.5, 1.0)];
    [self.view addSubview:topGradientView];
    _topGradientView = topGradientView;

    [self.topGradientView mas_makeConstraints:^(MASConstraintMaker* make) {
        make.top.equalTo(self.view.mas_top);
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        make.height.mas_equalTo(WMFImageGalleryTopGradientHeight);
    }];

    UIButton* closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
    // the title must be set first!
    closeButton.titleLabel.font = [UIFont wmf_glyphFontOfSize:22.f];
    [closeButton setTitle:WIKIGLYPH_X forState:UIControlStateNormal];

    // apply visual effects
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [closeButton.titleLabel wmf_applyDropShadow];

    // setup actions
    [closeButton addTarget:self
                    action:@selector(didTouchCloseButton:)
          forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:closeButton];
    _closeButton = closeButton;

    [self.closeButton mas_makeConstraints:^(MASConstraintMaker* make) {
        // size is doubled to increase hit area
        float const sizeScaleFactor = 2.f;
        CGSize const glyphIntrinsicSize = [self.closeButton.titleLabel intrinsicContentSize];
        CGSize const glyphScaledSize = CGSizeMake(glyphIntrinsicSize.width * sizeScaleFactor,
                                                  glyphIntrinsicSize.height * sizeScaleFactor);
        make.size.mas_equalTo(glyphScaledSize);

        // these offsets account for padding in the glyph
        // TODO: centralize/standardize glyph offsets
        float const glyphHorizPadding = glyphIntrinsicSize.width * 0.25;
        float const glyphVertPadding = glyphIntrinsicSize.height * 0.25;

        /*
           align "x" with 20pt leading offset, same as cell's image description. need to account for extra-hit-area
           padding as well as the glyph's intrinsic padding
         */
        make.leading.equalTo(self.view.mas_leading).with.offset(20.f
                                                                - glyphIntrinsicSize.width / 2.f
                                                                - glyphHorizPadding);
        // top of "x" is 10 pts from the top of the view
        make.top.equalTo(self.view.mas_top).with.offset(10.f
                                                        - glyphIntrinsicSize.height / 2.f
                                                        - glyphVertPadding);
    }];

    UITapGestureRecognizer* chromeTapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];

    // make sure taps don't interfere w/ other gestures
    chromeTapGestureRecognizer.delaysTouchesBegan   = NO;
    chromeTapGestureRecognizer.delaysTouchesEnded   = NO;
    chromeTapGestureRecognizer.cancelsTouchesInView = NO;
    chromeTapGestureRecognizer.delegate             = self;

    // NOTE(bgerstle): recognizer must be added to collection view so as to not disrupt interactions w/ overlay UI
    [self.collectionView addGestureRecognizer:chromeTapGestureRecognizer];
    _chromeTapGestureRecognizer = chromeTapGestureRecognizer;

    self.collectionView.backgroundColor = [UIColor blackColor];
    [self.collectionView registerClass:[WMFImageGalleryCollectionViewCell class]
            forCellWithReuseIdentifier:WMFImageGalleryCollectionViewCellReuseId];
    self.collectionView.pagingEnabled = YES;
}

#pragma mark - Chrome

- (void)didTapView:(UITapGestureRecognizer*)sender {
    [self toggleChromeHidden:YES];
}

- (void)toggleChromeHidden:(BOOL)animated {
    [self setChromeHidden:![self isChromeHidden] animated:animated];
}

- (void)setChromeHidden:(BOOL)hidden {
    [self setChromeHidden:hidden animated:NO];
}

- (void)setChromeHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_chromeHidden == hidden) {
        return;
    }
    _chromeHidden = hidden;
    [self applyChromeHidden:animated];
}

- (void)applyChromeHidden:(BOOL)animated {
    dispatch_block_t animations = ^{
        self.topGradientView.hidden = [self isChromeHidden];
        self.closeButton.hidden     = [self isChromeHidden];
        for (NSIndexPath* indexPath in self.collectionView.indexPathsForVisibleItems) {
            [self updateDetailVisibilityForCellAtIndexPath:indexPath];
        }
    };

    if (animated) {
        [UIView animateWithDuration:[CATransaction animationDuration]
                              delay:0
                            options:UIViewAnimationOptionTransitionCrossDissolve
                         animations:animations
                         completion:nil];
    } else {
        animations();
    }
}

#pragma mark - Dismissal

- (void)didTouchCloseButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Visible Image Index

- (void)applyVisibleImageIndex:(BOOL)animated {
    if ([self isViewLoaded]) {
        // can't use scrollToItem because it doesn't handle post-rotation scrolling well on iOS 6
        UICollectionViewLayoutAttributes* visibleImageAttributes =
            [self.collectionViewFlowLayout layoutAttributesForItemAtIndexPath:
             [NSIndexPath indexPathForItem:self.visibleImageIndex inSection:0]];
        NSAssert(visibleImageAttributes,
                 @"Layout attributes for visible image were nil because %@ was called too early!",
                 NSStringFromSelector(_cmd));
        [self.collectionView setContentOffset:visibleImageAttributes.frame.origin animated:animated];
    }
}

- (void)setVisibleImageIndex:(NSUInteger)visibleImageIndex animated:(BOOL)animated {
    [self setVisibleImageIndex:visibleImageIndex animated:animated forceViewUpdate:NO];
}

- (void)setVisibleImageIndex:(NSUInteger)visibleImageIndex animated:(BOOL)animated forceViewUpdate:(BOOL)force {
    if (!force && visibleImageIndex == _visibleImageIndex) {
        return;
    }
    NSParameterAssert(visibleImageIndex < self.uniqueArticleImages.count);
    _visibleImageIndex = visibleImageIndex;
    [self applyVisibleImageIndex:animated];
}

- (void)setVisibleImageIndex:(NSUInteger)visibleImageIndex {
    [self setVisibleImageIndex:visibleImageIndex animated:NO];
}

- (void)setVisibleImage:(MWKImage*)visibleImage animated:(BOOL)animated {
    NSInteger selectedImageIndex = [self.uniqueArticleImages indexOfObjectPassingTest:^BOOL (MWKImage* image,
                                                                                             NSUInteger idx,
                                                                                             BOOL* stop) {
        if ([image isEqualToImage:visibleImage] || [image isVariantOfImage:visibleImage]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];

    if (selectedImageIndex == NSNotFound) {
        NSLog(@"WARNING: falling back to showing the first image.");
        selectedImageIndex = 0;
    }

    self.visibleImageIndex = selectedImageIndex;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)                             gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return gestureRecognizer != self.chromeTapGestureRecognizer;
}

- (BOOL)                  gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
    shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer*)otherGestureRecognizer {
    return gestureRecognizer == self.chromeTapGestureRecognizer;
}

#pragma mark - CollectionView

#pragma mark Delegate

- (CGSize)  collectionView:(UICollectionView*)collectionView
                    layout:(UICollectionViewLayout*)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.collectionViewFlowLayout wmf_itemSizeThatFits:self.view.bounds.size];
}

#pragma mark DataSource

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
                 cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)
        [collectionView dequeueReusableCellWithReuseIdentifier:WMFImageGalleryCollectionViewCellReuseId
                                                  forIndexPath:indexPath];

    MWKImage* imageStub        = self.uniqueArticleImages[indexPath.item];
    MWKImageInfo* infoForImage = self.indexedImageInfo[imageStub.infoAssociationValue];

    [self updateDetailVisibilityForCell:cell withInfo:infoForImage];

    if (infoForImage) {
        cell.detailOverlayView.imageDescription =
            [infoForImage.imageDescription stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSString* ownerOrFallback = infoForImage.owner ?
                                    [infoForImage.owner stringByTrimmingCharactersInSet : [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                    : MWLocalizedString(@"image-gallery-unknown-owner", nil);

        [cell.detailOverlayView setLicense:infoForImage.license owner:ownerOrFallback];

        cell.detailOverlayView.ownerTapCallback = ^{
            [[UIApplication sharedApplication] openURL:infoForImage.license.URL];
        };
    }

    [self updateImageForCell:cell atIndexPath:indexPath image:imageStub info:infoForImage];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.uniqueArticleImages.count;
}

#pragma mark - Cell Updates

- (void)updateDetailVisibilityForCellAtIndexPath:(NSIndexPath*)indexPath {
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self updateDetailVisibilityForCell:cell atIndexPath:indexPath];
}

- (void)updateDetailVisibilityForCell:(WMFImageGalleryCollectionViewCell*)cell
                          atIndexPath:(NSIndexPath*)indexPath {
    MWKImage* imageStub        = self.uniqueArticleImages[indexPath.item];
    MWKImageInfo* infoForImage = self.indexedImageInfo[imageStub.infoAssociationValue];
    [self updateDetailVisibilityForCell:cell withInfo:infoForImage];
}

- (void)updateDetailVisibilityForCell:(WMFImageGalleryCollectionViewCell*)cell
                             withInfo:(MWKImageInfo*)info {
    BOOL const shouldHideDetails = [self isChromeHidden]
                                   || (!info.imageDescription && !info.owner && !info.license);
    [cell setDetailViewAlpha:shouldHideDetails ? 0.0 : 1.0];
}

- (void)updateImageAtIndexPath:(NSIndexPath*)indexPath {
    NSParameterAssert(indexPath);
    MWKImage* image                         = self.uniqueArticleImages[indexPath.item];
    MWKImageInfo* infoForImage              = self.indexedImageInfo[image.infoAssociationValue];
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self updateImageForCell:cell atIndexPath:indexPath image:image info:infoForImage];
}

- (void)updateImageForCell:(WMFImageGalleryCollectionViewCell*)cell
               atIndexPath:(NSIndexPath*)indexPath
                     image:(MWKImage*)image
                      info:(MWKImageInfo*)infoForImage {
    NSParameterAssert(cell);
    NSParameterAssert(indexPath);
    NSParameterAssert(image);
    UIImage* cachedBitmap   = infoForImage.imageThumbURL ? self.bitmapsForImageURL[infoForImage.imageThumbURL] : nil;
    MWKImage* matchingImage = nil;
    if (cachedBitmap) {
        ImgGalleryLog(@"Using cached bitmap for %@ at %@", infoForImage.imageThumbURL, indexPath);
        cell.image     = cachedBitmap;
        cell.imageSize = infoForImage.thumbSize;
    } else if ((matchingImage = [self.article imageWithURL:infoForImage.imageThumbURL.absoluteString])
               && matchingImage.isCached) {
        ImgGalleryLog(@"Reading image %@ from disk for cell %@.", infoForImage.imageThumbURL, indexPath);
        UIImage* matchingImageData = [matchingImage asUIImage];
        self.bitmapsForImageURL[infoForImage.imageThumbURL] = matchingImageData;
        cell.image                                          = matchingImageData;
        cell.imageSize                                      = matchingImageData.size;
    } else {
        ImgGalleryLog(@"Using article image (%@) as placeholder for thumbnail of cell %@", image.sourceURL, indexPath);
        // !!!: -asUIImage reads from disk AND has to decompress image data, maybe we should move it off the main thread?
        cell.image     = [image asUIImage];
        cell.imageSize = infoForImage ? infoForImage.thumbSize : cell.image.size;
        [self fetchImage:infoForImage.imageThumbURL forCellAtIndexPath:indexPath];
    }
}

- (void)fetchImage:(NSURL*)imageURL forCellAtIndexPath:(NSIndexPath*)indexPath {
    if (!imageURL) {
        return;
    }
    NSParameterAssert(indexPath);

    ImgGalleryLog(@"Fetching image at %@ for cell %@", imageURL.absoluteString, indexPath);

    NSAssert(![self.article imageWithURL:imageURL.absoluteString].isCached,
             @"Invalid fetch for existing image data for URL: %@", imageURL);

    __weak WMFImageGalleryViewController* weakSelf = self;
    AFHTTPRequestOperation* request                =
        [self.imageFetcher
         wmf_idempotentGET:imageURL.absoluteString
                parameters:nil
                   success:^(AFHTTPRequestOperation* operation, UIImage* image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
            WMFImageGalleryViewController* strSelf = weakSelf;
            if (!strSelf) {
                return;
            }
            ImgGalleryLog(@"Retrieved high-res image at %@ for cell %@", imageURL, indexPath);
            NSCParameterAssert(image);
            MWKImage* imageRecord = [strSelf.article importImageURL:imageURL.absoluteString
                                                          imageData:operation.responseData];
            NSCParameterAssert(imageRecord.isCached);
            self.bitmapsForImageURL[imageURL] = image;
            WMFImageGalleryCollectionViewCell* cell =
                (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.image = image;
        });
    }
                   failure:^(AFHTTPRequestOperation* operation, NSError* error) {
        ImgGalleryLog(@"Failed to fetch image at %@ for cell %@: %@", operation.request.URL, indexPath, error);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MWNetworkActivityIndicatorManager sharedManager] pop];
        });
    }];

    if (request) {
        // request will be nil if no request was sent (if another operation is already requesting the specified image)
        [[MWNetworkActivityIndicatorManager sharedManager] push];
    }
}

@end
