#import <WMF/WMFImageTag+TargetImageWidthURL.h>
#import <WMF/WMFImageURLParsing.h>

@implementation WMFImageTag (TargetImageWidthURL)

/**
 *  Get URL to image as close to desired target width as possible.
 *
 *  @param targetWidth  The desired width for images.
 *
 *  @return The URL returned needs to be as close to equal to the targetWidth as possible. Because the image scaler will not scale raster images above their canonical resolution the URL returned here needs to sometimes be modified to just use the canonical URL.
 */
- (NSURL *)URLForTargetWidth:(NSInteger)targetWidth {
    if (targetWidth < 1) {
        targetWidth = 320;
    }

    NSString *tagSrc = self.src;

    NSInteger sizeFromSrcUrl = WMFParseSizePrefixFromSourceURL(tagSrc);

    if (sizeFromSrcUrl != NSNotFound) {

        // One of these widths was set for us to even get here.
        NSNumber *safeCanonicalWidthAssumption = self.dataFileWidth ? self.dataFileWidth : self.width;
        NSString *canonicalExtension = [[[tagSrc stringByDeletingLastPathComponent] lastPathComponent] pathExtension];

        if ([canonicalExtension isEqualToString:@"svg"]) {
            // Ok to use desired width on svg.
            safeCanonicalWidthAssumption = @(targetWidth);
        }

        // We know we have a "px-" thumb variant at this point. Get as close to the
        // targetWidth as we can.
        NSInteger width = MAX(sizeFromSrcUrl, safeCanonicalWidthAssumption.integerValue);
        width = MIN(width, targetWidth);

        if (width == self.dataFileWidth.integerValue) {
            // The scaler wont scale raster images greater *or equal* to their canonical width.
            // So we need to get rid of "/thumb/" path component and "px-" size prefix last
            // path component, but only if we're actually dealing with a "thumb" scaled variant.
            // This check for "/thumb/" is needed in case the canonical image name happens to
            // start with "XXXpx-", as the last image on "enwiki > Geothermal gradient" does.
            tagSrc = WMFOriginalImageURLStringFromURLString(tagSrc);
        } else {
            tagSrc = WMFChangeImageSourceURLSizePrefix(tagSrc, width);
        }
    } else {
        // If the url isn't scaled assume it is canonical and just keep it as-is.
        // By this point it has already been determined that it's big enough, but
        // we can't scale it down to the targetWidth because the url is not
        // pointing to the scaler's subfolder for this image's thumbs.
    }

    // Ensure urls consistently start with // and not just /.
    if (![tagSrc hasPrefix:@"//"]) {
        if ([tagSrc hasPrefix:@"/"]) {
            tagSrc = [@"/" stringByAppendingString:tagSrc];
        }
    }
    return [NSURL URLWithString:tagSrc];
}

@end
