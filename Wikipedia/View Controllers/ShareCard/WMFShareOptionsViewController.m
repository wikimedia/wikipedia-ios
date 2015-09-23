//
//  ShareOptionsViewController.m
//  Wikipedia
//
//  Created by Adam Baso on 2/6/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFShareOptionsViewController.h"

#import "Wikipedia-Swift.h"
#import <Masonry/Masonry.h>

#import "WMFShareFunnel.h"

#import "NSString+Extras.h"
#import "NSString+WMFHTMLParsing.h"

#import "UIView+WMFShapshotting.h"

#import "WMFShareCardViewController.h"
#import "WMFShareOptionsView.h"
#import "PaddedLabel.h"
#import "WikipediaAppUtils.h"
#import "MWKArticle+WMFSharing.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFShareOptionsViewController ()

@property (strong, nonatomic, readwrite) MWKArticle* article;
@property (copy, nonatomic, readwrite) NSString* snippet;
@property (strong, nonatomic, readwrite) WMFShareFunnel* shareFunnel;

@property (weak, nonatomic) UIViewController* containerViewController;
@property (nullable, weak, nonatomic) UIBarButtonItem* originButtonItem;
@property (nullable, weak, nonatomic) UIView* originView;

@property (nullable, strong, nonatomic) UIView* grayOverlay;
@property (nullable, strong, nonatomic) WMFShareOptionsView* shareOptions;
@property (nullable, strong, nonatomic) UIImage* shareImage;
@property (strong, nonatomic) NSString* shareTitle;

@property (strong, nonatomic) UIPopoverController* popover;

@end

@implementation WMFShareOptionsViewController

- (instancetype)initWithArticle:(MWKArticle*)article
                        snippet:(nullable NSString*)snippet
                    shareFunnel:(WMFShareFunnel*)funnel{
    
    NSParameterAssert(article);
    NSParameterAssert(funnel);
    NSParameterAssert(article.title.desktopURL.absoluteString);

    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        
        _article        = article;
        _shareTitle     = [article.title.text copy];
        _shareFunnel = funnel;
        _snippet = [snippet copy];
    }
    return self;
}

#pragma mark - Accessors

- (NSString*)snippet{
    if(_snippet.length == 0){
        return [[self.article shareSnippet] copy];
    }
    return _snippet;
}

- (NSString*)snippetForTextOnlySharing{
    if(_snippet.length == 0){
        return @"";
    }
    return [_snippet copy];
}

#pragma mark - Public Presentation methods

- (void)presentShareOptionsFromViewController:(UIViewController*)viewController barButtonItem:(UIBarButtonItem*)item{
    self.containerViewController = viewController;
    self.originButtonItem = item;
    self.originView = nil;
    [self fetchImageThenShowShareCard];

}

- (void)presentShareOptionsFromViewController:(UIViewController*)viewController view:(nullable UIView*)view{
    self.containerViewController = viewController;
    self.originButtonItem = nil;
    self.originView = view;
    [self fetchImageThenShowShareCard];
}

#pragma mark - Asynchornous Fetch and Present

- (void)fetchImageThenShowShareCard {
    [[WMFImageController sharedInstance] fetchImageWithURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]].then(^(WMFImageDownload* download){
        [self showShareOptionsWithImage:download.image];
    }).catch(^(NSError* error){
        [self showShareOptionsWithImage:nil];
    });
}

#pragma mark - Share Options Setup

- (void)showShareOptionsWithImage:(nullable UIImage*)image {
    
    [self setupBackgroundView];

    _shareImage = [self cardImageWithArticleImage:image];
    
    [self setupShareOptionsWithImage:_shareImage];
    
    [self presentShareOptionsView:self.shareOptions];
}

- (void)setupBackgroundView{
    
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
    [grayOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.edges.equalTo(containingView);
    }];
}

- (void)setupShareOptionsWithImage:(UIImage*)image{
    
    WMFShareOptionsView* shareOptionsView =
    [[[NSBundle mainBundle] loadNibNamed:@"ShareOptions" owner:self options:nil] objectAtIndex:0];
    shareOptionsView.cardImageViewContainer.userInteractionEnabled = YES;
    shareOptionsView.shareAsCardLabel.userInteractionEnabled       = YES;
    shareOptionsView.shareAsTextLabel.userInteractionEnabled       = YES;
    shareOptionsView.shareAsCardLabel.text                         = MWLocalizedString(@"share-as-image", nil);
    shareOptionsView.shareAsTextLabel.text                         = MWLocalizedString(@"share-as-text", nil);
    shareOptionsView.cardImageView.image                           = _shareImage;
    
    [self.containerViewController.view addSubview:shareOptionsView];
    self.shareOptions = shareOptionsView;
}


#pragma mark - Create Card Image

- (UIImage*)cardImageWithArticleImage:(UIImage*)image{
    WMFShareCardViewController* cardViewController =
    [[WMFShareCardViewController alloc] initWithNibName:@"ShareCard" bundle:nil];
    
    UIView* cardView = cardViewController.view;
    [cardViewController fillCardWithMWKArticle:self.article snippet:_snippet image:image];
    
    return [cardView wmf_snapshotImage];
}


#pragma mark - Share Options

- (void)presentShareOptionsView:(UIView*)shareOptionsView{
    
    UIView* containingView = self.containerViewController.view;
    
    [shareOptionsView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@360);
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);

        make.top.equalTo(containingView.mas_bottom);
    }];
    
    [shareOptionsView layoutIfNeeded];

    [shareOptionsView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@360);
        make.width.equalTo(containingView.mas_width);
        make.centerX.equalTo(containingView.mas_centerX);
    
        make.bottom.equalTo(containingView.mas_bottom);
    }];
    
    [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.0 options:0 animations:^{
        
        [shareOptionsView layoutIfNeeded];
        
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
    }];
}

- (void)dismissShareOptions {
    [UIView animateWithDuration:0.35 animations:^{
        self.grayOverlay.alpha = 0.0;
        self.shareOptions.hidden = YES;
    } completion:^(BOOL finished) {
        [self.grayOverlay removeFromSuperview];
        [self.shareOptions removeFromSuperview];
        self.grayOverlay = nil;
        self.shareOptions = nil;
    }];
}


#pragma mark - Tap Gestures

- (void)respondToDimAreaTapGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logAbandonedAfterSeeingShareAFact];
    [[WMFImageController sharedInstance] cancelFetchForURL:[NSURL wmf_optionalURLWithString:self.article.imageURL]];
    [self dismissShareOptions];
}

- (void)respondToTapForCardGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logShareAsImageTapped];
    [self dismissShareOptions];
    [self presentActivityViewControllerWithImage:self.shareImage title:[self titleForActivityWithCard]];
}

- (void)respondToTapForTextGesture:(UITapGestureRecognizer*)recognizer {
    [self.shareFunnel logShareAsTextTapped];
    [self dismissShareOptions];
    [self presentActivityViewControllerWithImage:nil title:[self titleForActivityTextOnly]];
}

#pragma mark - Activity View Controller

- (NSString*)titleForActivityWithCard{
    return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
                       stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
}

- (NSString*)titleForActivityTextOnly{
    if (self.snippetForTextOnlySharing.length == 0) {
        return [MWLocalizedString(@"share-article-name-on-wikipedia", nil)
                           stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle];
    } else {
        return [[MWLocalizedString(@"share-article-name-on-wikipedia-with-selected-text", nil)
                            stringByReplacingOccurrencesOfString:@"$1" withString:self.shareTitle]
                           stringByReplacingOccurrencesOfString:@"$2" withString:self.snippetForTextOnlySharing];
    }
}

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
    
    [shareActivityVC setCompletionWithItemsHandler:^(NSString * __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        if (completed) {
            [self.shareFunnel logShareSucceededWithShareMethod:activityType];
        } else {
            [self.shareFunnel logShareFailedWithShareMethod:activityType];
        }
    }];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.containerViewController presentViewController:shareActivityVC animated:YES completion:nil];
    } else {
        
        self.popover = [[UIPopoverController alloc] initWithContentViewController:shareActivityVC];
        
        if(self.originButtonItem){

            [self.popover presentPopoverFromBarButtonItem:self.originButtonItem
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
        }else{
            
            [self.popover presentPopoverFromRect:self.originView.frame
                                          inView:self.containerViewController.view
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
        
    }
}

@end

NS_ASSUME_NONNULL_END
