#import "WMFImageTagList+ImageURLs.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "WMFImageTag.h"

@implementation WMFImageTagList (ImageURLs)

- (NSArray<NSURL *> *)imageURLsForGallery {
    return [[self.imageTags bk_select:^BOOL(WMFImageTag *tag) {
        return [tag isSizeLargeEnoughForGalleryInclusion];
    }] bk_map:^id(WMFImageTag *tag) {
        return [tag URLForTargetWidth:[[UIScreen mainScreen] wmf_articleImageWidthForScale]];
    }];
}

- (NSArray<NSURL *> *)imageURLsForSaving {
    return [self.imageTags bk_map:^id(WMFImageTag *tag) {
        if ([tag isSizeLargeEnoughForGalleryInclusion]) {
            return [tag URLForTargetWidth:[[UIScreen mainScreen] wmf_articleImageWidthForScale]];
        } else {
            return [NSURL URLWithString:tag.src];
        }
    }];
}

@end
