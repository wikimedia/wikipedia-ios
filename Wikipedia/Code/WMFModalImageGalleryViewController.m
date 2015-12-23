//
//  WMFImageGalleryViewController.m
//  Wikipedia
//
//  Created by Brian Gerstle on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFModalImageGalleryViewController_Subclass.h"
#import "WMFBaseImageGalleryViewController_Subclass.h"
#import "Wikipedia-Swift.h"

#import "AnyPromise+WMFExtensions.h"

// Utils
#import <BlocksKit/BlocksKit.h>
#import "WikipediaAppUtils.h"
#import "SessionSingleton.h"
#import "MWNetworkActivityIndicatorManager.h"
#import "NSArray+WMFLayoutDirectionUtilities.h"
#import "UIViewController+WMFOpenExternalUrl.h"

// View
#import <Masonry/Masonry.h>
#import "WMFImageGalleryCollectionViewCell.h"
#import "WMFImageGalleryDetailOverlayView.h"
#import "UIFont+WMFStyle.h"
#import "UIButton+WMFButton.h"
#import "UICollectionViewFlowLayout+NSCopying.h"
#import "UICollectionViewFlowLayout+WMFItemSizeThatFits.h"
#import "WMFCollectionViewPageLayout.h"
#import "UICollectionViewLayout+AttributeUtils.h"
#import "UILabel+WMFStyling.h"
#import "UIButton+FrameUtils.h"
#import "UIView+WMFFrameUtils.h"
#import "WMFGradientView.h"
#import "UICollectionView+WMFExtensions.h"

// Model
#import "MWKImage.h"
#import "MWKLicense+ToGlyph.h"
#import "MWKImageInfo+MWKImageComparison.h"
#import "MWKArticle.h"

// Data Sources
#import "WMFModalArticleImageGalleryDataSource.h"
#import "WMFModalPOTDGalleryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ WMFGalleryCellEnumerator)(WMFImageGalleryCollectionViewCell* cell, NSIndexPath* indexPath);

static double const WMFImageGalleryTopGradientHeight = 150.0;

static NSString* const WMFImageGalleryCollectionViewCellReuseId = @"WMFImageGalleryCollectionViewCellReuseId";

@interface WMFModalImageGalleryViewController ()

/**
 *  Designated initializer for public convenience initializers.
 *
 *  @return A modal gallery view controller with the given data source, configured to display images in gallery cells.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER NS_AVAILABLE_IPHONE(__IPHONE_8_0);

#pragma mark - Chrome

/**
 * Controls whether auxilliary image information and controls are visible (e.g. close button & image metadata).
 *
 * Set to `YES` to hide image metadata, close button, and gradients. Only has an effect if `chromeEnabled` is `YES`.
 *
 * @see chromeEnabled
 */
@property (nonatomic, getter = isChromeHidden) BOOL chromeHidden;

/**
 *  Toggle the display of the chrome UI.
 *
 *  Subclasses shouldn't need to call this, as @c WMFModalImageGalleryViewController already implements gesture
 *  recognition to allow users to toggle the state.
 *
 *  @param hidden   The desired state.
 *  @param animated Whether the transition to @c hidden should be animated.
 */
- (void)setChromeHidden:(BOOL)hidden animated:(BOOL)animated;

@end

@implementation WMFModalImageGalleryViewController

/// Default layout for modal gallery.
+ (UICollectionViewFlowLayout*)wmf_defaultGalleryLayout {
    UICollectionViewFlowLayout* defaultLayout = [[WMFCollectionViewPageLayout alloc] init];
    defaultLayout.sectionInset            = UIEdgeInsetsZero;
    defaultLayout.minimumInteritemSpacing = 0.f;
    defaultLayout.minimumLineSpacing      = 0.f;
    defaultLayout.scrollDirection         = UICollectionViewScrollDirectionHorizontal;
    return defaultLayout;
}

- (instancetype)init {
    self = [super initWithCollectionViewLayout:[[self class] wmf_defaultGalleryLayout]];
    if (self) {
        self.chromeHidden = NO;
    }
    return self;
}

#pragma mark - Article Gallery

- (instancetype)initWithImagesInArticle:(MWKArticle*)article currentImage:(nullable MWKImage*)currentImage {
    self = [self init];
    if (self) {
        NSAssert(article.isCached, @"Unexpected initialization with uncached instance of %@ in %@, use %@ instead.",
                 article.title,
                 NSStringFromSelector(_cmd),
                 NSStringFromSelector(@selector(initWithImagesInFutureArticle:placeholder:)));
        WMFModalArticleImageGalleryDataSource* articleGalleryDataSource =
            [[WMFModalArticleImageGalleryDataSource alloc] initWithArticle:article];
        self.dataSource = articleGalleryDataSource;
        if (currentImage) {
            NSInteger selectedImageIndex = [articleGalleryDataSource.allItems
                                            indexOfObjectPassingTest:^BOOL (MWKImage* image, NSUInteger _, BOOL* stop) {
                if ([image isEqualToImage:currentImage] || [image isVariantOfImage:currentImage]) {
                    *stop = YES;
                    return YES;
                }
                return NO;
            }];

            if (selectedImageIndex == NSNotFound) {
                DDLogWarn(@"Falling back to showing the first image.");
                selectedImageIndex = 0;
            }
            self.currentPage = selectedImageIndex;
        }
    }
    return self;
}

- (instancetype)initWithImagesInFutureArticle:(AnyPromise*)articlePromise
                                  placeholder:(nullable MWKArticle*)placeholderArticle {
    self = [self init];
    if (self) {
        if (placeholderArticle) {
            self.dataSource = [[WMFModalArticleImageGalleryDataSource alloc] initWithArticle:placeholderArticle];
        }
        @weakify(self);
        articlePromise.then(^(MWKArticle* article) {
            @strongify(self);
            self.dataSource = [[WMFModalArticleImageGalleryDataSource alloc] initWithArticle:article];
        })
        // NOTE: article load error is caught in article view, which will also show a banner
        .finally(^{
            [self.loadingIndicator stopAnimating];
        });
    }
    return self;
}

#pragma mark - Picture of the Day Gallery

- (instancetype)initWithInfo:(MWKImageInfo*)info forDate:(nonnull NSDate*)date {
    self = [self init];
    if (self) {
        self.dataSource = [[WMFModalPOTDGalleryDataSource alloc] initWithInfo:info forDate:date];
    }
    return self;
}

#pragma mark - Accessors

- (void)setDataSource:(nullable SSBaseDataSource<WMFImageGalleryDataSource>*)dataSource {
    NSParameterAssert([dataSource conformsToProtocol:@protocol(WMFModalImageGalleryDataSource)]);
    [super setDataSource:dataSource];
    self.dataSource.cellClass = [WMFImageGalleryCollectionViewCell class];
    @weakify(self);
    self.dataSource.cellConfigureBlock = ^(WMFImageGalleryCollectionViewCell* cell,
                                           id __unused obj,
                                           UICollectionView* _,
                                           NSIndexPath* indexPath) {
        @strongify(self);
        [self updateCell:cell atIndexPath:indexPath];
    };
    [[self modalGalleryDataSource] setDelegate:self];
}

- (id<WMFModalImageGalleryDataSource>)modalGalleryDataSource {
    return (id<WMFModalImageGalleryDataSource>)self.dataSource;
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

#pragma mark - UIViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // fetch after appearing so we don't do work while the animation is rendering
    [[self modalGalleryDataSource] fetchDataAtIndexPath:[NSIndexPath indexPathForItem:self.currentPage inSection:0]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIActivityIndicatorView* loadingIndicator =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    loadingIndicator.hidesWhenStopped = YES;
    [loadingIndicator stopAnimating];
    [self.view addSubview:loadingIndicator];
    [loadingIndicator mas_makeConstraints:^(MASConstraintMaker* make) {
        make.center.equalTo(self.view);
    }];
    self.loadingIndicator = loadingIndicator;

    if (!self.dataSource) {
        // Start loading indicator if we don't have any data. Hopefully it will be set soon...
        [self.loadingIndicator startAnimating];
    }

    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator   = NO;

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

    @weakify(self)
    UIButton * closeButton = [UIButton wmf_buttonType:WMFButtonTypeClose handler:^(id sender){
        @strongify(self)
        [self closeButtonTapped : sender];
    }];
    closeButton.tintColor = [UIColor whiteColor];
    [self.view addSubview:closeButton];
    _closeButton = closeButton;

    [self.closeButton mas_makeConstraints:^(MASConstraintMaker* make) {
        make.width.and.height.mas_equalTo(60.f);
        make.leading.equalTo(self.view.mas_leading);
        make.top.equalTo(self.view.mas_top);
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
            forCellWithReuseIdentifier:[WMFImageGalleryCollectionViewCell identifier]];
    self.collectionView.alwaysBounceHorizontal = YES;

    [self applyChromeHidden:NO];
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
    if (![self isViewLoaded]) {
        return;
    }

    [UIView transitionWithView:self.view
                      duration:animated ? [CATransaction animationDuration] : 0.0
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        self.topGradientView.hidden = [self isChromeHidden];
        self.closeButton.hidden = [self isChromeHidden];
        for (NSIndexPath* indexPath in self.collectionView.indexPathsForVisibleItems) {
            [self updateDetailVisibilityForCellAtIndexPath:indexPath animated:NO];
        }
    }
                    completion:nil];
}

#pragma mark - Dismissal

- (void)closeButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(willDismissGalleryController:)]) {
        [self.delegate willDismissGalleryController:self];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(didDismissGalleryController:)]) {
            [self.delegate didDismissGalleryController:self];
        }
    }];
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

- (void)collectionView:(UICollectionView*)collectionView
       willDisplayCell:(UICollectionViewCell*)cell
    forItemAtIndexPath:(NSIndexPath*)indexPath {
    /*
       since we have to wait until the cells are laid out before applying visibleImageIndex, this method can be
       called before currentPage has been applied.  as a result, we check the flag here to ensure our first fetch
       is for the current visible image. otherwise, we could fetch the first image in the gallery, apply visibleImageIndex,
       then fetch the visible image.
     */
    if (self.didApplyCurrentPage) {
        [[self modalGalleryDataSource] fetchDataAtIndexPath:indexPath];
    }
}

#pragma mark - Cell Updates

- (void)updateCell:(WMFImageGalleryCollectionViewCell*)cell
       atIndexPath:(NSIndexPath*)indexPath {
    MWKImageInfo* infoForImage = [[self modalGalleryDataSource] imageInfoAtIndexPath:indexPath];

    [cell startLoadingAfterDelay:0.25];

    if (infoForImage) {
        cell.detailOverlayView.imageDescription =
            [infoForImage.imageDescription stringByTrimmingCharactersInSet:
             [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        NSString* ownerOrFallback = infoForImage.owner ?
                                    [infoForImage.owner stringByTrimmingCharactersInSet : [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                    : MWLocalizedString(@"image-gallery-unknown-owner", nil);

        [cell.detailOverlayView setLicense:infoForImage.license owner:ownerOrFallback];

        cell.detailOverlayView.ownerTapCallback = ^{
            [self wmf_openExternalUrl:infoForImage.license.URL];
        };
    }

    // update detail visibility after info might have been populated
    [self updateDetailVisibilityForCell:cell withInfo:infoForImage animated:NO];

    [self updateImageForCell:cell
                 atIndexPath:indexPath
         placeholderImageURL:[self.dataSource imageURLAtIndexPath:indexPath]
                        info:infoForImage];
}

#pragma mark - Image Details

- (void)updateDetailVisibilityForCellAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated {
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    [self updateDetailVisibilityForCell:cell atIndexPath:indexPath animated:animated];
}

- (void)updateDetailVisibilityForCell:(WMFImageGalleryCollectionViewCell*)cell
                          atIndexPath:(NSIndexPath*)indexPath
                             animated:(BOOL)animated {
    [self updateDetailVisibilityForCell:cell
                               withInfo:[[self modalGalleryDataSource] imageInfoAtIndexPath:indexPath]
                               animated:animated];
}

- (void)updateDetailVisibilityForCell:(WMFImageGalleryCollectionViewCell*)cell
                             withInfo:(MWKImageInfo*)info
                             animated:(BOOL)animated {
    if (!cell) {
        return;
    }

    BOOL const shouldHideDetails = [self isChromeHidden]
                                   || (!info.imageDescription && !info.owner && !info.license);
    dispatch_block_t animations = ^{
        cell.detailOverlayView.hidden = shouldHideDetails;
    };

    /*
       HAX: UIView transition API doesn't invoke animations inline if duration is 0, which can lead to staggered UI updates
       if there are nested animations. For example, if this is invoked within the animation block of `applyChromeHidden`,
       the detail overlay will appear *without animation* after the chrome is cross-dissolved away.
     */
    if (animated) {
        [UIView transitionWithView:cell
                          duration:[CATransaction animationDuration]
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:animations
                        completion:nil];
    } else {
        animations();
    }
}

#pragma mark - Image Handling

- (void)updateImageAtIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated {
    NSParameterAssert(indexPath);
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        [self updateImageForCell:cell
                     atIndexPath:indexPath
             placeholderImageURL:[self.dataSource imageURLAtIndexPath:indexPath]
                            info:[[self modalGalleryDataSource] imageInfoAtIndexPath:indexPath]];
    }
}

- (void)updateImageForCell:(WMFImageGalleryCollectionViewCell*)cell
               atIndexPath:(NSIndexPath*)indexPath
       placeholderImageURL:(NSURL*)placeholderImageURL
                      info:(MWKImageInfo* __nullable)infoForImage {
    NSParameterAssert(cell);
    @weakify(self);
    [[WMFImageController sharedInstance]
     cascadingFetchWithMainURL:infoForImage.imageThumbURL
           cachedPlaceholderURL:placeholderImageURL
                 mainImageBlock:^(WMFImageDownload* download) {
        @strongify(self);
        [self setImage:download.image withInfo:infoForImage forCellAtIndexPath:indexPath];
    }
    cachedPlaceholderImageBlock:^(WMFImageDownload* download) {
        @strongify(self);
        [self setPlaceholderImage:download.image ofInfo:infoForImage forCellAtIndexPath:indexPath];
    }]
    .catch(^(NSError* error) {
        DDLogWarn(@"Failed to load image for cell at %@: %@", indexPath, error);
        [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
    });
}

- (void)      setImage:(UIImage*)image
              withInfo:(MWKImageInfo*)info
    forCellAtIndexPath:(NSIndexPath*)indexPath {
    DDLogDebug(@"Setting image for info %@ to indexpath %@", info, indexPath);
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) {
        DDLogDebug(@"Not applying download for %@ at %@ since cell is no longer visible.", info, indexPath);
        return;
    }
    cell.image     = image;
    cell.imageSize = info.thumbSize;
    cell.loading   = NO;
}

- (void)setPlaceholderImage:(UIImage* __nullable)image
                     ofInfo:(MWKImageInfo* __nullable)info
         forCellAtIndexPath:(NSIndexPath*)indexPath {
    if (!image) {
        return;
    }
    NSAssert(!info
             || ![[WMFImageController sharedInstance] hasImageWithURL:info.imageThumbURL]
             || (!info && ![[WMFImageController sharedInstance] hasImageWithURL:info.imageThumbURL]),
             @"Breach of contract to never apply variant when desired image is present!");
    DDLogDebug(@"Applying variant of info %@ to indexpath %@", info, indexPath);
    WMFImageGalleryCollectionViewCell* cell =
        (WMFImageGalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) {
        DDLogDebug(@"Not applying download of variant for %@ at %@ since cell is no longer visible.",
                   info, indexPath);
        return;
    }
    cell.image = image;
    /*
       set the expected image size to the image info's size if we have it, yielding the "ENHANCE" effect when
       the higher-res image is downloaded
     */
    cell.imageSize = info ? info.thumbSize : image.size;
    if (!info) {
        // only stop loading if info is nil, meaning that there's no high-res image coming
        cell.loading = NO;
    }
}

#pragma mark - WMFModalGalleryDataSourceDelegate

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource didFailWithError:(NSError*)error {
    [self.loadingIndicator stopAnimating];
    [[WMFAlertManager sharedInstance] showErrorAlert:error sticky:NO dismissPreviousAlerts:NO tapCallBack:NULL];
}

- (void)modalGalleryDataSource:(id<WMFModalImageGalleryDataSource>)dataSource
         updatedItemsAtIndexes:(NSIndexSet*)indexes {
    [self.loadingIndicator stopAnimating];
    /*
       NOTE: Do not call `reloadItemsAtIndexPaths:` because that will cause an infinite loop with the collection view
       reloading the cell, which asks the dataSource to fetch data, which triggers this method, which reloads the cell...
     */
    [self.collectionView wmf_enumerateVisibleCellsUsingBlock:^(WMFImageGalleryCollectionViewCell* cell,
                                                               NSIndexPath* indexPath,
                                                               BOOL* _) {
        if ([indexes containsIndex:indexPath.item]) {
            UIViewAnimationOptions options = UIViewAnimationOptionTransitionCrossDissolve
                                             | UIViewAnimationOptionAllowAnimatedContent
                                             | UIViewAnimationOptionAllowUserInteraction;
            /*
               NOTE: Perform animations with the cell as the view (as opposed altogether w/ the collectionView), otherwise
               it causes all the cells to fade, which makes cross-dissolving while swiping look very strange.
             */
            [UIView transitionWithView:cell
                              duration:[CATransaction animationDuration]
                               options:options
                            animations:^{
                [self updateCell:cell atIndexPath:indexPath];
            } completion:nil];
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
