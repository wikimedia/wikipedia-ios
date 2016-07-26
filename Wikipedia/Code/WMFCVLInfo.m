#import "WMFCVLInfo.h"
#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"

@interface WMFCVLInfo ()
@property (nonatomic, strong, nonnull) NSMutableArray <WMFCVLColumn *> *columns;
@property (nonatomic, strong, nonnull) NSMutableArray <WMFCVLSection *> *sections;
@end

@implementation WMFCVLInfo

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns numberOfSections:(NSInteger)numberOfSections {
    self = [super init];
    if (self) {
        self.columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
        for (NSInteger i = 0; i < numberOfColumns; i++) {
            WMFCVLColumn *column = [WMFCVLColumn new];
            column.index = i;
            [_columns addObject:column];
        }
        
        self.sections = [NSMutableArray arrayWithCapacity:numberOfSections];
        for (NSInteger i = 0; i < numberOfSections; i++) {
            WMFCVLSection *section = [WMFCVLSection sectionWithIndex:i];
            [_sections addObject:section];
        }
    }
    return self;
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.columns enumerateObjectsUsingBlock:block];
}

- (nullable WMFCVLAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger sectionIndex = indexPath.section;
    
    if (sectionIndex < 0 || sectionIndex >= self.sections.count) {
        return nil;
    }
    
    WMFCVLSection *section = self.sections[sectionIndex];
    NSInteger itemIndex = indexPath.item;
    if (itemIndex < 0 || itemIndex >= section.items.count) {
        return nil;
    }
    
    WMFCVLAttributes *attributes = section.items[itemIndex];
    assert(attributes != nil);
    return attributes;
}

- (nullable WMFCVLAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSInteger sectionIndex = indexPath.section;
    if (sectionIndex < 0 || sectionIndex >= self.sections.count) {
        return nil;
    }
    
    WMFCVLSection *section = self.sections[sectionIndex];
    
    WMFCVLAttributes *attributes = nil;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        NSInteger itemIndex = indexPath.item;
        if (itemIndex < 0 || itemIndex >= section.headers.count) {
            return nil;
        }
        attributes = section.headers[itemIndex];
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        NSInteger itemIndex = indexPath.item;
        if (itemIndex < 0 || itemIndex >= section.footers.count) {
            return nil;
        }
        attributes = section.footers[itemIndex];
    }
    
    assert(attributes != nil);
    return attributes;
}

@end
