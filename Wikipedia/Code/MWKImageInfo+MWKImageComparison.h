#import <WMF/MWKImageInfo.h>
#import <WMF/MWKImage.h>

@interface MWKImageInfo (MWKImageComparison)

- (BOOL)isAssociatedWithImage:(MWKImage *)image;

@end

@interface MWKImage (MWKImageInfoComparison)

@property (nonatomic, readonly) id infoAssociationValue;

- (BOOL)isAssociatedWithInfo:(MWKImageInfo *)info;

@end