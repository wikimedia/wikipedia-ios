
#import "MWKHistoryEntry+WMFDatabaseStorable.h"

@implementation MWKHistoryEntry (WMFDatabaseStorable)

+ (NSString*)databaseKeyForURL:(NSURL*)url{
    return [[NSURL wmf_desktopURLForURL:url] absoluteString];
}

- (NSString*)databaseKey {
    return [self.url absoluteString];
}

+ (NSString*)databaseCollectionName {
    return @"MWKHistoryEntry";
}

@end
