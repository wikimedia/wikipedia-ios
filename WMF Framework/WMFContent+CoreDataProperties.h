#import <WMF/WMFContent+CoreDataClass.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFContent (CoreDataProperties)

+ (NSFetchRequest<WMFContent *> *)fetchRequest;

@property (nullable, nonatomic, retain) id<NSCoding> object;
@property (nullable, nonatomic, retain) WMFContentGroup *contentGroup;

@end

NS_ASSUME_NONNULL_END
