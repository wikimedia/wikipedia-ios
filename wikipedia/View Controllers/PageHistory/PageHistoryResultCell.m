//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryResultCell.h"
#import "WikipediaAppUtils.h"
#import "NSObject+ConstraintsScale.h"
#import "Defines.h"

@implementation PageHistoryResultCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];

    // Initial changes to ui elements go here.
    // See: http://stackoverflow.com/a/15591474 for details.

    //self.summary.layer.borderWidth = 1;
    //self.summary.layer.borderColor = [UIColor redColor].CGColor;
    //self.backgroundColor = [UIColor greenColor];
    
    self.separatorHeightConstraint.constant = 1.0f / [UIScreen mainScreen].scale;

    self.summaryLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.nameLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.timeLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.deltaLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];
    self.iconLabel.textAlignment = [WikipediaAppUtils rtlSafeAlignment];

    self.summaryLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    self.nameLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    self.timeLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    self.deltaLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];
    self.iconLabel.font = [UIFont systemFontOfSize:12.0 * MENUS_SCALE_MULTIPLIER];

    [self adjustConstraintsScaleForViews:@[self.summaryLabel, self.nameLabel, self.timeLabel, self.deltaLabel, self.iconLabel]];
}

-(void)prepareForReuse
{
    //NSLog(@"imageView frame = %@", NSStringFromCGRect(self.imageView.frame));
}

@end
