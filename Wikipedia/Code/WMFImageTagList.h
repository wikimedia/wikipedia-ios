@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class WMFImageTag;

@interface WMFImageTagList : NSObject

@property (nonatomic, strong, readonly, nullable) NSArray<WMFImageTag *> *imageTags;

- (instancetype)initWithImageTags:(nullable NSArray<WMFImageTag *> *)imageTags NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
