//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleTableHeaderView.h"
#import "UIButton+WMFButton.h"

@implementation WMFArticleTableHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.saveButton wmf_setButtonType:WMFButtonTypeHeart];
}

@end

