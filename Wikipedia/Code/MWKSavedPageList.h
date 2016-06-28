
#import "MWKList.h"
#import "MWKSavedPageEntry.h"
#import "MWKDataStoreList.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString* const MWKSavedPageListDidSaveNotification;
extern NSString* const MWKSavedPageListDidUnsaveNotification;

extern NSString* const MWKURLKey;


@interface MWKSavedPageList : MWKList<MWKSavedPageEntry*, NSURL*>
    < MWKDataStoreList >

- (MWKSavedPageEntry* __nullable)entryForListIndex:(NSURL*)url;
- (MWKSavedPageEntry*)           mostRecentEntry;

- (BOOL)isSaved:(NSURL*)url;

/**
 * Toggle the save state for `title`.
 *
 * @param title Title to toggle state for, either saving or un-saving it.
 */
- (void)toggleSavedPageForURL:(NSURL*)url;

/**
 *  Add a saved page
 *
 *  @param title The title of the page to add
 */
- (void)addSavedPageWithURL:(NSURL*)url;

- (NSDictionary*)dataExport;

@end

NS_ASSUME_NONNULL_END
