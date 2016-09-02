#import <Mantle/Mantle.h>

@interface WMFZeroConfiguration : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nonnull, readonly) NSString *message;
@property (nonatomic, strong, nonnull, readonly) UIColor *foreground;
@property (nonatomic, strong, nonnull, readonly) UIColor *background;
@property (nonatomic, copy, nullable, readonly) NSString *exitTitle;
@property (nonatomic, copy, nullable, readonly) NSString *exitWarning;
@property (nonatomic, copy, nullable, readonly) NSString *partnerInfoText;
@property (nonatomic, copy, nullable, readonly) NSString *partnerInfoUrl;
@property (nonatomic, copy, nullable, readonly) NSString *bannerUrl;

@end
