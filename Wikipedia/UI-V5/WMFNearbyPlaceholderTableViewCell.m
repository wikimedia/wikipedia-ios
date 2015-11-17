
#import "WMFNearbyPlaceholderTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"

@implementation WMFNearbyPlaceholderTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.placeholderImageView.tintColor       = [UIColor wmf_placeholderImageTintColor];
    self.placeholderImageView.image           = [UIImage wmf_placeholderImage];
    self.placeholderImageView.backgroundColor = [UIColor wmf_placeholderImageBackgroundColor];
    self.placeholderImageView.contentMode     = UIViewContentModeCenter;
}

@end
