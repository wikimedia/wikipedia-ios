#import "WMFCustomDeleteButtonTableViewCell.h"
#import <Masonry/Masonry.h>

@interface WMFCustomDeleteButtonTableViewCell ()

@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) CALayer *cellWhiteLayer;
@property (strong, nonatomic) CALayer *deleteButtonWhiteLayer;

@end

@implementation WMFCustomDeleteButtonTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.deleteButton.superview.subviews.lastObject != self.deleteButton) {
        [self.deleteButton.superview bringSubviewToFront:self.deleteButton];
    }

    self.cellWhiteLayer.frame = self.bounds;
    self.deleteButtonWhiteLayer.frame = self.deleteButton.bounds;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.deleteButton = [self wmf_deleteButton];
    [self.contentView.superview addSubview:self.deleteButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.width.equalTo(@(50));

      // Attach leading edge to contentView so it tracks horizonally
      // with cell animations such as when enabling table view editing with
      // animations.
      make.leading.equalTo(self.contentView).offset(-40);

      // Use offsets for top and bottom so as not to overlap separators.
      make.top.equalTo(self.deleteButton.superview).offset(1);
      make.bottom.equalTo(self.deleteButton.superview).offset(-1);
    }];

    self.cellWhiteLayer = [self whiteLayer];
    [self.layer insertSublayer:self.cellWhiteLayer atIndex:0];
}

- (UIButton *)wmf_deleteButton {
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.userInteractionEnabled = NO;
    button.clipsToBounds = YES;
    button.tintColor = [UIColor redColor];
    [button setImage:[UIImage imageNamed:@"language-delete"] forState:UIControlStateNormal];
    button.imageView.backgroundColor = [UIColor whiteColor];

    self.deleteButtonWhiteLayer = [self whiteLayer];
    [button.layer insertSublayer:self.deleteButtonWhiteLayer atIndex:0];

    return button;
}

// HAX: need white layer beneath the custom minus button to hide the baked-in minus button.
// Used layer because this is immune to cell drag forcing background colors set otherwise to
// go transparent on drag. Also needed to do same for entire cell otherwise it looks weird on
// drag if only the minus button part stays white.
- (CALayer *)whiteLayer {
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    return layer;
}

@end
