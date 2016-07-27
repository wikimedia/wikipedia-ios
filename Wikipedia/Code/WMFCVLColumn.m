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
    copy.width = self.width;
    copy.height = self.height;
    copy.sectionIndexes = [self.sectionIndexes mutableCopy];
    copy.info = self.info;
    return copy;
}

- (void)addSection:(nonnull WMFCVLSection *)section {
    section.column = self;
    [self.sectionIndexes addIndex:section.index];
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.info.sections enumerateObjectsAtIndexes:self.sectionIndexes options:0 usingBlock:block];
}

- (void)updateHeightWithDelta:(CGFloat)deltaH {
    self.height += deltaH;
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
    [self enumerateSectionsWithBlock:^(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        if (section == afterSection) {
            update = YES;
        } else if (update) {
            [section offsetByDeltaY:deltaY withInvalidationContext:invalidationContext];
        }
    }];
}

@end