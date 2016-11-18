#import "WMFFeedNewsStory.h"
#import "WMFFeedArticlePreview.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFFeedNewsStory

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{ WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, storyHTML): @"story",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, articlePreviews): @"links",
              WMF_SAFE_KEYPATH(WMFFeedNewsStory.new, featuredArticlePreview): @"featuredArticlePreview"};
}

+ (NSValueTransformer *)articlePreviewsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[WMFFeedArticlePreview class]];
}

+ (NSUInteger)modelVersion {
    return 3;
}

+ (nullable NSString *)semanticFeaturedArticleTitleFromStoryHTML:(NSString *)storyHTML {
    NSString *pictured = @"pictured"; //TODO: other languages, variants
    
    NSRange range = [storyHTML rangeOfString:pictured options:0];
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

@end

NS_ASSUME_NONNULL_END
