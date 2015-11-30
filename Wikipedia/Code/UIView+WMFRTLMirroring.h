//  Created by Monte Hurd on 6/22/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface UIView (WMFRTLMirroring)

- (void)wmf_mirrorIfDeviceRTL;

+ (BOOL)wmf_shouldMirrorIfDeviceLanguageRTL;

@end
