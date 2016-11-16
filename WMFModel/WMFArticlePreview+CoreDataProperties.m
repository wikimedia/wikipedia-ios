#import "WMFArticlePreview+CoreDataProperties.h"

@implementation WMFArticlePreview (CoreDataProperties)

+ (NSFetchRequest<WMFArticlePreview *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"WMFArticlePreview"];
}

@dynamic key;
@dynamic displayTitle;
@dynamic wikidataDescription;
@dynamic snippet;
@dynamic thumbnailURLString;
@dynamic latitude;
@dynamic longitude;
@dynamic pageViews;

@end
