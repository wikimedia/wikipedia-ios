
#import "WMFHomeSection.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "MWKHistoryEntry.h"
#import "MWKSavedPageEntry.h"
#import "NSDate+Utilities.h"

NS_ASSUME_NONNULL_BEGIN
@interface WMFHomeSection ()

@property (nonatomic, assign, readwrite) WMFHomeSectionType type;
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

- (NSComparisonResult)compare:(WMFHomeSection*)section {
    NSParameterAssert([section isKindOfClass:[WMFHomeSection class]]);
    switch (self.type) {
        case WMFHomeSectionTypeContinueReading: {
            return NSOrderedAscending;
        }
        break;

        case WMFHomeSectionTypeFeaturedArticle: {
            switch (section.type) {
                case WMFHomeSectionTypeContinueReading: {
                    return NSOrderedDescending;
                }
                break;
                case WMFHomeSectionTypeMainPage:
                case WMFHomeSectionTypeRandom:
                case WMFHomeSectionTypeNearby: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedAscending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                }
                break;
                default:
                    return -[self.dateCreated compare:section.dateCreated];
                    break;
            }
        }
        break;
        case WMFHomeSectionTypeMainPage: {
            switch (section.type) {
                case WMFHomeSectionTypeContinueReading: {
                    return NSOrderedDescending;
                }

                case WMFHomeSectionTypeFeaturedArticle: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedDescending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                }

                case WMFHomeSectionTypeRandom:
                case WMFHomeSectionTypeNearby: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedAscending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                    return NSOrderedAscending;
                }
                break;
                default:
                    return -[self.dateCreated compare:section.dateCreated];
                    break;
            }
        }
        break;

        case WMFHomeSectionTypeRandom: {
            switch (section.type) {
                case WMFHomeSectionTypeContinueReading: {
                    return NSOrderedDescending;
                }
                case WMFHomeSectionTypeFeaturedArticle:
                case WMFHomeSectionTypeMainPage: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedDescending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                }
                break;
                case WMFHomeSectionTypeNearby: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedAscending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                }
                break;
                default:
                    return -[self.dateCreated compare:section.dateCreated];
                    break;
            }
        }
        break;

        case WMFHomeSectionTypeNearby: {
            switch (section.type) {
                case WMFHomeSectionTypeContinueReading: {
                    return NSOrderedDescending;
                }
                case WMFHomeSectionTypeFeaturedArticle:
                case WMFHomeSectionTypeMainPage:
                case WMFHomeSectionTypeRandom: {
                    if (self.dateCreated.day == section.dateCreated.day) {
                        return NSOrderedDescending;
                    } else {
                        return -[self.dateCreated compare:section.dateCreated];
                    }
                }
                break;
                default:
                    return -[self.dateCreated compare:section.dateCreated];
                    break;
            }
        }
        break;

        default: {
            switch (section.type) {
                case WMFHomeSectionTypeContinueReading:
                    return NSOrderedDescending;
                default:
                    return -[self.dateCreated compare:section.dateCreated];
                    break;
            }
            break;

            return -[self.dateCreated compare:section.dateCreated];
        }
        break;
    }
}

+ (instancetype)pictureOfTheDaySection {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypePictureOfTheDay;
    return item;
}

+ (instancetype)continueReadingSectionWithTitle:(MWKTitle*)title {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type  = WMFHomeSectionTypeContinueReading;
    item.title = title;
    return item;
}

+ (instancetype)featuredSection {
    WMFHomeSection* item = [[WMFHomeSection alloc] init];
    item.type = WMFHomeSectionTypeFeaturedArticle;
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