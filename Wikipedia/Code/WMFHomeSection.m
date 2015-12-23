
#import "WMFHomeSection.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFHomeSection ()

@property (nonatomic, assign, readwrite) WMFHomeSectionType type;
@property (nonatomic, strong, readwrite) MWKSite* site;
@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) NSDate* dateCreated;
@property (nonatomic, strong, readwrite) CLLocation* location;

@end

@implementation WMFHomeSection

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dateCreated = [NSDate date];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        //site was added after persistence. We need to provide a default value.
        if (self.type == WMFHomeSectionTypeFeaturedArticle && self.site == nil) {
            self.site = [MWKSite siteWithLanguage:@"en"];
        }
    }
    return self;
}

/**
 *  Provides the index of the receiver's item, specifying its ordering with other item types within its @c dateCreated.
 *
 *  @return A positive integer which, when compared with other items' indices, will yield the comparison result describing
 *          their ordering.
 */
- (NSInteger)dailyOrderingIndex {
    switch (self.type) {
        case WMFHomeSectionTypeContinueReading:
            return 0;
        case WMFHomeSectionTypeFeaturedArticle:
            return 1;
        case WMFHomeSectionTypeMainPage:
            return 2;
        case WMFHomeSectionTypePictureOfTheDay:
            return 3;
        case WMFHomeSectionTypeRandom:
            return 4;
        case WMFHomeSectionTypeNearby:
            return 5;

        case WMFHomeSectionTypeSaved:
        case WMFHomeSectionTypeHistory:
            // Saved & History have identical same-day sorting behavior
            return 6;
    }
}

- (NSComparisonResult)compare:(WMFHomeSection*)section {
    NSParameterAssert([section isKindOfClass:[WMFHomeSection class]]);
    if (self.type == WMFHomeSectionTypeContinueReading) {
        // continue reading always goes above everything else, regardless of date
        return NSOrderedAscending;
    } else if (section.type == WMFHomeSectionTypeContinueReading) {
        // corollary of above, everything else always goes below continue reading, regardless of date
        return NSOrderedDescending;
    } else if (self.type != WMFHomeSectionTypeSaved
               && section.type != WMFHomeSectionTypeSaved
               && self.type != WMFHomeSectionTypeHistory
               && section.type != WMFHomeSectionTypeHistory
               && [self.dateCreated isEqualToDateIgnoringTime:section.dateCreated]) {
        // explicit ordering for non-history/-saved items created w/in the same day
        NSInteger selfOrderingIndex  = [self dailyOrderingIndex];
        NSInteger otherOrderingIndex = [section dailyOrderingIndex];
        if (selfOrderingIndex > otherOrderingIndex) {
            return NSOrderedDescending;
        } else if (selfOrderingIndex < otherOrderingIndex) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    } else {
        // sort all items from different days and/or history/saved items by date, descending
        return -[self.dateCreated compare:section.dateCreated];
    }
}

#pragma mark - Factory Methods

+ (instancetype)pictureOfTheDaySection {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypePictureOfTheDay;
    return item;
}

+ (instancetype)continueReadingSectionWithTitle:(MWKTitle*)title {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypeContinueReading;
    item.title = title;
    return item;
}

+ (nullable instancetype)featuredArticleSectionWithSiteIfSupported:(MWKSite *)site {
    NSParameterAssert(site);
    if(![site.language isEqualToString:@"en"] || ![site.domain isEqualToString:@"wikipedia.org"]) {
        /*
         HAX: "Today's Featured Article" template is only available on en.wikipedia.org.
         */
        return nil;
    }
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeFeaturedArticle;
    item.site = site;
    return item;
}

+ (instancetype)mainPageSection {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeMainPage;
    return item;
}

+ (instancetype)nearbySectionWithLocation:(nullable CLLocation*)location {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type     = WMFHomeSectionTypeNearby;
    item.location = location;
    return item;
}

+ (instancetype)randomSection {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeRandom;
    return item;
}

+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry {
    NSParameterAssert(entry.title);
    NSParameterAssert(entry.date);
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type        = WMFHomeSectionTypeHistory;
    item.title       = entry.title;
    item.dateCreated = entry.date;
    return item;
}

+ (instancetype)savedSectionWithSavedPageEntry:(MWKSavedPageEntry*)entry {
    NSParameterAssert(entry.title);
    NSParameterAssert(entry.date);
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type        = WMFHomeSectionTypeSaved;
    item.title       = entry.title;
    item.dateCreated = entry.date;
    return item;
}

@end

NS_ASSUME_NONNULL_END
