#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "WMFAnnouncement.h"
#import "WMFFeedNewsStory.h"
#import "WMFContentGroup+Extensions.h"
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFContentGroup (WMFContentManaging)

- (nullable NSString *)headerTitle {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindContinueReading:
            return [WMFCommonStrings continueReadingTitle];
        case WMFContentGroupKindMainPage:
            return WMFLocalizedStringWithDefaultValue(@"explore-main-page-heading", nil, nil, @"Today on Wikipedia", @"Text for 'Today on Wikipedia' header");
        case WMFContentGroupKindRelatedPages:
            return [WMFCommonStrings relatedPagesTitle];
        case WMFContentGroupKindLocation:
            return WMFLocalizedStringWithDefaultValue(@"explore-nearby-heading", nil, nil, @"Places near", @"Text for 'Nearby places' header. The next line of the header is the name of the nearest article.");
        case WMFContentGroupKindLocationPlaceholder:
            return WMFLocalizedStringWithDefaultValue(@"explore-nearby-placeholder-heading", nil, nil, @"Places", @"Nearby placeholder heading. The user hasn't granted location access so we show a generic section about Places on Wikipedia {{Identical|Place}}");
        case WMFContentGroupKindPictureOfTheDay:
            return [WMFCommonStrings pictureOfTheDayTitle];
        case WMFContentGroupKindRandom:
            return WMFLocalizedStringWithDefaultValue(@"explore-random-article-heading", nil, nil, @"Random article", @"Text for 'Random article' header {{Identical|Random article}}");
        case WMFContentGroupKindFeaturedArticle:
            return [WMFCommonStrings featuredArticleTitle];
        case WMFContentGroupKindTopRead:
            return WMFLocalizedStringWithDefaultValue(@"explore-most-read-generic-heading", nil, nil, @"Top read", @"Text for 'Most read articles' explore section header used when no language is present");
        case WMFContentGroupKindNews:
            return WMFLocalizedStringWithDefaultValue(@"in-the-news-title", nil, nil, @"In the news", @"Title for the 'In the news' notification & feed section");
        case WMFContentGroupKindOnThisDay:
            return WMFCommonStrings.onThisDayTitle;
        default:
            break;
    }
    return [[NSString alloc] init];
}

- (NSString *)stringWithLocalizedCurrentSiteLanguageReplacingPlaceholderInString:(NSString *)string fallingBackOnGenericString:(NSString *)genericString {
    // fall back to language code if it can't be localized
    NSString *language = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.siteURL.wmf_language];

    NSString *result = nil;

    //crash protection if language is nil
    if (language) {
        result = [NSString localizedStringWithFormat:string, language];
    } else {
        result = genericString;
    }
    return result;
}

- (NSString *)fromLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback {
    if (self.siteURL.wmf_language) {
        NSString *localizedString = WMFCommonStrings.fromLanguageWikipedia[self.siteURL.wmf_language];
        if (localizedString) {
            return localizedString;
        }
    }

    return WMFCommonStrings.fromWikipedia;
}

- (NSString *)onLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback {
    if (self.siteURL.wmf_language) {
        NSString *localizedString = WMFCommonStrings.onLanguageWikipedia[self.siteURL.wmf_language];
        if (localizedString) {
            return localizedString;
        }
    }

    return WMFCommonStrings.onWikipedia;
}

- (NSString *)exploreNearbySubheadingStringWithLocalizedCurrentSiteLanguageOrGenericFallback {
    if (self.siteURL.wmf_language) {
        NSString *localizedString = WMFCommonStrings.exploreNearbySubheading[self.siteURL.wmf_language];
        if (localizedString) {
            return localizedString;
        }
    }

    return WMFLocalizedStringWithDefaultValue(@"explore-nearby-sub-heading-your-location", nil, nil, @"Your location", @"Subtext beneath the 'Places near' header when showing articles near the user's current location.");
}

- (nullable NSString *)headerSubTitle {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindRelatedPages:
        case WMFContentGroupKindContinueReading: {
            NSString *subtitle = [self.contentMidnightUTCDate wmf_localizedRelativeDateFromMidnightUTCDate];
            if (subtitle == nil) {
                subtitle = [[self.date wmf_midnightUTCDateFromLocalDate] wmf_localizedRelativeDateFromMidnightUTCDate];
            }
            return subtitle ? subtitle : @"";
        } break;
        case WMFContentGroupKindMainPage:
            return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:[NSDate date]];
            break;
        case WMFContentGroupKindLocation: {
            if (self.isForToday) {
                return [self exploreNearbySubheadingStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
            } else if (self.placemark) {
                return [NSString stringWithFormat:@"%@, %@", self.placemark.name, self.placemark.locality];
            } else {
                return [NSString stringWithFormat:@"%f, %f", self.location.coordinate.latitude, self.location.coordinate.longitude];
            }
        } break;
        case WMFContentGroupKindLocationPlaceholder:
            return [self fromLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
        case WMFContentGroupKindPictureOfTheDay:
            return WMFLocalizedStringWithDefaultValue(@"explore-potd-sub-heading", nil, nil, @"From Wikimedia Commons", @"Subtext beneath the 'Picture of the day' header.");
        case WMFContentGroupKindRandom:
            return [self fromLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
        case WMFContentGroupKindFeaturedArticle:
            return [self fromLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
        case WMFContentGroupKindTopRead: {
            return [self onLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
        }
        case WMFContentGroupKindNews:
            return [self fromLanguageWikipediaStringWithLocalizedCurrentSiteLanguageOrGenericFallback];
        case WMFContentGroupKindOnThisDay: {
            NSString *language = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.siteURL.wmf_language];
            if (language) {
                // TODO: Convert to CommonStrings with language code
                return
                    [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"on-this-day-sub-title-for-date-from-language-wikipedia", nil, nil, @"%1$@ from %2$@ Wikipedia", @"Subtext beneath the 'On this day' header when describing the date and which specific Wikipedia. %1$@ will be substituted with the date. %2$@ will be replaced with the language - for example, 'June 8th from English Wikipedia'"), [[NSDateFormatter wmf_utcMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.midnightUTCDate], language];
            } else {
                return [[NSDateFormatter wmf_utcMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.midnightUTCDate];
            }
        }
        default:
            break;
    }
    return [[NSString alloc] init];
}

- (nullable NSURL *)headerContentURL {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindMainPage:
            break;
        case WMFContentGroupKindRelatedPages:
            return self.articleURL;
        default:
            break;
    }
    return nil;
}

- (WMFFeedHeaderActionType)headerActionType {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindRelatedPages:
            return WMFFeedHeaderActionTypeOpenHeaderContent;
        case WMFContentGroupKindLocation:
            return WMFFeedHeaderActionTypeOpenMore;
        case WMFContentGroupKindTopRead:
            return WMFFeedHeaderActionTypeOpenMore;
        case WMFContentGroupKindNews:
            return WMFFeedHeaderActionTypeOpenFirstItem;
        case WMFContentGroupKindOnThisDay:
            return WMFFeedHeaderActionTypeOpenFirstItem;
        case WMFContentGroupKindAnnouncement:
            return WMFFeedHeaderActionTypeOpenHeaderNone;
        default:
            break;
    }
    return WMFFeedHeaderActionTypeOpenFirstItem;
}

- (WMFFeedDisplayType)displayTypeForItemAtIndex:(NSInteger)index {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindContinueReading:
            return WMFFeedDisplayTypeContinueReading;
        case WMFContentGroupKindMainPage:
            return WMFFeedDisplayTypeMainPage;
        case WMFContentGroupKindRelatedPages:
            return index == 0 ? WMFFeedDisplayTypeRelatedPagesSourceArticle : WMFFeedDisplayTypeRelatedPages;
        case WMFContentGroupKindLocation:
            return WMFFeedDisplayTypePageWithLocation;
        case WMFContentGroupKindLocationPlaceholder:
            return WMFFeedDisplayTypePageWithLocationPlaceholder;
        case WMFContentGroupKindPictureOfTheDay:
            return WMFFeedDisplayTypePhoto;
        case WMFContentGroupKindRandom:
            return WMFFeedDisplayTypeRandom;
        case WMFContentGroupKindFeaturedArticle:
            return WMFFeedDisplayTypePageWithPreview;
        case WMFContentGroupKindTopRead:
            return WMFFeedDisplayTypeRanked;
        case WMFContentGroupKindNews:
            return WMFFeedDisplayTypeStory;
        case WMFContentGroupKindOnThisDay:
            return WMFFeedDisplayTypeEvent;
        case WMFContentGroupKindNotification:
            return WMFFeedDisplayTypeNotification;
        case WMFContentGroupKindTheme:
            return WMFFeedDisplayTypeTheme;
        case WMFContentGroupKindReadingList:
            return WMFFeedDisplayTypeReadingList;
        case WMFContentGroupKindAnnouncement:
            return WMFFeedDisplayTypeAnnouncement;
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return WMFFeedDisplayTypePage;
}

- (NSUInteger)maxNumberOfCells {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindRelatedPages:
            return 3;
        case WMFContentGroupKindLocation:
            return 3;
        case WMFContentGroupKindLocationPlaceholder:
            return 1;
        case WMFContentGroupKindTopRead:
            return 5;
        case WMFContentGroupKindNews:
            return 5;
        case WMFContentGroupKindAnnouncement:
            return NSUIntegerMax;
        default:
            break;
    }
    return 1;
}

- (BOOL)prefersWiderColumn {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindContinueReading:
            break;
        case WMFContentGroupKindMainPage:
            break;
        case WMFContentGroupKindRelatedPages:
            return YES /*FBTweakValue(@"Explore", @"General", @"Put 'Because You Read' in Wider Column", YES)*/;
        case WMFContentGroupKindLocation:
            break;
        case WMFContentGroupKindLocationPlaceholder:
            break;
        case WMFContentGroupKindPictureOfTheDay:
            return YES;
        case WMFContentGroupKindRandom:
            break;
        case WMFContentGroupKindFeaturedArticle:
            return YES;
        case WMFContentGroupKindTopRead:
            break;
        case WMFContentGroupKindNews:
            return YES;
        case WMFContentGroupKindOnThisDay:
            break;
        case WMFContentGroupKindNotification:
            return YES;
        case WMFContentGroupKindTheme:
            return YES;
        case WMFContentGroupKindReadingList:
            return YES;
        case WMFContentGroupKindAnnouncement:
            return YES;
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return NO;
}

- (WMFFeedDetailType)detailType {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindPictureOfTheDay:
            return WMFFeedDetailTypeGallery;
        case WMFContentGroupKindRandom:
            return WMFFeedDetailTypePageWithRandomButton;
        case WMFContentGroupKindNews:
            return WMFFeedDetailTypeStory;
        case WMFContentGroupKindOnThisDay:
            return WMFFeedDetailTypeEvent;
        case WMFContentGroupKindNotification:
            return WMFFeedDetailTypeNone;
        case WMFContentGroupKindTheme:
            return WMFFeedDetailTypeNone;
        case WMFContentGroupKindReadingList:
            return WMFFeedDetailTypeNone;
        case WMFContentGroupKindAnnouncement:
            return WMFFeedDetailTypeNone;
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return WMFFeedDetailTypePage;
}

- (nullable NSString *)footerText {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindRelatedPages:
            return WMFLocalizedStringWithDefaultValue(@"explore-because-you-read-footer", nil, nil, @"Additional related articles", @"Footer for presenting user option to see longer list of articles related to a previously read article.");
        case WMFContentGroupKindLocation: {
            if (self.isForToday) {
                return [WMFCommonStrings nearbyFooterTitle];
            } else {
                return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"home-nearby-location-footer", nil, nil, @"More nearby %1$@", @"Footer for presenting user option to see longer list of articles nearby a specific location. %1$@ will be replaced with the name of the location"), self.placemark.name];
            }
        }
        case WMFContentGroupKindPictureOfTheDay:
            break;
        case WMFContentGroupKindRandom:
            return WMFLocalizedStringWithDefaultValue(@"explore-another-random", nil, nil, @"Another random article", @"Displayed on buttons that indicate they would load 'Another random article'");
        case WMFContentGroupKindFeaturedArticle:
            break;
        case WMFContentGroupKindTopRead:
            return WMFLocalizedStringWithDefaultValue(@"explore-most-read-footer", nil, nil, @"All top read articles", @"Text which shown on the footer beneath 'Most read articles', which presents a longer list of 'most read' articles for a given date when tapped.");
        case WMFContentGroupKindNews:
            return WMFLocalizedStringWithDefaultValue(@"home-news-footer", nil, nil, @"More current events", @"Footer for presenting user option to see longer list of news stories.");
        case WMFContentGroupKindOnThisDay:
            return WMFLocalizedStringWithDefaultValue(@"on-this-day-footer", nil, nil, @"More historical events on this day", @"Footer for presenting user option to see longer list of 'On this day' articles. %1$@ will be substituted with the number of events");
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return nil;
}

- (WMFFeedMoreType)moreType {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindRelatedPages:
            return WMFFeedMoreTypePageList;
        case WMFContentGroupKindLocation:
            return WMFFeedMoreTypePageListWithLocation;
        case WMFContentGroupKindLocationPlaceholder:
            return WMFFeedMoreTypeLocationAuthorization;
        case WMFContentGroupKindRandom:
            return WMFFeedMoreTypePageWithRandomButton;
        case WMFContentGroupKindTopRead:
            return WMFFeedMoreTypePageList;
        case WMFContentGroupKindNews:
            return WMFFeedMoreTypeNews;
        case WMFContentGroupKindOnThisDay:
            return WMFFeedMoreTypeOnThisDay;
        default:
            break;
    }
    return WMFFeedMoreTypeNone;
}

- (nullable NSString *)moreLikeTitle {
    return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"home-more-like-footer", nil, nil, @"More like %1$@", @"Footer for presenting user option to see longer list of articles related to a previously read article. %1$@ will be replaced with the name of the previously read article."), self.articleURL.wmf_title];
}

- (nullable NSString *)moreTitle {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindContinueReading:
            break;
        case WMFContentGroupKindMainPage:
            break;
        case WMFContentGroupKindRelatedPages:
            return self.moreLikeTitle;
        case WMFContentGroupKindLocation:
            return WMFLocalizedStringWithDefaultValue(@"main-menu-nearby", nil, nil, @"Nearby", @"Button for showing nearby articles. {{Identical|Nearby}}");
        case WMFContentGroupKindLocationPlaceholder:
            break;
        case WMFContentGroupKindPictureOfTheDay:
            break;
        case WMFContentGroupKindRandom:
            break;
        case WMFContentGroupKindFeaturedArticle:
            break;
        case WMFContentGroupKindTopRead:
            return [self topReadMoreTitleForDate:self.contentMidnightUTCDate];
        case WMFContentGroupKindNews:
            break;
        case WMFContentGroupKindOnThisDay:
            break;
        case WMFContentGroupKindNotification:
            break;
        case WMFContentGroupKindAnnouncement:
            break;
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return nil;
}

- (WMFFeedHeaderType)headerType {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindNotification:
            return WMFFeedHeaderTypeNone;
        case WMFContentGroupKindTheme:
            return WMFFeedHeaderTypeNone;
        case WMFContentGroupKindReadingList:
            return WMFFeedHeaderTypeNone;
        case WMFContentGroupKindAnnouncement:
            return WMFFeedHeaderTypeNone;
        case WMFContentGroupKindUnknown:
        default:
            break;
    }
    return WMFFeedHeaderTypeStandard;
}

- (BOOL)requiresVisibilityUpdate {
    switch (self.contentGroupKind) {
        case WMFContentGroupKindReadingList:
            return YES;
        default:
            return NO;
    }
}

/**
 *  String to display to the user for the receiver's date.
 *
 *  "Most read" articles are computed for UTC dates. UTC time zone is used because converting to the user's time zone
 *  might accidentally change the "day" the app displays based on the the offset between UTC & the device's default time
 *  zone.  For example: 02/12/2016 01:26 UTC converted to EST is 02/11/2016 20:26, one day off!
 *
 *  @return A string formatted with the current locale, in the UTC time zone.
 */
- (NSString *)localContentDateDisplayString {
    return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.contentMidnightUTCDate];
}

- (NSString *)localContentDateShortDisplayString {
    return [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.contentMidnightUTCDate];
}

- (NSString *)topReadMoreTitleForDate:(NSDate *)date {
    return
        [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"explore-most-read-more-list-title-for-date", nil, nil, @"Top on %1$@", @"Title with date for the view displaying longer list of top read articles. %1$@ will be substituted with the date"), [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date]];
}

@end

NS_ASSUME_NONNULL_END
