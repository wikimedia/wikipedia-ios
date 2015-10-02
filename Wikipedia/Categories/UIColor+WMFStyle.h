//
//  UIColor+WMFStyle.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/31/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (WMFStyle)

+ (instancetype)wmf_logoBlue;

+ (instancetype)wmf_logoBlueWithAlpha:(CGFloat)alpha;

+ (instancetype)wmf_summaryTextColor;

+ (instancetype)wmf_tableOfContentsHeaderTextColor;

+ (instancetype)wmf_tableOfContentsSelectionBackgroundColor;

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor;

+ (instancetype)wmf_tableOfContentsSectionTextColor;

+ (instancetype)wmf_tableOfContentsSubsectionTextColor;

@end
