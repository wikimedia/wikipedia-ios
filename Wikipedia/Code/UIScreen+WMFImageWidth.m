#import "UIScreen+WMFImageWidth.h"
#import <Tweaks/FBTweakInline.h>

/**
 *  Image width buckets used to ensure image sizes don't vary too wildly.
 *
 *  This prevents us from fragmenting the image thumbnail caches on the back-end.
 */
typedef NS_ENUM(NSUInteger, WMFImageWidth) {
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

- (NSUInteger)wmf_maxScale {
    NSUInteger scaleMultiplierCeiling = 2; /* FBTweakValue(@"Images", @"Scale multiplier", @"Ceiling", 2, 1, 3);*/
    // Reminder: "MIN" is intentional - we're setting scale multipler cap to 2.
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

- (NSNumber *)wmf_galleryImageWidthForScale {
    return @(self.wmf_maxScale * WMFImageWidthLarge);
}

- (NSUInteger)wmf_articleImageWidthForScale {
    return self.wmf_maxScale * WMFImageWidthMedium;
}

@end
