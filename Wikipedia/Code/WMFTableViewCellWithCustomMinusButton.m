#import "WMFTableViewCellWithCustomMinusButton.h"
#import <Masonry/Masonry.h>

@interface WMFTableViewCellWithCustomMinusButton ()

@property (strong, nonatomic) UIButton* minusButton;
@property (strong, nonatomic) CALayer* cellWhiteLayer;
@property (strong, nonatomic) CALayer* minusButtonWhiteLayer;

@end

@implementation WMFTableViewCellWithCustomMinusButton

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // HAX: ensure the custom button is always on top.
    [self.minusButton.superview bringSubviewToFront:self.minusButton];

    self.cellWhiteLayer.frame = self.bounds;
    self.minusButtonWhiteLayer.frame = self.minusButton.bounds;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.minusButton = [self wmf_minusButton];
    [self.contentView.superview addSubview:self.minusButton];
    [self.minusButton mas_makeConstraints:^(MASConstraintMaker* make) {
        make.width.equalTo(@(50));

        // HAX: attach leading edge to contentView so it tracks horizonally
        // with cell animations such as when enabling table view editing with
        // animations.
        make.leading.equalTo(self.contentView).offset(-40);

        // HAX: use offsets for top and bottom so as not to overlap separators.
        make.top.equalTo(self.minusButton.superview).offset(1);
        make.bottom.equalTo(self.minusButton.superview).offset(-1);
    }];

    self.cellWhiteLayer = [self whiteLayer];
    [self.layer insertSublayer:self.cellWhiteLayer atIndex:0];
}

- (UIButton *)wmf_minusButton {
    UIButton *button = [[UIButton alloc] init];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.userInteractionEnabled = NO;
    button.clipsToBounds = YES;
    button.tintColor = [UIColor redColor];
    [button setImage:[UIImage imageNamed:@"language-delete"] forState:UIControlStateNormal];
    button.imageView.backgroundColor = [UIColor whiteColor];
    
    self.minusButtonWhiteLayer = [self whiteLayer];
    [button.layer insertSublayer:self.minusButtonWhiteLayer atIndex:0];
    
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
