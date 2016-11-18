
#import <Mantle/Mantle.h>

@interface WMFAnnouncement : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, strong, readonly) NSDate *startTime;
@property (nonatomic, strong, readonly) NSDate *endTime;
@property (nonatomic, strong, readonly) NSArray<NSString *> *platforms;
@property (nonatomic, strong, readonly) NSArray<NSString *> *countries;

@property (nonatomic, strong, readonly) NSString *text;

@property (nonatomic, strong, readonly) NSString *actionTitle;
@property (nonatomic, strong, readonly) NSURL *actionURL;

@property (nonatomic, strong, readonly) NSString *captionHTML;

@end
