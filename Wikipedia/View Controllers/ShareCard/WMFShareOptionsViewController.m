//
//  ShareOptionsViewController.m
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareOptionsViewController.h"
#import "WMFShareCardViewController.h"
#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "NSString+Extras.h"
#import "NSString+WMFHTMLParsing.h"

@interface WMFShareOptionsViewController ()

@property (strong, nonatomic, readwrite) UIView* backgroundView;
@property (strong, nonatomic, readwrite) NSString* snippet;
@property (strong, nonatomic, readwrite) NSString* snippetForTextOnlySharing;
@property (strong, nonatomic, readwrite) MWKArticle* article;
@property (nonatomic, assign, readwrite) id<WMFShareOptionsViewControllerDelegate> delegate;

@property (strong, nonatomic) UIView* grayOverlay;
@property (strong, nonatomic) WMFShareOptionsView* shareOptions;
@property (strong, nonatomic) UIImage* shareImage;
@property (strong, nonatomic) NSString* shareTitle;
@property (strong, nonatomic) UIPopoverController* popover;


@end

@implementation WMFShareOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)initWithMWKArticle:(MWKArticle*)article
                           snippet:(NSString*)snippet
                    backgroundView:(UIView*)backgroundView
                          delegate:(id)delegate {
    if (!article || !backgroundView) {
        NSAssert(false,
                 @"Valid (article, backgroundView) required: (%@, %@)",
                 article,
                 backgroundView);
        // seriously, we don't need to be crashing the app in prod
        return nil;
    }
    self = [super init];
    if (self) {
        if (!article.title.desktopURL.absoluteString) {
            NSLog(@"Could not retrieve desktop URL for article.");
            return nil;
        }

        _delegate   = delegate;
        _article    = article;
        _shareTitle = article.title.prefixedText;
        WMFShareCardViewController* cardViewController = [[WMFShareCardViewController alloc] initWithNibName:@"ShareCard" bundle:nil];
        _snippet = snippet;
        if (snippet.length == 0) {
            _snippet                   = [self generateSnippetHeuristicallyWithArticle:article];
            _snippetForTextOnlySharing = @"";
        } else {
            _snippetForTextOnlySharing = snippet;
        }

        // get handle, fill, and render
        UIView* cardView = cardViewController.view;
        [cardViewController fillCardWithMWKArticle:article snippet:_snippet];
        _shareImage = [self cardAsUIImageWithView:cardView];

        WMFShareOptionsView* shareOptionsView = [[[NSBundle mainBundle] loadNibNamed:@"ShareOptions" owner:self options:nil] objectAtIndex:0];
        shareOptionsView.cardImageViewContainer.userInteractionEnabled = YES;
        shareOptionsView.shareAsCardLabel.userInteractionEnabled       = YES;
        shareOptionsView.shareAsTextLabel.userInteractionEnabled       = YES;
        shareOptionsView.shareAsCardLabel.text                         = MWLocalizedString(@"share-as-image", nil);
        shareOptionsView.shareAsTextLabel.text                         = MWLocalizedString(@"share-as-text", nil);
        shareOptionsView.cardImageView.image                           = _shareImage;
        _backgroundView                                                = backgroundView;
        [self makeTappableGrayBackgroundWithContainingView:backgroundView];
        [backgroundView addSubview:shareOptionsView];
        _shareOptions = shareOptionsView;
        [self toastShareOptionsView:shareOptionsView toContainingView:backgroundView];
        [_delegate didShowSharePreviewForMWKArticle:article withText:_snippet];
    }
    return self;
}

- (NSString*)generateSnippetHeuristicallyWithArticle:(MWKArticle*)article {
    NSString* heuristicText;
    MWKSectionList* sections = article.sections;
    for (MWKSection* section in sections) {
        heuristicText = [section.text wmf_getStringSnippetWithoutHTML];
        if (heuristicText) {
            break;
        }
    }
    // fall back to something with less treatment
    if (!heuristicText) {
        for (MWKSection* section in sections) {
            heuristicText = [section.text getStringWithoutHTML];
            if (heuristicText) {
                break;
            }
        }
    }

    return heuristicText ? heuristicText : @"";
}

- (UIImage*)cardAsUIImageWithView:(UIView*)theView {
    UIGraphicsBeginImageContext(CGSizeMake(theView.bounds.size.width, theView.bounds.size.height));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [theView.layer renderInContext:ctx];
    UIImage* img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)makeTappableGrayBackgroundWithContainingView:(UIView*)containingView {
    UIView* grayOverlay = [[UIView alloc] initWithFrame:containingView.frame];
    grayOverlay.backgroundColor = [UIColor blackColor];
    grayOverlay.alpha           = 0.42;
    [containingView addSubview:grayOverlay];
    self.grayOverlay = grayOverlay;
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(respondToDimAreaTapGesture:)];
    [grayOverlay addGestureRecognizer:tapRecognizer];
    grayOverlay.translatesAutoresizingMaskIntoConstraints = NO;
    [containingView addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"H:|[grayOverlay]|"
                                                        options:NSLayoutFormatDirectionLeadingToTrailing
                                                        metrics:nil
                                                          views:NSDictionaryOfVariableBindings(grayOverlay)]];
    [containingView addConstraints:[NSLayoutConstraint
                                    constraintsWithVisualFormat:@"V:|[grayOverlay]|"
                                                        options:NSLayoutFormatDirectionLeadingToTrailing
                                                        metrics:nil
                                                          views:NSDictionaryOfVariableBindings(grayOverlay)]];
}

- (void)toastShareOptionsView:(UIView*)sov toContainingView:(UIView*)containingView {
    [containingView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:sov
                                            attribute:NSLayoutAttributeCenterX
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:containingView
                                            attribute:NSLayoutAttributeCenterX
                                           multiplier:1.0f
                                             constant:0.0f]];
    NSLayoutConstraint* verticalPositioning = [NSLayoutConstraint
                                               constraintWithItem:sov
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:containingView
                                                        attribute:NSLayoutAttributeBottom
                                                       multiplier:1.0f
                                                         constant:0.0f];
    [containingView addConstraint:verticalPositioning];

    [containingView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:sov
                                            attribute:NSLayoutAttributeWidth
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                           multiplier:1.0f
                                             constant:sov.bounds.size.width]];

    [containingView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:sov
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                               toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                           multiplier:1.0f
                                             constant:sov.bounds.size.height]];

    [containingView layoutIfNeeded];


    [UIView animateWithDuration:0.42 animations:^{
        [containingView removeConstraint:verticalPositioning];
        [containingView addConstraint:[NSLayoutConstraint
                                       constraintWithItem:sov
                                                attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:containingView
                                                attribute:NSLayoutAttributeBottom
                                               multiplier:1.0f
                                                 constant:0.0f]];
        [containingView layoutIfNeeded];
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
    }];
}

- (void)fadeOutCardChoice {
    [UIView animateWithDuration:0.42 animations:^{
        self.grayOverlay.backgroundColor = [UIColor clearColor];
        self.shareOptions.hidden = YES;
    } completion:^(BOOL finished) {
        [self.grayOverlay removeFromSuperview];
        [self.shareOptions removeFromSuperview];
        self.grayOverlay = nil;
        self.shareOptions = nil;
    }];
}

- (void)respondToDimAreaTapGesture:(UITapGestureRecognizer*)recognizer {
    [self fadeOutCardChoice];
    [self.delegate tappedBackgroundToAbandonWithText:self.snippet];
    [self removeFromParentViewController];
}

- (void)respondToTapForCardGesture:(UITapGestureRecognizer*)recognizer {
    [self.delegate tappedShareCardWithText:self.snippet];
    self.shareTitle = [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
                       stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
    [self transferSharingToDelegate];
}

- (void)respondToTapForTextGesture:(UITapGestureRecognizer*)recognizer {
    [self.delegate tappedShareTextWithText:self.snippet];
    if (self.snippetForTextOnlySharing.length == 0) {
        self.shareTitle = [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
                           stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
    } else {
        self.shareTitle = [[MWLocalizedString(@"share-article-name-on-wikipedia-with-selected-text", nil)
                            stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle]
                           stringByReplacingOccurrencesOfString:@"$2" withString:self.snippetForTextOnlySharing];
    }

    // per UX, don't have an image for Share as text
    self.shareImage = nil;
    [self transferSharingToDelegate];
}

- (void)transferSharingToDelegate {
    NSString* parameter = self.shareImage ? @"wprov=sfii1" : @"wprov=sfti1";

    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?%@",
                                                self.article.title.desktopURL.absoluteString,
                                                parameter]];

    NSMutableArray* activityItems = @[self.shareTitle, url].mutableCopy;
    if (self.shareImage) {
        [activityItems addObject:self.shareImage];
    }
    [self fadeOutCardChoice];
    [self.delegate finishShareWithActivityItems:activityItems text:self.snippet];
    [self removeFromParentViewController];
}

@end
