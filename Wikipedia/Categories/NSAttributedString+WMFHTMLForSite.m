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

@implementation NSAttributedString (WMFHTMLForSite)

+ (NSDictionary*)wmf_defaultHTMLOptionsForSite:(MWKSite*)site {
    UIFont* defaultFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    return @{
               NSBaseURLDocumentOption: [site URL],
               DTMaxImageSize: [NSValue valueWithCGSize:CGSizeZero],
               // prevents things like background colors
               DTIgnoreInlineStylesOption: @YES,
               DTDefaultTextAlignment: @(site.textAlignment),
               DTDefaultFontFamily: defaultFont.familyName,
               DTDefaultFontName: defaultFont.fontName,
               DTDefaultFontSize: @(defaultFont.pointSize),
               DTDefaultLineHeightMultiplier: @([[NSParagraphStyle defaultParagraphStyle] lineHeightMultiple])
    };
}

- (instancetype)initWithHTMLData:(NSData*)data site:(MWKSite*)site {
    return [self initWithHTMLData:data
                          options:[[self class] wmf_defaultHTMLOptionsForSite:site]
               documentAttributes:nil];
}

@end
