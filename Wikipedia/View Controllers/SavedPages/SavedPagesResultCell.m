//  Created by Monte Hurd on 11/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SavedPagesResultCell.h"
#import "Defines.h"
#import "NSObject+ConstraintsScale.h"
#import "PaddedLabel.h"

static CGFloat const kMinVerticalPadding = 4.0f;

@implementation SavedPagesResultCell

@synthesize imageView;
@synthesize useField;

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.useField       = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setUseField:(BOOL)use {
    if (use) {
        UIColor* borderColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.imageView.layer.borderColor = borderColor.CGColor;
        self.imageView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        self.imageView.backgroundColor   = [UIColor colorWithWhite:0.0 alpha:0.025];
    } else {
        self.imageView.layer.borderWidth = 0.0f;
        self.imageView.backgroundColor   = [UIColor clearColor];
    }
    useField = use;
}

- (void)prepareForReuse {
    self.imageView.image               = nil;
    self.savedItemLabel.attributedText = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.savedItemLabel.padding =
        UIEdgeInsetsMake(kMinVerticalPadding, 0.0f, kMinVerticalPadding, 0.0f);

    [self adjustConstraintsScaleForViews:@[self.imageView, self.savedItemLabel]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    if (selected) {
        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }

    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
