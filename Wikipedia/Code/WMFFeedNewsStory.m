#import <WMF/WMFFeedNewsStory.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/WMF-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedNewsStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, midnightUTCMonthAndDay): @"story",
             WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, storyHTML): @"story",
             WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, articlePreviews): @"links",
             WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, featuredArticlePreview): @"featuredArticlePreview"};
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

+ (nullable NSString *)semanticFeaturedArticleTitleFromStoryHTML:(NSString *)storyHTML siteURL:(NSURL *)siteURL {
    NSString *pictured = [WMFFeedNewsStory localizedPicturedTextForWikiLanguage: siteURL.wmf_languageCode];
    NSRange range = [storyHTML rangeOfString:pictured options:NSCaseInsensitiveSearch];
    if (range.length == 0) {
        return nil;
    }

    NSString *openLink = @"<a";
    NSRange openLinkRange = [storyHTML rangeOfString:openLink options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
    if (openLinkRange.length == 0) {
        return nil;
    }

    NSString *closeLink = @">";

    NSRange closeLinkRange = [storyHTML rangeOfString:closeLink options:0 range:NSMakeRange(openLinkRange.location, storyHTML.length - openLinkRange.location)];
    if (closeLinkRange.length == 0) {
        return nil;
    }

    NSInteger linkTagContentsStart = openLinkRange.location + openLinkRange.length;
    NSInteger linkTagContentsEnd = closeLinkRange.location;
    NSInteger linkTagContentsLength = linkTagContentsEnd - linkTagContentsStart;
    NSRange linkTagContentsRange = NSMakeRange(linkTagContentsStart, linkTagContentsLength);

    static NSRegularExpression *hrefRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *hrefPattern = @"(href)=[\"']?((?:.(?![\"']?\\s+(?:\\S+)=|[>\"']))+.)[\"']?";
        hrefRegex = [NSRegularExpression regularExpressionWithPattern:hrefPattern options:NSRegularExpressionCaseInsensitive error:nil];
    });

    NSArray<NSTextCheckingResult *> *matches = [hrefRegex matchesInString:storyHTML options:0 range:linkTagContentsRange];
    if ([matches count] == 0) {
        return nil;
    }

    NSTextCheckingResult *match = matches[0];
    NSString *href = [hrefRegex replacementStringForResult:match inString:storyHTML offset:0 template:@"$2"];
    NSString *title = nil;
    if ([href hasPrefix:@"./"] && [href length] > 2) {
        title = [[href substringFromIndex:2] wmf_normalizedPageTitle];
    } else {
        NSURL *storyURL = [NSURL URLWithString:href];
        title = [storyURL wmf_title];
    }

    return title;
}

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys {
    return @[@"featuredArticlePreview", @"articlePreviews"];
}

// No languageVariantCodePropagationURLKeys

@end

NS_ASSUME_NONNULL_END
