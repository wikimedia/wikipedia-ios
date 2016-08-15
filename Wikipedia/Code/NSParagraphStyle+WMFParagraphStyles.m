//
//  NSParagraphStyle+WMFParagraphStyles.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSParagraphStyle+WMFParagraphStyles.h"

@implementation NSParagraphStyle (WMFParagraphStyles)

+ (NSParagraphStyle *)wmf_naturalAlignmentStyle {
    NSParameterAssert([NSThread isMainThread]);
    static NSParagraphStyle *naturalAlignmentStyle = nil;
    if (!naturalAlignmentStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.alignment = NSTextAlignmentNatural;
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        naturalAlignmentStyle = [style copy];
    }
    return naturalAlignmentStyle;
}

+ (NSParagraphStyle *)wmf_tailTruncatingNaturalAlignmentStyle {
    NSParameterAssert([NSThread isMainThread]);
    static NSParagraphStyle *tailTruncatingNaturalAlignmentStyle = nil;
    if (!tailTruncatingNaturalAlignmentStyle) {
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.alignment = NSTextAlignmentNatural;
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        tailTruncatingNaturalAlignmentStyle = [style copy];
    }
    return tailTruncatingNaturalAlignmentStyle;
}

@end
