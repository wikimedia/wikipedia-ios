#import "BulletedLabel.h"
#import "PaddedLabel.h"

// Bullets from: http://www.fileformat.info/info/unicode/block/geometric_shapes/list.htm
#define BULLET_ROUND @"\u2022"

@implementation BulletedLabel

- (instancetype)initWithBulletType:(BulletType)bulletType bulletColor:(UIColor *)bulletColor {
    self = [super init];
    if (self) {
        self.bulletType = bulletType;
        self.bulletColor = bulletColor;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.bulletType = BULLET_TYPE_NONE;
        self.bulletColor = [UIColor blackColor];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bulletType = BULLET_TYPE_NONE;
        self.bulletColor = [UIColor blackColor];
    }
    return self;
}

- (void)setBulletType:(BulletType)bulletType {
    _bulletType = bulletType;

    self.bulletLabel.text = [self getBulletString];
}

- (void)setBulletColor:(UIColor *)bulletColor {
    _bulletColor = bulletColor;

    self.bulletLabel.textColor = bulletColor;
}

- (NSString *)getBulletString {
    switch (self.bulletType) {
        case BULLET_TYPE_ROUND:
            return BULLET_ROUND;
            break;
        default:
            return @"";
            break;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];

    // The labels have not been created when init happens, so reset type here.
    self.bulletType = self.bulletType;
    self.bulletColor = self.bulletColor;

    //self.titleLabel.layer.borderWidth = 1;
    //self.prefixLabel.layer.borderWidth = 1;
    //self.titleLabel.layer.borderColor = [UIColor blackColor].CGColor;
    //self.prefixLabel.layer.borderColor = [UIColor blackColor].CGColor;
}

/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect
   {
    // Drawing code
   }
 */

@end
