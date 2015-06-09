//
//  LanguagesSectionHeaderView.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/5/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "LanguagesSectionHeaderView.h"
#import "WikipediaAppUtils.h"
#import "PaddedLabel.h"
#import "Defines.h"
#import <Masonry/Masonry.h>

static const CGFloat LanguagesSectionTitleLabelVerticalMargin = 8.f;

@implementation LanguagesSectionHeaderView

+ (CGFloat)defaultHeaderHeight {
    return [[self labelFont] lineHeight] + LanguagesSectionTitleLabelVerticalMargin * 2;
}

+ (UIFont*)labelFont {
    return [UIFont boldSystemFontOfSize:14.0 * MENUS_SCALE_MULTIPLIER];
}

- (instancetype)initWithReuseIdentifier:(NSString*)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        PaddedLabel* titleLabel = [[PaddedLabel alloc] initWithFrame:self.bounds];
        titleLabel.textAlignment = NSTextAlignmentNatural;
        titleLabel.font          = [[self class] labelFont];

        [self.contentView addSubview:titleLabel];
        self.titleLabel = titleLabel;

        self.contentView.backgroundColor = CHROME_COLOR;

        /*
           must set contentView constraints to prevent autolayout warning about not being able to satisfy
           contentView.width == 0 and titleLabel leading/trailing constraints
         */
        [self.contentView mas_makeConstraints:^(MASConstraintMaker* make) {
            make.edges.equalTo(self);
        }];

        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker* make) {
            make.leading.equalTo(self.contentView.mas_leading).with.offset(20.f);
            make.trailing.equalTo(self.contentView.mas_trailing).with.offset(0.f);
            make.top.equalTo(self.contentView.mas_top).with.offset(LanguagesSectionTitleLabelVerticalMargin);
            make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-LanguagesSectionTitleLabelVerticalMargin);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.titleLabel.text = @"";
}

@end
