#import "WMFAnnouncement.h"
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/NSString+WMFHTMLParsing.h>

@implementation WMFAnnouncement

@synthesize actionURL = _actionURL;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, identifier): @"id",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, type): @"type",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, startTime): @"start_time",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, endTime): @"end_time",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, platforms): @"platforms",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, countries): @"countries",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, placement): @"placement",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, text): @"text",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, actionTitle): @"action.title",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, actionURLString): @"action.url",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, captionHTML): @"caption_HTML",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, imageURL): @[@"image", @"image_url"],
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, imageHeight): @"image_height",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, negativeText): @"negative_text",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, loggedIn): @"logged_in",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, readingListSyncEnabled): @"reading_list_sync_enabled",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, beta): @"beta",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, domain): @"domain",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, articleTitles): @"articleTitles",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, displayDelay): @"displayDelay",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, percentReceivingExperiment): @"percent_receiving_experiment"
    };
}

+ (NSInteger)version {
    return 4;
}

- (NSURL *)actionURL {
    if (!_actionURL) {
        _actionURL = [NSURL wmf_optionalURLWithString: self.actionURLString];
    }
    
    return _actionURL;
}

+ (NSValueTransformer *)imageURLJSONTransformer {
    return [MTLValueTransformer
            transformerUsingForwardBlock:^NSURL *(NSDictionary *value,
                                                  BOOL *success,
                                                  NSError *__autoreleasing *error) {
            NSString *urlString = value[@"image"] ?: value[@"image_url"];
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSDictionary *(NSURL *URL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            NSString *urlString = [URL absoluteString];
            if (!urlString) {
                return @{};
            }
            return @{@"image_url": urlString};
        }];
}

+ (NSValueTransformer *)startTimeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        NSDate *date = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:value];
        return date;
    }];
}

+ (NSValueTransformer *)endTimeJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        NSDate *date = [[NSDateFormatter wmf_iso8601Formatter] dateFromString:value];
        return date;
    }];
}

// No languageVariantCodePropagationSubelementKeys

+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys {
    return @[@"imageURL",
             @"actionURL"];
}

@end
