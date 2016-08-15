//
//  NSParagraphStyle+WMFParagraphStyles.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSParagraphStyle (WMFParagraphStyles)

/// Provides a backwards-compatible way to have "natural" text alignment of labels & buttons.
+ (NSParagraphStyle *)wmf_naturalAlignmentStyle;

+ (NSParagraphStyle *)wmf_tailTruncatingNaturalAlignmentStyle;

@end
