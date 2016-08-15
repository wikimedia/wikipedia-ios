#import "PageHistoryResultCell.h"
#import "NSObject+ConstraintsScale.h"
#import "PageHistoryLabel.h"
#import "Defines.h"
#import "NSString+WMFExtras.h"
#import "UIFont+WMFStyle.h"
#import "NSDateFormatter+WMFExtensions.h"

@interface PageHistoryResultCell ()

@property(weak, nonatomic) IBOutlet PageHistoryLabel *summaryLabel;
@property(weak, nonatomic) IBOutlet PageHistoryLabel *nameLabel;
@property(weak, nonatomic) IBOutlet PageHistoryLabel *timeLabel;
@property(weak, nonatomic) IBOutlet PageHistoryLabel *deltaLabel;
@property(weak, nonatomic) IBOutlet PageHistoryLabel *iconLabel;
@property(weak, nonatomic)
    IBOutlet NSLayoutConstraint *separatorHeightConstraint;

@end

@implementation PageHistoryResultCell

- (void)setName:(NSString *)name
           date:(NSDate *)date
          delta:(NSNumber *)delta
           icon:(NSString *)icon
        summary:(NSString *)summary
      separator:(BOOL)separator {
  self.nameLabel.text = name;

  self.timeLabel.text =
      [[NSDateFormatter wmf_shortTimeFormatter] stringFromDate:date];

  self.deltaLabel.text = [NSString
      stringWithFormat:@"%@%@", (delta.integerValue > 0) ? @"+" : @"",
                       delta.stringValue];

  if (delta.integerValue == 0) {
    self.deltaLabel.textColor = WMF_COLOR_BLUE;
  } else if (delta.integerValue > 0) {
    self.deltaLabel.textColor = WMF_COLOR_GREEN;
  } else {
    self.deltaLabel.textColor = WMF_COLOR_RED;
  }

  NSDictionary *iconAttributes = @{
    NSFontAttributeName :
        [UIFont wmf_glyphFontOfSize:23.0 * MENUS_SCALE_MULTIPLIER],
    NSForegroundColorAttributeName :
        [UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0],
    NSBaselineOffsetAttributeName : @1
  };

  self.iconLabel.attributedText =
      [[NSAttributedString alloc] initWithString:icon
                                      attributes:iconAttributes];

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

  // Initial changes to ui elements go here.
  // See: http://stackoverflow.com/a/15591474 for details.

  [self adjustConstraintsScaleForViews:@[
    self.summaryLabel, self.nameLabel, self.timeLabel, self.deltaLabel,
    self.iconLabel
  ]];
}

@end
