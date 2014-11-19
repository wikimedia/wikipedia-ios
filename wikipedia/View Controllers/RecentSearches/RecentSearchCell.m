//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchCell.h"
#import "PaddedLabel.h"
#import "NSObject+ConstraintsScale.h"
#import "Defines.h"
#import "WikiGlyph_Chars.h"

#define FONT_SIZE (16.0f * MENUS_SCALE_MULTIPLIER)
#define FONT_COLOR [UIColor grayColor]
#define ICON_SIZE (20.0f * MENUS_SCALE_MULTIPLIER)
#define ICON_GLYPH WIKIGLYPH_MAGNIFYING_GLASS
#define BORDER_COLOR [UIColor colorWithWhite:0.9 alpha:1.0]
#define MAGNIFY_ICON_COLOR [UIColor colorWithWhite:0.8 alpha:1.0]

@interface RecentSearchCell()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topBorderHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *topBorderView;
@property (strong, nonatomic) NSAttributedString *magnifyIconString;
@property (weak, nonatomic) IBOutlet PaddedLabel *iconLabel;

@end

@implementation RecentSearchCell

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.iconLabel.attributedText = [self getAttributedIconString];
    self.topBorderView.backgroundColor = BORDER_COLOR;
    self.topBorderHeightConstraint.constant = 1.0f / [UIScreen mainScreen].scale;
    self.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    
    self.label.numberOfLines = 1;
    self.label.lineBreakMode = NSLineBreakByTruncatingTail; // <-- Don't make truncating a habit! :) Is bad.

    self.label.textColor = FONT_COLOR;

    [self adjustConstraintsScaleForViews:@[self.label, self.iconLabel]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(NSAttributedString *)getAttributedIconString
{
    return [[NSAttributedString alloc] initWithString: ICON_GLYPH
                                           attributes: @{
                                                         NSFontAttributeName: [UIFont fontWithName:@"WikiFont-Glyphs" size:ICON_SIZE],
                                                         NSForegroundColorAttributeName : MAGNIFY_ICON_COLOR,
                                                         NSBaselineOffsetAttributeName: @0
                                                         }];
}

@end
