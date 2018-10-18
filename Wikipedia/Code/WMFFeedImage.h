#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedImage : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *canonicalPageTitle;

@property (nonatomic, readonly, copy) NSString *imageDescription;

@property (nonatomic, assign, readonly) BOOL imageDescriptionIsRTL;

@property (nonatomic, readonly, copy) NSURL *imageThumbURL;

@property (nonatomic, readonly, copy) NSURL *imageURL;

@end

NS_ASSUME_NONNULL_END
