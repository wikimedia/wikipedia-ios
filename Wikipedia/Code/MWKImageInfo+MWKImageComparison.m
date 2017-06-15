#import <WMF/MWKImageInfo+MWKImageComparison.h>
#import <WMF/MWKImage.h>

@implementation MWKImageInfo (MWKImageComparison)

- (BOOL)isAssociatedWithImage:(MWKImage *)image {
    return [self.imageAssociationValue isEqual:image.infoAssociationValue];
}

@end

@implementation MWKImage (MWKImageInfoComparison)

- (id)infoAssociationValue {
    return self.fileNameNoSizePrefix;
}

- (BOOL)isAssociatedWithInfo:(MWKImageInfo *)info {
    return [info isAssociatedWithImage:self];
}

@end
