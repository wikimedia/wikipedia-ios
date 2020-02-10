#import <WMF/UIScreen+WMFImageWidth.h>

@implementation UIScreen (WMFImageWidth)

- (NSInteger)wmf_maxScale {
    NSUInteger scaleMultiplierCeiling = 2;
    return MIN((NSUInteger)self.scale, scaleMultiplierCeiling);
}

- (NSNumber *)wmf_listThumbnailWidthForScale {
    return @(self.wmf_maxScale * WMFImageWidthExtraSmall);
}

- (NSNumber *)wmf_nearbyThumbnailWidthForScale {
    return @(self.wmf_maxScale * WMFImageWidthSmall);
}

- (NSNumber *)wmf_leadImageWidthForScale {
    return @(self.wmf_maxScale * WMFImageWidthMedium);
}

- (NSNumber *)wmf_potdImageWidthForScale {
    return @(self.wmf_maxScale * WMFImageWidthMedium);
}

- (NSInteger)wmf_galleryImageWidthForScale {
    return self.wmf_maxScale * WMFImageWidthLarge;
}

- (NSInteger)wmf_articleImageWidthForScale {
    return self.wmf_maxScale * WMFImageWidthMedium;
}

@end

@implementation UITraitCollection (WMFImageWidth)

- (NSInteger)wmf_maxScale {
    NSUInteger scaleMultiplierCeiling = 2;
    NSInteger scale = MIN((NSUInteger)self.displayScale, scaleMultiplierCeiling);
    if (scale == 0) {
        scale = 2;
    }
    return scale;
}

- (NSInteger)wmf_listThumbnailWidth {
    return self.wmf_maxScale * WMFImageWidthExtraSmall;
}

- (NSInteger)wmf_nearbyThumbnailWidth {
    return self.wmf_maxScale * WMFImageWidthSmall;
}

- (NSInteger)wmf_leadImageWidth {
    return self.wmf_maxScale * WMFImageWidthLarge;
}

- (NSInteger)wmf_potdImageWidth {
    return self.wmf_maxScale * WMFImageWidthMedium;
}

- (NSInteger)wmf_galleryImageWidth {
    return self.wmf_maxScale * WMFImageWidthLarge;
}

- (NSInteger)wmf_articleImageWidth {
    return self.wmf_maxScale * WMFImageWidthMedium;
}

@end
