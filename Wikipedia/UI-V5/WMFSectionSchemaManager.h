
@import Foundation;

@class MWKSavedPageList, MWKHistoryList;

@interface WMFSectionSchemaManager : NSObject

- (instancetype)initWithSavedPages:(MWKSavedPageList*)savedPages recentPages:(MWKHistoryList*)recentPages;

@property (nonatomic, strong, readonly) MWKSavedPageList* savedPages;
@property (nonatomic, strong, readonly) MWKHistoryList* recentPages;

@property (nonatomic, strong, readonly) NSArray* sectionSchema;

/**
 *  Update the schema based on the recents and saved pages.
 *  Call this when you want to update the sections.
 */
- (void)updateSchema;

@end
