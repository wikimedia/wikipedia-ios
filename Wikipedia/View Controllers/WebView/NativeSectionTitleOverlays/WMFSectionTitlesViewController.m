//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionTitlesViewController.h"
#import "WMFTitleOverlayLabel.h"
#import "WMFTitleOverlayModel.h"
#import "NSString+Extras.h"
#import "UIView+WMFSearchSubviews.h"
#import <Masonry/Masonry.h>

@interface WMFSectionTitlesViewController ()

@property (nonatomic, strong) NSMutableArray* overlayModels;
@property (nonatomic) NSUInteger indexOfNativeTitleLabelNearestTop;
@property (nonatomic, strong) MASConstraint* topStaticNativeTitleLabelTopConstraint;
@property (nonatomic, strong) WMFTitleOverlayLabel* topStaticNativeTitleLabel;

@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) UIViewController* webViewController;

@end

@implementation WMFSectionTitlesViewController

- (instancetype)initWithWebView:(UIWebView*)webView webViewController:(UIViewController*)webViewController {
    self = [super init];
    if (self) {
        self.overlayModels                     = @[].mutableCopy;
        self.indexOfNativeTitleLabelNearestTop = -1;
        self.webView                           = webView;
        self.webViewController                 = webViewController;
    }
    return self;
}

- (void)hideTopOverlay {
    self.topStaticNativeTitleLabel.alpha = 0;
}

- (void)resetOverlays {
    for (WMFTitleOverlayModel* m in self.overlayModels) {
        [m.label removeFromSuperview];
    }
    [self.overlayModels removeAllObjects];

    [self setupTopStaticNativeTitleOverlayLabel];

    UIView* browserView = [self.webView.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];

    NSArray* sections = [self getSectionTitlesJSON];

    for (NSDictionary* section in sections) {
        NSNumber* sectionId = section[@"sectionId"];

        NSString* title = section[@"text"];
        if (title) {
            title = [title wmf_stringByRemovingHTML];

            WMFTitleOverlayLabel* label = [[WMFTitleOverlayLabel alloc] init];
            label.text      = title;
            label.sectionId = sectionId;

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
            m.anchor        = section[@"anchor"];
            m.title         = title;
            m.topConstraint = topConstraint;
            m.yOffset       = topConstraint.constant;
            m.label         = label;
            m.sectionId     = sectionId;
            [self.overlayModels addObject:m];
        }
    }

    [self updateOverlaysPositions];
}

- (void)setupTopStaticNativeTitleOverlayLabel {
    if (self.topStaticNativeTitleLabel) {
        return;
    }
    self.topStaticNativeTitleLabel       = [[WMFTitleOverlayLabel alloc] init];
    self.topStaticNativeTitleLabel.alpha = 0;
    [self.webViewController.view addSubview:self.topStaticNativeTitleLabel];
    [self.topStaticNativeTitleLabel mas_makeConstraints:^(MASConstraintMaker* make) {
        make.left.equalTo(self.webViewController.view.mas_left);
        make.right.equalTo(self.webViewController.view.mas_right);
        self.topStaticNativeTitleLabelTopConstraint = make.top.equalTo(self.webViewController.mas_topLayoutGuide);
    }];
}

- (void)updateOverlaysPositions {
    NSArray* headingsTopOffsets = [self getSectionTitlesLocationsJSON];
    if (headingsTopOffsets.count == self.overlayModels.count) {
        for (NSUInteger i = 0; i < self.overlayModels.count; i++) {
            WMFTitleOverlayModel* m = self.overlayModels[i];
            if (m.anchor && m.topConstraint) {
                NSNumber* topOffset = headingsTopOffsets[i];
                CGFloat topFloat    = topOffset.floatValue + self.webView.scrollView.contentOffset.y;
                m.topConstraint.constant = topFloat;
                m.yOffset                = topFloat;
            }
        }
    }
}

- (void)updateTopOverlayForScrollOffsetY:(CGFloat)offsetY {
    [self updateIndexOfNativeTitleLabelNearestTopForScrollOffsetY:offsetY];
    [self nudgeTopStaticTitleLabelIfNecessaryForScrollOffsetY:offsetY];
}

- (void)updateIndexOfNativeTitleLabelNearestTopForScrollOffsetY:(CGFloat)offsetY {
    self.topStaticNativeTitleLabel.alpha = (offsetY <= 0) ? 0 : 1;

    CGFloat lastOffset          = 0;
    NSUInteger newTopLabelIndex = -1;

    for (NSUInteger thisIndex = 0; thisIndex < self.overlayModels.count; thisIndex++) {
        WMFTitleOverlayModel* m = self.overlayModels[thisIndex];
        CGFloat thisOffset      = m.yOffset;
        if (offsetY > lastOffset && offsetY <= thisOffset) {
            newTopLabelIndex = thisIndex - 1;
            break;
        } else if ((thisIndex == (self.overlayModels.count - 1)) && (offsetY > thisOffset)) {
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

- (void)nudgeTopStaticTitleLabelIfNecessaryForScrollOffsetY:(CGFloat)offsetY {
    NSUInteger pusherIndex  = self.indexOfNativeTitleLabelNearestTop + 1;
    CGFloat distanceToPushY = 0;
    if (pusherIndex < (self.overlayModels.count)) {
        WMFTitleOverlayModel* pusherTitleLabel = self.overlayModels[pusherIndex];
        if (pusherTitleLabel.sectionId > 0) {
            CGFloat topmostHeaderOffsetY  = pusherTitleLabel.yOffset;
            CGRect staticLabelPseudoRect  = CGRectMake(0, 0, 1, self.topStaticNativeTitleLabel.frame.size.height);
            CGRect topmostLabelPseudoRect = CGRectMake(0, topmostHeaderOffsetY - offsetY, 1, 1);
            if (CGRectIntersectsRect(staticLabelPseudoRect, topmostLabelPseudoRect)) {
                distanceToPushY = staticLabelPseudoRect.size.height - topmostLabelPseudoRect.origin.y;
            }
        }
    }
    [self.topStaticNativeTitleLabelTopConstraint setOffset:-distanceToPushY];
}

- (void)updateTopStaticTitleLabelText {
    self.topStaticNativeTitleLabel.alpha = 1.0;
    WMFTitleOverlayModel* m = self.overlayModels[self.indexOfNativeTitleLabelNearestTop];
    self.topStaticNativeTitleLabel.text      = m.title;
    self.topStaticNativeTitleLabel.sectionId = m.sectionId;
}

#pragma mark Section title and title location determination

- (id)getJSONFromWebViewUsingFunction:(NSString*)jsFunctionString {
    NSString* jsonString = [self.webView stringByEvaluatingJavaScriptFromString:jsFunctionString];
    NSData* jsonData     = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error       = nil;
    id result            = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    return (error) ? nil : result;
}

static NSString* const WMFJSGetSectionTitlesJSON =
    @"(function(){"
    @"  var nodeList = document.querySelectorAll('h1.section_heading');"
    @"  var nodeArray = Array.prototype.slice.call(nodeList);"
    @"  nodeArray = nodeArray.map(function(n){"
    @"    var rect = n.getBoundingClientRect();"
    @"    return {"
    @"        anchor:n.id,"
    @"        sectionId:n.getAttribute('sectionId'),"
    @"        text:n.innerHTML"
    @"    };"
    @"  });"
    @"  return JSON.stringify(nodeArray);"
    @"})();";

- (NSArray*)getSectionTitlesJSON {
    return [self getJSONFromWebViewUsingFunction:WMFJSGetSectionTitlesJSON];
}

static NSString* const WMFJSGetSectionTitlesLocationsJSON =
    @"(function(){"
    @"  var nodeList = document.querySelectorAll('h1.section_heading');"
    @"  var nodeArray = Array.prototype.slice.call(nodeList);"
    @"  nodeArray = nodeArray.map(function(n){"
    @"    return n.getBoundingClientRect().top;"
    @"  });"
    @"  return JSON.stringify(nodeArray);"
    @"})();";

- (NSArray*)getSectionTitlesLocationsJSON {
    return [self getJSONFromWebViewUsingFunction:WMFJSGetSectionTitlesLocationsJSON];
}

@end
