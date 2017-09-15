#import <WMF/MWKDataObject.h>
NS_ASSUME_NONNULL_BEGIN
@interface MWKLicense : MWKDataObject

@property (nullable, nonatomic, readonly, copy) NSString *code;
@property (nullable, nonatomic, readonly, copy) NSString *shortDescription;
@property (nullable, nonatomic, readonly, copy) NSURL *URL;

+ (instancetype)licenseWithExportedData:(NSDictionary *)exportedData;

- (instancetype)initWithCode:(nullable NSString *)code
            shortDescription:(nullable NSString *)shortDescription
                         URL:(nullable NSURL *)URL;

- (BOOL)isEqualToLicense:(MWKLicense *)other;

@end
NS_ASSUME_NONNULL_END
