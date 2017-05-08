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
    [[WMFImageController sharedInstance] cancelFetchWithURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]];
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
            [self showShareOptionsWithImage:download.image.staticImage];
        }];
}

#pragma mark - Share Options Setup

- (void)showShareOptionsWithImage:(nullable UIImage *)image {
    [self setupBackgroundView];

    [self cardImageWithArticleImage:image completion:^(UIImage *_Nullable cardImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.shareImage = cardImage;
            [self setupShareOptions];
            [self presentShareOptions];
        });
    }];
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
    shareOptionsView.shareAsCardLabel.text = WMFLocalizedStringWithDefaultValue(@"share-as-image", nil, nil, @"Share as image", @"Button label for sharing as an image card");
    shareOptionsView.shareAsTextLabel.text = WMFLocalizedStringWithDefaultValue(@"share-as-text", nil, nil, @"Share as text", @"Button label for sharing as a text snippet (instead of as an image card)");
    shareOptionsView.cancelLabel.text = WMFLocalizedStringWithDefaultValue(@"share-cancel", nil, nil, @"Cancel", @"Button which dismisses the share dialog, cancelling the action.\n{{Identical|Cancel}}");
    shareOptionsView.cardImageView.image = self.shareImage;
    shareOptionsView.accessibilityDelegate = self;

    [self.containerViewController.view addSubview:shareOptionsView];
    self.shareOptions = shareOptionsView;
}

#pragma mark - Create Card Image

- (void)cardImageWithArticleImage:(nullable UIImage *)image completion:(void (^)(UIImage *_Nullable cardImage))completion {
    WMFShareCardViewController *cardViewController =
        [[WMFShareCardViewController alloc] initWithNibName:@"ShareCard"
                                                     bundle:nil];

    UIView *cardView = cardViewController.view;
    [cardViewController fillCardWithMWKArticle:self.article snippet:self.snippet image:image
                                    completion:^(void){
                                        completion([cardView wmf_snapshotImage]);
                                    }];
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
    return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"share-article-name-on-wikipedia", nil, nil, @"\"%1$@\" on @Wikipedia:", @"Formatted string expressing article being on Wikipedia with at symbol handle. Please do not translate the \"@Wikipedia\" in the message, and preserve the spaces around it, as it refers specifically to the Wikipedia Twitter account. %1$@ will be an article title, which should be wrapped in the localized double quote marks."), self.shareTitle];
}

- (NSString *)titleForActivityTextOnly {
    if ([self snippetForTextOnlySharing].length == 0) {
        return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"share-article-name-on-wikipedia", nil, nil, @"\"%1$@\" on @Wikipedia:", @"Formatted string expressing article being on Wikipedia with at symbol handle. Please do not translate the \"@Wikipedia\" in the message, and preserve the spaces around it, as it refers specifically to the Wikipedia Twitter account. %1$@ will be an article title, which should be wrapped in the localized double quote marks."), self.shareTitle];
    } else {
        return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"share-article-name-on-wikipedia-with-selected-text", nil, nil, @"\"%1$@\" on @Wikipedia: \"%2$@\"", @"Formatted string expressing article being on Wikipedia with at symbol handle, with a user-selected snippet. Please do not translate the \"@Wikipedia\" in the message, and preserve the spaces around it, as it refers specifically to the Wikipedia Twitter account. %1$@ will be an article title, which should be wrapped in the localized double quote marks. %2$@ will be a user-selected text snippet, which should be wrapped in the localized double quote marks."), self.shareTitle, [self snippetForTextOnlySharing]];
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
