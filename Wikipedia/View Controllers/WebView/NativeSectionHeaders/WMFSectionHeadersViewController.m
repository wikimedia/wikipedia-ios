//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionHeadersViewController.h"
#import "WMFSectionHeader.h"
#import "WMFSectionHeaderModel.h"
#import "NSString+Extras.h"
#import "UIView+WMFSearchSubviews.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/BlocksKit.h>
#import "UIView+WMFDefaultNib.h"
#import "WMFEditSectionProtocol.h"

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
            [self updateHeadersPositions];
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

    NSArray* sections         = [self getSectionHeadersJSON];
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
        model.anchor = section[@"anchor"];
        model.title = [section[@"text"] wmf_stringByRemovingHTML];
        model.yOffset = 0;
        model.sectionId = section[@"sectionId"];
        return model;
    }];
}

- (void)addHeaderForEachModel {
    [self removeExistingSectionHeaders];
    UIView* browserView = [self.webView.scrollView wmf_firstSubviewOfClass:NSClassFromString(@"UIWebBrowserView")];
    for (WMFSectionHeaderModel* model in self.sectionHeaderModels) {
        WMFSectionHeader* header = [WMFSectionHeader wmf_viewFromClassNib];
        header.editSectionDelegate = self.editSectionDelegate;
        header.title               = model.title;
        header.sectionId           = model.sectionId;
        [self.webView.scrollView addSubview:header];
        [header mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.equalTo(browserView.mas_leading);
            make.trailing.equalTo(browserView.mas_trailing);
            model.topConstraint = make.top.equalTo(browserView.mas_top);
        }];
    }
}

- (void)setupTopStaticHeader {
    if (self.topStaticHeader) {
        return;
    }
    self.topStaticHeader                     = [WMFSectionHeader wmf_viewFromClassNib];
    self.topStaticHeader.editSectionDelegate = self.editSectionDelegate;
    self.topStaticHeader.alpha               = 0;
    [self.view addSubview:self.topStaticHeader];
    [self.topStaticHeader mas_makeConstraints:^(MASConstraintMaker* make) {
        make.leading.equalTo(self.view.mas_leading);
        make.trailing.equalTo(self.view.mas_trailing);
        self.topStaticHeaderTopConstraint = make.top.equalTo(self.topLayoutGuide);
    }];
}

- (void)updateHeadersPositions {
    NSArray* headingsTopOffsets = [self getSectionHeadersLocationsJSON];

    if (headingsTopOffsets.count == self.sectionHeaderModels.count) {
        for (NSUInteger i = 0; i < self.sectionHeaderModels.count; i++) {
            WMFSectionHeaderModel* m = self.sectionHeaderModels[i];
            if (m.anchor && m.topConstraint) {
                NSNumber* topOffset = headingsTopOffsets[i];
                CGFloat topFloat    = topOffset.floatValue + self.webView.scrollView.contentOffset.y;
                [m.topConstraint setOffset:topFloat];
                m.yOffset = topFloat;
            }
        }
    }
}

- (void)updateTopHeaderForScrollOffsetY:(CGFloat)offsetY {
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

- (id)getJSONFromWebViewUsingFunction:(NSString*)jsFunctionString {
    NSString* jsonString = [self.webView stringByEvaluatingJavaScriptFromString:jsFunctionString];
    NSData* jsonData     = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error       = nil;
    id result            = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    return (error) ? nil : result;
}

static NSString* const WMFJSGetSectionHeadersJSON =
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

- (NSArray*)getSectionHeadersJSON {
    return [self getJSONFromWebViewUsingFunction:WMFJSGetSectionHeadersJSON];
}

static NSString* const WMFJSGetSectionHeadersLocationsJSON =
    @"(function(){"
    @"  var nodeList = document.querySelectorAll('h1.section_heading');"
    @"  var nodeArray = Array.prototype.slice.call(nodeList);"
    @"  nodeArray = nodeArray.map(function(n){"
    @"    return n.getBoundingClientRect().top;"
    @"  });"
    @"  return JSON.stringify(nodeArray);"
    @"})();";

- (NSArray*)getSectionHeadersLocationsJSON {
    return [self getJSONFromWebViewUsingFunction:WMFJSGetSectionHeadersLocationsJSON];
}

@end
