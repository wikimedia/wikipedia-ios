#import "WMFArticlePreview+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePreview (CoreDataProperties)

+ (NSFetchRequest<WMFArticlePreview *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *key;
@property (nullable, nonatomic, copy) NSString *displayTitle;
@property (nullable, nonatomic, copy) NSString *wikidataDescription;
@property (nullable, nonatomic, copy) NSString *snippet;
@property (nullable, nonatomic, copy) NSString *thumbnailURLString;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nullable, nonatomic, retain) NSDictionary *pageViews;

@end

NS_ASSUME_NONNULL_END
