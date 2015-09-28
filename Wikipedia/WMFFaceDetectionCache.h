
#import <Foundation/Foundation.h>

@class MWKImage;

@interface WMFFaceDetectionCache : NSObject


- (AnyPromise*)getFaceBoundsInImage:(UIImage*)image URL:(NSURL*)url;
- (NSValue*)faceBoundsForURL:(NSURL*)url;

- (AnyPromise*)getFaceBoundsInImage:(UIImage*)image imageMetadata:(MWKImage*)imageMetadata;
- (NSValue*)faceBoundsForImageMetadata:(MWKImage*)imageMetadata;

@end
