#import <Foundation/Foundation.h>

@class WMFSession;
@class WMFConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface WMFFetcher : NSObject

@property (nonatomic, strong, readonly) WMFSession *session;
@property (nonatomic, strong, readonly) WMFConfiguration *configuration;

@end

NS_ASSUME_NONNULL_END
