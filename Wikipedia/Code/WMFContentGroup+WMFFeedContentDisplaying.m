#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFContentGroup (WMFContentManaging)

- (WMFFeedHeaderType)headerType{
    return WMFFeedHeaderTypeStandard;
}

- (nullable UIImage *)headerIcon {
    return nil;
}

- (nullable UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (nullable UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (nullable NSString *)headerTitle {
    return [[NSString alloc] init];
}

- (nullable NSString *)headerSubTitle {
    return [[NSString alloc] init];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor blackColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor grayColor];
}

- (nullable NSURL *)headerContentURL {
    return nil;
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenFirstItem;
}

- (WMFFeedBlacklistOption)blackListOptions {
    return WMFFeedBlacklistOptionNone;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePage;
}

- (NSUInteger)maxNumberOfCells {
    return 1;
}

- (BOOL)prefersWiderColumn {
    return NO;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypePage;
}

- (nullable NSString *)footerText {
    return nil;
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypeNone;
}

- (nullable NSString *)moreTitle {
    return nil;
}

- (NSString *)analyticsContentType {
    return @"Unknown Content Type";
}

@end

@implementation WMFContinueReadingContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-continue-reading-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return [[self.date wmf_relativeTimestamp] wmf_stringByCapitalizingFirstCharacter];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (NSString *)analyticsContentType {
    return @"Continue Reading";
}

@end

@implementation WMFMainPageContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"news-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-main-page-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:[NSDate date]];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (NSString *)analyticsContentType {
    return @"Main Page";
}

@end

@implementation WMFRelatedPagesContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"recent-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-continue-related-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return self.articleURL.wmf_title;
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_blueTintColor];
}

- (nullable NSURL *)headerContentURL {
    return self.articleURL;
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenHeaderContent;
}

- (WMFFeedBlacklistOption)blackListOptions {
    return WMFFeedBlacklistOptionContent;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

- (BOOL)prefersWiderColumn {
    return YES /*FBTweakValue(@"Explore", @"General", @"Put 'Because You Read' in Wider Column", YES)*/;
}

- (NSUInteger)maxNumberOfCells {
    return 3;
}

- (nullable NSString *)footerText {
    return
        [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                    withString:self.articleURL.wmf_title];
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageList;
}

- (nullable NSString *)moreTitle {
    return [MWLocalizedString(@"home-more-like-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.articleURL.wmf_title];
}

- (NSString *)analyticsContentType {
    return @"Recommended";
}

@end

@implementation WMFLocationContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"nearby-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-nearby-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    if ([self.date isToday]) {
        return MWLocalizedString(@"explore-nearby-sub-heading-your-location", nil);
    } else if (self.placemark) {
        return [NSString stringWithFormat:@"%@, %@", self.placemark.name, self.placemark.locality];
    } else {
        return [NSString stringWithFormat:@"%f, %f", self.location.coordinate.latitude, self.location.coordinate.longitude];
    }
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenMore;
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithLocation;
}

- (NSUInteger)maxNumberOfCells {
    return 3;
}

- (nullable NSString *)footerText {
    if ([self.date isToday]) {
        return MWLocalizedString(@"home-nearby-footer", nil);
    } else {
        return [MWLocalizedString(@"home-nearby-location-footer", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.placemark.name];
    }
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageListWithLocation;
}

- (nullable NSString *)moreTitle {
    return MWLocalizedString(@"main-menu-nearby", nil);
}

- (NSString *)analyticsContentType {
    return @"Nearby";
}

@end

@implementation WMFPictureOfTheDayContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"potd-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-potd-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePhoto;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypeGallery;
}

- (NSString *)analyticsContentType {
    return @"Picture of the Day";
}


@end

@implementation WMFRandomContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"random-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-random-article-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return MWSiteLocalizedString(self.siteURL, @"onboarding-wikipedia", nil);
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

- (nullable NSString *)footerText {
    return MWLocalizedString(@"explore-another-random", nil);
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypePageWithRandomButton;
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageWithRandomButton;
}

- (NSString *)analyticsContentType {
    return @"Random";
}

@end

@implementation WMFFeaturedArticleContentGroup (WMFContentManaging)
- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"featured-mini"];
}

- (nullable UIColor *)headerIconTintColor {
    return [UIColor wmf_colorWithHex:0xE6B84F alpha:1.0];
}

- (nullable UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_colorWithHex:0xFCF5E4 alpha:1.0];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"explore-featured-article-heading", nil);
}

- (nullable NSString *)headerSubTitle {
    return [[NSDateFormatter wmf_dayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderSubTitleColor];
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypePageWithPreview;
}

@end

@implementation WMFTopReadContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"trending-mini"];
}

- (nullable NSString *)headerTitle {
    // fall back to language code if it can't be localized
    NSString *language = [[NSLocale currentLocale] wmf_localizedLanguageNameForCode:self.siteURL.wmf_language];

    NSString *heading = nil;

    //crash protection if language is nil
    if (language) {
        heading =
            [MWLocalizedString(@"explore-most-read-heading", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                            withString:language];
    } else {
        heading = MWLocalizedString(@"explore-most-read-generic-heading", nil);
    }

    return heading;
}

- (nullable NSString *)headerSubTitle {
    NSString* dateString = [self localDateDisplayString];
    if(!dateString){
        dateString = @"";
    }

    return dateString;
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerIconTintColor {
    return [UIColor wmf_blueTintColor];
}

- (nullable UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_lightBlueTintColor];
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenMore;
}

- (NSUInteger)maxNumberOfCells {
    return 5;
}

- (nullable NSString *)footerText {
    NSString* dateString = [self localDateShortDisplayString];
    if(!dateString){
        dateString = @"";
    }
    
    return
        [MWLocalizedString(@"explore-most-read-footer-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                withString:dateString];
}

- (WMFFeedMoreType)moreType {
    return WMFFeedMoreTypePageList;
}

- (nullable NSString *)moreTitle {
    return [self titleForDate:self.mostReadDate];
}

- (NSString *)analyticsContentType {
    return @"Most Read";
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
- (NSString *)localDateDisplayString {
    return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.mostReadDate];
}

- (NSString *)localDateShortDisplayString {
    return [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.mostReadDate];
}

- (NSString *)titleForDate:(NSDate *)date {
    return
        [MWLocalizedString(@"explore-most-read-more-list-title-for-date", nil) stringByReplacingOccurrencesOfString:@"$1"
                                                                                                         withString:
                                                                                                             [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:date]];
}

@end


@implementation WMFNewsContentGroup (WMFContentManaging)

- (nullable UIImage *)headerIcon {
    return [UIImage imageNamed:@"news-mini"];
}

- (nullable NSString *)headerTitle {
    return MWLocalizedString(@"in-the-news-title", nil);
}

- (nullable NSString *)headerSubTitle {
    return [self localDateDisplayString];
}

- (nullable UIColor *)headerTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerSubTitleColor {
    return [UIColor wmf_exploreSectionHeaderTitleColor];
}

- (nullable UIColor *)headerIconTintColor {
    return [UIColor wmf_exploreSectionHeaderIconTintColor];
}

- (nullable UIColor *)headerIconBackgroundColor {
    return [UIColor wmf_exploreSectionHeaderIconBackgroundColor];
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenFirstItem;
}

- (NSUInteger)maxNumberOfCells {
    return 5;
}

- (NSString *)analyticsContentType {
    return @"In The News";
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypeStory;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypeStory;
}

- (NSString *)localDateDisplayString {
    return [[NSDateFormatter wmf_utcDayNameMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
}

- (NSString *)localDateShortDisplayString {
    return [[NSDateFormatter wmf_utcShortDayNameShortMonthNameDayOfMonthNumberDateFormatter] stringFromDate:self.date];
}

@end

@implementation WMFAnnouncementContentGroup (WMFContentManaging)

- (WMFFeedHeaderType)headerType{
    return WMFFeedHeaderTypeNone;
}

- (nullable UIColor *)headerIconTintColor {
    return nil;
}

- (nullable UIColor *)headerIconBackgroundColor {
    return nil;
}

- (WMFFeedHeaderActionType)headerActionType {
    return WMFFeedHeaderActionTypeOpenHeaderNone;
}

- (NSUInteger)maxNumberOfCells {
    return NSUIntegerMax;
}

- (NSString *)analyticsContentType {
    return @"Announcements";
}

- (WMFFeedDisplayType)displayType {
    return WMFFeedDisplayTypeAnnouncement;
}

- (WMFFeedDetailType)detailType {
    return WMFFeedDetailTypeNone;
}

- (BOOL)prefersWiderColumn{
    return YES;
}


@end

NS_ASSUME_NONNULL_END
