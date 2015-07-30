
#import <Mantle/Mantle.h>

@interface MWKSectionMetaData : MTLModel<MTLJSONSerializing>

@property (readonly, copy, nonatomic) NSString* displayTitle;

@property (readonly, copy, nonatomic) NSIndexPath* number;
@property (readonly, copy, nonatomic) NSNumber* level;

@end
