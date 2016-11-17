#import "WMFArticlePreview+WMFDatabaseStorable.h"

@implementation WMFArticlePreview (WMFDatabaseStorable)

+ (NSString *)databaseKeyForURL:(NSURL *)url {
    NSParameterAssert(url);
    return [url wmf_articleDatabaseKey];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:self.url];
}

+ (NSString *)databaseCollectionName {
    return @"WMFArticlePreview";
}

@end
