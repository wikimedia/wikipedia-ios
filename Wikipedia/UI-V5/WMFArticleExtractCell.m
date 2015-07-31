//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleExtractCell.h"
#import <DTCoreText/DTAttributedLabel.h>

@implementation WMFArticleExtractCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.attributedTextLabel.attributedString = nil;
}

@end
