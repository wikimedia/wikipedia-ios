#import "EventLoggingFunnel.h"
#import "EventLogger.h"
#import "SessionSingleton.h"
#import <WMF/WMF-Swift.h>

@implementation EventLoggingFunnel

- (id)initWithSchema:(NSString *)schema version:(int)revision {
    if (self) {
        self.schema = schema;
        self.revision = revision;
        self.rate = 1;
    }
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    return eventData;
}

- (void)log:(NSDictionary *)eventData {
    SessionSingleton *session = [SessionSingleton sharedInstance];
    NSString *wiki = [session.currentArticleSiteURL.wmf_language stringByAppendingString:@"wiki"];
    [self log:eventData wiki:wiki];
}

- (void)log:(NSDictionary *)eventData wiki:(NSString *)wiki {
    if ([SessionSingleton sharedInstance].shouldSendUsageReports) {
        BOOL chosen = NO;
        if (self.rate == 1) {
            chosen = YES;
        } else if (self.rate != 0) {
            chosen = (self.getEventLogSamplingID % self.rate) == 0;
        }
        if (chosen) {
            (void)[[EventLogger alloc] initAndLogEvent:[self preprocessData:eventData]
                                             forSchema:self.schema
                                              revision:self.revision
                                                  wiki:wiki];
        }
    }
}

- (NSString *)singleUseUUID {
    return [[NSUUID UUID] UUIDString];
}

- (NSString *)persistentUUID:(NSString *)key {
    NSString *prefKey = [@"EventLoggingID-" stringByAppendingString:key];
    NSString *uuid = [[NSUserDefaults wmf_userDefaults] objectForKey:prefKey];
    if (!uuid) {
        uuid = [self singleUseUUID];
        [[NSUserDefaults wmf_userDefaults] setObject:uuid forKey:prefKey];
        [[NSUserDefaults wmf_userDefaults] synchronize];
    }
    return uuid;
}

/**
 *  Persistent random integer id used for sampling.
 *
 *  @return integer sampling id
 */
- (NSInteger)getEventLogSamplingID {
    NSNumber *samplingId = [[NSUserDefaults wmf_userDefaults] objectForKey:@"EventLogSamplingID"];
    if (!samplingId) {
        NSInteger intId = arc4random_uniform(UINT32_MAX);
        [[NSUserDefaults wmf_userDefaults] setInteger:intId forKey:@"EventLogSamplingID"];
        return intId;
    } else {
        return samplingId.integerValue;
    }
}

@end
