#import <UIKit/UIKit.h>

@interface UIImage (WMFSerialization)

- (NSData*)wmf_pngRepresentation;

- (NSData*)wmf_losslessJPEGRepresentation;

- (NSData*)wmf_dataRepresentationForMimeType:(NSString*)mimeType serializedMimeType:(NSString**)outMimeType;

@end
