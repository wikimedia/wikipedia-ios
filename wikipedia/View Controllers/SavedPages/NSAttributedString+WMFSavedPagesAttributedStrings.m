//  Created by Monte Hurd on 4/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSAttributedString+WMFSavedPagesAttributedStrings.h"
#import "NSString+FormattedAttributedString.h"
#import "Defines.h"
#import "NSString+Extras.h"
#import "UIColor+WMFHexColor.h"

static const NSInteger kTitleColor  = 0x000000;
static CGFloat const kTitleFontSize = 21.0f;

static const NSInteger kDescriptionColor    = 0x777777;
static CGFloat const kDescriptionFontSize   = 13.0f;
static CGFloat const kDescriptionSpaceAbove = 3.0f;

static const NSInteger kLanguageColor    = 0x999999;
static CGFloat const kLanguageFontSize   = 10.0f;
static CGFloat const kLanguageSpaceAbove = 5.0f;

static NSString* const kLineBreak    = @"\n";
static NSString* const kFormatString = @"$1$2$3$4$5";

@implementation NSAttributedString (WMFSavedPagesAttributedStrings)

+ (NSAttributedString*)wmf_attributedStringWithTitle:(NSString*)title
                                         description:(NSString*)description
                                            language:(NSString*)language {
    description = [description capitalizeFirstLetter];

    // Shrink super long titles.
    CGFloat titleSizeMultiplier = 1.0f;
    if (title.length > 100) {
        titleSizeMultiplier = 0.75f;
    }

    NSDictionary* titleAttribs =
        @{
        NSFontAttributeName: [UIFont systemFontOfSize:titleSizeMultiplier * kTitleFontSize * MENUS_SCALE_MULTIPLIER],
        NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kTitleColor alpha:1.0f]
    };

    static NSDictionary* descripAttribs = nil;
    if (!descripAttribs) {
        NSMutableParagraphStyle* descParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        descParagraphStyle.paragraphSpacingBefore = kDescriptionSpaceAbove;
        descripAttribs                            = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kDescriptionFontSize * MENUS_SCALE_MULTIPLIER],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kDescriptionColor alpha:1.0f],
            NSParagraphStyleAttributeName: descParagraphStyle
        };
    }

    static NSDictionary* langAttribs = nil;
    if (!langAttribs) {
        NSMutableParagraphStyle* langParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        langParagraphStyle.paragraphSpacingBefore = kLanguageSpaceAbove;
        langAttribs                               = @{
            NSFontAttributeName: [UIFont systemFontOfSize:kLanguageFontSize * MENUS_SCALE_MULTIPLIER],
            NSForegroundColorAttributeName: [UIColor wmf_colorWithHex:kLanguageColor alpha:1.0f],
            NSParagraphStyleAttributeName: langParagraphStyle
        };
    }

    NSString* descripLineBreak = (description.length == 0) ? @"" : kLineBreak;
    description = description ? description : @"";
    language    = language ? language : @"";

    return
        [kFormatString attributedStringWithAttributes:@{}
                                  substitutionStrings:@[title, kLineBreak, description, descripLineBreak, language]
                               substitutionAttributes:@[titleAttribs, @{}, descripAttribs, @{}, langAttribs]
        ];
}

@end
