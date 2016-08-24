
#import "WMFExploreSection+WMFDatabaseStorable.h"
#import "NSDate+Utilities.h"

@implementation WMFExploreSection (WMFDatabaseStorable)

+ (NSString *)databaseKeyForArticleURL:(NSURL *)url {
    NSParameterAssert(url);
    return [[NSURL wmf_desktopURLForURL:url] absoluteString];
}

+ (NSString *)databaseKeyForDate:(NSDate*)date type:(WMFExploreSectionType)type {
    NSParameterAssert(date);
    return [NSString stringWithFormat:@"%f-%lu", [[date dateAtStartOfDay] timeIntervalSinceReferenceDate], (unsigned long)type];
}

- (NSString *)databaseKey {
    if(self.type == WMFExploreSectionTypeSaved || self.type == WMFExploreSectionTypeHistory){
        return [[self class] databaseKeyForArticleURL:self.articleURL];
    }else{
        return [[self class] databaseKeyForDate:self.dateCreated type:self.type];
    }
}

+ (NSString *)databaseCollectionName {
    return @"WMFFeedSection";
}

@end
