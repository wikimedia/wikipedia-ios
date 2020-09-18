#import <Foundation/Foundation.h>

@class NSManagedObjectContext;

NS_ASSUME_NONNULL_BEGIN

/// Keeps a shared persistent store in sync across different processes
/// Likely should be replaced with Persistent History Tracking introduced in iOS 13:
/// https://developer.apple.com/videos/play/wwdc2017/210/
/// https://www.avanderlee.com/swift/persistent-history-tracking-core-data/

@interface WMFCrossProcessCoreDataSynchronizer : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier storageDirectory:(NSURL *)directoryURL NS_DESIGNATED_INITIALIZER;

- (void)startSynchronizingContexts:(NSArray<NSManagedObjectContext *> *)contexts;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
