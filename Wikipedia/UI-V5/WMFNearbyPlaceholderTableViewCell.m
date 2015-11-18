
#import "WMFNearbyPlaceholderTableViewCell.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"

@implementation WMFNearbyPlaceholderTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage* stretch = [UIImage imageNamed:@"nearby-card-placeholder"];
    stretch                               = [stretch resizableImageWithCapInsets:UIEdgeInsetsMake(stretch.size.height / 2, stretch.size.width / 2 - 28, stretch.size.height / 2, stretch.size.width / 2 - 28)];
    self.placeholderImageView.image       = stretch;
    self.placeholderImageView.contentMode = UIViewContentModeScaleToFill;
}

@end
