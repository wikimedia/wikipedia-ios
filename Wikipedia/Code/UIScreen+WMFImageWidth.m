#import <WMF/UIScreen+WMFImageWidth.h>

/**
 *  Image width buckets used to ensure image sizes don't vary too wildly.
 *
 *  This prevents us from fragmenting the image thumbnail caches on the back-end.
 */
typedef NS_ENUM(NSInteger, WMFImageWidth) {
    /**
     *  The smallest image width we will show, e.g. in search cell thumbnails.
     *
     *  There's no guarantee about image aspect ratio, so we fetch a little more and use aspect fill.
     */
    WMFImageWidthExtraSmall = 60,
    /**
     *  The next-smallest thumbnail we'll show, e.g. in nearby cell thumbnails.
     */
    WMFImageWidthSmall = 120,
    /**
     *  A medium width, e.g. POTD & lead images.
     */
    WMFImageWidthMedium = 320,
    /**
     *  A slightly larger width, e.g. modal gallery.
     */
    WMFImageWidthLarge = 640
};

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
