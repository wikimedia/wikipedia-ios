#import "MWKHistoryEntry+MWKRandom.h"
#import "MWKSite+Random.h"

@implementation MWKHistoryEntry (MWKRandom)

+ (instancetype)random {
    MWKHistoryEntry *entry = [[self alloc] initWithURL:[NSURL wmf_randomArticleURL]];
    // HAX: history entries need significantly different dates for the order to persist properly
    float timeInterval = roundf((float)1e6 * ((float)arc4random() / (float)UINT32_MAX));
    entry.dateViewed = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
    timeInterval = roundf((float)1e6 * ((float)arc4random() / (float)UINT32_MAX));
    entry.dateSaved = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
    return entry;
}
@end
