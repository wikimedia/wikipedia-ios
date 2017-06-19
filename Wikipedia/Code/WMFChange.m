#import "WMFChange.h"

@implementation WMFChange

- (NSString *)debugDescription {
    switch (self.type) {
        case NSFetchedResultsChangeInsert:
            return @"insert";
        case NSFetchedResultsChangeDelete:
            return @"delete";
        case NSFetchedResultsChangeMove:
            return @"move";
        default:
            return @"update";
    }
}

@end

@implementation WMFSectionChange

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ section %li", [super debugDescription], self.sectionIndex];
}

@end

@implementation WMFObjectChange

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@ object %@ to %@", [super debugDescription], self.fromIndexPath, self.toIndexPath];
}

@end
