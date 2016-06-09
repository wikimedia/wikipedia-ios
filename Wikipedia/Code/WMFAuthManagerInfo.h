
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFAuthManagerInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign, readonly) BOOL canAuthenticate;
@property (nonatomic, assign, readonly) BOOL canCreateAccount;

@property (nonatomic, copy, readonly) NSString* captchaID;

@end

NS_ASSUME_NONNULL_END