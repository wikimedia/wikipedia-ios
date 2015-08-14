//  Created by Monte Hurd on 7/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFMinimalArticleContentCell.h"

@interface WMFMinimalArticleContentCell ()

@property (nonatomic, strong) IBOutlet UITextView* textView;

@end

@implementation WMFMinimalArticleContentCell

- (void)setAttributedText:(NSAttributedString*)attributedText {
    NSMutableAttributedString* mutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];

    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 12;

    NSDictionary* attributes =
        @{
        NSParagraphStyleAttributeName: paragraphStyle
    };

    [mutableAttributedText addAttributes:attributes range:NSMakeRange(0, attributedText.length)];

    self.textView.attributedText = mutableAttributedText;
}

@end
