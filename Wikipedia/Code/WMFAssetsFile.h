#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, WMFAssetsFileType) {
    WMFAssetsFileTypeUndefined = 0,
    WMFAssetsFileTypeConfig,
    WMFAssetsFileTypeLanguages,
    WMFAssetsFileTypeMainPages
};

@interface WMFAssetsFile : NSObject

@property (nonatomic, readonly) WMFAssetsFileType fileType;

@property (nonatomic, retain, readonly) NSString* path;

@property (nonatomic, retain, readonly) NSArray* array;

@property (nonatomic, retain, readonly) NSDictionary* dictionary;

@property (nonatomic, retain, readonly) NSURL* url;

- (id)initWithFileType:(WMFAssetsFileType)file;

- (BOOL)isOlderThan:(NSTimeInterval)maxAge;

@end
