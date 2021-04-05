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
    return 5;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitle): @"normalizedtitle",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, displayTitleHTML): @[@"displaytitle", @"normalizedtitle"],
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, thumbnailURL): @"thumbnail.source",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageURLString): @"originalimage.source",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageWidth): @"originalimage.width",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, imageHeight): @"originalimage.height",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, wikidataDescription): @"description",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, snippet): @"extract",
             WMF_SAFE_KEYPATH(WMFFeedArticlePreview.new, articleURL): @[@"content_urls.desktop.page", @"lang", @"normalizedtitle"]};
};

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

+ (NSRegularExpression *)wikiLanguageFromURLStringRegex {
    static dispatch_once_t onceToken;
    static NSRegularExpression *wikiLanguageFromURLStringRegex;
    dispatch_once(&onceToken, ^{
        wikiLanguageFromURLStringRegex = [NSRegularExpression regularExpressionWithPattern:@"\\/\\/([^.]*)" options:0 error:nil];
    });
    return wikiLanguageFromURLStringRegex;
}

+ (NSValueTransformer *)articleURLJSONTransformer {
    return [MTLValueTransformer
        transformerUsingForwardBlock:^NSURL *(NSDictionary *value,
                                              BOOL *success,
                                              NSError *__autoreleasing *error) {
            NSString *urlString = value[@"content_urls.desktop.page"];
            NSURL *url = [NSURL URLWithString:urlString];
            if (!url) { // url can fail due to unescaped characters - should be fixed when https://gerrit.wikimedia.org/r/#/c/mediawiki/services/mobileapps/+/489329/ is deployed
                __block NSString *lang = nil;
                if (urlString) {
                    NSRegularExpression *regex = [WMFFeedArticlePreview wikiLanguageFromURLStringRegex];
                    [regex enumerateMatchesInString:urlString
                                            options:0
                                              range:NSMakeRange(0, urlString.length)
                                         usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
                                             lang = [regex replacementStringForResult:result inString:urlString offset:0 template:@"$1"];
                                             *stop = YES;
                                         }];
                }
                if (lang == nil) { // lang is problematic to use for URLs because it's yue when it shuold be zh-yue, lzh instead of zh-classical, etc.
                    lang = value[@"lang"];
                }
                NSString *normalizedTitle = value[@"normalizedtitle"];
                NSURL *siteURL = [NSURL wmf_URLWithDefaultSiteAndLanguageCode:lang];
                url = [siteURL wmf_URLWithTitle:normalizedTitle];
            }
            assert(url);
            return url;
        }
        reverseBlock:^NSDictionary *(NSURL *articleURL,
                                     BOOL *success,
                                     NSError *__autoreleasing *error) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{@"content_urls.desktop.page": @"",
                                                                                        @"lang": @"",
                                                                                        @"normalizedtitle": @""}];
            NSString *urlString = articleURL.absoluteString;
            if (urlString) {
                dict[@"content_urls.desktop.page"] = urlString;
            }
            NSString *lang = articleURL.wmf_languageCode;
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
        nonNullKeys = @{@"articleURL": @YES,
                        @"language": @YES,
                        @"displayTitle": @YES,
                        @"displayTitleHTML": @YES};
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

// No languageVariantCodePropagationSubelementKeys

+ (NSArray<NSString *> *)languageVariantCodePropagationURLKeys {
    return @[@"thumbnailURL",
             @"articleURL"];
}

@end

@implementation WMFFeedTopReadArticlePreview

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return [[super JSONKeyPathsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, numberOfViews): @"views",
                                                                                            WMF_SAFE_KEYPATH(WMFFeedTopReadArticlePreview.new, rank): @"rank"}];
}

@end

NS_ASSUME_NONNULL_END
