#import <Mantle/Mantle.h>

@interface MWKSectionMetaData : MTLModel <MTLJSONSerializing>

@property (copy, nonatomic, readonly) NSString *displayTitle;

@property (copy, nonatomic, readonly) NSIndexPath *number;
@property (copy, nonatomic, readonly) NSNumber *level;

@end
