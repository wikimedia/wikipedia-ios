#import "WMFArticle+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest;

@property (nonatomic) BOOL blocked;
@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSDate *lastViewedDate;
@property (nullable, nonatomic, copy) NSDate *lastViewedCalendarDate;
@property (nullable, nonatomic, copy) NSString *lastViewedFragment;
@property (nonatomic) double lastViewedScrollPosition;
@property (nullable, nonatomic, copy) NSDate *newsNotificationDate;
@property (nullable, nonatomic, copy) NSDate *savedDate;
@property (nonatomic) BOOL wasSignificantlyViewed;

@end

NS_ASSUME_NONNULL_END
