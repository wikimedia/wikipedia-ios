//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFArticleSectionCell.h"

@interface WMFArticleSectionCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint* leadingIndentationConstraint;

@end

@implementation WMFArticleSectionCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setSelectionBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.1]];
    }
    return self;
}

- (void)setSelectionBackgroundColor:(UIColor*)color {
    UIView* selectionColor = [[UIView alloc] init];
    selectionColor.backgroundColor = color;
    self.selectedBackgroundView    = selectionColor;
}

- (void)setLevel:(NSNumber*)level {
    [self applyIndentForLevel:level];
}

- (void)applyIndentForLevel:(NSNumber*)level {
    self.leadingIndentationConstraint.constant = [self getIndentationForLevel:level];
}

- (CGFloat)getIndentationForLevel:(NSNumber*)level {
    return 10 + ((level.integerValue - 2) * 10);
}

@end
