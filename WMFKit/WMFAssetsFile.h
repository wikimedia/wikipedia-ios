#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WMFAssetsFileType) {
    WMFAssetsFileTypeUndefined = 0,
    WMFAssetsFileTypeConfig,
    WMFAssetsFileTypeLanguages,
    WMFAssetsFileTypeMainPages
};

@interface WMFAssetsFile : NSObject

@property (nonatomic, readonly) WMFAssetsFileType fileType;

@property (nonatomic, strong, readonly) NSString *path;

@property (nonatomic, strong, readonly) NSArray *array;

@property (nonatomic, strong, readonly) NSDictionary *dictionary;

@property (nonatomic, strong, readonly) NSURL *url;

- (id)initWithFileType:(WMFAssetsFileType)file;

- (BOOL)isOlderThan:(NSTimeInterval)maxAge;

@end
