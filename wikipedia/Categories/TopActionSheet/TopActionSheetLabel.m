//  Created by Monte Hurd on 3/18/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "TopActionSheetLabel.h"

@implementation TopActionSheetLabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];

    // This is needed for iOS 6 which doesn't seem to keep label preferredMaxLayoutWidth
    // in sync with its width, which means the label won't grow vertically to encompass
    // its text if the label's width constraint changes.
    self.preferredMaxLayoutWidth = self.bounds.size.width;
}

@end
