#import <WMF/WMFMTLModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFAnnouncement : WMFMTLModel <MTLJSONSerializing>

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
@property (nonatomic, copy, readonly, nullable) NSString *actionURLString;

@property (nonatomic, copy, readonly, nullable) NSString *captionHTML;
@property (nonatomic, copy, readonly, nullable) NSString *negativeText;

@property (nonatomic, copy, readonly, nullable) NSNumber *readingListSyncEnabled;
@property (nonatomic, copy, readonly, nullable) NSNumber *loggedIn;
@property (nonatomic, copy, readonly, nullable) NSNumber *beta;

@property (nonatomic, copy, readonly, nullable) NSString *domain;

//only applies to survey types
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *articleTitles;
@property(nonatomic, copy, readonly, nullable) NSNumber *percentReceivingExperiment;
@property (nonatomic, strong, readonly, nullable) NSNumber *displayDelay;

@end

NS_ASSUME_NONNULL_END
