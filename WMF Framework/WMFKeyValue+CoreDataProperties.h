#import <WMF/WMFKeyValue+CoreDataClass.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFKeyValue (CoreDataProperties)

+ (NSFetchRequest<WMFKeyValue *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSString *group;
@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, retain) id<NSCoding> value;

@end

NS_ASSUME_NONNULL_END
