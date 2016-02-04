
#import <UIKit/UIKit.h>

@interface UIColor (WMFStyle)

+ (instancetype)wmf_blueTintColor;

+ (instancetype)wmf_tapHighlightColor;

+ (instancetype)wmf_summaryTextColor;

+ (instancetype)wmf_licenseTextColor;

+ (instancetype)wmf_licenseLinkColor;

+ (instancetype)wmf_articleListBackgroundColor;

+ (instancetype)wmf_articleBackgroundColor;

+ (instancetype)wmf_tableOfContentsHeaderTextColor;

+ (instancetype)wmf_tableOfContentsSelectionBackgroundColor;

+ (instancetype)wmf_tableOfContentsSelectionIndicatorColor;

+ (instancetype)wmf_tableOfContentsSectionTextColor;

+ (instancetype)wmf_tableOfContentsSubsectionTextColor;

+ (instancetype)wmf_exploreSectionHeaderTitleColor;

+ (instancetype)wmf_exploreSectionHeaderSubTitleColor;

+ (instancetype)wmf_exploreSectionFooterTextColor;

+ (instancetype)wmf_exploreSectionHeaderLinkTextColor;

+ (instancetype)wmf_exploreSectionHeaderIconTintColor;

+ (instancetype)wmf_exploreSectionHeaderIconBackgroundColor;

/**
 *  Color which is used in places like cell separators & various 1px lines in the interface.
 */
+ (instancetype)wmf_lightGrayColor;


+ (instancetype)wmf_999999Color;

+ (instancetype)wmf_customGray;

+ (instancetype)wmf_placeholderImageTintColor;

+ (instancetype)wmf_placeholderImageBackgroundColor;

+ (instancetype)wmf_placeholderLightGrayColor;

+ (instancetype)wmf_nearbyArrowColor;

+ (instancetype)wmf_nearbyTickColor;

+ (instancetype)wmf_nearbyTitleColor;

+ (instancetype)wmf_nearbyDescriptionColor;

+ (instancetype)wmf_nearbyDistanceBackgroundColor;

+ (instancetype)wmf_nearbyDistanceTextColor;

+ (instancetype)wmf_emptyGrayTextColor;

+ (instancetype)wmf_settingsBackgroundColor;

///
/// @name Derivative Colors
///

/**
 *  @return A dimmed copy of the receiver.
 *
 *  @see -wmf_colorByScalingComponents:
 */
- (instancetype)wmf_colorByApplyingDim;

/**
 *  @return A copy of the receiver, applying @c amount as a scalar to its red, green, blue, and alpha values.
 */
- (instancetype)wmf_colorByScalingComponents:(CGFloat)amount;

@end
