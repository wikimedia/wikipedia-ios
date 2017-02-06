#import "WMFShareOptionsController.h"

#import "Wikipedia-Swift.h"
#import <Masonry/Masonry.h>

#import "WMFShareFunnel.h"

#import "NSString+WMFExtras.h"
#import "NSString+WMFHTMLParsing.h"

#import "UIView+WMFSnapshotting.h"

#import "WMFShareCardViewController.h"
#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"
#import "MWKArticle.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFBackgroundAccessibilityEscapeView : UIView

@property (nonatomic, weak) NSObject *accessibilityDelegate;

@end

@implementation WMFBackgroundAccessibilityEscapeView

- (BOOL)accessibilityPerformEscape {
    [self.accessibilityDelegate accessibilityPerformEscape];
    return true;
}

@end

@interface WMFShareOptionsController ()

@property (strong, nonatomic, readwrite) MWKArticle *article;
@property (strong, nonatomic, readwrite) WMFShareFunnel *shareFunnel;
@property (nonatomic, readwrite) BOOL active;

@property (nullable, copy, nonatomic) NSString *snippet;
@property (weak, nonatomic) UIViewController *containerViewController;
@property (nullable, strong, nonatomic) UIBarButtonItem *originButtonItem;

@property (nullable, strong, nonatomic) WMFBackgroundAccessibilityEscapeView *grayOverlay;
@property (nullable, strong, nonatomic) WMFShareOptionsView *shareOptions;
@property (nullable, strong, nonatomic) UIImage *shareImage;

@end

@implementation WMFShareOptionsController

- (void)cleanup {
    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]];
    self.containerViewController = nil;
    self.originButtonItem = nil;
    self.shareImage = nil;
    self.snippet = nil;
}

- (instancetype)initWithArticle:(MWKArticle *)article
                    shareFunnel:(WMFShareFunnel *)funnel {
    NSParameterAssert(article);
    NSParameterAssert(funnel);
    NSParameterAssert(article.url.absoluteString);

    self = [super init];

    if (self) {
        _article = article;
        _shareFunnel = funnel;
    }
    return self;
}

- (BOOL)isActive {
    return self.containerViewController != nil;
}

#pragma mark - Public Presentation methods

- (void)presentShareOptionsWithSnippet:(NSString *)snippet inViewController:(UIViewController *)viewController fromBarButtonItem:(UIBarButtonItem *)item {
    NSParameterAssert(item);
    NSParameterAssert(viewController);
    self.snippet = snippet;
    self.containerViewController = viewController;
    self.originButtonItem = item;
    [self fetchImageThenShowShareCard];
}

#pragma mark - Asynchornous Fetch and Present

- (void)fetchImageThenShowShareCard {
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]
        failure:^(NSError *_Nonnull error) {
            DDLogInfo(@"Ignoring share card image error: %@", error);
            [self showShareOptionsWithImage:nil];
        }
        success:^(WMFImageDownload *_Nonnull download) {
            @strongify(self);
            [self showShareOptionsWithImage:download.image];
        }];
}

#pragma mark - Share Options Setup

- (void)showShareOptionsWithImage:(nullable UIImage *)image {
    [self setupBackgroundView];

    self.shareImage = [self cardImageWithArticleImage:image];

    [self setupShareOptions];

    [self presentShareOptions];
}

- (void)setupBackgroundView {
    UIView *containingView = self.containerViewController.view;

    WMFBackgroundAccessibilityEscapeView *grayOverlay = [[WMFBackgroundAccessibilityEscapeView alloc] initWithFrame:containingView.frame];
    grayOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
    grayOverlay.alpha = 0.0;
    grayOverlay.accessibilityDelegate = self;
    [containingView addSubview:grayOverlay];
    self.grayOverlay = grayOverlay;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(respondToDimAreaTapGesture:)];
    [grayOverlay addGestureRecognizer:tapRecognizer];
    grayOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [grayOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containingView);
    }];
}

- (void)setupShareOptions {
    WMFShareOptionsView *shareOptionsView =
        [[[NSBundle mainBundle] loadNibNamed:@"ShareOptions" owner:self options:nil] objectAtIndex:0];
    shareOptionsView.cardImageViewContainer.userInteractionEnabled = YES;
    shareOptionsView.shareAsCardLabel.userInteractionEnabled = YES;
    shareOptionsView.shareAsTextLabel.userInteractionEnabled = YES;
    shareOptionsView.cancelLabel.userInteractionEnabled = YES;
    shareOptionsView.shareAsCardLabel.text = MWLocalizedString(@"share-as-image", nil);
    shareOptionsView.shareAsTextLabel.text = MWLocalizedString(@"share-as-text", nil);
    shareOptionsView.cancelLabel.text = MWLocalizedString(@"share-cancel", nil);
    shareOptionsView.cardImageView.image = self.shareImage;
    shareOptionsView.accessibilityDelegate = self;

    [self.containerViewController.view addSubview:shareOptionsView];
    self.shareOptions = shareOptionsView;
}

#pragma mark - Create Card Image

- (nullable UIImage *)cardImageWithArticleImage:(nullable UIImage *)image {
    WMFShareCardViewController *cardViewController =
        [[WMFShareCardViewController alloc] initWithNibName:@"ShareCard"
                                                     bundle:nil];

    UIView *cardView = cardViewController.view;
    [cardViewController fillCardWithMWKArticle:self.article snippet:self.snippet image:image];

    return [cardView wmf_snapshotImage];
}

- (void)setContainerViewControllerActionsEnabled:(BOOL)enabled {
    self.containerViewController.navigationController.navigationBar.userInteractionEnabled = enabled;
    [self.containerViewController.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        obj.enabled = enabled;
    }];
    [self.containerViewController.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        obj.enabled = enabled;
    }];
    [self.containerViewController.toolbarItems enumerateObjectsUsingBlock:^(__kindof UIBarButtonItem *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        obj.enabled = enabled;
    }];
    self.containerViewController.navigationController.navigationBar.accessibilityElementsHidden = !enabled;
    self.containerViewController.navigationController.toolbar.accessibilityElementsHidden = !enabled;
}

#pragma mark - Share Options

- (void)presentShareOptions {
    [self setContainerViewControllerActionsEnabled:NO];

    UIView *containingView = self.containerViewController.view;

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.top.equalTo(containingView.mas_bottom);
    }];

    [self.shareOptions layoutIfNeeded];

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.bottom.equalTo(self.containerViewController.mas_bottomLayoutGuide);
    }];

    [UIView animateWithDuration:0.40
        delay:0.0
        usingSpringWithDamping:0.8
        initialSpringVelocity:0.0
        options:0
        animations:^{
            [self.shareOptions layoutIfNeeded];
            self.grayOverlay.alpha = 1.0;
        }
        completion:^(BOOL finished) {
            UITapGestureRecognizer *tapForCardOnCardImageViewRecognizer = [[UITapGestureRecognizer alloc]
                initWithTarget:self
                        action:@selector(respondToTapForCardGesture:)];
            UITapGestureRecognizer *tapForCardOnButtonRecognizer = [[UITapGestureRecognizer alloc]
                initWithTarget:self
                        action:@selector(respondToTapForCardGesture:)];
            UITapGestureRecognizer *tapForTextRecognizer = [[UITapGestureRecognizer alloc]
                initWithTarget:self
                        action:@selector(respondToTapForTextGesture:)];
            [self.shareOptions.cardImageViewContainer addGestureRecognizer:tapForCardOnCardImageViewRecognizer];
            [self.shareOptions.shareAsCardLabel addGestureRecognizer:tapForCardOnButtonRecognizer];
            [self.shareOptions.shareAsTextLabel addGestureRecognizer:tapForTextRecognizer];
            UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCancelLabelTapGesture:)];
            [self.shareOptions.cancelLabel addGestureRecognizer:tapGR];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.shareOptions);
        }];
}

- (void)handleCancelLabelTapGesture:(UIGestureRecognizer *)tapGR {
    if (tapGR.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    [self dismissShareOptionsWithCompletion:nil];
}

- (void)dismissShareOptionsWithCompletion:(nullable dispatch_block_t)completion {
    UIView *containingView = self.containerViewController.view;

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.top.equalTo(containingView.mas_bottom);
    }];

    [UIView animateWithDuration:0.40
        delay:0.0
        usingSpringWithDamping:0.8
        initialSpringVelocity:0.0
        options:0
        animations:^{
            self.grayOverlay.alpha = 0.0;
            [self.shareOptions layoutIfNeeded];
        }
        completion:^(BOOL finished) {
            [self.grayOverlay removeFromSuperview];
            [self.shareOptions removeFromSuperview];
            self.grayOverlay = nil;
            self.shareOptions = nil;
            [self setContainerViewControllerActionsEnabled:YES];
            if (completion) {
                completion();
            }
            [self cleanup];
        }];
}

- (BOOL)accessibilityPerformEscape {
    [self dismissShareOptionsWithCompletion:nil];
    return true;
}

#pragma mark - Tap Gestures

- (void)respondToDimAreaTapGesture:(UITapGestureRecognizer *)recognizer {
    [self.shareFunnel logAbandonedAfterSeeingShareAFact];
    [self dismissShareOptionsWithCompletion:nil];
}

- (void)respondToTapForCardGesture:(UITapGestureRecognizer *)recognizer {
    [self.shareFunnel logShareAsImageTapped];
    [self dismissShareOptionsWithCompletion:^{
        [self presentActivityViewControllerWithImage:self.shareImage title:[self titleForActivityWithCard]];
    }];
}

- (void)respondToTapForTextGesture:(UITapGestureRecognizer *)recognizer {
    [self.shareFunnel logShareAsTextTapped];
    [self dismissShareOptionsWithCompletion:^{
        [self presentActivityViewControllerWithImage:nil title:[self titleForActivityTextOnly]];
    }];
}

#pragma mark - Snippet and Title Conversion

- (NSString *)shareTitle {
    return [self.article.url.wmf_title length] > 0 ? [self.article.url.wmf_title copy] : @"";
}

- (NSString *)snippetForTextOnlySharing {
    return [self.snippet length] > 0 ? [self.snippet copy] : @"";
}

- (NSString *)titleForActivityWithCard {
    return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
        stringByReplacingOccurrencesOfString:@"$1"
                                  withString:self.shareTitle];
}

- (NSString *)titleForActivityTextOnly {
    if ([self snippetForTextOnlySharing].length == 0) {
        return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
            stringByReplacingOccurrencesOfString:@"$1"
                                      withString:self.shareTitle];
    } else {
        return [[MWLocalizedString(@"share-article-name-on-wikipedia-with-selected-text", nil)
            stringByReplacingOccurrencesOfString:@"$1"
                                      withString:self.shareTitle]
            stringByReplacingOccurrencesOfString:@"$2"
                                      withString:[self snippetForTextOnlySharing]];
    }
}

#pragma mark - Activity View Controller

- (void)presentActivityViewControllerWithImage:(nullable UIImage *)image title:(NSString *)title {
    if (!self.originButtonItem) {
        //bailing here because we will crash below in production.
        //The asserion above will catch this in development/beta.
        return;
    }
    NSString *parameter = image ? @"wprov=sfii1" : @"wprov=sfti1";

    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@",
                                                                          [NSURL wmf_desktopURLForURL:self.article.url].absoluteString,
                                                                          parameter]];

    NSMutableArray *activityItems = @[title, url].mutableCopy;
    if (image) {
        [activityItems addObject:image];
    }

    UIActivityViewController *shareActivityVC =
        [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                          applicationActivities:@[]];
    UIPopoverPresentationController *presenter = [shareActivityVC popoverPresentationController];
    presenter.barButtonItem = self.originButtonItem;

    shareActivityVC.excludedActivityTypes = @[
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeAirDrop,
        UIActivityTypeAddToReadingList
    ];
    ;

    [shareActivityVC setCompletionWithItemsHandler:^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
        if (completed) {
            [self.shareFunnel logShareSucceededWithShareMethod:activityType];
        } else {
            [self.shareFunnel logShareFailedWithShareMethod:activityType];
        }
    }];

    [self.containerViewController presentViewController:shareActivityVC animated:YES completion:nil];

    [self cleanup];
}

@end

NS_ASSUME_NONNULL_END
