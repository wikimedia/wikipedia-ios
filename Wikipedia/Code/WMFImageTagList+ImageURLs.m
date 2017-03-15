#import "WMFImageTagList+ImageURLs.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "WMFImageTag.h"
#import <WMF/WMF-Swift.h>

@implementation WMFImageTagList (ImageURLs)

- (NSArray<NSURL *> *)imageURLsForGallery {
    return [[self.imageTags wmf_select:^BOOL(WMFImageTag *tag) {
        return [tag isSizeLargeEnoughForGalleryInclusion];
    }] wmf_map:^id(WMFImageTag *tag) {
        return [tag URLForTargetWidth:[[UIScreen mainScreen] wmf_articleImageWidthForScale]];
    }];
}

- (NSArray<NSURL *> *)imageURLsForSaving {
    return [self.imageTags wmf_map:^id(WMFImageTag *tag) {
        if ([tag isSizeLargeEnoughForGalleryInclusion]) {
            return [tag URLForTargetWidth:[[UIScreen mainScreen] wmf_articleImageWidthForScale]];
        } else {
            return [NSURL URLWithString:tag.src];
        }
    }];
}

@end
