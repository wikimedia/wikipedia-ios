//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionHeadersViewController.h"
#import "WMFSectionHeader.h"
#import "WMFSectionHeaderModel.h"
#import "UIView+WMFSearchSubviews.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import "UIView+WMFDefaultNib.h"
#import "WMFSectionHeaderEditProtocol.h"
#import "UIWebView+WMFJavascriptContext.h"

@import JavaScriptCore;

@interface WMFSectionHeadersViewController ()

@property (nonatomic, strong) NSArray* sectionHeaderModels;
@property (nonatomic, strong) MASConstraint* topStaticHeaderTopConstraint;
@property (nonatomic, strong) WMFSectionHeader* topStaticHeader;
@property (nonatomic, weak) UIView* view;
@property (nonatomic, weak) UIWebView* webView;
@property (nonatomic, strong) MASViewAttribute* topLayoutGuide;

@end

@implementation WMFSectionHeadersViewController

- (instancetype)initWithView:(UIView*)view
                     webView:(UIWebView*)webView
              topLayoutGuide:(MASViewAttribute*)topLayoutGuide {
    self = [super init];
    if (self) {
        self.sectionHeaderModels = @[];
        self.view                = view;
        self.webView             = webView;
        self.topLayoutGuide      = topLayoutGuide;
        [self.KVOControllerNonRetaining observe:self.webView.scrollView
                                        keyPath:WMF_SAFE_KEYPATH(UIScrollView.new, contentSize)
                                        options:NSKeyValueObservingOptionNew
                                          block:^(WMFSectionHeadersViewController* observer, id object, NSDictionary* change) {
            [observer updateHeadersPositions];
        }];
    }
    return self;
}

- (void)hideTopHeader {
    self.topStaticHeader.alpha = 0;
}

- (void)removeExistingSectionHeaders {
    NSArray* existingHeaders = [self.webView.scrollView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [WMFSectionHeader class]]];
    [existingHeaders makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)resetHeaders {
    [self setupTopStaticHeader];

    NSArray* sections         = [self getSectionHeadersFromWebView];
    NSArray* nonBlankSections = [sections bk_select:^BOOL (NSDictionary* section) {
        return (section[@"text"] != nil);
    }];

    [self updateModelsForSections:nonBlankSections];
    [self addHeaderForEachModel];
    [self updateHeadersPositions];
}

- (void)updateModelsForSections:(NSArray*)sections {
    self.sectionHeaderModels = [sections bk_map:^id (NSDictionary* section) {
        WMFSectionHeaderModel* model = [[WMFSectionHeaderModel alloc] init];
        model.title = section[@"text"];
        model.yOffset = 0;
        model.sectionId = section[@"sectionId"];
        model.anchor = section[@"anchor"];
        return model;
    }];
}

- (void)addHeaderForEachModel {
    [self removeExistingSectionHeaders];
    UIView* browserView = [self.webView.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];
    for (WMFSectionHeaderModel* model in self.sectionHeaderModels) {
        WMFSectionHeader* header = [WMFSectionHeader wmf_viewFromClassNib];
        header.editSectionDelegate = self.editSectionDelegate;
        [self setupTapCallbackForSectionHeader:header];
        header.title     = model.title;
        header.sectionId = model.sectionId;
        header.anchor    = model.anchor;
        [self.webView.scrollView addSubview:header];
        [header mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.equalTo(browserView.mas_leading);
            make.trailing.equalTo(browserView.mas_trailing);
            model.topConstraint = make.top.equalTo(browserView.mas_top);
        }];
    }
}

- (void)setupTapCallbackForSectionHeader:(WMFSectionHeader*)sectionHeader {
    [sectionHeader addTarget:self action:@selector(scrollToAnchorForSectionHeader:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)scrollToAnchorForSectionHeader:(WMFSectionHeader*)sectionHeader {
    WMFSectionHeaderModel* tappedModel = [self.sectionHeaderModels bk_match:^BOOL (WMFSectionHeaderModel* model) {
        return ([model.anchor isEqualToString:sectionHeader.anchor]);
    }];
    if (tappedModel) {
        [self.webView.scrollView setContentOffset:CGPointMake(0, tappedModel.yOffset + 3) animated:YES];
    }
}

- (void)setupTopStaticHeader {
    if (self.topStaticHeader) {
        return;
    }
    self.topStaticHeader                     = [WMFSectionHeader wmf_viewFromClassNib];
    self.topStaticHeader.editSectionDelegate = self.editSectionDelegate;
    [self setupTapCallbackForSectionHeader:self.topStaticHeader];
    self.topStaticHeader.alpha = 0;
    [self.view addSubview:self.topStaticHeader];
    [self.topStaticHeader mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        self.topStaticHeaderTopConstraint = make.top.equalTo(self.topLayoutGuide);
    }];
}

- (void)updateHeadersPositions {
    NSArray* headingsTopOffsets = [self getSectionHeadersLocationsFromWebView];

    if (headingsTopOffsets.count == self.sectionHeaderModels.count) {
        for (NSUInteger i = 0; i < self.sectionHeaderModels.count; i++) {
            WMFSectionHeaderModel* m = self.sectionHeaderModels[i];
            if (m.topConstraint) {
                NSNumber* topOffset = headingsTopOffsets[i];
                CGFloat topFloat    = topOffset.floatValue + self.webView.scrollView.contentOffset.y;
                topFloat += self.webView.scrollView.contentInset.top;
                [m.topConstraint setOffset:topFloat];
                m.yOffset = topFloat;
            }
        }
    }
}

- (void)updateTopHeaderForScrollOffsetY:(CGFloat)offsetY {
    offsetY += self.webView.scrollView.contentInset.top;
    static NSUInteger lastTopmostIndex = -1;

    NSUInteger topmostIndex = [self indexOfTopmostSectionForWebViewScrollOffsetY:offsetY];

    if (topmostIndex != lastTopmostIndex) {
        self.topStaticHeader.alpha = (topmostIndex == -1) ? 0 : 1;
        if (topmostIndex != -1) {
            WMFSectionHeaderModel* topmostHeaderModel = self.sectionHeaderModels[topmostIndex];
            [self updateTopStaticHeaderWithModel:topmostHeaderModel];
        }
    }

    lastTopmostIndex = topmostIndex;

    NSUInteger pusherIndex                = topmostIndex + 1;
    CGFloat distanceToPushTopStaticHeader = 0;

    if (pusherIndex < self.sectionHeaderModels.count) {
        WMFSectionHeaderModel* pusherHeaderModel = self.sectionHeaderModels[pusherIndex];
        if (pusherHeaderModel.sectionId != 0) {
            distanceToPushTopStaticHeader =
                [self yOverlapOfTopStaticHeaderAndPusherHeader:pusherHeaderModel forWebViewScrollOffsetY:offsetY];
        }
    }

    [self.topStaticHeaderTopConstraint setOffset:distanceToPushTopStaticHeader];
}

- (void)updateTopStaticHeaderWithModel:(WMFSectionHeaderModel*)model {
    self.topStaticHeader.title     = model.title;
    self.topStaticHeader.sectionId = model.sectionId;
    self.topStaticHeader.anchor    = model.anchor;
}

- (NSUInteger)indexOfTopmostSectionForWebViewScrollOffsetY:(CGFloat)offsetY {
    NSUInteger newPusherIndex = -1;
    // Note: "-1" above doesn't indicate "not found" - the scroll offset Y can be
    // negative (think "pull-to-refresh") and we need to be able to tell when this happens.

    CGFloat lastOffset = 0;
    for (NSUInteger thisIndex = 0; thisIndex < self.sectionHeaderModels.count; thisIndex++) {
        WMFSectionHeaderModel* m = self.sectionHeaderModels[thisIndex];
        CGFloat thisOffset       = m.yOffset;
        if (offsetY > lastOffset && offsetY <= thisOffset) {
            newPusherIndex = thisIndex - 1;
            break;
        } else if ((thisIndex == (self.sectionHeaderModels.count - 1)) && (offsetY > thisOffset)) {
            newPusherIndex = thisIndex;
            break;
        }
        lastOffset = thisOffset;
    }
    return newPusherIndex;
}

- (CGFloat)yOverlapOfTopStaticHeaderAndPusherHeader:(WMFSectionHeaderModel*)pusherModel forWebViewScrollOffsetY:(CGFloat)offsetY {
    CGFloat yOverlap              = 0;
    CGRect staticHeaderPseudoRect = CGRectMake(0, 0, 1, self.topStaticHeader.frame.size.height);
    CGRect pusherHeaderPseudoRect = CGRectMake(0, pusherModel.yOffset - offsetY, 1, 1);
    if (CGRectIntersectsRect(staticHeaderPseudoRect, pusherHeaderPseudoRect)) {
        yOverlap = staticHeaderPseudoRect.size.height - pusherHeaderPseudoRect.origin.y;
    }
    return -yOverlap;
}

#pragma mark Section title and title location determination

- (NSArray*)getSectionHeadersFromWebView {
    return [[[self.webView wmf_javascriptContext][@"getSectionHeadersArray"] callWithArguments:nil] toArray];
}

- (NSArray*)getSectionHeadersLocationsFromWebView {
    return [[[self.webView wmf_javascriptContext][@"getSectionHeaderLocationsArray"] callWithArguments:nil] toArray];
}

@end
