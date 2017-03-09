#import "MWKImage+AssociationTestUtils.h"
#import "MWKArticle.h"

@implementation MWKImage (AssociationTestUtils)

+ (instancetype)imageAssociatedWithSourceURL:(NSString *)imageURL {
    NSURL *title = [[NSURL wmf_URLWithDefaultSiteAndCurrentLocale] wmf_URLWithTitle:@"foo"];
    MWKArticle *article = [[MWKArticle alloc] initWithURL:title dataStore:nil];
    return [[self alloc] initWithArticle:article sourceURLString:imageURL];
}

- (MWKImageInfo *)createAssociatedInfo {
    return [MWKImageInfo infoAssociatedWithSourceURL:self.sourceURLString];
}

@end

@implementation MWKImageInfo (AssociationTestUtils)

+ (instancetype)infoAssociatedWithSourceURL:(NSString *)imageURL {
    return [[self alloc] initWithCanonicalPageTitle:imageURL
                                   canonicalFileURL:[NSURL URLWithString:imageURL]
                                   imageDescription:nil
                                            license:nil
                                        filePageURL:nil
                                      imageThumbURL:nil
                                              owner:nil
                                          imageSize:CGSizeZero
                                          thumbSize:CGSizeZero];
}

- (MWKImage *)createAssociatedImage {
    return [MWKImage imageAssociatedWithSourceURL:self.canonicalFileURL.absoluteString];
}

@end
