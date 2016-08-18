#import "WMFDailyStatsLoggingFunnel.h"
#import "Wikipedia-Swift.h"
#import "NSDate+Utilities.h"

static NSString *const kAppInstallAgeKey = @"appInstallAgeDays";
static NSString *const kAppInstallIdKey = @"appInstallID";

@implementation WMFDailyStatsLoggingFunnel

- (instancetype)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppDailyStats
    self = [super initWithSchema:@"MobileWikiAppDailyStats" version:12637385];
    if (self) {
        self.appInstallId = [self persistentUUID:@"WMFDailyStatsLoggingFunnel"];
    }
    return self;
}

- (BOOL)shouldLogInstallDays {
    NSDate *date = [[NSUserDefaults standardUserDefaults] wmf_dateLastDailyLoggingStatsSent];
    if (date == nil) {
        return YES;
    } else if ([[NSCalendar currentCalendar] isDateInToday:date]) {
        return NO;
    } else {
        return YES;
    }
}

- (void)logAppNumberOfDaysSinceInstall {
    if (![self shouldLogInstallDays]) {
        return;
    }

    NSDate *date = [[NSUserDefaults standardUserDefaults] wmf_appInstallDate];
    NSParameterAssert(date);
    if (!date) {
        return;
    }

    NSInteger days = [[NSDate date] distanceInDaysToDate:date];
    [self log:@{ kAppInstallAgeKey : @(days) }];
    [[NSUserDefaults standardUserDefaults] wmf_setDateLastDailyLoggingStatsSent:date];
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    if (!eventData) {
        return nil;
    }
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = self.appInstallId;
    return [dict copy];
}

@end
