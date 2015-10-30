
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface MWKSearchRedirectMapping : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* redirectFromTitle;
@property (nonatomic, copy, readonly) NSString* redirectToTitle;

@end

NS_ASSUME_NONNULL_END