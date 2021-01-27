#import <WMF/EventLoggingFunnel.h>
#import <WMF/WMF-Swift.h>

EventLoggingCategory const EventLoggingCategoryFeed = @"feed";
EventLoggingCategory const EventLoggingCategoryFeedDetail = @"feed_detail";
EventLoggingCategory const EventLoggingCategoryHistory = @"history";
EventLoggingCategory const EventLoggingCategoryPlaces = @"places";
EventLoggingCategory const EventLoggingCategoryArticle = @"article";
EventLoggingCategory const EventLoggingCategorySearch = @"search";
EventLoggingCategory const EventLoggingCategoryAddToList = @"add_to_list";
EventLoggingCategory const EventLoggingCategorySaved = @"saved";
EventLoggingCategory const EventLoggingCategoryLogin = @"login";
EventLoggingCategory const EventLoggingCategorySetting = @"setting";
EventLoggingCategory const EventLoggingCategoryLoginToSyncPopover = @"login_to_sync_popover";
EventLoggingCategory const EventLoggingCategoryEnableSyncPopover = @"enable_sync_popover";
EventLoggingCategory const EventLoggingCategoryUnknown = @"unknown";

EventLoggingLabel const EventLoggingLabelAnnouncement = @"announcement";
EventLoggingLabel const EventLoggingLabelArticleAnnouncement = @"article_announcement";
EventLoggingLabel const EventLoggingLabelFeaturedArticle = @"featured_article";
EventLoggingLabel const EventLoggingLabelTopRead = @"top_read";
EventLoggingLabel const EventLoggingLabelReadMore = @"read_more";
EventLoggingLabel const EventLoggingLabelRandom = @"random";
EventLoggingLabel const EventLoggingLabelNews = @"news";
EventLoggingLabel const EventLoggingLabelOnThisDay = @"on_this_day";
EventLoggingLabel const EventLoggingLabelRelatedPages = @"related_pages";
EventLoggingLabel const EventLoggingLabelArticleList = @"article_list";
EventLoggingLabel const EventLoggingLabelOutLink = @"out_link";
EventLoggingLabel const EventLoggingLabelSimilarPage = @"similar_page";
EventLoggingLabel const EventLoggingLabelItems = @"items";
EventLoggingLabel const EventLoggingLabelLists = @"lists";
EventLoggingLabel const EventLoggingLabelDefault = @"default";
EventLoggingLabel const EventLoggingLabelSyncEducation = @"sync_education";
EventLoggingLabel const EventLoggingLabelLogin = @"login";
EventLoggingLabel const EventLoggingLabelSyncArticle = @"sync_article";
EventLoggingLabel const EventLoggingLabelLocation = @"location";
EventLoggingLabel const EventLoggingLabelMainPage = @"main_page";
EventLoggingLabel const EventLoggingLabelContinueReading = @"continue_reading";
EventLoggingLabel const EventLoggingLabelPictureOfTheDay = @"picture_of_the_day";

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
    WMFEventLoggingService *service = [WMFEventLoggingService sharedInstance];
    if (NSUserDefaults.standardUserDefaults.wmf_sendUsageReports) {
        BOOL chosen = NO;
        if (self.rate == 1) {
            chosen = YES;
        } else if (self.rate != 0) {
            chosen = (self.getEventLogSamplingID % self.rate) == 0;
        }
        if (chosen) {
            NSMutableDictionary *preprocessedEventData = [[self preprocessData:eventData] mutableCopy];
            [service logWithEvent:preprocessedEventData schema:self.schema revision:self.revision wiki:wiki];
            [self logged:eventData];
        }
    }
}

- (NSString *)primaryLanguage {
    NSString *primaryLanguage = @"en";
    MWKLanguageLink *appLanguage = [MWKDataStore shared].languageLinkController.appLanguage;
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
    return NSUserDefaults.standardUserDefaults.wmf_appInstallId;
}

- (NSString *)sessionID {
    return [[WMFEventLoggingService sharedInstance] sessionID];
}

- (NSString *)timestamp {
    return [[NSDateFormatter wmf_rfc3339LocalTimeZoneFormatter] stringFromDate:[NSDate date]];
}

- (NSNumber *)isAnon {
    // SINGLETONTODO
    BOOL isAnon = !MWKDataStore.shared.authenticationManager.isLoggedIn;
    return [NSNumber numberWithBool:isAnon];
}

/**
 *  Persistent random integer id used for sampling.
 *
 *  @return integer sampling id
 */
- (NSInteger)getEventLogSamplingID {
    NSNumber *samplingId = [[NSUserDefaults standardUserDefaults] objectForKey:@"EventLogSamplingID"];
    if (!samplingId) {
        NSInteger intId = arc4random_uniform(UINT32_MAX);
        [[NSUserDefaults standardUserDefaults] setInteger:intId forKey:@"EventLogSamplingID"];
        return intId;
    } else {
        return samplingId.integerValue;
    }
}

@end
