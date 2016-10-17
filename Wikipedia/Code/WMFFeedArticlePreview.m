#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedArticlePreview

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitle): @"normalizedtitle",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, thumbnailURL): @"thumbnail.source",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, wikidataDescription): @"description",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, snippet): @"extract",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, language): @"lang" };
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

- (NSURL *)articleURL {
    NSURL *siteURL = [NSURL wmf_URLWithDefaultSiteAndlanguage:self.language];
    return [siteURL wmf_URLWithTitle:self.displayTitle];
}

@end

@implementation WMFFeedTopReadArticlePreview

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{ WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, numberOfViews): @"views",
                                                                                             WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, rank): @"rank" }];
}

@end

NS_ASSUME_NONNULL_END
