#import <Foundation/Foundation.h>

@class WMFSession;
@class WMFConfiguration;

NS_ASSUME_NONNULL_BEGIN

// Bridge from old Obj-C fetcher classes to new Swift fetcher class
@interface WMFLegacyFetcher : NSObject

@property (nonatomic, strong, readonly) WMFSession *session;
@property (nonatomic, strong, readonly) WMFConfiguration *configuration;

@end

NS_ASSUME_NONNULL_END
