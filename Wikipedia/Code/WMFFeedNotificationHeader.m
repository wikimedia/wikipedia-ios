
#import "WMFFeedNotificationHeader.h"
#import "WMFLeadingImageTrailingTextButton.h"

@implementation WMFFeedNotificationHeader


- (instancetype)init{
    self = [super init];
    if (self) {
        [self.enableNotificationsButton configureAsNotifyTrendingButton];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:MWLocalizedString(@"feed-news-notification-text", nil)];

    [attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13] range:NSMakeRange(0, attributedText.length)];

    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, attributedText.length)];

    NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
    [p setLineBreakMode:NSLineBreakByWordWrapping];
    p.lineSpacing = 5;
    
    [attributedText addAttribute:NSParagraphStyleAttributeName value:p range:NSMakeRange(0, attributedText.length)];
    
    self.textLabel.attributedText = attributedText;
    self.textLabel.numberOfLines = 0;
    [self.enableNotificationsButton configureAsNotifyTrendingButton];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    if(self.textLabel.preferredMaxLayoutWidth != self.textLabel.frame.size.width){
        self.textLabel.preferredMaxLayoutWidth = self.textLabel.frame.size.width;
        [self layoutIfNeeded];
    }
}


@end
