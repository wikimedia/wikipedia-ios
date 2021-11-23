#import <WMF/WMFFeedOnThisDayEvent.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSURL+WMFLinkParsing.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedOnThisDayEvent

+ (NSUInteger)modelVersion {
    return 3;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        WMF_SAFE_KEYPATH(WMFFeedOnThisDayEvent.new, year): @"year",
        WMF_SAFE_KEYPATH(WMFFeedOnThisDayEvent.new, text): @"text",
        WMF_SAFE_KEYPATH(WMFFeedOnThisDayEvent.new, articlePreviews): @"pages"
    };
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

- (nullable NSURL *)siteURL {
    return self.articlePreviews.firstObject.articleURL.wmf_siteURL;
}

- (nullable NSString *)languageCode {
    return self.siteURL.wmf_languageCode;
}

- (nullable NSString *)contentLanguageCode {
    return self.siteURL.wmf_contentLanguageCode;
}

- (NSInteger)previewsImageCount {
    __block NSInteger imageCount = 0;
    [self.articlePreviews enumerateObjectsUsingBlock:^(WMFFeedArticlePreview *_Nonnull articlePreview, NSUInteger idx, BOOL *_Nonnull stop) {
        if (articlePreview.imageURLString) {
            imageCount += 1;
        }
    }];
    return imageCount;
}

// Presently EN only.
- (NSUInteger)textDeathRegexMatchCount {
    if (self.text == nil || self.siteURL == nil || [self.siteURL wmf_languageCode] == nil || ![[self.siteURL wmf_languageCode] isEqualToString:@"en"]) {
        return 0;
    }
    return [[WMFFeedOnThisDayEvent enDeathRegex] numberOfMatchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
}

+ (NSRegularExpression *)enDeathRegex {
    // Reminder: events with these keywords *still* appear in the full list of events for a given day.
    // This is just an experimental attempt at making the headline "On this day" events which appear in
    // the feed less overwhelmingly deathy. The "In the news" explore cards already regularly
    // showcase such events.
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(kill(s|ed|ers|ing)?|explosion(s)?|bomb(s|ers|ing|ings|ed)?|slaughter(s|ed|ing)?|massacre(d)?|die|dead|death(s)?|attack(ing|ers|ed)?|assassin(s|ated|ation)?|murder(s|ing|ers|ed)?|execute|execut(ed|ing|ion|ions)?|terror(ist|ism|ize|izing)?|fatal(ity|ly)?)\\b"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });
    return regex;
}

- (NSNumber *)calculateScore {
    NSInteger imageCount = [self previewsImageCount];

    // Use image count if not EN.
    if ([self.siteURL wmf_languageCode] == nil || ![[self.siteURL wmf_languageCode] isEqualToString:@"en"]) {
        return @(imageCount);
    }

    // If lang is EN weight images by 0.2 and subtract deathScore (-1 per death match)
    NSInteger deathScore = [self textDeathRegexMatchCount];
    NSNumber *imageScore = @(@(imageCount).floatValue * 0.2);
    NSNumber *score = @(imageScore.floatValue - deathScore);
    return score;
}

+ (NSArray<NSString *> *)languageVariantCodePropagationSubelementKeys {
    return @[@"articlePreviews"];
}

// No languageVariantCodePropagationURLKeys. The siteURL property is a derived value.

@end

NS_ASSUME_NONNULL_END
