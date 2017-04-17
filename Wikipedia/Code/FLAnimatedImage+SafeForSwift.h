@import Foundation;
@import FLAnimatedImage;

@interface FLAnimatedImage (SafeForSwift)

+ (nullable FLAnimatedImage *)wmf_animatedImageWithData:(nullable NSData *)data;

@property (nonatomic, readonly, nullable) UIImage *wmf_staticImage;

@end
