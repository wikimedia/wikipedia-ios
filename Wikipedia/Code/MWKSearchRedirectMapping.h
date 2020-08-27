#import <WMF/WMFMTLModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKSearchRedirectMapping : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString *redirectFromTitle;
@property (nonatomic, copy, readonly) NSString *redirectToTitle;

+ (instancetype)mappingFromTitle:(NSString *)from toTitle:(NSString *)to;

@end

NS_ASSUME_NONNULL_END
