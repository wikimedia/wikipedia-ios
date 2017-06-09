@import UIKit;

typedef NS_ENUM(NSInteger, BulletType) {
    BULLET_TYPE_NONE,
    BULLET_TYPE_ROUND
};

@class PaddedLabel;

@interface BulletedLabel : UIView

@property (nonatomic, weak) IBOutlet PaddedLabel *bulletLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel *titleLabel;

@property (nonatomic) BulletType bulletType;

@property (nonatomic, strong) UIColor *bulletColor;

- (instancetype)initWithBulletType:(BulletType)bulletType bulletColor:(UIColor *)bulletColor;

@end
