#import "WMFArticleFooterMenuCell.h"
#import "UITableViewCell+WMFEdgeToEdgeSeparator.h"

@interface WMFArticleFooterMenuCell ()

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;

@end

@implementation WMFArticleFooterMenuCell

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setSubTitle:(NSString *)subTitle {
    _subTitle = subTitle;
    self.descriptionLabel.text = subTitle;
}

- (void)setImageName:(NSString *)imageName {
    _imageName = imageName;
    self.iconImageView.image = [UIImage imageNamed:imageName];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self wmf_makeCellDividerBeEdgeToEdge];
}

@end
