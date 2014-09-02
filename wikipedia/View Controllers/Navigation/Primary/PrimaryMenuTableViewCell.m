//  Created by Monte Hurd on 5/23/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PrimaryMenuTableViewCell.h"
#import "PaddedLabel.h"

@implementation PrimaryMenuTableViewCell

-(void)didMoveToSuperview
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        // Needed by iOS 8. The table view and its cells were made transparent to make
        // iOS 6 fade animation more smooth. Unfortunately iOS 8 makes the table cells
        // white for some reason...
        self.backgroundColor = [UIColor blackColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
