//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "WMFEditSectionProtocol.h"

@class MASViewAttribute;

@interface WMFSectionTitlesViewController : NSObject

- (instancetype)initWithView:(UIView*)view
                     webView:(UIWebView*)webView
              topLayoutGuide:(MASViewAttribute*)topLayoutGuide;

- (void)resetOverlays;
- (void)updateTopOverlayForScrollOffsetY:(CGFloat)offsetY;
- (void)hideTopOverlay;

@property (nonatomic, weak) id <WMFEditSectionDelegate> editSectionDelegate;

@end
