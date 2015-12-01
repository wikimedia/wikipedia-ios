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
#import "UIImageView+WMFPlaceholder.h"

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
        [self configureImageViewWithPlaceholder];
    }
    return self;
}

- (void)configureImageViewWithPlaceholder {
    [self.imageView wmf_configureWithDefaultPlaceholder];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self configureImageViewWithPlaceholder];
}

@end
