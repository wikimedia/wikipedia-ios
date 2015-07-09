//  Created by Monte Hurd on 7/9/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleReadMoreCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@implementation WMFArticleReadMoreCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self wmf_makeCellDividerBeEdgeToEdge];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.thumbnailImageView.layer.borderWidth  = 1;
    self.thumbnailImageView.layer.borderColor  = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    self.thumbnailImageView.layer.cornerRadius = 5.0f;
}

@end
