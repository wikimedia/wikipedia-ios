#import "MWKImage.h"
#import "MWKImageInfo.h"

@interface MWKImage (AssociationTestUtils)

+ (instancetype)imageAssociatedWithSourceURL:(NSString *)imageURL;

- (MWKImageInfo *)createAssociatedInfo;

@end

@interface MWKImageInfo (AssociationTestUtils)

+ (instancetype)infoAssociatedWithSourceURL:(NSString *)imageURL;

- (MWKImage *)createAssociatedImage;

+ (id)mappedFromImages:(id)images;

@end
