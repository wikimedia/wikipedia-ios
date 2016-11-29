#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WMFAnalyticsContextProviding <NSObject>

- (NSString *)analyticsContext;

@end

@protocol WMFAnalyticsContentTypeProviding <NSObject>

- (NSString *)analyticsContentType;

@end

@protocol WMFAnalyticsViewNameProviding <NSObject>

- (NSString *)analyticsName;

@end

@protocol WMFAnalyticsValueProviding <NSObject>

- (nullable NSNumber *)analyticsValue;

@end

NS_ASSUME_NONNULL_END
