#import <WMF/EventLoggingFunnel.h>
#import <WMF/EventLogger.h>
#import <WMF/SessionSingleton.h>
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
    NSString *wiki = [self.primaryLanguage stringByAppendingString:@"wiki"];
    [self log:eventData wiki:wiki];
}

- (void)log:(NSDictionary *)eventData language:(nullable NSString *)language {
    if (language) {
        NSString *wiki = [language stringByAppendingString:@"wiki"];
        [self log:eventData wiki:wiki];
    } else {
        [self log:eventData];
    }
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
            NSMutableDictionary *preprocessedEventData = [[self preprocessData:eventData] mutableCopy];
            (void)[[EventLogger alloc] initAndLogEvent:preprocessedEventData
                                             forSchema:self.schema
                                              revision:self.revision
                                                  wiki:wiki];
            [self logged:eventData];
        }
    }
}

- (NSString *)primaryLanguage {
    NSString *primaryLanguage = @"en";
    MWKLanguageLink *appLanguage = [MWKLanguageLinkController sharedInstance].appLanguage;
    if (appLanguage) {
        primaryLanguage = appLanguage.languageCode;
    }
    assert(primaryLanguage);
    return primaryLanguage;
}

- (NSString *)singleUseUUID {
    return [[NSUUID UUID] UUIDString];
}

- (void)logged:(NSDictionary *)eventData {
}

- (NSString *)appInstallID {
    return [[KeychainCredentialsManager shared] appInstallID];
}

- (NSString *)sessionID {
    return [[KeychainCredentialsManager shared] sessionID];
}

- (NSString *)timestamp {
    return [[NSDateFormatter wmf_rfc3339LocalTimeZoneFormatter] stringFromDate:[NSDate date]];
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
