#import "WMFCVLColumn.h"
#import "WMFCVLSection.h"
#import "WMFCVLInvalidationContext.h"

@interface WMFCVLColumn ()
@property (nonatomic, strong, nonnull) NSMutableArray <WMFCVLSection *> *sections;
@property (nonatomic, strong, nonnull) NSMutableDictionary <NSNumber *, WMFCVLSection *> *sectionsByIndex;
@end

@implementation WMFCVLColumn

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sections = [NSMutableArray array];
        self.sectionsByIndex = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addSection:(nonnull WMFCVLSection *)section {
    section.column = self;
    self.sectionsByIndex[@(section.index)] = section;
    [self.sections addObject:section];
}

- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block {
    [self.sections enumerateObjectsUsingBlock:block];
}

- (void)setSize:(CGSize)size forHeaderAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forHeaderAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)setSize:(CGSize)size forFooterAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forFooterAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)setSize:(CGSize)size forItemAtIndexPath:(NSIndexPath *)indexPath invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSInteger sectionIndex = indexPath.section;
    
    WMFCVLSection *section = self.sectionsByIndex[@(sectionIndex)];
    CGFloat deltaY = [section setSize:size forItemAtIndex:indexPath.item invalidationContext:invalidationContext];
    [self offsetSectionsByDistance:deltaY startingAfterSection:section invalidationContext:invalidationContext];
    self.height += deltaY;
    invalidationContext.contentSizeAdjustment = CGSizeMake(0, deltaY);
}

- (void)offsetSectionsByDistance:(CGFloat)deltaY startingAfterSection:(WMFCVLSection *)afterSection invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    if (ABS(deltaY) == 0) {
        return;
    }
    
    BOOL update = NO;
    for (WMFCVLSection *section in self.sections) {
        if (section == afterSection) {
            update = YES;
        } else if (update) {
            [section offsetByDeltaY:deltaY withInvalidationContext:invalidationContext];
        }
    }
}

@end