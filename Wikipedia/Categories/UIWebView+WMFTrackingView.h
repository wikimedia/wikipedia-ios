//  Created by Monte Hurd on 2/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, WMFTrackingViewLocation) {
    WMFTrackingViewLocationTop,
    WMFTrackingViewLocationBottom
};

@interface UIWebView (WMF_TrackingView)

- (void)wmf_addTrackingView:(UIView*)view
                 atLocation:(WMFTrackingViewLocation)location;

@end
