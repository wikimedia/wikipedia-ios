#import <WMF/WMFMTLModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleRevision : WMFMTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSNumber *revisionId;

@property (nonatomic, assign, readonly, getter=isMinorEdit) BOOL minorEdit;

@property (nonatomic, assign, readonly) NSNumber *sizeInBytes;

@end

NS_ASSUME_NONNULL_END
