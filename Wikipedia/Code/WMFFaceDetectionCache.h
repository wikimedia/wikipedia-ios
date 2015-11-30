
#import <Foundation/Foundation.h>

@class MWKImage;

@interface WMFFaceDetectionCache : NSObject

- (BOOL)imageAtURLRequiresFaceDetection:(NSURL*)url;
- (AnyPromise*)detectFaceBoundsInImage:(UIImage*)image URL:(NSURL*)url;
- (NSValue*)faceBoundsForURL:(NSURL*)url;

- (BOOL)imageRequiresFaceDetection:(MWKImage*)imageMetadata;
- (AnyPromise*)detectFaceBoundsInImage:(UIImage*)image imageMetadata:(MWKImage*)imageMetadata;
- (NSValue*)faceBoundsForImageMetadata:(MWKImage*)imageMetadata;

- (void)clearCache;

@end
