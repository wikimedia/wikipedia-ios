//  Created by Monte Hurd on 7/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, BulletType) {
    BULLET_TYPE_NONE,
    BULLET_TYPE_ROUND
};

@class PaddedLabel;

@interface BulletedLabel : UIView

@property (nonatomic, weak) IBOutlet PaddedLabel* bulletLabel;
@property (nonatomic, weak) IBOutlet PaddedLabel* titleLabel;

@property (nonatomic) BulletType bulletType;

@property (nonatomic, strong) UIColor* bulletColor;

- (instancetype)initWithBulletType:(BulletType)bulletType bulletColor:(UIColor*)bulletColor;

@end
