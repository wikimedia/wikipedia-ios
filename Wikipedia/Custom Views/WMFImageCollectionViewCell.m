//
//  WMFImageCollectionViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFImageCollectionViewCell.h"
#import "UIImageView+WMFContentOffset.h"
#import "UIImageView+WMFImageFetching.h"
#import <Masonry/Masonry.h>
#import "UIColor+WMFHexColor.h"
#import "UIColor+WMFStyle.h"
#import "UIImage+WMFStyle.h"

@implementation WMFImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [UIImageView new];
        [self.contentView addSubview:self.imageView];
        [self.imageView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.edges.equalTo(self.contentView);
        }];
        self.imageView.clipsToBounds = YES;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self configureImageViewWithPlaceholder];
}

- (void)configureImageViewWithPlaceholder {
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.backgroundColor = [UIColor wmf_colorWithHex:0xF5F5F5 alpha:1.0];
    self.imageView.image = [UIImage wmf_placeholderImage];
    self.imageView.tintColor = [UIColor wmf_lightGrayColor];
}

@end
