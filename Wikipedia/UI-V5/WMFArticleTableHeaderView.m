//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleTableHeaderView.h"
#import "UIButton+WMFButton.h"
#import "NSString+FormattedAttributedString.h"

static NSString* const WMFArticleTableHeaderFont                 = @"Times New Roman";
static CGFloat const WMFArticleTableHeaderFontSizeTitle          = 34.f;
static CGFloat const WMFArticleTableHeaderFontSizeDescripion     = 17.f;
static CGFloat const WMFArticleTableHeaderLineSpacingTitle       = -5.f;
static CGFloat const WMFArticleTableHeaderLineSpacingDescription = 2.f;
static CGFloat const WMFArticleTableHeaderSpaceAboveDescription  = 4.f;

@interface WMFArticleTableHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel* titleLabel;

@end

@implementation WMFArticleTableHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.saveButton wmf_setButtonType:WMFButtonTypeHeart];
}

- (void)setTitle:(NSString*)title description:(NSString*)description {
    self.titleLabel.attributedText = [self attributedStringWithTitle:title description:description];
}

- (NSAttributedString*)attributedStringWithTitle:(NSString*)title
                                     description:(NSString*)description {
    title       = title ? title : @"";
    description = description ? description : @"";

    CGFloat titleFontSizeMultiplier = [self getSizeReductionMultiplierForTitleOfLength:title.length];
    CGFloat titleFontSize           = floor(WMFArticleTableHeaderFontSizeTitle * titleFontSizeMultiplier);

    NSDictionary* titleAttribs = @{
        NSShadowAttributeName: [self shadow],
        NSFontAttributeName: [UIFont fontWithName:WMFArticleTableHeaderFont size:titleFontSize],
        NSParagraphStyleAttributeName: [self titleParagraph]
    };

    return
        [@"$1$2$3" attributedStringWithAttributes:@{}
                              substitutionStrings:@[title, (description.length == 0) ? @"" : @"\n", description]
                           substitutionAttributes:@[titleAttribs, @{}, [self descriptionAttributes]]
        ];
}

- (NSParagraphStyle*)titleParagraph {
    static dispatch_once_t once;
    static NSMutableParagraphStyle* paragraph;
    dispatch_once(&once, ^{
        paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineSpacing = WMFArticleTableHeaderLineSpacingTitle;
    });
    return paragraph;
}

- (NSDictionary*)descriptionAttributes {
    static dispatch_once_t once;
    static NSDictionary* attributes;
    dispatch_once(&once, ^{
        NSMutableParagraphStyle* descParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        descParagraphStyle.lineSpacing = WMFArticleTableHeaderLineSpacingDescription;
        descParagraphStyle.paragraphSpacingBefore = WMFArticleTableHeaderSpaceAboveDescription;
        attributes = @{
            NSShadowAttributeName: [self shadow],
            NSFontAttributeName: [UIFont fontWithName:WMFArticleTableHeaderFont size:WMFArticleTableHeaderFontSizeDescripion],
            NSParagraphStyleAttributeName: descParagraphStyle
        };
    });
    return attributes;
}

- (NSShadow*)shadow {
    static dispatch_once_t once;
    static NSShadow* shadow;
    dispatch_once(&once, ^{
        shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:CGSizeMake(0.0, 1.0)];
        [shadow setShadowBlurRadius:0.5];
    });
    return shadow;
}

- (CGFloat)getSizeReductionMultiplierForTitleOfLength:(NSUInteger)length {
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
