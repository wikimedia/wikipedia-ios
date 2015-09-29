
#import <Foundation/Foundation.h>

@class MWKImage;

@interface WMFFaceDetectionCache : NSObject

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL*)url;
- (AnyPromise*)getFaceBoundsInImage:(UIImage*)image URL:(NSURL*)url;
- (NSValue*)faceBoundsForURL:(NSURL*)url;

- (BOOL)imageRequiresFaceDetection:(MWKImage*)imageMetadata;
- (AnyPromise*)getFaceBoundsInImage:(UIImage*)image imageMetadata:(MWKImage*)imageMetadata;
- (NSValue*)faceBoundsForImageMetadata:(MWKImage*)imageMetadata;

@end
