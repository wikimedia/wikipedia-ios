#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSURL+WMFExtras.h>
#import <WMF/NSString+WMFExtras.h>
#import <WMF/NSURL+WMFLinkParsing.h>
#import <WMF/NSString+WMFHTMLParsing.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedArticlePreview
@synthesize displayTitleHTML = _displayTitleHTML;
@synthesize displayTitle = _displayTitle;

+ (NSUInteger)modelVersion {
    return 3;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitle): @"normalizedtitle",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitleHTML): @[@"displaytitle", @"normalizedtitle"],
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, thumbnailURL): @"thumbnail.source",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageURLString): @"originalimage.source",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageWidth): @"originalimage.width",
              WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageHeight): @"originalimage.height",
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
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"lang": @"",
                                                                                        @"normalizedtitle": @""}];
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

+ (NSValueTransformer *)displayTitleHTMLJSONTransformer {
    return [MTLValueTransformer
            transformerUsingForwardBlock:^NSURL *(NSDictionary *value,
                                                  BOOL *success,
                                                  NSError *__autoreleasing *error) {
                return value[@"displaytitle"] ?: value[@"normalizedtitle"];
            }
            reverseBlock:^NSDictionary *(NSString *displayTitleHTML,
                                         BOOL *success,
                                         NSError *__autoreleasing *error) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"displaytitle": @""}];
                if (displayTitleHTML) {
                    dict[@"displaytitle"] = displayTitleHTML;
                }
                return dict;
            }];
}

- (NSString *)displayTitleHTML {
    return _displayTitleHTML && ![_displayTitleHTML isEqualToString:@""] ? _displayTitleHTML : _displayTitle;
}

+ (NSValueTransformer *)snippetJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSString *(NSString *extract,
                                                 BOOL *success,
                                                 NSError *__autoreleasing *error) {
            return [extract wmf_summaryFromText];
        }
        reverseBlock:^NSString *(NSString *snippet,
                                 BOOL *success,
                                 NSError *__autoreleasing *error) {
            return snippet;
        }];
}

- (BOOL)validateValue:(inout id _Nullable *_Nonnull)ioValue forKey:(NSString *)inKey error:(out NSError **)outError {
    static NSDictionary *nonNullKeys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nonNullKeys = @{ @"articleURL": @YES,
                         @"language": @YES,
                         @"displayTitle": @YES,
                         @"displayTitleHTML": @YES };
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
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, numberOfViews): @"views",
                                                                                            WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, rank): @"rank"}];
}

@end

NS_ASSUME_NONNULL_END
