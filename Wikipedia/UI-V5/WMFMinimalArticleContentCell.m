//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFMinimalArticleContentCell.h"
#import "NSAttributedString+WMFModifyParagraphs.h"

@interface WMFMinimalArticleContentCell ()

@property (nonatomic, strong) IBOutlet UITextView* textView;

@end

@implementation WMFMinimalArticleContentCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.tintColor = [UIColor wmf_logoBlue];
    }
    return self;
}

- (void)setAttributedText:(NSAttributedString*)attributedText {
    self.textView.attributedText = [attributedText wmf_attributedStringWithParagraphStylesAdjustments:^(NSMutableParagraphStyle* paragraphStyle){
        // Needed because if you set DTDefaultLineHeightMultiplier to anything larger than
        // 1.0 it ends up adding a bunch of padding before the first paragraph of text.
        paragraphStyle.lineSpacing = 12;
    }];
}

@end
