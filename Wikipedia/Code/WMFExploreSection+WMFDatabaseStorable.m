
#import "WMFExploreSection+WMFDatabaseStorable.h"
#import "NSDate+Utilities.h"

@implementation WMFExploreSection (WMFDatabaseStorable)

+ (NSURL *)urlForSiteURL:(NSURL*)url date:(NSDate*)date type:(WMFExploreSectionType)type {
    NSParameterAssert(date);
    url = [url wmf_siteURL];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%f", [[date dateAtStartOfDay] timeIntervalSinceReferenceDate]]];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)type]];
    return url;
}

+ (NSString *)databaseKeyForURL:(NSURL *)url {
    NSParameterAssert(url);
    return [[NSURL wmf_desktopURLForURL:url] absoluteString];
}

- (NSString *)databaseKey {
    if(self.type == WMFExploreSectionTypeSaved || self.type == WMFExploreSectionTypeHistory){
        return [[self class] databaseKeyForURL:self.articleURL];
    }else{
        return [[self class] databaseKeyForURL:[[self class] urlForSiteURL:self.siteURL date:self.dateCreated type:self.type]];
    }
}

+ (NSString *)databaseCollectionName {
    return @"WMFFeedSection";
}

@end
