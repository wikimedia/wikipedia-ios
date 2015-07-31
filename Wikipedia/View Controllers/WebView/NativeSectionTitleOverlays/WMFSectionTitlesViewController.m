//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionTitlesViewController.h"
#import "WMFTitleOverlayLabel.h"
#import "WMFTitleOverlayModel.h"
#import "MWKSection.h"
#import "MWKArticle.h"
#import "MWKSectionList.h"
#import "MWKTitle.h"
#import "NSString+Extras.h"
#import "UIView+WMFSearchSubviews.h"
#import <Masonry/Masonry.h>
#import "UIWebView+ElementLocation.h"

@interface WMFSectionTitlesViewController ()

@property (nonatomic, strong) NSMutableArray* nativeTitleLabelModelsArray;
@property (nonatomic) NSUInteger indexOfNativeTitleLabelNearestTop;
@property (nonatomic, strong) NSLayoutConstraint* topStaticNativeTitleLabelTopConstraint;
@property (nonatomic, strong) WMFTitleOverlayLabel* topStaticNativeTitleLabel;

@end

@implementation WMFSectionTitlesViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.nativeTitleLabelModelsArray       = @[].mutableCopy;
        self.indexOfNativeTitleLabelNearestTop = -1;
    }
    return self;
}

- (void)hideTopOverlay {
    self.topStaticNativeTitleLabel.alpha = 0;
}

- (void)addOverlaysForSections:(MWKSectionList*)sections {
    for (WMFTitleOverlayModel* m in self.nativeTitleLabelModelsArray) {
        [m.label removeFromSuperview];
    }
    [self.nativeTitleLabelModelsArray removeAllObjects];

    [self setupTopStaticNativeTitleOverlayLabel];

    UIView* browserView = [self.webView.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];

    for (MWKSection* section in sections) {
        NSString* title = (section.sectionId == 0) ? section.title.text : section.line;
        if (title) {
            title = [title wmf_stringByRemovingHTML];

            WMFTitleOverlayLabel* label = [[WMFTitleOverlayLabel alloc] init];
            label.text      = title;
            label.sectionId = section.sectionId;

            [self.webView.scrollView addSubview:label];

            NSLayoutConstraint* (^ constrainEqually)(NSLayoutAttribute) = ^NSLayoutConstraint*(NSLayoutAttribute attr) {
                NSLayoutConstraint* c =
                    [NSLayoutConstraint constraintWithItem:label
                                                 attribute:attr
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:browserView
                                                 attribute:attr
                                                multiplier:1.0
                                                  constant:0];

                [self.webView.scrollView addConstraint:c];

                return c;
            };

            constrainEqually(NSLayoutAttributeTrailing);
            constrainEqually(NSLayoutAttributeLeading);

            NSLayoutConstraint* topConstraint = constrainEqually(NSLayoutAttributeTop);

            WMFTitleOverlayModel* m = [[WMFTitleOverlayModel alloc] init];
            m.anchor        = section.anchor.copy;
            m.title         = title;
            m.topConstraint = topConstraint;
            m.yOffset       = topConstraint.constant;
            m.label         = label;
            m.sectionId     = section.sectionId;
            [self.nativeTitleLabelModelsArray addObject:m];
        }
    }

    [self updateOverlayPositions];
}

- (void)setupTopStaticNativeTitleOverlayLabel {
    if (self.topStaticNativeTitleLabel) {
        return;
    }
    self.topStaticNativeTitleLabel       = [[WMFTitleOverlayLabel alloc] init];
    self.topStaticNativeTitleLabel.alpha = 0;
    [self.vc.view addSubview:self.topStaticNativeTitleLabel];
    [self.topStaticNativeTitleLabel mas_makeConstraints:^(MASConstraintMaker* make) {
        make.left.equalTo(self.vc.view.mas_left);
        make.right.equalTo(self.vc.view.mas_right);
    }];

    self.topStaticNativeTitleLabelTopConstraint = [NSLayoutConstraint constraintWithItem:self.topStaticNativeTitleLabel
                                                                               attribute:NSLayoutAttributeTop
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.vc.topLayoutGuide
                                                                               attribute:NSLayoutAttributeBottom
                                                                              multiplier:1.0
                                                                                constant:0];
    [self.vc.view addConstraint:self.topStaticNativeTitleLabelTopConstraint];
}

- (void)updateOverlayPositions {
    if (self.nativeTitleLabelModelsArray.count > 0) {
        for (NSUInteger i = 0; i < self.nativeTitleLabelModelsArray.count; i++) {
            WMFTitleOverlayModel* m = self.nativeTitleLabelModelsArray[i];
            if (m.anchor && m.topConstraint) {
                CGRect rect = [self.webView getWebViewRectForHtmlElementWithId:m.anchor];
                m.topConstraint.constant = rect.origin.y;
                m.yOffset                = m.topConstraint.constant;
            }
        }
    }
}

- (void)didScrollToOffsetY:(CGFloat)offsetY {
    [self updateIndexOfNativeTitleLabelNearestTopForScrollContentOffset:offsetY];
    [self nudgeTopStaticTitleLabelIfNecessaryForScrollContentOffset:offsetY];
}

- (void)updateIndexOfNativeTitleLabelNearestTopForScrollContentOffset:(CGFloat)offsetY {
    self.topStaticNativeTitleLabel.alpha = (offsetY <= 0) ? 0 : 1;

    CGFloat lastOffset          = 0;
    NSUInteger newTopLabelIndex = -1;

    for (NSUInteger thisIndex = 0; thisIndex < self.nativeTitleLabelModelsArray.count; thisIndex++) {
        WMFTitleOverlayModel* m = self.nativeTitleLabelModelsArray[thisIndex];
        CGFloat thisOffset      = m.yOffset;
        if (offsetY > lastOffset && offsetY <= thisOffset) {
            newTopLabelIndex = thisIndex - 1;
            break;
        } else if ((thisIndex == (self.nativeTitleLabelModelsArray.count - 1)) && (offsetY > thisOffset)) {
            newTopLabelIndex = thisIndex;
            break;
        }
        lastOffset = thisOffset;
    }

    if (newTopLabelIndex != -1) {
        if (newTopLabelIndex != self.indexOfNativeTitleLabelNearestTop) {
            self.indexOfNativeTitleLabelNearestTop = newTopLabelIndex;
            [self updateTopStaticTitleLabelText];
        }
    }
}

- (void)nudgeTopStaticTitleLabelIfNecessaryForScrollContentOffset:(CGFloat)offsetY {
    NSUInteger pusherIndex  = self.indexOfNativeTitleLabelNearestTop + 1;
    CGFloat distanceToPushY = 0;
    if (pusherIndex < (self.nativeTitleLabelModelsArray.count)) {
        WMFTitleOverlayModel* pusherTitleLabel = self.nativeTitleLabelModelsArray[pusherIndex];
        if (pusherTitleLabel.sectionId > 0) {
            CGFloat topmostHeaderOffsetY  = pusherTitleLabel.yOffset;
            CGRect staticLabelPseudoRect  = CGRectMake(0, 0, 1, self.topStaticNativeTitleLabel.frame.size.height);
            CGRect topmostLabelPseudoRect = CGRectMake(0, topmostHeaderOffsetY - offsetY, 1, 1);
            if (CGRectIntersectsRect(staticLabelPseudoRect, topmostLabelPseudoRect)) {
                distanceToPushY = staticLabelPseudoRect.size.height - topmostLabelPseudoRect.origin.y;
            }
        }
    }
    self.topStaticNativeTitleLabelTopConstraint.constant = -distanceToPushY;
}

- (void)updateTopStaticTitleLabelText {
    self.topStaticNativeTitleLabel.alpha = 1.0;
    WMFTitleOverlayModel* m = self.nativeTitleLabelModelsArray[self.indexOfNativeTitleLabelNearestTop];
    self.topStaticNativeTitleLabel.text      = m.title;
    self.topStaticNativeTitleLabel.sectionId = m.sectionId;
}

@end
