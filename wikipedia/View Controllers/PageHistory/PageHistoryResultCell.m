//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PageHistoryResultCell.h"

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
}

-(void)prepareForReuse
{
    //NSLog(@"imageView frame = %@", NSStringFromCGRect(self.imageView.frame));
}

@end
