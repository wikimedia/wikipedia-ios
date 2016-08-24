
#import "WMFExploreSection.h"
#import "WMFDatabaseStorable.h"

@interface WMFExploreSection (WMFDatabaseStorable)<WMFDatabaseStorable>

/**
 * Database Key for saved and history. Based on article URL.
 */
+ (NSString *)databaseKeyForArticleURL:(NSURL *)url;

/**
 * Database Key for daily sections. Based on date and the type.
 */
+ (NSString *)databaseKeyForDate:(NSDate*)date type:(WMFExploreSectionType)type;

@end
