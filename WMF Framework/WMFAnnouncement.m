#import "WMFAnnouncement.h"
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>
#import <WMF/NSString+WMFHTMLParsing.h>

@implementation WMFAnnouncement

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, identifier): @"id",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, type): @"type",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, startTime): @"start_time",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, endTime): @"end_time",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, platforms): @"platforms",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, countries): @"countries",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, text): @"text",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, actionTitle): @"action.title",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, actionURL): @"action.url",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, captionHTML): @"caption_HTML",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, caption): @"caption_HTML",
        WMF_SAFE_KEYPATH(WMFAnnouncement.new, imageURL): @"image_url",
    };
}

+ (NSValueTransformer *)actionURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *URL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [URL absoluteString];
        }];
}

+ (NSValueTransformer *)imageURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *URL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [URL absoluteString];
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

+ (NSValueTransformer *)captionJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value, BOOL *success, NSError *__autoreleasing *error) {
        //HACK: Fix padding around the caption
        if (value) {
            value = [@[value, @"\n"] componentsJoinedByString:@""];
        }

        return [value wmf_attributedStringWithLinksFromHTMLTags];
    }];
}

@end
