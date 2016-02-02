//
//  ShareOptionsViewController.m
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

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
#import "WikipediaAppUtils.h"
#import "MWKArticle.h"
#import "NSURL+WMFExtras.h"
#import "MWKTitle.h"
#import <BlocksKit/BlocksKit+UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFShareOptionsController ()<UIPopoverControllerDelegate>

@property (strong, nonatomic, readwrite) MWKArticle* article;
@property (strong, nonatomic, readwrite) WMFShareFunnel* shareFunnel;

@property (nullable, copy, nonatomic) NSString* snippet;
@property (weak, nonatomic) UIViewController* containerViewController;
@property (nullable, weak, nonatomic) UIBarButtonItem* originButtonItem;
@property (nullable, weak, nonatomic) UIView* originView;

@property (nullable, strong, nonatomic) UIView* grayOverlay;
@property (nullable, strong, nonatomic) WMFShareOptionsView* shareOptions;
@property (nullable, strong, nonatomic) UIImage* shareImage;

@property (nullable, strong, nonatomic) UIPopoverController* popover;

@end

@implementation WMFShareOptionsController

- (void)cleanup {
    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]];
    self.containerViewController = nil;
    self.originButtonItem        = nil;
    self.originView              = nil;
    self.shareImage              = nil;
    self.snippet                 = nil;
}

- (instancetype)initWithArticle:(MWKArticle*)article
                    shareFunnel:(WMFShareFunnel*)funnel {
    NSParameterAssert(article);
    NSParameterAssert(funnel);
    NSParameterAssert(article.title.desktopURL.absoluteString);

    self = [super init];

    if (self) {
        _article     = article;
        _shareFunnel = funnel;
    }
    return self;
}

#pragma mark - Public Presentation methods

- (void)presentShareOptionsWithSnippet:(NSString*)snippet inViewController:(UIViewController*)viewController fromBarButtonItem:(nullable UIBarButtonItem*)item {
    self.snippet                 = [snippet copy];
    self.containerViewController = viewController;
    self.originButtonItem        = item;
    self.originView              = nil;
    [self fetchImageThenShowShareCard];
}

- (void)presentShareOptionsWithSnippet:(NSString*)snippet inViewController:(UIViewController*)viewController fromView:(nullable UIView*)view {
    self.snippet                 = [snippet copy];
    self.containerViewController = viewController;
    self.originButtonItem        = nil;
    self.originView              = view;
    [self fetchImageThenShowShareCard];
}

#pragma mark - Asynchornous Fetch and Present

- (void)fetchImageThenShowShareCard {
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]]
    .catch(^(NSError* error){
        DDLogInfo(@"Ignoring share card image error: %@", error);
        return nil;
    })
    .then(^(WMFImageDownload* _Nullable download){
        @strongify(self);
        [self showShareOptionsWithImage:download.image];
    });
}

#pragma mark - Share Options Setup

- (void)showShareOptionsWithImage:(nullable UIImage*)image {
    [self setupBackgroundView];

    self.shareImage = [self cardImageWithArticleImage:image];

    [self setupShareOptions];

    [self presentShareOptions];
}

- (void)setupBackgroundView {
    UIView* containingView = self.containerViewController.view;

    UIView* grayOverlay = [[UIView alloc] initWithFrame:containingView.frame];
    grayOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
    grayOverlay.alpha           = 0.0;
    [containingView addSubview:grayOverlay];
    self.grayOverlay = grayOverlay;
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(respondToDimAreaTapGesture:)];
    [grayOverlay addGestureRecognizer:tapRecognizer];
    grayOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [grayOverlay mas_makeConstraints:^(MASConstraintMaker* make) {
        make.edges.equalTo(containingView);
    }];
}

- (void)setupShareOptions {
    WMFShareOptionsView* shareOptionsView =
        [[[NSBundle mainBundle] loadNibNamed:@"ShareOptions" owner:self options:nil] objectAtIndex:0];
    shareOptionsView.cardImageViewContainer.userInteractionEnabled = YES;
    shareOptionsView.shareAsCardLabel.userInteractionEnabled       = YES;
    shareOptionsView.shareAsTextLabel.userInteractionEnabled       = YES;
    shareOptionsView.cancelLabel.userInteractionEnabled       = YES;
    shareOptionsView.shareAsCardLabel.text                         = MWLocalizedString(@"share-as-image", nil);
    shareOptionsView.shareAsTextLabel.text                         = MWLocalizedString(@"share-as-text", nil);
    shareOptionsView.cancelLabel.text = MWLocalizedString(@"share-cancel", nil);
    shareOptionsView.cardImageView.image                           = self.shareImage;

    [self.containerViewController.view addSubview:shareOptionsView];
    self.shareOptions = shareOptionsView;
}

#pragma mark - Create Card Image

- (UIImage*)cardImageWithArticleImage:(UIImage*)image {
    WMFShareCardViewController* cardViewController =
        [[WMFShareCardViewController alloc] initWithNibName:@"ShareCard" bundle:nil];

    UIView* cardView = cardViewController.view;
    [cardViewController fillCardWithMWKArticle:self.article snippet:self.snippet image:image];

    return [cardView wmf_snapshotImage];
}

- (void)setContainerViewControllerActionsEnabled:(BOOL)enabled {
    self.containerViewController.navigationController.navigationBar.userInteractionEnabled = enabled;
    [self.containerViewController.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        obj.enabled = enabled;
    }];
    [self.containerViewController.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        obj.enabled = enabled;
    }];
    [self.containerViewController.toolbarItems enumerateObjectsUsingBlock:^(__kindof UIBarButtonItem* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
        obj.enabled = enabled;
    }];
    self.containerViewController.navigationController.navigationBar.accessibilityElementsHidden = !enabled;
    self.containerViewController.navigationController.toolbar.accessibilityElementsHidden       = !enabled;
}

#pragma mark - Share Options

- (void)presentShareOptions {
    [self setContainerViewControllerActionsEnabled:NO];

    UIView* containingView = self.containerViewController.view;

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.top.equalTo(containingView.mas_bottom);
    }];

    [self.shareOptions layoutIfNeeded];

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.bottom.equalTo(self.containerViewController.mas_bottomLayoutGuide);
    }];

    [UIView animateWithDuration:0.40 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
        [self.shareOptions layoutIfNeeded];
        self.grayOverlay.alpha = 1.0;
    } completion:^(BOOL finished) {
        UITapGestureRecognizer* tapForCardOnCardImageViewRecognizer = [[UITapGestureRecognizer alloc]
                                                                       initWithTarget:self action:@selector(respondToTapForCardGesture:)];
        UITapGestureRecognizer* tapForCardOnButtonRecognizer = [[UITapGestureRecognizer alloc]
                                                                initWithTarget:self action:@selector(respondToTapForCardGesture:)];
        UITapGestureRecognizer* tapForTextRecognizer = [[UITapGestureRecognizer alloc]
                                                        initWithTarget:self action:@selector(respondToTapForTextGesture:)];
        [self.shareOptions.cardImageViewContainer addGestureRecognizer:tapForCardOnCardImageViewRecognizer];
        [self.shareOptions.shareAsCardLabel addGestureRecognizer:tapForCardOnButtonRecognizer];
        [self.shareOptions.shareAsTextLabel addGestureRecognizer:tapForTextRecognizer];
        @weakify(self);
        [self.shareOptions.cancelLabel bk_whenTapped:^{
            [self dismissShareOptionsWithCompletion:^{
                @strongify(self);
                [self cleanup];
            }];
        }];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.shareOptions);
    }];
}

- (void)dismissShareOptionsWithCompletion:(dispatch_block_t)completion {
    UIView* containingView = self.containerViewController.view;

    [self.shareOptions mas_remakeConstraints:^(MASConstraintMaker* make) {
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.top.equalTo(containingView.mas_bottom);
    }];

    [UIView animateWithDuration:0.40 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
        self.grayOverlay.alpha = 0.0;
        [self.shareOptions layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.grayOverlay removeFromSuperview];
        [self.shareOptions removeFromSuperview];
        self.grayOverlay = nil;
        self.shareOptions = nil;
        [self setContainerViewControllerActionsEnabled:YES];
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Tap Gestures

- (void)respondToDimAreaTapGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logAbandonedAfterSeeingShareAFact];
    [self dismissShareOptionsWithCompletion:^{
        [self cleanup];
    }];
}

- (void)respondToTapForCardGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logShareAsImageTapped];
    [self dismissShareOptionsWithCompletion:^{
        [self presentActivityViewControllerWithImage:self.shareImage title:[self titleForActivityWithCard]];
    }];
}

- (void)respondToTapForTextGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logShareAsTextTapped];
    [self dismissShareOptionsWithCompletion:^{
        [self presentActivityViewControllerWithImage:nil title:[self titleForActivityTextOnly]];
    }];
}

#pragma mark - Snippet and Title Conversion

- (NSString*)shareTitle {
    return [self.article.title.text length] > 0 ? [self.article.title.text copy] : @"";
}

- (NSString*)snippetForTextOnlySharing {
    return [self.snippet length] > 0 ? [self.snippet copy] : @"";
}

- (NSString*)titleForActivityWithCard {
    return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
            stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
}

- (NSString*)titleForActivityTextOnly {
    if ([self snippetForTextOnlySharing].length == 0) {
        return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
                stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
    } else {
        return [[MWLocalizedString(@"share-article-name-on-wikipedia-with-selected-text", nil)
                 stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle]
                stringByReplacingOccurrencesOfString:@"$2" withString:[self snippetForTextOnlySharing]];
    }
}

#pragma mark - Activity View Controller

- (void)presentActivityViewControllerWithImage:(nullable UIImage*)image title:(NSString*)title {
    NSString* parameter = image ? @"wprov=sfii1" : @"wprov=sfti1";

    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@",
                                                self.article.title.desktopURL.absoluteString,
                                                parameter]];

    NSMutableArray* activityItems = @[title, url].mutableCopy;
    if (image) {
        [activityItems addObject:image];
    }

    UIActivityViewController* shareActivityVC =
        [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                          applicationActivities:@[] /*shareMenuSavePageActivity*/ ];

    shareActivityVC.excludedActivityTypes = @[
        UIActivityTypePrint,
        UIActivityTypeAssignToContact,
        UIActivityTypeAirDrop,
        UIActivityTypeAddToReadingList
    ];;

    [shareActivityVC setCompletionWithItemsHandler:^(NSString* __nullable activityType, BOOL completed, NSArray* __nullable returnedItems, NSError* __nullable activityError){
        if (completed) {
            [self.shareFunnel logShareSucceededWithShareMethod:activityType];
        } else {
            [self.shareFunnel logShareFailedWithShareMethod:activityType];
        }
    }];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.containerViewController presentViewController:shareActivityVC animated:YES completion:nil];
    } else {
        self.popover          = [[UIPopoverController alloc] initWithContentViewController:shareActivityVC];
        self.popover.delegate = self;

        if (self.originButtonItem) {
            [self.popover presentPopoverFromBarButtonItem:self.originButtonItem
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
        } else {
            CGRect frame = self.originView.frame;
            if (CGRectIsNull(frame)) {
                frame = self.containerViewController.view.frame;
            } else {
                frame = [self.containerViewController.view convertRect:frame fromView:self.originView.superview];
            }

            [self.popover presentPopoverFromRect:frame
                                          inView:self.containerViewController.view
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
    }

    [self cleanup];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController {
    self.popover = nil;
}

@end

NS_ASSUME_NONNULL_END
