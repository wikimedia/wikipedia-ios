#import <CoreData/CoreData.h>

@interface WMFChange : NSObject
@property (nonatomic) NSFetchedResultsChangeType type;
@end

@interface WMFSectionChange : WMFChange
@property (nonatomic) NSInteger sectionIndex;
@end

@interface WMFObjectChange : WMFChange
@property (nullable, nonatomic, strong) NSIndexPath *fromIndexPath;
@property (nullable, nonatomic, strong) NSIndexPath *toIndexPath;
@end
