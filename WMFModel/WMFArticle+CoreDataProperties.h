#import "WMFArticle+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFArticle (CoreDataProperties)

+ (NSFetchRequest<WMFArticle *> *)fetchRequest;

@property (nonatomic) BOOL isBlocked;
@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSDate *viewedDate;
@property (nullable, nonatomic, copy) NSDate *viewedCalendarDate;
@property (nullable, nonatomic, copy) NSString *viewedFragment;
@property (nonatomic) double viewedScrollPosition;
@property (nullable, nonatomic, copy) NSDate *newsNotificationDate;
@property (nullable, nonatomic, copy) NSDate *savedDate;
@property (nonatomic) BOOL wasSignificantlyViewed;

@end

NS_ASSUME_NONNULL_END
