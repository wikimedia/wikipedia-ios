#import <WMF/WMFImageTagList.h>
#import <WMF/WMFImageTag.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFImageTagList ()

@property (nonatomic, strong, readwrite, nullable) NSArray<WMFImageTag *> *imageTags;

@end

@implementation WMFImageTagList

- (instancetype)initWithImageTags:(nullable NSArray<WMFImageTag *> *)imageTags {
    self = [super init];
    if (self) {
        self.imageTags = imageTags;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
