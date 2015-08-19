//
//  NSAttributedString+WMFHTMLForSite.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/28/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "NSAttributedString+WMFHTMLForSite.h"
#import <DTCoreText/DTCoreText.h>
#import "MWKSite.h"
#import "NSAttributedString+WMFModify.h"

@implementation NSAttributedString (WMFHTMLForSite)

+ (NSDictionary*)wmf_defaultHTMLOptionsForSite:(MWKSite*)site {
    UIFont* defaultFont                = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    DTCSSStylesheet* defaultStyleSheet =
        [[DTCSSStylesheet alloc] initWithStyleBlock:@"img { display: none } "];
    return @{
               NSBaseURLDocumentOption: [site URL],
               DTMaxImageSize: [NSValue valueWithCGSize:CGSizeZero],
               DTIgnoreInlineStylesOption: @YES, // prevents things like background colors
               DTDefaultTextAlignment: @(NSTextAlignmentToCTTextAlignment(site.textAlignment)),
               DTDefaultFontFamily: defaultFont.familyName,
               DTDefaultFontName: defaultFont.fontName,
               DTDefaultFontSize: @(defaultFont.pointSize),
               DTDefaultLinkDecoration: @NO, // disable decoration for links
               DTDocumentPreserveTrailingSpaces: @YES,
               DTDefaultStyleSheet: defaultStyleSheet,
               DTUseiOS6Attributes: @YES
    };
    // Reminder! Use tintColor with UILabel or UITextView to control link color!
}

- (instancetype)initWithHTMLData:(NSData*)data site:(MWKSite*)site {
    NSAttributedString* attrStr = [self initWithHTMLData:data
                                                 options:[[self class] wmf_defaultHTMLOptionsForSite:site]
                                      documentAttributes:nil];

    // DTCoreText adds a trailing line break to the attributed string it generates. Remove it.
    attrStr = [self attributedStringWithoutTrailingSpace:attrStr];

    // Needed because DTCoreText adds funky padding above the first paragraph if you use DTDefaultLineHeightMultiplier to increase line spacing.
    attrStr = [self attributedStringWithFinalAdjustments:attrStr];

    return attrStr;
}

- (NSAttributedString*)attributedStringWithFinalAdjustments:(NSAttributedString*)attrStr {
    return [attrStr wmf_attributedStringChangingAttribute:NSParagraphStyleAttributeName
                                                withBlock:^NSParagraphStyle*(NSParagraphStyle* paragraphStyle){
        NSMutableParagraphStyle* style = paragraphStyle.mutableCopy;
        style.lineSpacing = 12;
        return style;
    }];
}

- (NSAttributedString*)attributedStringWithoutTrailingSpace:(NSAttributedString*)attrStr {
    if (attrStr.length == 0) {
        return attrStr;
    }
    NSAttributedString* lastCharacter = [attrStr attributedSubstringFromRange:NSMakeRange(attrStr.length - 1, 1)];
    if ([[lastCharacter string] isEqualToString:@"\n"]) {
        attrStr = [attrStr attributedSubstringFromRange:NSMakeRange(0, attrStr.length - 1)];
    }
    return attrStr;
}

@end
