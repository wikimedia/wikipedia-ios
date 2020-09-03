#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFAnnouncement : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, readonly, nullable) NSString *identifier;
@property (nonatomic, copy, readonly, nullable) NSString *type;
@property (nonatomic, copy, readonly, nullable) NSDate *startTime;
@property (nonatomic, copy, readonly, nullable) NSDate *endTime;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *platforms;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *countries;
@property (nonatomic, copy, readonly, nullable) NSString *placement;

@property (nonatomic, copy, readonly, nullable) NSURL *imageURL;
@property (nonatomic, copy, readonly, nullable) NSNumber *imageHeight;

@property (nonatomic, copy, readonly, nullable) NSString *text;

@property (nonatomic, copy, readonly, nullable) NSString *actionTitle;
@property (nonatomic, copy, readonly, nullable) NSURL *actionURL;

@property (nonatomic, copy, readonly, nullable) NSString *captionHTML;
@property (nonatomic, copy, readonly, nullable) NSString *negativeText;

@property (nonatomic, copy, readonly, nullable) NSNumber *readingListSyncEnabled;
@property (nonatomic, copy, readonly, nullable) NSNumber *loggedIn;
@property (nonatomic, copy, readonly, nullable) NSNumber *beta;

@end

NS_ASSUME_NONNULL_END
