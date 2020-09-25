#import <WMF/WMFMTLModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedImage : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, copy) NSString *canonicalPageTitle;

@property (nonatomic, readonly, copy) NSString *imageDescription;

@property (nonatomic, assign, readonly) BOOL imageDescriptionIsRTL;

@property (nonatomic, readonly, copy) NSURL *imageThumbURL;

@property (nonatomic, readonly, copy) NSURL *imageURL;

@property (nonatomic, readonly, copy, nullable) NSNumber *imageWidth;

@property (nonatomic, readonly, copy, nullable) NSNumber *imageHeight;

- (nullable NSURL *)getImageURLForWidth:(double)width height:(double)height;

@end

NS_ASSUME_NONNULL_END
