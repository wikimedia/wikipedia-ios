#import "WMFMainPagePlaceholderCollectionViewCell.h"

@implementation WMFMainPagePlaceholderCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *stretch = [UIImage imageNamed:@"main-page-placeholder"];
    stretch = [stretch resizableImageWithCapInsets:UIEdgeInsetsMake(stretch.size.height / 2, stretch.size.width / 2 - 0.5, stretch.size.height / 2, stretch.size.width / 2 - 0.5)];
    self.placeholderImageView.image = stretch;
    self.placeholderImageView.contentMode = UIViewContentModeScaleToFill;
}

@end
