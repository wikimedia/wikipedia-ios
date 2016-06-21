#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFPeekHTMLElement : NSObject

@property (nonatomic, strong) NSString* tagName;
@property (nonatomic, strong, nullable) NSString* src;
@property (nonatomic, strong, nullable) NSString* href;

- (instancetype)initWithTagName:(NSString*)tagName src:(nullable NSString*)src href:(nullable NSString*)href NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END