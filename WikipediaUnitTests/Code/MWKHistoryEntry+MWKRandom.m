
#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKSite+Random.h"

@implementation MWKHistoryEntry (MWKRandom)

+ (instancetype)random {
    return [[self alloc] initWithURL:[NSURL wmf_randomArticleURL]];
}

+ (instancetype)randomSaveableEntry {
    MWKHistoryEntry* entry = [self random];
    // HAX: history entries need significantly different dates for the order to persist properly
    float timeInterval = roundf((float)1e6 * ((float)arc4random() / (float)UINT32_MAX));
    // HAX: round-trip the date through formatting to prevent data loss (bug) and allow equality checks to pass
    entry.date = [entry getDateFromIso8601DateString:
                  [entry iso8601DateString:
                   [NSDate dateWithTimeIntervalSinceNow:timeInterval]]];
    return entry;
}

@end
