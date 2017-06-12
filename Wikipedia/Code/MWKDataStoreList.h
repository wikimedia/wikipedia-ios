@class MWKDataStore;

@protocol MWKDataStoreList

/**
 *  Initialize the receiver from a data store.
 *
 *  The receiver should read any data which resides in the store, and subsequent saves should update it.
 *
 *  @param dataStore The store to read data from.
 *
 *  @return A new list.
 */
- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

@property (nonatomic, weak, readonly) MWKDataStore *dataStore;

@end
