#import "PageHistoryResultCell.h"
#import "NSString+WMFExtras.h"
#import "UIFont+WMFStyle.h"
#import "Wikipedia-Swift.h"

@interface PageHistoryResultCell ()

@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *deltaLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeightConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;

@end

@implementation PageHistoryResultCell

- (void)setName:(NSString *)name
           date:(NSDate *)date
          delta:(NSNumber *)delta
         isAnon:(BOOL)isAnon
        summary:(NSString *)summary
      separator:(BOOL)separator {
    
    self.nameLabel.text = name;
    self.timeLabel.text = [[NSDateFormatter wmf_shortTimeFormatter] stringFromDate:date];
    self.deltaLabel.text = [NSString stringWithFormat:@"%@%@", (delta.integerValue > 0) ? @"+" : @"", delta.stringValue];
    self.userImageView.image = [[UIImage imageNamed:isAnon ? @"user-sleep" : @"user-smile"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    if (delta.integerValue == 0) {
        self.deltaLabel.textColor = [UIColor colorWithRed:0.2039 green:0.4824 blue:1.0 alpha:1.0];
    } else if (delta.integerValue > 0) {
        self.deltaLabel.textColor = [UIColor colorWithRed:0.00 green:0.69 blue:0.54 alpha:1.0];
    } else {
        self.deltaLabel.textColor = [UIColor colorWithRed:0.82 green:0.09 blue:0.07 alpha:1.0];
    }

    self.userImageView.tintColor = [UIColor wmf_customGray];
    self.summaryLabel.text = [summary wmf_stringByRemovingHTML];

    self.separatorHeightConstraint.constant =
        (separator) ? (1.0f / [UIScreen mainScreen].scale) : 0.0f;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self wmf_configureSubviewsForDynamicType];
}

@end
