
#import "WMFBottomStackLayout.h"
#import <BlocksKit/BlocksKit.h>

@interface WMFBottomStackLayout ()

@property (nonatomic, strong) NSArray* visibleIndexPaths;

@end


@implementation WMFBottomStackLayout

#pragma mark - Setup

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDefualts];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefualts];
    }
    return self;
}

- (void)setupDefualts{
    
    self.minimumLineSpacing      = 0.0f;
    self.minimumInteritemSpacing = 0.0f;
    self.scrollDirection         = UICollectionViewScrollDirectionVertical;

    _topCardExposedHeight = 40.0;
    _overlapSpacing = 4;
}

#pragma mark - Accessors

- (void)setOverlapSpacing:(CGFloat)closedStackSpacing {
    if (_overlapSpacing != closedStackSpacing) {
        _overlapSpacing = closedStackSpacing;
        [self invalidateLayout];
    }
}

- (void)setTopCardExposedHeight:(CGFloat)topCardExposedHeight{
    if (_topCardExposedHeight != topCardExposedHeight) {
        _topCardExposedHeight = topCardExposedHeight;
        [self invalidateLayout];
    }
}

#pragma mark - UICollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    
    NSArray* items = [self.visibleIndexPaths bk_map:^id(id obj) {
        
        return [self layoutAttributesForItemAtIndexPath:obj];
    }];

    return items;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewLayoutAttributes* item = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self adjustLayoutAttributes:item];
    return item;
    
}

- (void)adjustLayoutAttributes:(UICollectionViewLayoutAttributes*)attributes{
    
    CGFloat spacingForIndexPath;
    
    //Stagger the first 2 cards, then stack the rest behind
    if([self.visibleIndexPaths indexOfObject:attributes.indexPath] < 2){
        spacingForIndexPath = (self.overlapSpacing * [self.visibleIndexPaths indexOfObject:attributes.indexPath]);
    }else{
        spacingForIndexPath = (self.overlapSpacing * 2);
    }
    
    CGFloat topCardYOffset = CGRectGetHeight(self.collectionView.bounds)-self.topCardExposedHeight;
    CGRect frame = attributes.frame;
    frame.origin.y = topCardYOffset + spacingForIndexPath;
    attributes.frame = frame;
    attributes.zIndex = attributes.indexPath.item;
}

- (CGSize)collectionViewContentSize{
    
    return self.collectionView.bounds.size;
}

- (void)prepareForTransitionFromLayout:(UICollectionViewLayout *)oldLayout{
    
    self.visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
}

@end
