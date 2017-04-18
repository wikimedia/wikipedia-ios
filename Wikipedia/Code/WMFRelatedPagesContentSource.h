#import "WMFContentSource.h"

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFRelatedPagesContentSource : NSObject <WMFContentSource, WMFDateBasedContentSource>

- (void)loadContentForDate:(NSDate *)date inManagedObjectContext:(NSManagedObjectContext *)moc force:(BOOL)force addNewContent:(BOOL)shouldAddNewContent completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
