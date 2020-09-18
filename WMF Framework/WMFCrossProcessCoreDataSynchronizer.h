#import <Foundation/Foundation.h>

@class NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN
@interface WMFCrossProcessCoreDataSynchronizer : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier storageDirectory:(NSURL *)directoryURL NS_DESIGNATED_INITIALIZER;

- (void)startSynchronizingContexts:(NSArray<NSManagedObjectContext *> *)contexts;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
