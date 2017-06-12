#import <WMF/FLAnimatedImage+SafeForSwift.h>

@implementation FLAnimatedImage (SafeForSwift)

+ (nullable FLAnimatedImage *)wmf_animatedImageWithData:(nullable NSData *)data {
    return [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
}

- (nullable UIImage *)wmf_staticImage {
    return self.posterImage;
}

@end
