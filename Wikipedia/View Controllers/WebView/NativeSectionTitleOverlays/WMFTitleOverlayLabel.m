//  Created by Monte Hurd on 7/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFTitleOverlayLabel.h"

@implementation WMFTitleOverlayLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.font                                      = [UIFont fontWithName:@"Times New Roman" size:29];
        self.padding                                   = UIEdgeInsetsMake(14, 18, 14, 18);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.numberOfLines                             = 0;
        self.lineBreakMode                             = NSLineBreakByWordWrapping;
        self.backgroundColor                           = [UIColor whiteColor];

        UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressRecognizer.minimumPressDuration = 1.0f;
        self.userInteractionEnabled              = YES;
        [self addGestureRecognizer:longPressRecognizer];
    }
    return self;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"EditSection" object:self userInfo:@{@"sectionId": self.sectionId}];
    }
}

@end
