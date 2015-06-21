//  Created by Monte Hurd on 6/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIView+WMFRTLMirroring.h"
#import "WikipediaAppUtils.h"

@implementation UIView (WMFRTLMirroring)

- (void)wmf_mirrorIfDeviceRTL {
    if ([WikipediaAppUtils isDeviceLanguageRTL] && [UIView wmf_shouldMirrorIfDeviceLanguageRTL]) {
        // Mirror the view.
        self.transform = CGAffineTransformMakeScale(-1, 1);
        // Flip labels back so their text isn't mirrored.
        [self recursivelyUnMirrorSubviewLabels];
    }
}

- (void)recursivelyUnMirrorSubviewLabels {
    for (UIView* subView in self.subviews.copy) {
        if ([subView isKindOfClass:[UILabel class]]) {
            subView.transform = CGAffineTransformMakeScale(-1, 1);
        }
        [subView recursivelyUnMirrorSubviewLabels];
    }
}

+ (BOOL)wmf_shouldMirrorIfDeviceLanguageRTL {
//TODO: Confirm the presumption that on iOS 9 (and greater) navigation and tool bars get mirrored automatically.
    return ([UIDevice currentDevice].systemVersion.floatValue < 9.0);
}

@end
