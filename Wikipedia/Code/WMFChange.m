#import "WMFChange.h"

@implementation WMFChange

- (NSString *)description {
    NSString *superDescription = [super description];
    NSString *changeTypeString = nil;
    switch (self.type) {
        case NSFetchedResultsChangeInsert:
            changeTypeString = @"insert";
            break;
        case NSFetchedResultsChangeDelete:
            changeTypeString = @"delete";
            break;
        case NSFetchedResultsChangeMove:
            changeTypeString = @"move";
            break;
        default:
            changeTypeString = @"update";
    }
    return [NSString stringWithFormat:@"%@ %@", superDescription, changeTypeString];
}

@end

@implementation WMFSectionChange

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ section %li", [super description], (long)self.sectionIndex];
}

@end

@implementation WMFObjectChange

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ object %@ to %@", [super description], self.fromIndexPath, self.toIndexPath];
}

@end
