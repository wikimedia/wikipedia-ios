//
//  NSParagraphStyle+WMFNaturalAlignmentStyle.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSParagraphStyle+WMFNaturalAlignmentStyle.h"

@implementation NSParagraphStyle (WMFNaturalAlignmentStyle)

+ (NSParagraphStyle*)wmf_naturalAlignmentStyle {
    NSParameterAssert([NSThread isMainThread]);
    static NSParagraphStyle* naturalAlignmentStyle = nil;
    if (!naturalAlignmentStyle) {
        NSMutableParagraphStyle* style = [NSMutableParagraphStyle new];
        style.alignment       = NSTextAlignmentNatural;
        naturalAlignmentStyle = [style copy];
    }
    return naturalAlignmentStyle;
}

@end
