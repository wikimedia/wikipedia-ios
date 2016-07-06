#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static CGSize const WMFImageTagMinimumSizeForGalleryInclusion = {64, 64};

@interface WMFImageTag : NSObject

@property (nonatomic, strong, readonly) NSString* src;
@property (nonatomic, strong, readonly, nullable) NSString* srcset;
@property (nonatomic, strong, readonly, nullable) NSString* alt;
@property (nonatomic, strong, readonly, nullable) NSNumber* width;
@property (nonatomic, strong, readonly, nullable) NSNumber* height;
@property (nonatomic, strong, readonly, nullable) NSNumber* dataFileWidth;
@property (nonatomic, strong, readonly, nullable) NSNumber* dataFileHeight;

- (instancetype)initWithSrc:(NSString*)src
                     srcset:(nullable NSString*)srcset
                        alt:(nullable NSString*)alt
                      width:(nullable NSString*)width
                     height:(nullable NSString*)height
              dataFileWidth:(nullable NSString*)dataFileWidth
             dataFileHeight:(nullable NSString*)dataFileHeight NS_DESIGNATED_INITIALIZER;

- (BOOL)isSizeLargeEnoughForGalleryInclusion;

@end

NS_ASSUME_NONNULL_END
