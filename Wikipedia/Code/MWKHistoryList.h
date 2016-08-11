
#import <Foundation/Foundation.h>

@class MWKHistoryEntry, MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface MWKHistoryList : NSObject

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore NS_DESIGNATED_INITIALIZER;

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

#pragma mark - Convienence Methods

- (NSInteger)numberOfItems;

- (nullable MWKHistoryEntry*)mostRecentEntry;

- (nullable MWKHistoryEntry*)entryForURL:(NSURL*)url;

#pragma mark - Update Methods

/**
 *  Add a page to the user history.
 *
 *  Calling this on a page already in the history will simply update its @c date.
 *
 *  @param url The url of the page to add
 */
- (MWKHistoryEntry*)addPageToHistoryWithURL:(NSURL*)url;

/**
 *  Save the scroll position of a page.
 *
 *  @param scrollposition The scroll position to save
 *  @param url          The url of the page
 *
 *  @return The task. The result is the MWKHistoryEntry.
 */
- (void)setPageScrollPosition:(CGFloat)scrollposition onPageInHistoryWithURL:(NSURL*)url;

/**
 *  Sets the history entry to be "significantly viewed"
 *  This denotes that a user looked at this title for a period of time to indicate interest
 *
 *  @param url The url to set to significantly viewed
 */
- (void)setSignificantlyViewedOnPageInHistoryWithURL:(NSURL*)url;

/**
 *  Remove a page from the user history
 *
 *  @param url The url of the page to remove
 */
- (void)removeEntryWithURL:(NSURL*)url;


/**
 *  Remove all history entries
 */
- (void)removeAllEntries;


@end


NS_ASSUME_NONNULL_END
