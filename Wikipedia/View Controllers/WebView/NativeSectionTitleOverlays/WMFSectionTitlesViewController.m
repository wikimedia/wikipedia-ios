//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionTitlesViewController.h"
#import "WMFTitleOverlay.h"
#import "WMFTitleOverlayModel.h"
#import "NSString+Extras.h"
#import "UIView+WMFSearchSubviews.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import "UIView+WMFDefaultNib.h"

@interface WMFSectionTitlesViewController ()

@property (nonatomic, strong) NSArray* overlayModels;
@property (nonatomic, strong) MASConstraint* topStaticOverlayTopConstraint;
@property (nonatomic, strong) WMFTitleOverlay* topStaticOverlay;
@property (nonatomic, weak) UIView* view;
@property (nonatomic, weak) UIWebView* webView;
@property (nonatomic, strong) MASViewAttribute* topLayoutGuide;

@end

@implementation WMFSectionTitlesViewController

- (instancetype)initWithView:(UIView*)view
                     webView:(UIWebView*)webView
              topLayoutGuide:(MASViewAttribute*)topLayoutGuide {
    self = [super init];
    if (self) {
        self.overlayModels  = @[];
        self.view           = view;
        self.webView        = webView;
        self.topLayoutGuide = topLayoutGuide;
        [self.KVOControllerNonRetaining observe:self.webView.scrollView
                                        keyPath:WMF_SAFE_KEYPATH(UIScrollView.new, contentSize)
                                        options:NSKeyValueObservingOptionNew
                                          block:^(WMFSectionTitlesViewController* observer, id object, NSDictionary* change) {
            [self updateOverlaysPositions];
        }];
    }
    return self;
}

- (void)hideTopOverlay {
    self.topStaticOverlay.alpha = 0;
}

- (void)removeAnyExistingTitleOverlays {
    NSArray* existingOverlays = [self.webView.scrollView.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [WMFTitleOverlay class]]];
    [existingOverlays makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)resetOverlays {
    [self setupTopStaticTitleOverlay];

    NSArray* sections         = [self getSectionTitlesJSON];
    NSArray* nonBlankSections = [sections bk_select:^BOOL (NSDictionary* section) {
        return (section[@"text"] != nil);
    }];

    [self updateOverlayModelsForSections:nonBlankSections];
    [self addOverlayForEachOverlayModel];
    [self updateOverlaysPositions];
}

- (void)updateOverlayModelsForSections:(NSArray*)sections {
    self.overlayModels = [sections bk_map:^id (NSDictionary* section) {
        WMFTitleOverlayModel* model = [[WMFTitleOverlayModel alloc] init];
        model.anchor = section[@"anchor"];
        model.title = [section[@"text"] wmf_stringByRemovingHTML];
        model.yOffset = 0;
        model.sectionId = section[@"sectionId"];
        return model;
    }];
}

- (void)addOverlayForEachOverlayModel {
    [self removeAnyExistingTitleOverlays];
    UIView* browserView = [self.webView.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];
    for (WMFTitleOverlayModel* model in self.overlayModels) {
        WMFTitleOverlay* overlay = [WMFTitleOverlay wmf_viewFromClassNib];
        overlay.title     = model.title;
        overlay.sectionId = model.sectionId;
        [self.webView.scrollView addSubview:overlay];
        [overlay mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.equalTo(browserView.mas_leading);
            make.trailing.equalTo(browserView.mas_trailing);
            model.topConstraint = make.top.equalTo(browserView.mas_top);
        }];
    }
}

- (void)setupTopStaticTitleOverlay {
    if (self.topStaticOverlay) {
        return;
    }
    self.topStaticOverlay       = [WMFTitleOverlay wmf_viewFromClassNib];
    self.topStaticOverlay.alpha = 0;
    [self.view addSubview:self.topStaticOverlay];
    [self.topStaticOverlay mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        self.topStaticOverlayTopConstraint = make.top.equalTo(self.topLayoutGuide);
    }];
}

- (void)updateOverlaysPositions {
    NSArray* headingsTopOffsets = [self getSectionTitlesLocationsJSON];

    NSAssert((headingsTopOffsets.count == self.overlayModels.count), @"Headings offsets count %ld is not equal to Models count %ld!", headingsTopOffsets.count, self.overlayModels.count);

    if (headingsTopOffsets.count == self.overlayModels.count) {
        for (NSUInteger i = 0; i < self.overlayModels.count; i++) {
            WMFTitleOverlayModel* m = self.overlayModels[i];
            if (m.anchor && m.topConstraint) {
                NSNumber* topOffset = headingsTopOffsets[i];
                CGFloat topFloat    = topOffset.floatValue + self.webView.scrollView.contentOffset.y;
                [m.topConstraint setOffset:topFloat];
                m.yOffset = topFloat;
            }
        }
    }
}

- (void)updateTopOverlayForScrollOffsetY:(CGFloat)offsetY {
    static NSUInteger lastTopmostIndex = -1;

    NSUInteger topmostIndex = [self indexOfTopmostSectionForWebViewScrollOffsetY:offsetY];

    if (topmostIndex != lastTopmostIndex) {
        self.topStaticOverlay.alpha = (topmostIndex == -1) ? 0 : 1;
        if (topmostIndex != -1) {
            WMFTitleOverlayModel* topmostOverlayModel = self.overlayModels[topmostIndex];
            [self updateTopStaticOverlayWithModel:topmostOverlayModel];
        }
    }

    lastTopmostIndex = topmostIndex;

    NSUInteger pusherIndex                 = topmostIndex + 1;
    CGFloat distanceToPushTopStaticOverlay = 0;

    if (pusherIndex < self.overlayModels.count) {
        WMFTitleOverlayModel* pusherOverlayModel = self.overlayModels[pusherIndex];
        if (pusherOverlayModel.sectionId != 0) {
            distanceToPushTopStaticOverlay =
                [self yOverlapOfTopStaticOverlayAndPusherOverlay:pusherOverlayModel forWebViewScrollOffsetY:offsetY];
        }
    }

    [self.topStaticOverlayTopConstraint setOffset:distanceToPushTopStaticOverlay];
}

- (void)updateTopStaticOverlayWithModel:(WMFTitleOverlayModel*)model {
    self.topStaticOverlay.title     = model.title;
    self.topStaticOverlay.sectionId = model.sectionId;
}

- (NSUInteger)indexOfTopmostSectionForWebViewScrollOffsetY:(CGFloat)offsetY {
    NSUInteger newPusherIndex = -1;
    // Note: "-1" above doesn't indicate "not found" - the scroll offset Y can be
    // negative (think "pull-to-refresh") and we need to be able to tell when this happens.

    CGFloat lastOffset = 0;
    for (NSUInteger thisIndex = 0; thisIndex < self.overlayModels.count; thisIndex++) {
        WMFTitleOverlayModel* m = self.overlayModels[thisIndex];
        CGFloat thisOffset      = m.yOffset;
        if (offsetY > lastOffset && offsetY <= thisOffset) {
            newPusherIndex = thisIndex - 1;
            break;
        } else if ((thisIndex == (self.overlayModels.count - 1)) && (offsetY > thisOffset)) {
            newPusherIndex = thisIndex;
            break;
        }
        lastOffset = thisOffset;
    }
    return newPusherIndex;
}

- (CGFloat)yOverlapOfTopStaticOverlayAndPusherOverlay:(WMFTitleOverlayModel*)pusherModel forWebViewScrollOffsetY:(CGFloat)offsetY {
    CGFloat yOverlap               = 0;
    CGRect staticOverlayPseudoRect = CGRectMake(0, 0, 1, self.topStaticOverlay.frame.size.height);
    CGRect pusherOverlayPseudoRect = CGRectMake(0, pusherModel.yOffset - offsetY, 1, 1);
    if (CGRectIntersectsRect(staticOverlayPseudoRect, pusherOverlayPseudoRect)) {
        yOverlap = staticOverlayPseudoRect.size.height - pusherOverlayPseudoRect.origin.y;
    }
    return -yOverlap;
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
