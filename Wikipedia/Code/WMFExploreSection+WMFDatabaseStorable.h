
#import "WMFExploreSection.h"
#import "WMFDatabaseStorable.h"

@interface WMFExploreSection (WMFDatabaseStorable)<WMFDatabaseStorable>

/**
 * URL for daily sections. Based on date and the type since there is no canonical URL
 */
+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date type:(WMFExploreSectionType)type;


@end
