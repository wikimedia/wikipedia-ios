#import <WMF/WMFContentGroup+CoreDataClass.h>
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@interface WMFContentGroup (CoreDataProperties)

+ (NSFetchRequest<WMFContentGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSDate *midnightUTCDate;
@property (nullable, nonatomic, copy) NSDate *contentMidnightUTCDate;
@property (nullable, nonatomic, copy) NSDate *contentDate;

@property (nullable, nonatomic, copy) NSString *siteURLString;
@property (nullable, nonatomic, copy) NSString *variant;

@property (nonatomic) int32_t contentGroupKindInteger;
@property (nonatomic) int16_t contentTypeInteger;

@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL wasDismissed;

@property (nullable, nonatomic, copy) id<NSCoding> contentPreview;

@property (nonatomic) int32_t dailySortPriority;

@property (nullable, nonatomic, copy) NSString *articleURLString;
@property (nullable, nonatomic, copy) NSString *featuredContentIdentifier;

@property (nullable, nonatomic, retain) CLLocation *location;
@property (nullable, nonatomic, retain) CLPlacemark *placemark;

@property (nullable, nonatomic, retain) NSNumber *countOfFullContent;
@property (nullable, nonatomic, retain) WMFContent *fullContent;

@property (nonatomic)  int16_t undoTypeInteger;

@property (nullable, nonatomic, copy) NSString *placement;

@end

NS_ASSUME_NONNULL_END
