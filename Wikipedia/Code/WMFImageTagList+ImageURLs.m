#import "WMFImageTagList+ImageURLs.h"
#import "WMFImageTag+TargetImageWidthURL.h"
#import "WMFImageTag.h"
#import "UIScreen+WMFImageWidth.h"

@implementation WMFImageTagList (ImageURLs)

- (NSArray<NSURL*>*)imageURLsForGallery {
    return [[self.imageTags bk_select:^BOOL(WMFImageTag* tag){
        return [tag isWideEnoughForGallery];
    }] bk_map:^id(WMFImageTag* tag){
        return [tag urlForTargetWidth:[[UIScreen mainScreen] wmf_galleryImageWidthForScale].integerValue];
    }];
}

- (NSArray<NSURL*>*)imageURLsForSaving {
    return [self.imageTags bk_map:^id(WMFImageTag* tag){
        if ([tag isWideEnoughForGallery]) {
            return [tag urlForTargetWidth:[[UIScreen mainScreen] wmf_articleImageWidthForScale]];
        }else{
            return [NSURL URLWithString:tag.src];
        }
    }];
}

@end
