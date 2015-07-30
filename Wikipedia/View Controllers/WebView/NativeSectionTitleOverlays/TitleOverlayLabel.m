//  Created by Monte Hurd on 7/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TitleOverlayLabel.h"

@implementation TitleOverlayLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.font                                      = [UIFont fontWithName:@"Times New Roman" size:30];
        self.padding                                   = UIEdgeInsetsMake(14, 18, 14, 18);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.numberOfLines                             = 0;
        self.lineBreakMode                             = NSLineBreakByWordWrapping;
        self.backgroundColor                           = [UIColor whiteColor];
    }
    return self;
}

@end
