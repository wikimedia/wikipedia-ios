
#import <Foundation/Foundation.h>

@class WMFMediaObject;

@protocol WMFMediaDelegate;

#pragma mark - container for video URLs

@interface WMFMedia : NSObject

@property (nonatomic, readonly) WMFMediaObject *lowQualityMediaObject;
@property (nonatomic, readonly) WMFMediaObject *highQualityMediaObject;

@property (nonatomic, readonly) NSArray<WMFMediaObject *> *sortedMediaObjects;

- (instancetype)initWithJSONData:(NSData *)json;

- (instancetype)initWithTitles:(NSString *)titles withAsyncDelegate:(id<WMFMediaDelegate>)delegate;

@end

#pragma mark - meta info about video

@interface WMFMediaObject : NSObject

@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;

@end

#pragma mark - async delegate

@protocol WMFMediaDelegate <NSObject>

- (void)wmf_MediaSuccess:(WMFMedia *)media;

- (void)wmf_MediaFailed:(WMFMedia *)media;

@end
