#import <WMF/MWKDataObject.h>

@interface MWKLicense : MWKDataObject

@property (nonatomic, readonly, copy) NSString *code;
@property (nonatomic, readonly, copy) NSString *shortDescription;
@property (nonatomic, readonly, copy) NSURL *URL;

+ (instancetype)licenseWithExportedData:(NSDictionary *)exportedData;

- (instancetype)initWithCode:(NSString *)code
            shortDescription:(NSString *)shortDescription
                         URL:(NSURL *)URL;

- (BOOL)isEqualToLicense:(MWKLicense *)other;

@end
