//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class MWKSectionList;

@interface WMFSectionTitlesViewController : NSObject

@property (nonatomic, strong) UIWebView* webView;
@property (nonatomic, strong) UIViewController* webViewController;

- (void)addOverlaysForSections:(MWKSectionList*)sections;
- (void)updateOverlayPositions;
- (void)didScrollToOffsetY:(CGFloat)offsetY;
- (void)hideTopOverlay;

@end
