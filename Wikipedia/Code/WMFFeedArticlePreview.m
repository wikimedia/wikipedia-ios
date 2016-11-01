#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedArticlePreview

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitle): @"normalizedtitle",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, thumbnailURL): @"thumbnail.source",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, wikidataDescription): @"description",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, snippet): @"extract",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, language): @"lang",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, articleURL): @[@"lang", @"normalizedtitle"] };
}

+ (NSValueTransformer *)thumbnailURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSString *urlString,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            return [NSURL wmf_optionalURLWithString:urlString];
        }
        reverseBlock:^NSString *(NSURL *thumbnailURL,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return [thumbnailURL absoluteString];
        }];
}

+ (NSValueTransformer *)articleURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSDictionary *value,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            NSString *lang = value[@"lang"];
            NSString *normalizedTitle = value[@"normalizedtitle"];
            NSURL *siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:lang];
            return [siteURL wmf_URLWithTitle:normalizedTitle];
        }
        reverseBlock:^NSDictionary *(NSURL *articleURL,
                                     BOOL *success,
                                     NSError *__autoreleasing *error) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{ @"lang": @"",
                                                                                         @"normalizedtitle": @"" }];
            NSString *lang = articleURL.wmf_language;
            if (lang) {
                dict[@"lang"] = lang;
            }
            NSString *normalizedTitle = articleURL.wmf_title;
            if (normalizedTitle) {
                dict[@"normalizedtitle"] = normalizedTitle;
            }
            return dict;
        }];
}

- (BOOL)validateValue:(inout id _Nullable *_Nonnull)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    static NSDictionary *nonNullKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nonNullKeys = @{ @"articleURL": @YES,
                         @"language": @YES,
                         @"displayTitle": @YES };
    });

    if (nonNullKeys[inKey]) {
        if (!ioValue) {
            return NO;
        }
        return *ioValue != nil;
    } else {
        return YES;
    }
}

@end

@implementation WMFFeedTopReadArticlePreview

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{ WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, numberOfViews): @"views",
                                                                                             WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, rank): @"rank" }];
}

@end

NS_ASSUME_NONNULL_END
