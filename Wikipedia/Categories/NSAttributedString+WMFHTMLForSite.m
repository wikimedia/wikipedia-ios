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
#import "NSAttributedString+WMFModifyParagraphs.h"

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
    attrStr = [attrStr wmf_attributedStringWithParagraphStylesAdjustments:^(NSMutableParagraphStyle* paragraphStyle){
        /*
           Needed because if you try adjust line spacing with DTDefaultLineHeightMultiplier
           anything larger than 1.0 ends up adding a bunch of padding before the first
           paragraph of text.
         */
        paragraphStyle.lineSpacing = 12;
    }];
    return attrStr;
}

@end
