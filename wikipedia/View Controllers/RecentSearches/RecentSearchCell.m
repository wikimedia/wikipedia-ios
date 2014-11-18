//  Created by Monte Hurd on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RecentSearchCell.h"
#import "PaddedLabel.h"
#import "NSObject+ConstraintsScale.h"
#import "Defines.h"

#define FONT_SIZE (16.0f * MENUS_SCALE_MULTIPLIER)
#define FONT_COLOR [UIColor grayColor];

@implementation RecentSearchCell

- (void)awakeFromNib {
    // Initialization code

    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.label.font = [UIFont systemFontOfSize:FONT_SIZE];
    
    self.label.textColor = FONT_COLOR;

    [self adjustConstraintsScaleForViews:@[self.label]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
