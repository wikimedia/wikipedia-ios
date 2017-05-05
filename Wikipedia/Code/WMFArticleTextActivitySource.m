#import "WMFArticleTextActivitySource.h"
#import "MWKArticle+WMFSharing.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleTextActivitySource ()

@property (nonatomic, strong) MWKArticle *article;
@property (nonatomic, copy, nullable) NSString *shareText;

@end

@implementation WMFArticleTextActivitySource

- (instancetype)initWithArticle:(MWKArticle *)article shareText:(nullable NSString *)text {
    self = [super init];
    if (self) {
        self.article = article;
        self.shareText = text;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return [NSString string];
}

- (nullable id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard] || [activityType isEqualToString:UIActivityTypeAirDrop]) {
        if (self.shareText.length > 0) {
            return self.shareText;
        } else {
            return nil; //just send the URL
        }
    }

    return [NSString localizedStringWithFormat:WMFLocalizedStringWithDefaultValue(@"share-article-name-on-wikipedia", nil, nil, @"\"%1$@\" on @Wikipedia:", @"Formatted string expressing article being on Wikipedia with at symbol handle. Please do not translate the \"@Wikipedia\" in the message, and preserve the spaces around it, as it refers specifically to the Wikipedia Twitter account. %1$@ will be an article title, which should be wrapped in the localized double quote marks."), self.article.url.wmf_title]; //send just the title for other sharing services
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable NSString *)activityType {
    return self.article.url.wmf_title;
}

@end

NS_ASSUME_NONNULL_END
