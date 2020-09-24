#import <WMF/WMFContentSource.h>

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContinueReadingContentSource : NSObject <WMFContentSource, WMFAutoUpdatingContentSource>

@property (readonly, nonatomic, weak) MWKDataStore *userDataStore;

- (instancetype)initWithUserDataStore:(MWKDataStore *)userDataStore;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
