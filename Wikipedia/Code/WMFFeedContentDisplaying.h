@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFFeedDisplayType) {
    WMFFeedDisplayTypePage,
    WMFFeedDisplayTypePageWithPreview,
    WMFFeedDisplayTypePageWithLocation,
    WMFFeedDisplayTypePhoto,
    WMFFeedDisplayTypeStory,
    WMFFeedDisplayTypeEvent,
    WMFFeedDisplayTypeAnnouncement,
    WMFFeedDisplayTypeRelatedPagesSourceArticle,
    WMFFeedDisplayTypeRelatedPages,
    WMFFeedDisplayTypeContinueReading,
    WMFFeedDisplayTypeMainPage,
    WMFFeedDisplayTypeRandom,
    WMFFeedDisplayTypeRanked,
    WMFFeedDisplayTypeNotification,
    WMFFeedDisplayTypeCompactList,
    WMFFeedDisplayTypeTheme,
    WMFFeedDisplayTypeReadingList,
    WMFFeedDisplayTypePageWithLocationPlaceholder
};

typedef NS_ENUM(NSUInteger, WMFFeedDetailType) {
    WMFFeedDetailTypeNone,
    WMFFeedDetailTypePage,
    WMFFeedDetailTypePageWithRandomButton,
    WMFFeedDetailTypeGallery,
    WMFFeedDetailTypeStory,
    WMFFeedDetailTypeEvent
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
    WMFFeedMoreTypePageListWithLocation,
    WMFFeedMoreTypeLocationAuthorization,
    WMFFeedMoreTypeNews,
    WMFFeedMoreTypeOnThisDay
};

@protocol WMFFeedContentDisplaying

/**
 *  The type of header to display for the section
 *
 *  @return An image
 */
- (WMFFeedHeaderType)headerType;

/**
 *  The text to be displayed on the first line of the header.
 *  Additional styling will be added before display time.
 *
 *  @return The header title string
 */
@property (nonatomic, readonly, nullable) NSString *headerTitle;

/**
 *  The text to be displayed on the second line of the header.
 *  Additional styling will be added bfore display time.
 *
 *  @return The header sub-title string
 */
@property (nonatomic, readonly, nullable) NSString *headerSubTitle;

/*
 * The URL of the content that the header represents
 * Usually an article
 */
@property (nonatomic, readonly, nullable) NSURL *headerContentURL;

/*
 * The action that shoud be performed when a user taps on the header.
 */
@property (nonatomic, readonly) WMFFeedHeaderActionType headerActionType;

/**
 *  How to display the content of the section.
 */
- (WMFFeedDisplayType)displayTypeForItemAtIndex:(NSInteger)index;

@property (nonatomic, readonly) NSUInteger maxNumberOfCells;

@property (nonatomic, readonly) BOOL prefersWiderColumn;

@property (nonatomic, readonly) WMFFeedDetailType detailType;

/**
 *  Specify the text for an optional footer which allows the user to see a list of more content.
 *
 *  No footer will be displayed if this is nil.
 *
 *  @return The "More" footer text that prompts a user to get more items from a section.
 */
@property (nonatomic, readonly, nullable) NSString *footerText;

/**
 *  How to display content when tapping the more footer
 */
@property (nonatomic, readonly) WMFFeedMoreType moreType;

/*
 *  Title for the view displayed when tapping more
 */
@property (nonatomic, readonly, nullable) NSString *moreTitle;

/*
 *  Specifies if group's visibility should be updated.
 */
@property (nonatomic, readonly) BOOL requiresVisibilityUpdate;

@end

NS_ASSUME_NONNULL_END
