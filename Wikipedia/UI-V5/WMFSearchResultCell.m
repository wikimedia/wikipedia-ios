//
//  WMFSearchCollectionViewCell.m
//  Wikipedia
//
//  Created by Brian Gerstle on 9/2/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFSearchResultCell.h"
#import "WMFSaveableTitleCollectionViewCell+Subclass.h"
#import "MWKTitle.h"
#import "WMFRangeUtils.h"
#import "NSParagraphStyle+WMFParagraphStyles.h"
#import "UIColor+WMFStyle.h"

static CGFloat const WMFSearchResultImageWidth                  = 40.f;
static CGFloat const WMFSearchResultTitleLabelHorizontalPadding = 15.f;

@interface WMFSearchResultCell ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bottomTitleToTopDescriptionConstraint;

@property (nonatomic, strong) IBOutlet UILabel* searchResultDescriptionLabel;

@property (nonatomic, copy) NSString* highlightSubstring;

@end

@implementation WMFSearchResultCell

#pragma mark - Style

+ (CGFloat)titleLabelFontSize {
    return 16.f;
}

+ (UIFont*)titleLabelFont {
    return [UIFont systemFontOfSize:[self titleLabelFontSize]];
}

+ (UIFont*)boldTitleLabelFont {
    return [UIFont boldSystemFontOfSize:[self titleLabelFontSize]];
}

#pragma mark - Accessors

- (void)setTitle:(MWKTitle*)title highlightingSubstring:(NSString*)substring {
    self.highlightSubstring = substring;
    self.title              = title;
}

- (void)setSearchResultDescription:(NSString*)searchResultDescription {
    self.searchResultDescriptionLabel.text = searchResultDescription;
}

#pragma mark - WMFSaveableTitleCollectionViewCell

- (void)updateTitleLabel {
    NSRange highlightRange =
        self.highlightSubstring.length ?
        [self.title.text rangeOfString : self.highlightSubstring options:NSCaseInsensitiveSearch]
        : WMFRangeMakeNotFound();
    if (WMFRangeIsNotFoundOrEmpty(highlightRange)) {
        [super updateTitleLabel];
    } else {
        [self applyAttributedTitleWithHighlightRange:highlightRange];
    }
}

- (void)configureImageViewWithPlaceholder {
    [super configureImageViewWithPlaceholder];
    self.imageView.contentMode     = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Highlighting

- (void)applyAttributedTitleWithHighlightRange:(NSRange)highlightRange {
    NSParameterAssert(!WMFRangeIsNotFoundOrEmpty(highlightRange));
    NSMutableAttributedString* attributedTitle =
        [[NSMutableAttributedString alloc] initWithString:self.title.text attributes:nil];

    NSRange beforeHighlight = NSMakeRange(0, highlightRange.location);
    if (!WMFRangeIsNotFoundOrEmpty(beforeHighlight)) {
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[[self class] titleLabelFont]
                                range:beforeHighlight];
    }

    [attributedTitle addAttribute:NSFontAttributeName
                            value:[[self class] boldTitleLabelFont]
                            range:highlightRange];

    NSUInteger afterHighlightStart = WMFRangeGetMaxIndex(highlightRange) - 1;
    NSRange afterHighlight         = NSMakeRange(afterHighlightStart, self.title.text.length - afterHighlightStart);
    if (!WMFRangeIsNotFoundOrEmpty(afterHighlight)) {
        [attributedTitle addAttribute:NSFontAttributeName
                                value:[[self class] titleLabelFont]
                                range:beforeHighlight];
    }

    [attributedTitle addAttribute:NSParagraphStyleAttributeName
                            value:[NSParagraphStyle wmf_tailTruncatingNaturalAlignmentStyle]
                            range:NSMakeRange(0, self.title.text.length)];

    self.titleLabel.attributedText = attributedTitle;
}

#pragma mark - UICollectionViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.highlightSubstring = nil;
    [self setSearchResultDescription:nil];
}

- (UICollectionViewLayoutAttributes*)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes*)layoutAttributes {
    CGFloat preferredMaxLayoutWidth =
        layoutAttributes.size.width
        - WMFSearchResultImageWidth
        - 3.f * WMFSearchResultTitleLabelHorizontalPadding;

    if (self.titleLabel.preferredMaxLayoutWidth != preferredMaxLayoutWidth) {
        self.titleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth;
    }

    self.searchResultDescriptionLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth;

    UICollectionViewLayoutAttributes* preferredAttributes = [layoutAttributes copy];
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, WMFSearchResultImageWidth + 20.f);
    return preferredAttributes;
}

@end
