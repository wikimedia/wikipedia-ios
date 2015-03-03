//  Created by Monte Hurd on 1/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LanguagesCell.h"
#import "WikipediaAppUtils.h"
#import "UIView+ConstraintsScale.h"
#import "Defines.h"

#define BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:1.0f]

@implementation LanguagesCell

@synthesize textLabel;
@synthesize canonicalLabel;

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    //self.textLabel.layer.borderWidth = 1;
    //self.textLabel.layer.borderColor = [UIColor redColor].CGColor;
    self.backgroundColor              = BACKGROUND_COLOR;
    self.textLabel.textAlignment      = [WikipediaAppUtils rtlSafeAlignment];
    self.canonicalLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];

    self.textLabel.font      = [UIFont systemFontOfSize:17.0 * MENUS_SCALE_MULTIPLIER];
    self.canonicalLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
