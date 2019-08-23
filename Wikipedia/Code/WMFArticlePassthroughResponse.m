
#import "WMFArticlePassthroughResponse.h"

@implementation WMFArticlePassthroughResponse

- (instancetype)initWithArticle:(MWKArticle *)article success:(BOOL)success error:(NSError *)error force:(BOOL)force
{
    self = [super init];
    if (self) {
        self.article = article;
        self.success = success;
        self.error = error;
        self.force = force;
    }
    return self;
}

@end
