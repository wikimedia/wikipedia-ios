//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LeadImageTitleAttributedString.h"
#import "NSString+FormattedAttributedString.h"
#import "Defines.h"

#define FONT @"Times New Roman"
#define FONT_SIZE_TITLE (34.0f * MENUS_SCALE_MULTIPLIER)
#define FONT_SIZE_DESCRIPTION (17.0f * MENUS_SCALE_MULTIPLIER)

#define LINE_SPACING_TITLE (-5.0f * MENUS_SCALE_MULTIPLIER)
#define LINE_SPACING_DESCRIPTION (2.0f * MENUS_SCALE_MULTIPLIER)

#define SPACE_ABOVE_DESCRIPTION (4.0f * MENUS_SCALE_MULTIPLIER)

@implementation LeadImageTitleAttributedString

+ (NSAttributedString*)attributedStringWithTitle:(NSString*)title
                                     description:(NSString*)description {
    CGFloat shadowBlurRadius = 0.5;

    NSShadow* shadow = [[NSShadow alloc] init];

    [shadow setShadowOffset:CGSizeMake(0.0, 1.0)];
    [shadow setShadowBlurRadius:shadowBlurRadius];

    CGFloat titleFontSizeMultiplier = [self getSizeReductionMultiplierForTitleOfLength:title.length];

    CGFloat titleFontSize = floor(FONT_SIZE_TITLE * titleFontSizeMultiplier);

    NSMutableParagraphStyle* titleParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    titleParagraphStyle.lineSpacing = LINE_SPACING_TITLE;

    NSMutableParagraphStyle* descParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descParagraphStyle.lineSpacing            = LINE_SPACING_DESCRIPTION;
    descParagraphStyle.paragraphSpacingBefore = SPACE_ABOVE_DESCRIPTION;

    NSDictionary* titleAttribs =
        @{
        NSShadowAttributeName: shadow,
        NSFontAttributeName: [UIFont fontWithName:FONT size:titleFontSize],
        NSParagraphStyleAttributeName: titleParagraphStyle
    };
    NSDictionary* descripAttribs =
        @{
        NSShadowAttributeName: shadow,
        NSFontAttributeName: [UIFont fontWithName:FONT size:FONT_SIZE_DESCRIPTION],
        NSParagraphStyleAttributeName: descParagraphStyle
    };

    NSString* lineBreak = (description.length == 0) ? @"" : @"\n";
    description = description ? description : @"";

    return
        [@"$1$2$3" attributedStringWithAttributes:@{}
                              substitutionStrings:@[title, lineBreak, description]
                           substitutionAttributes:@[titleAttribs, @{}, descripAttribs]
        ];
}

+ (CGFloat)getSizeReductionMultiplierForTitleOfLength:(NSUInteger)length {
    // Quick hack for shrinking long titles in rough proportion to their length.

    CGFloat multiplier = 1.0f;

    // Assume roughly title 28 chars per line. Note this doesn't take in to account
    // interface orientation, which means the reduction is really not strictly
    // in proportion to line count, rather to string length. This should be ok for
    // now. Search for "lopado" and you'll see an insanely long title in the search
    // results, which is nice for testing, and which this seems to handle.
    // Also search for "list of accidents" for lots of other long title articles,
    // many with lead images.

    CGFloat charsPerLine = 28;
    CGFloat lines        = ceil(length / charsPerLine);

    // For every 2 "lines" (after the first 2) reduce title text size by 10%.
    if (lines > 2) {
        CGFloat linesAfter2Lines = lines - 2;
        multiplier = 1.0f - (linesAfter2Lines * 0.1f);
    }

    // Don't shrink below 60%.
    return MAX(multiplier, 0.6f);
}

@end
