#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFAnnouncement : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly, nullable) NSString *identifier;
@property (nonatomic, strong, readonly, nullable) NSString *type;
@property (nonatomic, strong, readonly, nullable) NSDate *startTime;
@property (nonatomic, strong, readonly, nullable) NSDate *endTime;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *platforms;
@property (nonatomic, strong, readonly, nullable) NSArray<NSString *> *countries;

@property (nonatomic, strong, readonly, nullable) NSURL *imageURL;

@property (nonatomic, strong, readonly, nullable) NSString *text;

@property (nonatomic, strong, readonly, nullable) NSString *actionTitle;
@property (nonatomic, strong, readonly, nullable) NSURL *actionURL;

@property (nonatomic, strong, readonly, nullable) NSString *captionHTML;
@property (nonatomic, strong, readonly, nullable) NSAttributedString *caption;

@end

NS_ASSUME_NONNULL_END
