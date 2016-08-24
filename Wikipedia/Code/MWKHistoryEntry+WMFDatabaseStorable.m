#import "MWKHistoryEntry+WMFDatabaseStorable.h"

@implementation MWKHistoryEntry (WMFDatabaseStorable)

+ (NSString *)databaseKeyForURL:(NSURL *)url {
    return [[NSURL wmf_desktopURLForURL:url] absoluteString];
}

- (NSString *)databaseKey {
    return [[self class] databaseKeyForURL:self.url];
}

+ (NSString *)databaseCollectionName {
    return @"MWKHistoryEntry";
}

@end
