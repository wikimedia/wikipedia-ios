#import "MWKHistoryEntry+WMFDatabaseStorable.h"

@implementation MWKHistoryEntry (WMFDatabaseStorable)

+ (NSString *)databaseKeyForURL:(NSURL *)url {
    return url.wmf_articleDatabaseKey;
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:self.url];
}

+ (NSString *)databaseCollectionName {
    return @"MWKHistoryEntry";
}

@end
