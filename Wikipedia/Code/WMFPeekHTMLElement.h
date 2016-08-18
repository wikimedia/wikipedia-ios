#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WMFPeekElementType) {
    WMFPeekElementTypeUnpeekable,
    WMFPeekElementTypeAnchor,
    WMFPeekElementTypeImage
};

@interface WMFPeekHTMLElement : NSObject

@property (nonatomic, readonly) WMFPeekElementType type;
@property (nonatomic, strong, readonly, nullable) NSURL *url;

- (instancetype)initWithTagName:(NSString *)tagName src:(nullable NSString *)src href:(nullable NSString *)href NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END