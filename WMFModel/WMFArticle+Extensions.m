#import "WMFArticle+Extensions.h"

@implementation WMFArticle (Extensions)

- (nullable NSURL *)URL {
    NSString *key = self.key;
    if (!key) {
        return nil;
    }
    return [NSURL URLWithString:key];
}

@end
