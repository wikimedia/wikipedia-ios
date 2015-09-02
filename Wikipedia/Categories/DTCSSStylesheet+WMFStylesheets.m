//
//  DTCSSStylesheet+WMFStylesheets.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "DTCSSStylesheet+WMFStylesheets.h"

@implementation DTCSSStylesheet (WMFStylesheets)

+ (instancetype)wmf_imageHidingStylesheet {
    static DTCSSStylesheet* imageHidingStyleSheet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageHidingStyleSheet = [[DTCSSStylesheet alloc] initWithStyleBlock:@"img { display: none } "];
    });
    return imageHidingStyleSheet;
}

@end
