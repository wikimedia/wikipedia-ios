//  Created by Monte Hurd on 2/24/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class WMFWebViewFooterContainerView;

@protocol WMFWebViewFooterContainerDelegate <NSObject>

- (void)footerContainer:(WMFWebViewFooterContainerView*)footerContainer heightChanged:(CGFloat)newHeight;

@end

@interface WMFWebViewFooterContainerView : UIView

@property (nonatomic, weak) id <WMFWebViewFooterContainerDelegate> delegate;

@end
