@import UIKit;
#import "WMFAnalyticsLogging.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFFeedDisplayType) {
    WMFFeedDisplayTypePage,
    WMFFeedDisplayTypePageWithPreview,
    WMFFeedDisplayTypePageWithLocation,
    WMFFeedDisplayTypePhoto,
    WMFFeedDisplayTypeStory,
    WMFFeedDisplayTypeAnnouncement
};

typedef NS_ENUM(NSUInteger, WMFFeedDetailType) {
    WMFFeedDetailTypeNone,
    WMFFeedDetailTypePage,
    WMFFeedDetailTypePageWithRandomButton,
    WMFFeedDetailTypeGallery,
    WMFFeedDetailTypeStory,
    WMFFeedDetailTypeAnnouncement
};

typedef NS_ENUM(NSUInteger, WMFFeedHeaderType) {
    WMFFeedHeaderTypeNone,
    WMFFeedHeaderTypeStandard,
};

typedef NS_ENUM(NSUInteger, WMFFeedHeaderActionType) {
    WMFFeedHeaderActionTypeOpenHeaderNone,
    WMFFeedHeaderActionTypeOpenHeaderContent,
    WMFFeedHeaderActionTypeOpenFirstItem,
    WMFFeedHeaderActionTypeOpenMore,
};

typedef NS_ENUM(NSUInteger, WMFFeedMoreType) {
    WMFFeedMoreTypeNone,
    WMFFeedMoreTypePage,
    WMFFeedMoreTypePageWithRandomButton,
    WMFFeedMoreTypePageList,
    WMFFeedMoreTypePageListWithPreview,
    WMFFeedMoreTypePageListWithLocation,
};

typedef NS_OPTIONS(NSInteger, WMFFeedBlacklistOption) {
    WMFFeedBlacklistOptionNone = 0,
    WMFFeedBlacklistOptionContent = 1 << 0, //blacklist specific section content
    //    WMFFeedBlacklistOptionSection = 1 << 1, //blacklist all sections of this type
};

@protocol WMFFeedContentDisplaying <WMFAnalyticsContentTypeProviding>

/**
 *  The type of header to display for the section
 *
 *  @return An image
 */
- (WMFFeedHeaderType)headerType;

/**
 *  An icon to be displayed in the section's header
 *
 *  @return An image
 */
- (nullable UIImage *)headerIcon;

/**
 *  Color used for icon tint
 *
 *  @return A color
 */
- (nullable UIColor *)headerIconTintColor;

/**
 *  Background color of section's header icon container view
 *
 *  @return A color
 */
- (nullable UIColor *)headerIconBackgroundColor;

/**
 *  The text to be displayed on the first line of the header.
 *  Note this is an attributed stirng to allow links to be embeded
 *  Additional styling will be added before display time.
 *
 *  @return The header title string
 */
- (nullable NSAttributedString *)headerTitle;

/**
 *  The text to be displayed on the second line of the header.
 *  Note this is an attributed stirng to allow links to be embeded
 *  Additional styling will be added bfore display time.
 *
 *  @return The header sub-title string
 */
- (nullable NSAttributedString *)headerSubTitle;

/*
 * The URL of the content that the header represents
 * Usually an article
 */
- (nullable NSURL *)headerContentURL;

/*
 * The action that shoud be performed when a user taps on the header.
 */
- (WMFFeedHeaderActionType)headerActionType;

/*
 * Options for the blacklist menu
 */
- (WMFFeedBlacklistOption)blackListOptions;

/**
 *  How to display the content of the section.
 */
- (WMFFeedDisplayType)displayType;

- (NSUInteger)maxNumberOfCells;

- (BOOL)prefersWiderColumn;

- (WMFFeedDetailType)detailType;

/**
 *  Specify the text for an optional footer which allows the user to see a list of more content.
 *
 *  No footer will be displayed if this is nil.
 *
 *  @return The "More" footer text that prompts a user to get more items from a section.
 */
- (nullable NSString *)footerText;

/**
 *  How to display content when tapping the more footer
 */
- (WMFFeedMoreType)moreType;

/*
 *  Title for the view displayed when tapping more
 */
- (nullable NSString *)moreTitle;

@end

NS_ASSUME_NONNULL_END
