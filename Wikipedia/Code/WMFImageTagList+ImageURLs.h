#import <WMF/WMFImageTagList.h>

@interface WMFImageTagList (ImageURLs)

/**
 *  Gallery urls should use 'wmf_articleImageWidthForScale' so the gallery can immediately show images which have already been fetched/cached by the web view. The gallery will then lazily show higher resolution 'wmf_galleryImageWidthForScale' versions of the images. This is important for saved pages galleries to work properly as well.
 */
- (NSArray<NSURL *> *)imageURLsForGallery;

/**
 *  The urls for images to be saved should be the same as the urls used by the web view to display images in the article. Article images use 'wmf_articleImageWidthForScale', so we'll want to save those images, but we additionally want to save any smaller images.
 */
- (NSArray<NSURL *> *)imageURLsForSaving;

@end
