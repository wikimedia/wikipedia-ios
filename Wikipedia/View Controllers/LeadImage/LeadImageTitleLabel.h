//  Created by Monte Hurd on 12/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "PaddedLabel.h"

@interface LeadImageTitleLabel : PaddedLabel

@property (nonatomic) BOOL imageExists;

- (void)setTitle:(NSString*)title
     description:(NSString*)description;

@end
