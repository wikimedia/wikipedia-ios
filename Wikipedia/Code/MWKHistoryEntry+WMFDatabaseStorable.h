
#import "MWKHistoryEntry.h"
#import "WMFDatabaseStorable.h"

@interface MWKHistoryEntry (WMFDatabaseStorable)<WMFDatabaseStorable>

+ (NSString*)databaseKeyForURL:(NSURL*)url;

@end
