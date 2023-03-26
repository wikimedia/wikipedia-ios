@import CoreLocation;

@interface CLLocation (WMFDictionary)
+ (nullable instancetype)locationWithDictionary:(nullable NSDictionary<NSString *, NSNumber *> *)dictionary;
@end
