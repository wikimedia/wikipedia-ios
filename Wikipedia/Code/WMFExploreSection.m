
#import "WMFExploreSection.h"
#import "MWKHistoryEntry.h"
#import "NSDate+Utilities.h"
#import "WMFLocationManager.h"
#import "CLLocation+WMFComparison.h"
#import "MWKTitle.h"
#import "MWKSite.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFExploreSection ()

@property (nonatomic, assign, readwrite) WMFExploreSectionType type;
@property (nonatomic, strong, readwrite) NSURL* siteURL;
@property (nonatomic, strong, readwrite) NSURL* articleURL;
@property (nonatomic, strong, readwrite) NSDate* dateCreated;
@property (nonatomic, strong, readwrite) CLLocation* location;
@property (nonatomic, strong, readwrite) CLPlacemark* placemark;
@property (nonatomic, strong, readwrite) NSDate* mostReadFetchDate;

@end

@implementation WMFExploreSection

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
        //Unarchive site and title
        MWKSite* site      = [self decodeValueForKey:@"site" withCoder:coder modelVersion:0];
        if(site && self.siteURL == nil){
            self.siteURL = site.URL;
        }
        MWKTitle* title      = [self decodeValueForKey:@"title" withCoder:coder modelVersion:0];
        if(title && !self.articleURL){
            self.articleURL = title.desktopURL;
        }
        
        if([self.articleURL wmf_isMobile]){
            self.articleURL = [NSURL wmf_desktopURLForURL:self.articleURL];
        }
        
        //site was added after persistence. We need to provide a default value.
        switch (self.type) {
            case WMFExploreSectionTypeFeaturedArticle: {
                if (self.siteURL == nil) {
                    self.siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:@"en"];
                }
                break;
            }

            case WMFExploreSectionTypeMostRead: {
                if (!self.mostReadFetchDate) {
                    // fall back for legacy beta "most read" sections
                    self.mostReadFetchDate = self.dateCreated;
                }
                break;
            }
            default:
                break;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[WMFExploreSection class]]) {
        return [self isEqualToSection:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToSection:(WMFExploreSection*)rhs {
    return self.type == rhs.type
           && WMF_RHS_PROP_EQUAL(dateCreated, isEqualToDate:)
           && WMF_RHS_PROP_EQUAL(siteURL, isEqual:)
           && WMF_RHS_PROP_EQUAL(articleURL, isEqual:)
           && WMF_RHS_PROP_EQUAL(mostReadFetchDate, isEqualToDate:)
           && WMF_RHS_PROP_EQUAL(location, wmf_isEqual:)
           && WMF_RHS_PROP_EQUAL(placemark, wmf_isEqual:);
}

/**
 *  Provides the index of the receiver's item, specifying its ordering with other item types within its @c dateCreated.
 *  Ordering differs on iPad
 *
 *  @return A positive integer which, when compared with other items' indices, will yield the comparison result describing
 *          their ordering.
 */
- (NSInteger)dailyOrderingIndex {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        switch (self.type) {
            case WMFExploreSectionTypeMainPage:
                return 0;
            case WMFExploreSectionTypeContinueReading:
                return 1;
            case WMFExploreSectionTypeFeaturedArticle:
                return 2;
            case WMFExploreSectionTypeMostRead:
                return 3;
            case WMFExploreSectionTypePictureOfTheDay:
                return 4;
            case WMFExploreSectionTypeRandom:
                return 5;
            case WMFExploreSectionTypeNearby:
                return 6;
            case WMFExploreSectionTypeSaved:
            case WMFExploreSectionTypeHistory:
                // Saved & History have identical same-day sorting behavior
                return 7;
        }
    }else{
        switch (self.type) {
            case WMFExploreSectionTypeContinueReading:
                return 0;
            case WMFExploreSectionTypeFeaturedArticle:
                return 1;
            case WMFExploreSectionTypeMostRead:
                return 2;
            case WMFExploreSectionTypePictureOfTheDay:
                return 3;
            case WMFExploreSectionTypeMainPage:
                return 4;
            case WMFExploreSectionTypeRandom:
                return 5;
            case WMFExploreSectionTypeNearby:
                return 6;
            case WMFExploreSectionTypeSaved:
            case WMFExploreSectionTypeHistory:
                // Saved & History have identical same-day sorting behavior
                return 7;
        }
    }
}

- (NSComparisonResult)compare:(WMFExploreSection*)section {
    NSParameterAssert([section isKindOfClass:[WMFExploreSection class]]);
    if (self.type == WMFExploreSectionTypeContinueReading) {
        // continue reading always goes above everything else, regardless of date
        return NSOrderedAscending;
    } else if (section.type == WMFExploreSectionTypeContinueReading) {
        // corollary of above, everything else always goes below continue reading, regardless of date
        return NSOrderedDescending;
    } else if (self.type != WMFExploreSectionTypeSaved
               && section.type != WMFExploreSectionTypeSaved
               && self.type != WMFExploreSectionTypeHistory
               && section.type != WMFExploreSectionTypeHistory
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

+ (instancetype)mostReadSectionForDate:(NSDate*)date siteURL:(NSURL*)url {
    WMFExploreSection* trending = [[WMFExploreSection alloc] init];
    trending.type              = WMFExploreSectionTypeMostRead;
    trending.mostReadFetchDate = date;
    trending.siteURL         = [url wmf_siteURL];
    return trending;
}

+ (instancetype)pictureOfTheDaySectionWithDate:(NSDate*)date {
    NSParameterAssert(date);
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type        = WMFExploreSectionTypePictureOfTheDay;
    item.dateCreated = date;
    return item;
}

+ (instancetype)continueReadingSectionWithArticleURL:(NSURL*)url {
    NSParameterAssert(url.wmf_title);
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type       = WMFExploreSectionTypeContinueReading;
    item.articleURL = url;
    return item;
}

+ (nullable instancetype)featuredArticleSectionWithSiteURLIfSupported:(NSURL*)url {
    NSParameterAssert(url);
    if (![url.wmf_language isEqualToString:@"en"] || ![url.wmf_domain isEqualToString:@"wikipedia.org"]) {
        /*
           HAX: "Today's Featured Article" template is only available on en.wikipedia.org.
         */
        return nil;
    }
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type      = WMFExploreSectionTypeFeaturedArticle;
    item.siteURL = [url wmf_siteURL];
    return item;
}

+ (instancetype)mainPageSectionWithSiteURL:(NSURL*)url {
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type      = WMFExploreSectionTypeMainPage;
    item.siteURL = [url wmf_siteURL];
    return item;
}

+ (instancetype)nearbySectionWithLocation:(CLLocation*)location placemark:(nullable CLPlacemark*)placemark siteURL:(NSURL*)url {
    NSParameterAssert(location);
    NSParameterAssert(url);
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type      = WMFExploreSectionTypeNearby;
    item.location  = location;
    item.placemark = placemark;
    item.siteURL = [url wmf_siteURL];
    return item;
}

+ (instancetype)randomSectionWithSiteURL:(NSURL*)url {
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type      = WMFExploreSectionTypeRandom;
    item.siteURL = [url wmf_siteURL];
    return item;
}

+ (instancetype)historySectionWithHistoryEntry:(MWKHistoryEntry*)entry {
    NSParameterAssert(entry.url.wmf_title);
    NSParameterAssert(entry.dateViewed);
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type        = WMFExploreSectionTypeHistory;
    item.articleURL  = entry.url;
    item.dateCreated = entry.dateViewed;
    return item;
}

+ (instancetype)savedSectionWithSavedPageEntry:(MWKHistoryEntry*)entry {
    NSParameterAssert(entry.url.wmf_title);
    NSParameterAssert(entry.dateSaved);
    WMFExploreSection* item = [[WMFExploreSection alloc] init];
    item.type        = WMFExploreSectionTypeSaved;
    item.articleURL  = entry.url;
    item.dateCreated = entry.dateSaved;
    return item;
}

+ (NSUInteger)maxNumberOfSectionsForType:(WMFExploreSectionType)type {
    switch (type) {
        case WMFExploreSectionTypeHistory:
        case WMFExploreSectionTypeSaved:
        case WMFExploreSectionTypeFeaturedArticle:
        case WMFExploreSectionTypeMostRead:
        case WMFExploreSectionTypeNearby:
        case WMFExploreSectionTypePictureOfTheDay:
        case WMFExploreSectionTypeRandom:
            return 10;
            break;
        case WMFExploreSectionTypeContinueReading:
        case WMFExploreSectionTypeMainPage:
            return 1;
            break;
    }
}

+ (NSUInteger)totalMaxNumberOfSections {
    return [self maxNumberOfSectionsForType:WMFExploreSectionTypeHistory] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeSaved] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeFeaturedArticle] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypePictureOfTheDay] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeMostRead] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeNearby] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeContinueReading] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeRandom] +
           [self maxNumberOfSectionsForType:WMFExploreSectionTypeMainPage];
}

@end

NS_ASSUME_NONNULL_END
