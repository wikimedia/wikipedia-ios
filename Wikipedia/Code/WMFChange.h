#import <Foundation/Foundation.h>

@interface WMFChange : NSObject
@property (nonatomic) NSFetchedResultsChangeType type;
@end

@interface WMFSectionChange : WMFChange
@property (nonatomic) NSInteger sectionIndex;
@end

@interface WMFObjectChange : WMFChange
@property (nonatomic, strong) NSIndexPath *fromIndexPath;
@property (nonatomic, strong) NSIndexPath *toIndexPath;
@end
