#import "WMFCVLSection.h"
#import "WMFCVLAttributes.h"
#import "WMFCVLColumn.h"
#import "WMFCVLInvalidationContext.h"

@interface WMFCVLSection ()
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *headers;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *footers;
@property (nonatomic, strong) NSMutableArray <WMFCVLAttributes *> *items;

- (void)offsetItemsStartingAtIndex:(NSInteger)itemIndex distance:(CGFloat)deltaY invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)offsetHeadersStartingAtIndex:(NSInteger)headerIndex distance:(CGFloat)deltaY invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;
- (void)offsetFootersStartingAtIndex:(NSInteger)footerIndex distance:(CGFloat)deltaY invalidationContext:(nonnull WMFCVLInvalidationContext *)invalidationContext;

- (BOOL)addOrUpdateAttributesAtIndex:(NSInteger)index inArray:(nonnull NSMutableArray *)array withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider attributesProvider:(nonnull WMFCVLAttributes * (^)(NSIndexPath *indexPath))attributesProvider;
- (CGFloat)setSize:(CGSize)size forAttributesAtIndex:(NSInteger)index inArray:(NSMutableArray *)attributes;
- (NSArray *)offsetAttributesInArray:(NSMutableArray *)attributes startingAtIndex:(NSInteger)index distance:(CGFloat)deltaY;

@end

@implementation WMFCVLSection

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.headers = [NSMutableArray array];
        self.footers = [NSMutableArray array];
        self.items = [NSMutableArray array];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WMFCVLSection *copy = [[WMFCVLSection allocWithZone:zone] init];
    copy.headers = [[NSMutableArray allocWithZone:zone] initWithArray:self.headers copyItems:YES];
    copy.footers = [[NSMutableArray allocWithZone:zone] initWithArray:self.footers copyItems:YES];
    copy.items = [[NSMutableArray allocWithZone:zone] initWithArray:self.items copyItems:YES];
    copy.index = self.index;
    copy.frame = self.frame;
    return copy;
}

+ (WMFCVLSection *)sectionWithIndex:(NSInteger)index {
    WMFCVLSection *section = [[WMFCVLSection alloc] init];
    section.index = index;
    return section;
}

- (BOOL)addOrUpdateItemAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider {
    return [self addOrUpdateAttributesAtIndex:index inArray:_items withFrameProvider:frameProvider attributesProvider:^WMFCVLAttributes *(NSIndexPath *indexPath) {
        return [WMFCVLAttributes layoutAttributesForCellWithIndexPath:indexPath];
    }];
}

- (BOOL)addOrUpdateHeaderAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider {
    return [self addOrUpdateAttributesAtIndex:index inArray:_headers withFrameProvider:frameProvider attributesProvider:^WMFCVLAttributes *(NSIndexPath *indexPath) {
        return [WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
    }];
}

- (BOOL)addOrUpdateFooterAtIndex:(NSInteger)index withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider {
    return [self addOrUpdateAttributesAtIndex:index inArray:_footers withFrameProvider:frameProvider attributesProvider:^WMFCVLAttributes *(NSIndexPath *indexPath) {
        return [WMFCVLAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:indexPath];
    }];
}

- (void)enumerateLayoutAttributesWithBlock:(void(^)(WMFCVLAttributes *layoutAttributes, BOOL *stop))block {
    __block BOOL bigStop = NO;
    
    [self.headers enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
    
    if (bigStop) {
        return;
    }
    [self.items enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
    
    if (bigStop) {
        return;
    }
    
    [self.footers enumerateObjectsUsingBlock:^(WMFCVLAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, &bigStop);
        *stop = bigStop;
    }];
}

- (void)offsetByDeltaY:(CGFloat)deltaY withInvalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    self.frame = CGRectOffset(self.frame, 0, deltaY);
    [self offsetHeadersStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
    [self offsetItemsStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
    [self offsetFootersStartingAtIndex:0 distance:deltaY invalidationContext:invalidationContext];
}

- (CGFloat)setSize:(CGSize)size forHeaderAtIndex:(NSInteger)headerIndex invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:headerIndex inArray:_headers];
    
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:@[[NSIndexPath indexPathForItem:headerIndex inSection:self.index]]];
    [self offsetHeadersStartingAtIndex:headerIndex + 1 distance:deltaH invalidationContext:invalidationContext];
    [self offsetItemsStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
    [self offsetFootersStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
    
    return deltaH;
}

- (CGFloat)setSize:(CGSize)size forFooterAtIndex:(NSInteger)footerIndex invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:footerIndex inArray:_footers];
    
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:@[[NSIndexPath indexPathForItem:footerIndex inSection:self.index]]];
    [self offsetFootersStartingAtIndex:footerIndex + 1 distance:deltaH invalidationContext:invalidationContext];

    return deltaH;
}

- (CGFloat)setSize:(CGSize)size forItemAtIndex:(NSInteger)index invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    CGFloat deltaH = [self setSize:size forAttributesAtIndex:index inArray:_items];

    [invalidationContext invalidateItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:self.index]]];
    [self offsetItemsStartingAtIndex:index + 1 distance:deltaH invalidationContext:invalidationContext];
    [self offsetFootersStartingAtIndex:0 distance:deltaH invalidationContext:invalidationContext];
    
    return deltaH;
}


#pragma mark - Internal

- (void)offsetHeadersStartingAtIndex:(NSInteger)headerIndex distance:(CGFloat)deltaY invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSArray *invalidatedHeaderIndexPaths = [self offsetAttributesInArray:_headers startingAtIndex:headerIndex distance:deltaY];
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionHeader atIndexPaths:invalidatedHeaderIndexPaths];
}

- (void)offsetItemsStartingAtIndex:(NSInteger)itemIndex distance:(CGFloat)deltaY invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSArray *invalidatedItemIndexPaths = [self offsetAttributesInArray:_items startingAtIndex:itemIndex distance:deltaY];
    [invalidationContext invalidateItemsAtIndexPaths:invalidatedItemIndexPaths];
}

- (void)offsetFootersStartingAtIndex:(NSInteger)footerIndex distance:(CGFloat)deltaY invalidationContext:(WMFCVLInvalidationContext *)invalidationContext {
    NSArray *invalidatedFooterIndexPaths = [self offsetAttributesInArray:_footers startingAtIndex:footerIndex distance:deltaY];
    [invalidationContext invalidateSupplementaryElementsOfKind:UICollectionElementKindSectionFooter atIndexPaths:invalidatedFooterIndexPaths];
}

- (BOOL)addOrUpdateAttributesAtIndex:(NSInteger)index inArray:(nonnull NSMutableArray *)array withFrameProvider:(nonnull CGRect (^)(BOOL wasCreated, CGRect existingFrame))frameProvider attributesProvider:(nonnull WMFCVLAttributes * (^)(NSIndexPath *indexPath))attributesProvider {
    if (index >= array.count) {
        CGRect frame = frameProvider(YES, CGRectZero);
        WMFCVLAttributes *attributes = attributesProvider([NSIndexPath indexPathForItem:index inSection:self.index]);
        attributes.frame = frame;
        if (attributes != nil) {
            [array addObject:attributes];
        }
        return YES;
    } else {
        WMFCVLAttributes *attributes = array[index];
        CGRect newFrame = frameProvider(NO, attributes.frame);
        if (CGRectEqualToRect(newFrame, attributes.frame)) {
            return NO;
        } else {
            WMFCVLAttributes *attributes = array[index];
            attributes.frame = newFrame;
            return YES;
        }
    }
}

- (CGFloat)setSize:(CGSize)size forAttributesAtIndex:(NSInteger)index inArray:(NSMutableArray *)array {
    WMFCVLAttributes *attributes = array[index];
    
    if (CGSizeEqualToSize(size, attributes.frame.size)) {
        return 0;
    }
    
    CGFloat deltaH = size.height - attributes.frame.size.height;
    attributes.frame = (CGRect) {.origin = attributes.frame.origin, .size = size};
    
    CGSize newSize = self.frame.size;
    newSize.height += deltaH;
    self.frame = (CGRect){self.frame.origin, newSize};
    
    return deltaH;
}

- (NSArray *)offsetAttributesInArray:(NSMutableArray *)array startingAtIndex:(NSInteger)index distance:(CGFloat)deltaY {
    NSInteger count = array.count - index;
    if (count <= 0) {
        return nil;
    }
    NSMutableArray *invalidatedIndexPaths = [NSMutableArray arrayWithCapacity:count];
    while (index < array.count) {
        WMFCVLAttributes *attributes = array[index];
        attributes.frame = CGRectOffset(attributes.frame, 0, deltaY);
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:self.index];
        [invalidatedIndexPaths addObject:indexPath];
        index++;
    }
    return invalidatedIndexPaths;
}

- (void)trimItemsToCount:(NSInteger)count {
    [_items removeObjectsInRange:NSMakeRange(count, _items.count - count)];
}

@end