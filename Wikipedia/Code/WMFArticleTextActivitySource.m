
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
    
    if([activityType isEqualToString:UIActivityTypePostToTwitter]){
        NSString* text = nil;
        if (self.shareText.length > 0) {
            text = self.shareText;
        } else {
            text = self.article.displaytitle;
        }
        return [NSString stringWithFormat:@"%@ %@", text, MWLocalizedString(@"share-on-twitter-sign-off", nil)];
    }

    if([activityType isEqualToString:UIActivityTypePostToFacebook]){
        NSString* text = nil;
        if (self.shareText.length > 0) {
            text = self.shareText;
        } else {
            text = self.article.displaytitle;
        }
        return text;
    }
    
    return self.article.displaytitle; //send just the title for other sharing services
}

@end

NS_ASSUME_NONNULL_END
