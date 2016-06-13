
#import "WMFArticleTextActivitySource.h"
#import "MWKArticle+WMFSharing.h"
#import "MWKTitle.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleTextActivitySource ()

@property (nonatomic, strong) MWKArticle* article;
@property (nonatomic, copy, nullable) NSString* shareText;

@end

@implementation WMFArticleTextActivitySource

- (instancetype)initWithArticle:(MWKArticle*)article shareText:(nullable NSString*)text {
    self = [super init];
    if (self) {
        self.article   = article;
        self.shareText = text;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController*)activityViewController {
    return [NSString string];
}

- (nullable id)activityViewController:(UIActivityViewController*)activityViewController itemForActivityType:(NSString*)activityType {
    if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard] || [activityType isEqualToString:UIActivityTypeAirDrop]) {
        if (self.shareText.length > 0) {
            return self.shareText;
        } else {
            return nil; //just send the URL
        }
    }

    return [MWLocalizedString(@"share-article-name-on-wikipedia", nil) stringByReplacingOccurrencesOfString:@"$1" withString:self.article.title.text]; //send just the title for other sharing services
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable NSString *)activityType {
    return self.article.title.text;
}

@end

NS_ASSUME_NONNULL_END
