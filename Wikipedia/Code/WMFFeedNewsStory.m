#import "WMFFeedNewsStory.h"
#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedNewsStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, midnightUTCMonthAndDay): @"story",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, storyHTML): @"story",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, articlePreviews): @"links",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, featuredArticlePreview): @"featuredArticlePreview" };
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

+ (NSRegularExpression *)dateRegularExpression {
    static dispatch_once_t onceToken;
    static NSRegularExpression *dateRegex;
    dispatch_once(&onceToken, ^{
        dateRegex = [NSRegularExpression regularExpressionWithPattern:@"^(?:<!--)(:?[^-]+)(?:-->)" options:0 error:nil];
    });
    return dateRegex;
}

+ (NSDateFormatter *)dateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *dateFormatter;
    dispatch_once(&onceToken, ^{
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = locale;
        dateFormatter.dateFormat = @"MMM dd";
        dateFormatter.calendar = [NSCalendar wmf_utcGregorianCalendar];
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return dateFormatter;
}


+ (NSValueTransformer *)midnightUTCMonthAndDayJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSString *value,
                                                                 BOOL *success,
                                                                 NSError *__autoreleasing *error) {
        NSRegularExpression *regex = [WMFFeedNewsStory dateRegularExpression];
        NSTextCheckingResult *result = [[regex matchesInString:value options:0 range:NSMakeRange(0, value.length)] firstObject];
        if (result == nil) {
            return nil;
        }
        NSString *dateString = [regex replacementStringForResult:result inString:value offset:0 template:@"$1"];
        if (dateString == nil) {
            return nil;
        }
        NSDate *date = [[WMFFeedNewsStory dateFormatter] dateFromString:dateString];
        return date;
    }];
}

+ (NSUInteger)modelVersion {
    return 5;
}

@end

NS_ASSUME_NONNULL_END
