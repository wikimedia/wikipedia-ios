#import "WMFArticle+CoreDataClass.h"
#import <WMF/WMF-Swift.h>

@interface WMFArticle () {
    NSArray<ReadingList *> * _Nullable _sortedNonDefaultReadingLists;
}
@end

@implementation WMFArticle

- (NSNumber *)ns {
    NSNumber *primitiveNS = [self primitiveValueForKey:@"ns"];
    if (!primitiveNS) {
        primitiveNS = self.namespaceNumber;
        [self setPrimitiveValue:primitiveNS forKey:@"ns"];
    }
    return primitiveNS;
}


- (NSArray<ReadingList *> *)sortedNonDefaultReadingLists {
    @synchronized (self) {
        if (_sortedNonDefaultReadingLists != nil) {
            return _sortedNonDefaultReadingLists;
        }
        _sortedNonDefaultReadingLists = [[self.readingLists filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"isDefault == NO"]] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"canonicalName" ascending:YES comparator:^NSComparisonResult(NSString *a, NSString *b) {
            if (a == nil) {
                return NSOrderedAscending;
            }
            if (b == nil) {
                return NSOrderedDescending;
            }
            return [a localizedStandardCompare:b];
        }]]];
        return _sortedNonDefaultReadingLists ?: @[];
    }
}

- (void)didChangeValueForKey:(NSString *)inKey withSetMutation:(NSKeyValueSetMutationKind)inMutationKind usingObjects:(NSSet *)inObjects {
    [super didChangeValueForKey:inKey withSetMutation:inMutationKind usingObjects:inObjects];
    if (![inKey isEqualToString:@"readingLists"]) {
        return;
    }
    @synchronized (self) {
        _sortedNonDefaultReadingLists = nil;
    }
}

@end
