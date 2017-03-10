#import "UIColor+WMFStyle.h"
#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMFStyle)

+ (instancetype)wmf_licenseTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x565656 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_licenseLinkColor {
    return [self wmf_blueTintColor];
}

+ (instancetype)wmf_lightGrayColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xdddddd alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderLightGrayColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xf8f8f8 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageTintColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xb2b2b2 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xf4f4f4 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_articleListBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xEAECF0 alpha:1.0];
        ;
    });
    return c;
}

+ (instancetype)wmf_articleBackgroundColor {
    return [self wmf_articleListBackgroundColor];
}

+ (instancetype)wmf_inlineTableOfContentsBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xf4f5f7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_modalTableOfContentsBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xffffff alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_modalTableOfContentsSelectionBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xffffff alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_inlineTableOfContentsSelectionBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xf2f2f2 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x3366cc alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSectionTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x333333 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSubsectionTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x555a5f alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_exploreSectionHeaderTitleColor {
    return [UIColor wmf_customGray];
}

+ (instancetype)wmf_exploreSectionHeaderSubTitleColor {
    return [UIColor wmf_customGray];
}

+ (instancetype)wmf_exploreSectionFooterTextColor {
    return [self wmf_customGray];
}

+ (instancetype)wmf_exploreSectionHeaderIconTintColor {
    return [self wmf_customGray];
}

+ (instancetype)wmf_exploreSectionHeaderIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xF5F5F5 alpha:1.0];
}

+ (instancetype)wmf_exploreSectionHeaderLinkTextColor {
    return [self wmf_blueTintColor];
}

+ (instancetype)wmf_blueTintColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x3366cc alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_darkBlueTintColor {
    static UIColor *c = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x2a4b8d alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_lightBlueTintColor {
    return [UIColor wmf_colorWithHex:0xeaf2ff alpha:1.0];
}

+ (instancetype)wmf_tapHighlightColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xeeeeee alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_nearbyArrowColor {
    return [UIColor wmf_colorWithHex:0x00AF89 alpha:1.0];
}

+ (instancetype)wmf_nearbyTickColor {
    return [UIColor wmf_colorWithHex:0x00AF89 alpha:0.8];
}

+ (instancetype)wmf_nearbyTitleColor {
    return [UIColor blackColor];
}

+ (instancetype)wmf_nearbyDescriptionColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x666666 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_nearbyDistanceBackgroundColor {
    return [UIColor wmf_colorWithHex:0xAAAAAA alpha:1.0];
}

+ (instancetype)wmf_999999Color {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x999999 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_777777Color {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x777777 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_foundationGray {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x7D8389 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_darkGray {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x555A5f alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_customGray {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x9AA0A7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_readerWGray {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x444444 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_nearbyDistanceTextColor {
    return [UIColor whiteColor];
}

+ (instancetype)wmf_emptyGrayTextColor {
    return [self wmf_999999Color];
}

+ (instancetype)wmf_settingsBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xefeff4 alpha:1.0];
    });
    return c;
}

- (instancetype)wmf_copyWithAlpha:(CGFloat)alpha {
    CGFloat r, g, b, _;
    [self getRed:&r green:&g blue:&b alpha:&_];
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

- (instancetype)wmf_colorByApplyingDim {
    // NOTE(bgerstle): 0.6 is hand-tuned to roughly match UIImageView's default tinting amount
    return [self wmf_colorByScalingComponents:0.6];
}

- (instancetype)wmf_colorByScalingComponents:(CGFloat)amount {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r * amount green:g * amount blue:b * amount alpha:a];
}

+ (instancetype)wmf_green {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x00AF89 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_welcomeBackgroundGradientTopColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x3366cc alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_welcomeBackgroundGradientBottomColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x0af89 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_primaryLanguageLabelBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xcccccc alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_barButtonItemPopoverMessageBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x000000 alpha:0.8];
    });
    return c;
}

+ (instancetype)wmf_referencePopoverBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xffffff alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_referencePopoverLinkColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x3366CC alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_referencePopoverTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x000000 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_red {
    static UIColor *c = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xd11611 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_orange {
    static UIColor *c = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0xff5b00 alpha:1.0];
    });
    return c;
}

@end
