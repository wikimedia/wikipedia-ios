#import "UIColor+WMFStyle.h"
#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMFStyle)

+ (instancetype)wmf_summaryTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.118 green:0.118 blue:0.118 alpha:1];
    });
    return c;
}

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
        c = [UIColor colorWithWhite:0.870588 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderLightGrayColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.975 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageTintColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.96 alpha:1.0];
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
        c = [UIColor colorWithRed:244.0 / 255.0 green:245.0 / 255.0 blue:247.0 / 255.0 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_modalTableOfContentsBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:1 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_modalTableOfContentsSelectionBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:1 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_inlineTableOfContentsSelectionBackgroundColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.95 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:51.0 / 255.0 green:102.0 / 255.0 blue:204.0 / 255.0 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSectionTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSubsectionTextColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:85.0 / 255.0 green:90.0 / 255.0 blue:95.0 / 255.0 alpha:1];
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
        c = [UIColor colorWithHue:0.611 saturation:0.75 brightness:0.8 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_lightBlueTintColor {
    return [UIColor colorWithRed:0.92 green:0.95 blue:1.0 alpha:1.0];
}

+ (instancetype)wmf_tapHighlightColor {
    static UIColor *c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:238.0f / 255.0f green:238.0f / 255.0f blue:238.0f / 255.0f alpha:1];
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
        c = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
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
        c = [UIColor colorWithRed:0.8039 green:0.8039 blue:0.8039 alpha:1.0];
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
        c = [UIColor colorWithRed:0.82 green:0.09 blue:0.07 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_orange {
    static UIColor *c = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:1.00 green:0.36 blue:0.00 alpha:1.0];
    });
    return c;
}

@end
