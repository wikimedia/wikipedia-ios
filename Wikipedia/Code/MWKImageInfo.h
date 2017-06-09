#import "MWKDataObject.h"
@import CoreGraphics;
@class MWKLicense;

@interface MWKImageInfo : MWKDataObject

/// Name of the canonical file associated with this image, in the format @c "File:Some_file_name.extension".
@property (nonatomic, readonly, copy) NSString *canonicalPageTitle;

/// Name of the file associated with this image, without the "File:" prefix;
- (NSString *)canonicalPageName;

/// URL pointing at the canonical file associated with this gallery item, e.g. @c "//site/.../Some_file_name.extension".
/// @warning These images can be *very* large. Special handling may be needed when downloading or displaying.
@property (nonatomic, readonly, copy) NSURL *canonicalFileURL;

/// Short description of the image contents (e.g. "John Smith posing for a picture").
@property (nonatomic, readonly, copy) NSString *imageDescription;

@property (nonatomic, readonly, strong) MWKLicense *license;

/// URL pointing to the corresponding file page for the receiver.
@property (nonatomic, readonly, copy) NSURL *filePageURL;

/// URL pointing at a thumbnail version of the image at @c imageURL.
@property (nonatomic, readonly, copy) NSURL *imageThumbURL;

/// Size of the original image.
@property (nonatomic, readonly, assign) CGSize imageSize;

/// Size of the thumbnail at @c imageThumbURL.
@property (nonatomic, readonly, assign) CGSize thumbSize;

/// Name of the entity owning this image.
@property (nonatomic, readonly, copy) NSString *owner;

/// Value which can be used to associate the receiver with a @c MWKImage.
@property (nonatomic, readonly, strong) id imageAssociationValue;

/// Factory method for creating an instance from the output of @c exportData.
+ (instancetype)imageInfoWithExportedData:(NSDictionary *)exportedData;

- (instancetype)initWithCanonicalPageTitle:(NSString *)canonicalPageTitle
                          canonicalFileURL:(NSURL *)canonicalFileURL
                          imageDescription:(NSString *)imageDescription
                                   license:(MWKLicense *)license
                               filePageURL:(NSURL *)filePageURL
                             imageThumbURL:(NSURL *)imageThumbURL
                                     owner:(NSString *)owner
                                 imageSize:(CGSize)imageSize
                                 thumbSize:(CGSize)thumbSize;

@end
