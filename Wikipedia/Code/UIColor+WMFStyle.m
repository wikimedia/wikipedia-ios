
#import "UIColor+WMFStyle.h"
#import "UIColor+WMFHexColor.h"

@implementation UIColor (WMFStyle)

+ (instancetype)wmf_logoBlue {
    // measured from WMF logo using DigitalColorMeter
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [self wmf_logoBlueWithAlpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_logoBlueWithAlpha:(CGFloat)alpha {
    // measured from WMF logo using DigitalColorMeter
    return [UIColor colorWithRed:0.08203125 green:0.40625 blue:0.5859375 alpha:alpha];
}

+ (instancetype)wmf_summaryTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.118 green:0.118 blue:0.118 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_licenseTextColor {
    static UIColor* c = nil;

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
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.870588 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderLightGrayColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.975 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageTintColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.7 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_placeholderImageBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithWhite:0.96 alpha:1.0];
    });
    return c;
}

+ (instancetype)wmf_articleListBackgroundColor {
    static UIColor* c = nil;

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

+ (instancetype)wmf_tableOfContentsHeaderTextColor {
    return [self wmf_tableOfContentsSectionTextColor];
}

+ (instancetype)wmf_tableOfContentsSelectionBackgroundColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.929 green:0.929 blue:0.929 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.192 green:0.334 blue:0.811 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSectionTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tableOfContentsSubsectionTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_homeSectionHeaderTextColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_homeSectionFooterTextColor {
    return [self wmf_homeSectionHeaderTextColor];
}

+ (instancetype)wmf_blueTintColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithHue:0.611 saturation:0.75 brightness:0.8 alpha:1];
    });
    return c;
}

+ (instancetype)wmf_tapHighlightColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:238.0f / 255.0f green:238.0f / 255.0f blue:238.0f / 255.0f alpha:1];
    });
    return c;
}

+ (instancetype)wmf_homeSectionHeaderLinkTextColor {
    return [self wmf_blueTintColor];
}

+ (instancetype)wmf_nearbyArrowColor {
    return [UIColor blackColor];
}

+ (instancetype)wmf_nearbyTickColor {
    return [UIColor lightGrayColor];
}

+ (instancetype)wmf_nearbyTitleColor {
    return [UIColor blackColor];
}

+ (instancetype)wmf_nearbyDescriptionColor {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x666666 alpha:1.0];
        ;
    });
    return c;
}

+ (instancetype)wmf_nearbyDistanceBackgroundColor {
    return [UIColor wmf_colorWithHex:0xAAAAAA alpha:1.0];
}

+ (instancetype)wmf_999999Color {
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor wmf_colorWithHex:0x999999 alpha:1.0];
        ;
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
    static UIColor* c = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        c = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    });
    return c;
}

@end
