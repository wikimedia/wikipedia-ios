#import <Foundation/Foundation.h>
#import "FLAnimatedImage.h"

@interface FLAnimatedImage (SafeForSwift)

+ (nullable FLAnimatedImage *)wmf_animatedImageWithData:(nullable NSData *)data;

@property (nonatomic, readonly, nullable) UIImage *wmf_staticImage;

@end
