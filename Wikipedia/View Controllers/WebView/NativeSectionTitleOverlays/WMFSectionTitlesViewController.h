//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>

@class MWKSectionList, WMFTitleOverlayLabel;

@interface WMFSectionTitlesViewController : NSObject

@property (nonatomic, strong) UIViewController* vc;
@property (nonatomic, strong) UIWebView* webView;

- (void)addOverlaysForSections:(MWKSectionList*)sections;
- (void)updateOverlayPositions;
- (void)didScrollToOffsetY:(CGFloat)offsetY;
- (void)hideTopOverlay;

@end
