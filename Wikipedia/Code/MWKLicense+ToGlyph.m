//
//  MWKLicense+ToGlyph.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/10/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKLicense+ToGlyph.h"
#import "WikiGlyph_Chars.h"

@implementation MWKLicense (ToGlyph)

- (NSString *)toGlyph {
    if ([self.code isEqualToString:@"pd"]) {
        return WIKIGLYPH_PUBLIC_DOMAIN;
    } else if ([self.code hasPrefix:@"cc"]) {
        return WIKIGLYPH_CC;
    } else {
        return nil;
    }
}

@end
