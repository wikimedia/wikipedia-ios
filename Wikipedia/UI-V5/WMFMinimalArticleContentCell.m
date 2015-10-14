//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFMinimalArticleContentCell.h"

@interface WMFMinimalArticleContentCell ()

@property (nonatomic, weak) IBOutlet UITextView* textView;

@end

@implementation WMFMinimalArticleContentCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.tintColor = [UIColor wmf_logoBlue];
    }
    return self;
}

- (void)setText:(NSString*)text {
    self.textView.text = text;
}

- (void)prepareForReuse {
    self.textView.attributedText = nil;
    [super prepareForReuse];
}

@end
