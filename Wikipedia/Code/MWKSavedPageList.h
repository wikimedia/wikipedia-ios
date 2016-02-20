
#import "MWKList.h"
#import "MWKSavedPageEntry.h"
#import "MWKTitle.h"
#import "MWKDataStoreList.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const MWKSavedPageListDidSaveNotification;
extern NSString* const MWKSavedPageListDidUnsaveNotification;

extern NSString* const MWKTitleKey;


@interface MWKSavedPageList : MWKList<MWKSavedPageEntry*, MWKTitle*>
    < MWKDataStoreList >

- (MWKSavedPageEntry* __nullable)entryForListIndex:(MWKTitle*)title;
- (MWKSavedPageEntry*)           mostRecentEntry;

- (BOOL)isSaved:(MWKTitle*)title;

/**
 * Toggle the save state for `title`.
 *
 * @param title Title to toggle state for, either saving or un-saving it.
 */
- (void)toggleSavedPageForTitle:(MWKTitle*)title;

/**
 *  Add a saved page
 *
 *  @param title The title of the page to add
 */
- (void)addSavedPageWithTitle:(MWKTitle*)title;

- (NSDictionary*)dataExport;

@end

NS_ASSUME_NONNULL_END
