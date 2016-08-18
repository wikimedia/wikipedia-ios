#import "MWKImageInfo.h"
#import "MWKImage.h"

@interface MWKImageInfo (MWKImageComparison)

- (BOOL)isAssociatedWithImage:(MWKImage*)image;

@end

@interface MWKImage (MWKImageInfoComparison)

@property (nonatomic, readonly) id infoAssociationValue;

- (BOOL)isAssociatedWithInfo:(MWKImageInfo*)info;

@end