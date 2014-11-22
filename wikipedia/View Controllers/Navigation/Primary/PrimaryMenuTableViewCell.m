//  Created by Monte Hurd on 5/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PrimaryMenuTableViewCell.h"
#import "PaddedLabel.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "UIScreen+Extras.h"

@implementation PrimaryMenuTableViewCell

-(void)awakeFromNib
{
    CGFloat verticalPadding = [[UIScreen mainScreen] isThreePointFiveInchScreen] ? 9 : 13;
    self.label.padding = UIEdgeInsetsMake(verticalPadding, 5, verticalPadding, 5);
    self.label.font = [UIFont systemFontOfSize:27.0f * MENUS_SCALE_MULTIPLIER];
    [self adjustConstraintsScaleForViews:@[self.label]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] <= 6.1) {
        // Old iOS6 devices do a choppy W menu reveal animation if background
        // isn't transparent.
        self.backgroundColor = [UIColor clearColor];
    }else{
        // iPads of all versions show a white background if we use clearColor,
        // so use black.
        self.backgroundColor = [UIColor blackColor];
    }
    
    // Configure the view for the selected state
}

@end
