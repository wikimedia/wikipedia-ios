//  Created by Monte Hurd on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import "WMFSectionHeaderEditProtocol.h"

@class MASViewAttribute;

@interface WMFSectionHeadersViewController : NSObject

- (instancetype)initWithView:(UIView*)view
                     webView:(UIWebView*)webView
              topLayoutGuide:(MASViewAttribute*)topLayoutGuide;

- (void)resetHeaders;
- (void)updateTopHeaderForScrollOffsetY:(CGFloat)offsetY;
- (void)hideTopHeader;

@property (nonatomic, weak) id <WMFSectionHeaderEditDelegate> editSectionDelegate;

@end
