#import "WMFImageTag.h"

NS_ASSUME_NONNULL_BEGIN

@interface WMFImageTag()

@property (nonatomic, strong, readwrite) NSString* src;
@property (nonatomic, strong, readwrite, nullable) NSString* srcset;
@property (nonatomic, strong, readwrite, nullable) NSString* alt;
@property (nonatomic, strong, readwrite, nullable) NSNumber* width;
@property (nonatomic, strong, readwrite, nullable) NSNumber* height;
@property (nonatomic, strong, readwrite, nullable) NSNumber* dataFileWidth;
@property (nonatomic, strong, readwrite, nullable) NSNumber* dataFileHeight;

@end

@implementation WMFImageTag

- (instancetype)initWithSrc:(NSString*)src
                     srcset:(nullable NSString*)srcset
                        alt:(nullable NSString*)alt
                      width:(nullable NSString*)width
                     height:(nullable NSString*)height
              dataFileWidth:(nullable NSString*)dataFileWidth
             dataFileHeight:(nullable NSString*)dataFileHeight
{
    self = [super init];
    if (self) {

        // Strip protocol for consistency.
        if ([src hasPrefix:@"http:"]){
            src = [src substringFromIndex:5];
        }else if ([src hasPrefix:@"https:"]){
            src = [src substringFromIndex:6];
        }

        self.src = src;
        self.srcset = srcset;
        self.alt = alt;
        self.width = [width isEqual:[NSNull null]] ? nil : @([width integerValue]);
        self.height = [height isEqual:[NSNull null]] ? nil : @([height integerValue]);
        self.dataFileWidth = [dataFileWidth isEqual:[NSNull null]] ? nil : @([dataFileWidth integerValue]);
        self.dataFileHeight = [dataFileHeight isEqual:[NSNull null]] ? nil : @([dataFileHeight integerValue]);
    }
    return self;
}

- (BOOL)isSizeLargeEnoughForGalleryInclusion {
    return
    // Ensure images which are just used as tiny icons are not included in gallery.
    self.width.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.width &&
    self.height.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.height &&
    // Also make sure we only try to show them in the gallery if their canonical size is of sufficient resolution.
    self.dataFileWidth.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.width &&
    self.dataFileHeight.integerValue >= WMFImageTagMinimumSizeForGalleryInclusion.height;
}

- (NSString*)description {
    return [NSString stringWithFormat:@""
            "\n\n "
            "image tag: \n\t "
            "src = %@ \n\t "
            "srcset = %@ \n\t "
            "alt = %@ \n\t "
            "width = %@ \n\t "
            "height = %@ \n\t "
            "dataFileWidth = %@ \n\t "
            "dataFileHeight = %@ \n",
            self.src,
            self.srcset,
            self.alt,
            self.width,
            self.height,
            self.dataFileWidth,
            self.dataFileHeight];
}

@end

NS_ASSUME_NONNULL_END
