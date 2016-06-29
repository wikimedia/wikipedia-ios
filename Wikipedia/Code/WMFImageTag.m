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
        self.width = @([width integerValue]);
        self.height = @([height integerValue]);
        self.dataFileWidth = @([dataFileWidth integerValue]);
        self.dataFileHeight = @([dataFileHeight integerValue]);
    }
    return self;
}

+ (NSUInteger)minimumImageWidthForGalleryInclusion {
    return 80;
}

- (BOOL)isWideEnoughForGallery {
    NSUInteger minWidth = [WMFImageTag minimumImageWidthForGalleryInclusion];
    return self.width.integerValue > minWidth && self.dataFileWidth.integerValue > minWidth;
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
