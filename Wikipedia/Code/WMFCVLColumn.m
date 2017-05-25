#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLInvalidationContext.h"
#import "WMFCVLInfo.h"

@interface WMFCVLColumn ()
@property (nonatomic, strong, nonnull) NSMutableIndexSet *sectionIndexes;
@end

@implementation WMFCVLColumn

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sectionIndexes = [NSMutableIndexSet indexSet];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLColumn *copy = [[WMFCVLColumn allocWithZone:zone] init];
    copy.index = self.index;
    copy.frame = self.frame;
    copy.sectionIndexes = [self.sectionIndexes mutableCopy];
    copy.info = self.info;
    return copy;
}

- (NSInteger)sectionCount {
    return _sectionIndexes.count;
}

- (void)addSection:(nonnull WMFCVLSection *)section {
    section.columnIndex = self.index;
    [self.sectionIndexes addIndex:section.index];
}

- (void)removeSection:(nonnull WMFCVLSection *)section {
    [self.sectionIndexes removeIndex:section.index];
}

- (void)removeSectionsWithSectionIndexesInRange:(NSRange)range {
    [self.sectionIndexes removeIndexesInRange:range];
}

- (BOOL)containsSectionWithSectionIndex:(NSInteger)sectionIndex {
    return [self.sectionIndexes containsIndex:sectionIndex];
}

- (nullable WMFCVLSection *)lastSection {
    if (self.sectionIndexes.count == 0) {
        return nil;
    } else {
        return self.info.sections[[self.sectionIndexes lastIndex]];
    }
}

- (void)enumerateSectionsWithBlock:(nonnull void (^)(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop))block {
    [self.info.sections enumerateObjectsAtIndexes:self.sectionIndexes options:0 usingBlock:block];
}

- (void)updateHeightWithDelta:(CGFloat)deltaH {
    CGRect newFrame = self.frame;
    newFrame.size.height += deltaH;
    self.frame = newFrame;
}

- (void)setSize:(CGSize)size forHeaderAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;

    WMFCVLSection *section = self.info.sections[sectionIndex];
    CGFloat deltaY = [section setSize:size forHeaderAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];

    [self updateHeightWithDelta:deltaY];
}

- (void)setSize:(CGSize)size forFooterAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;

    WMFCVLSection *section = self.info.sections[sectionIndex];
    CGFloat deltaY = [section setSize:size forFooterAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];

    [self updateHeightWithDelta:deltaY];
}

- (void)setSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;

    if (sectionIndex >= self.info.sections.count) {
        return;
    }

    WMFCVLSection *section = self.info.sections[sectionIndex];
    CGFloat deltaY = [section setSize:size forItemAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];

    [self updateHeightWithDelta:deltaY];
}

- (void)offsetSectionsByDistance:(CGFloat)deltaY startingAfterSection:(WMFCVLSection *)afterSection invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    if (ABS(deltaY) == 0) {
        return;
    }

    __block BOOL update = NO;
    [self enumerateSectionsWithBlock:^(WMFCVLSection *_Nonnull section, NSUInteger idx, BOOL *_Nonnull stop) {
        if (section == afterSection) {
            update = YES;
        } else if (update) {
            [section offsetByDeltaY:deltaY withInvalidationContext:invalidationContext];
        }
    }];
}

@end
