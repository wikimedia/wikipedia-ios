#import <WMF/WMFFeedOnThisDayEvent.h>
#import <WMF/WMFFeedArticlePreview.h>
#import <WMF/WMFComparison.h>
#import <WMF/NSCalendar+WMFCommonCalendars.h>
#import <WMF/WMFLocalization.h>
#import <WMF/NSString+WMFPageUtilities.h>
#import <WMF/NSURL+WMFLinkParsing.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedOnThisDayEvent

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

+ (NSUInteger)modelVersion {
    return 2;
}

- (nullable NSURL *)siteURL {
    return self.articlePreviews.firstObject.articleURL.wmf_siteURL;
}

- (nullable NSString *)language {
    return self.siteURL.wmf_language;
}

@end

NS_ASSUME_NONNULL_END
