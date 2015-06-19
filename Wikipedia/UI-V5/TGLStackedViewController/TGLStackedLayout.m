//
//  TGLStackedLayout.m
//  TGLStackedViewController
//
//  Created by Tim Gleue on 07.04.14.
//  Copyright (c) 2014 Tim Gleue ( http://gleue-interactive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "TGLStackedLayout.h"

#define MOVE_ZOOM 0.95

#define SCROLL_PER_FRAME 5.0
#define SCROLL_ZONE_TOP 100.0
#define SCROLL_ZONE_BOTTOM 100.0

typedef NS_ENUM (NSInteger, TGLStackedViewControllerScrollDirection) {
    TGLStackedViewControllerScrollDirectionNone = 0,
    TGLStackedViewControllerScrollDirectionDown,
    TGLStackedViewControllerScrollDirectionUp
};

@interface TGLStackedLayout ()<UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIView* movingView;
@property (strong, nonatomic) UILongPressGestureRecognizer* moveGestureRecognizer;

@property (assign, nonatomic) TGLStackedViewControllerScrollDirection scrollDirection;
@property (strong, nonatomic) CADisplayLink* scrollDisplayLink;

@property (nonatomic, strong) UIPanGestureRecognizer* deletePanGesture;
@property (nonatomic, strong) NSIndexPath* panningIndexPath;
@property (nonatomic, strong) NSIndexPath* deletingIndexPath;

@property (nonatomic, strong) NSDictionary* layoutAttributes;

// Set to YES when layout is currently arranging
// items so that they evenly fill entire height
//
@property (nonatomic, assign) BOOL filling;

@end

@implementation TGLStackedLayout

- (instancetype)init {
    self = [super init];

    if (self) {
        [self initLayout];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self initLayout];
    }

    return self;
}

- (void)initLayout {
    self.layoutMargin = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0);
    self.topReveal    = 120.0;
    self.bounceFactor = 0.2;
}

#pragma mark - Accessors

- (void)setLayoutMargin:(UIEdgeInsets)margins {
    if (!UIEdgeInsetsEqualToEdgeInsets(margins, self.layoutMargin)) {
        _layoutMargin = margins;

        [self invalidateLayout];
    }
}

- (void)setTopReveal:(CGFloat)topReveal {
    if (topReveal != self.topReveal) {
        _topReveal = topReveal;

        [self invalidateLayout];
    }
}

- (void)setItemSize:(CGSize)itemSize {
    if (!CGSizeEqualToSize(itemSize, self.itemSize)) {
        _itemSize = itemSize;

        [self invalidateLayout];
    }
}

- (void)setBounceFactor:(CGFloat)bounceFactor {
    if (bounceFactor != self.bounceFactor) {
        _bounceFactor = bounceFactor;

        [self invalidateLayout];
    }
}

- (void)setFillHeight:(BOOL)fillHeight {
    if (fillHeight != self.isFillingHeight) {
        _fillHeight = fillHeight;

        [self invalidateLayout];
    }
}

- (void)setAlwaysBounce:(BOOL)alwaysBounce {
    if (alwaysBounce != self.alwaysBounce) {
        _alwaysBounce = alwaysBounce;

        [self invalidateLayout];
    }
}

#pragma mark - UICollectionViewLayout

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset {
    // Honor overwritten contentOffset
    //
    // See http://stackoverflow.com/a/25416243
    //
    return self.overwriteContentOffset ? self.contentOffset : proposedContentOffset;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (CGSize)collectionViewContentSize {
    CGSize contentSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), self.layoutMargin.top + self.topReveal* [self.collectionView numberOfItemsInSection:0] + self.layoutMargin.bottom - self.collectionView.contentInset.bottom);

    if (contentSize.height < CGRectGetHeight(self.collectionView.bounds)) {
        contentSize.height = CGRectGetHeight(self.collectionView.bounds) - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom;

        // Adding an extra point of content height
        // enables scrolling/bouncing
        //
        if (self.isAlwaysBouncing) {
            contentSize.height += 1.0;
        }

        self.filling = self.isFillingHeight;
    } else {
        self.filling = NO;
    }

    return contentSize;
}

- (void)prepareLayout {
    // Force update of property -filling
    // used to decide whether to arrange
    // items evenly in collection view's
    // full height
    //
    [self collectionViewContentSize];

    if (!self.moveGestureRecognizer) {
        self.moveGestureRecognizer          = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        self.moveGestureRecognizer.delegate = self;
        [self.collectionView addGestureRecognizer:self.moveGestureRecognizer];
    }

    if (!self.deletePanGesture) {
        self.deletePanGesture                        = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panWithGesture:)];
        self.deletePanGesture.maximumNumberOfTouches = 1;
        self.deletePanGesture.delegate               = self;
        [self.collectionView addGestureRecognizer:self.deletePanGesture];
        [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:self.deletePanGesture];
        [self.moveGestureRecognizer requireGestureRecognizerToFail:self.deletePanGesture];
    }

    CGFloat itemReveal = self.topReveal;

    if (self.filling) {
        itemReveal = floor((CGRectGetHeight(self.collectionView.bounds) - self.layoutMargin.top - self.layoutMargin.bottom - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom) / [self.collectionView numberOfItemsInSection:0]);
    }

    CGSize itemSize = self.itemSize;

    if (CGSizeEqualToSize(itemSize, CGSizeZero)) {
        itemSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds) - self.layoutMargin.left - self.layoutMargin.right, CGRectGetHeight(self.collectionView.bounds) - self.layoutMargin.top - self.layoutMargin.bottom - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom);
    }

    // Honor overwritten contentOffset
    //
    CGPoint contentOffset = self.overwriteContentOffset ? self.contentOffset : self.collectionView.contentOffset;

    NSMutableDictionary* layoutAttributes                                 = [NSMutableDictionary dictionary];
    UICollectionViewLayoutAttributes* previousTopOverlappingAttributes[2] = { nil, nil };
    NSInteger itemCount                                                   = [self.collectionView numberOfItemsInSection:0];

    static NSInteger firstCompressingItem = -1;

    for (NSInteger item = 0; item < itemCount; item++) {
        NSIndexPath* indexPath                       = [NSIndexPath indexPathForItem:item inSection:0];
        UICollectionViewLayoutAttributes* attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

        // Cards overlap each other
        // via z depth
        //
        attributes.zIndex = item;

        // The moving item is hidden
        //
        attributes.hidden = [attributes.indexPath isEqual:self.movingIndexPath];

        // By default all items are layed
        // out evenly with each revealing
        // only top part ...
        //
        attributes.frame = CGRectMake(self.layoutMargin.left, self.layoutMargin.top + itemReveal * item, itemSize.width, itemSize.height);

        if (contentOffset.y + self.collectionView.contentInset.top < 0.0) {
            // Expand cells when reaching top
            // and user scrolls further down,
            // i.e. when bouncing
            //
            CGRect frame = attributes.frame;

            frame.origin.y -= self.bounceFactor * (contentOffset.y + self.collectionView.contentInset.top) * item;

            attributes.frame = frame;
        } else if (CGRectGetMinY(attributes.frame) < contentOffset.y + self.layoutMargin.top) {
            // Topmost cells overlap stack, but
            // are placed directly above each
            // other such that only one cell
            // is visible
            //
            CGRect frame = attributes.frame;

            frame.origin.y = contentOffset.y + self.layoutMargin.top;

            attributes.frame = frame;

            // Keep queue of last two items'
            // attributes and hide any item
            // below top overlapping item to
            // improve performance
            //
            if (previousTopOverlappingAttributes[1]) {
                previousTopOverlappingAttributes[1].hidden = YES;
            }

            previousTopOverlappingAttributes[1] = previousTopOverlappingAttributes[0];
            previousTopOverlappingAttributes[0] = attributes;
        } else if (self.collectionViewContentSize.height > CGRectGetHeight(self.collectionView.bounds) && contentOffset.y > self.collectionViewContentSize.height - CGRectGetHeight(self.collectionView.bounds)) {
            // Compress cells when reaching bottom
            // and user scrolls further up,
            // i.e. when bouncing
            //
            if (firstCompressingItem < 0) {
                firstCompressingItem = item;
            } else {
                CGRect frame  = attributes.frame;
                CGFloat delta = contentOffset.y + CGRectGetHeight(self.collectionView.bounds) - self.collectionViewContentSize.height;

                frame.origin.y += self.bounceFactor * delta * (firstCompressingItem - item);
                frame.origin.y  = MAX(frame.origin.y, contentOffset.y + self.layoutMargin.top);

                attributes.frame = frame;
            }
        } else {
            firstCompressingItem = -1;
        }

        layoutAttributes[indexPath] = attributes;
    }

    self.layoutAttributes = layoutAttributes;
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray* layoutAttributes = [NSMutableArray array];

    [self.layoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath* indexPath, UICollectionViewLayoutAttributes* attributes, BOOL* stop) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [layoutAttributes addObject:attributes];
            if ([self.panningIndexPath isEqual:attributes.indexPath]) {
                [self updateAttibutesWithPanTranslation:attributes];
            }
        }
    }];

    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* item = self.layoutAttributes[indexPath];
    if ([self.panningIndexPath isEqual:indexPath]) {
        [self updateAttibutesWithPanTranslation:item];
    }
    return item;
}

- (UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath*)itemIndexPath {
    if ([self.deletingIndexPath isEqual:itemIndexPath]) {
        UICollectionViewLayoutAttributes* item = [self layoutAttributesForItemAtIndexPath:itemIndexPath];
        [self updateAttibutesForDeletion:item];
        return item;
    }
    return [super finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
}

#pragma mark - Update Attributes

- (void)updateAttibutesWithPanTranslation:(UICollectionViewLayoutAttributes*)item {
    CGPoint translation = [self.deletePanGesture translationInView:self.collectionView];

    CGRect frame = item.frame;
    frame.origin.x = translation.x;
    item.frame     = frame;
}

- (void)resetAttibutesWithPanTranslation:(UICollectionViewLayoutAttributes*)item {
    CGRect frame = item.frame;
    frame.origin.x = 0;
    item.frame     = frame;
}

- (void)updateAttibutesForDeletion:(UICollectionViewLayoutAttributes*)item {
    CGRect frame = item.frame;
    frame.origin.x = self.collectionView.bounds.size.width * 2;
    item.frame     = frame;
}

#pragma mark - Drag Action

- (IBAction)handleLongPress:(UILongPressGestureRecognizer*)recognizer {
    static CGPoint startCenter;
    static CGPoint startLocation;

    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            startLocation = [recognizer locationInView:self.collectionView];

            NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:startLocation];

            BOOL canMove = [self.delegate respondsToSelector:@selector(stackLayout:canMoveItemAtIndexPath:)] ? [self.delegate stackLayout : self canMoveItemAtIndexPath:indexPath] : YES;

            if (indexPath && canMove) {
                UICollectionViewCell* movingCell = [self.collectionView cellForItemAtIndexPath:indexPath];

                self.movingView = [[UIView alloc] initWithFrame:movingCell.frame];

                startCenter = self.movingView.center;

                UIImageView* movingImageView = [[UIImageView alloc] initWithImage:[self screenshotImageOfItem:movingCell]];

                movingImageView.alpha = 0.0f;

                [self.movingView addSubview:movingImageView];
                [self.collectionView addSubview:self.movingView];

                self.movingIndexPath = indexPath;

                __weak typeof(self) weakSelf = self;

                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^(void) {
                    __strong typeof(self) strongSelf = weakSelf;

                    if (strongSelf) {
                        strongSelf.movingView.transform = CGAffineTransformMakeScale(MOVE_ZOOM, MOVE_ZOOM);
                        movingImageView.alpha = 1.0f;
                    }
                }
                                 completion:^(BOOL finished) {
                }];

                self.movingIndexPath = self.movingIndexPath;
                [self invalidateLayout];
            }

            break;
        }

        case UIGestureRecognizerStateChanged: {
            if (self.movingIndexPath) {
                CGPoint currentLocation = [recognizer locationInView:self.collectionView];
                CGPoint currentCenter   = startCenter;

                currentCenter.y += (currentLocation.y - startLocation.y);

                self.movingView.center = currentCenter;

                if (currentLocation.y < CGRectGetMinY(self.collectionView.bounds) + SCROLL_ZONE_TOP && self.collectionView.contentOffset.y > SCROLL_ZONE_TOP) {
                    [self startScrollingUp];
                } else if (currentLocation.y > CGRectGetMaxY(self.collectionView.bounds) - SCROLL_ZONE_BOTTOM && self.collectionView.contentOffset.y < self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.bounds) - SCROLL_ZONE_BOTTOM) {
                    [self startScrollingDown];
                } else if (self.scrollDirection != TGLStackedViewControllerScrollDirectionNone) {
                    [self stopScrolling];
                }

                if (self.scrollDirection == TGLStackedViewControllerScrollDirectionNone) {
                    [self updateLayoutAtMovingLocation:currentLocation];
                }
            }

            break;
        }

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.movingIndexPath) {
                [self stopScrolling];

                UICollectionViewLayoutAttributes* layoutAttributes = [self layoutAttributesForItemAtIndexPath:self.movingIndexPath];

                self.movingIndexPath = nil;

                __weak typeof(self) weakSelf = self;

                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^(void) {
                    __strong typeof(self) strongSelf = weakSelf;

                    if (strongSelf) {
                        strongSelf.movingView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                        strongSelf.movingView.frame = layoutAttributes.frame;
                    }
                }
                                 completion:^(BOOL finished) {
                    __strong typeof(self) strongSelf = weakSelf;

                    if (strongSelf) {
                        [strongSelf.movingView removeFromSuperview];
                        strongSelf.movingView = nil;

                        self.movingIndexPath = nil;
                        [strongSelf invalidateLayout];
                    }
                }];
            }

            break;
        }

        default:

            break;
    }
}

#pragma mark - Drag Helpers

- (void)startScrollingUp {
    [self startScrollingInDirection:TGLStackedViewControllerScrollDirectionUp];
}

- (void)startScrollingDown {
    [self startScrollingInDirection:TGLStackedViewControllerScrollDirectionDown];
}

- (void)startScrollingInDirection:(TGLStackedViewControllerScrollDirection)direction {
    if (direction != TGLStackedViewControllerScrollDirectionNone && direction != self.scrollDirection) {
        [self stopScrolling];

        self.scrollDirection   = direction;
        self.scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScrolling:)];

        [self.scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopScrolling {
    if (self.scrollDirection != TGLStackedViewControllerScrollDirectionNone) {
        self.scrollDirection = TGLStackedViewControllerScrollDirectionNone;

        [self.scrollDisplayLink invalidate];
        self.scrollDisplayLink = nil;
    }
}

- (void)handleScrolling:(CADisplayLink*)displayLink {
    switch (self.scrollDirection) {
        case TGLStackedViewControllerScrollDirectionUp: {
            CGPoint offset = self.collectionView.contentOffset;

            offset.y -= SCROLL_PER_FRAME;

            if (offset.y > 0.0) {
                self.collectionView.contentOffset = offset;

                CGPoint center = self.movingView.center;

                center.y              -= SCROLL_PER_FRAME;
                self.movingView.center = center;
            } else {
                [self stopScrolling];

                CGPoint currentLocation = [self.moveGestureRecognizer locationInView:self.collectionView];

                [self updateLayoutAtMovingLocation:currentLocation];
            }

            break;
        }

        case TGLStackedViewControllerScrollDirectionDown: {
            CGPoint offset = self.collectionView.contentOffset;

            offset.y += SCROLL_PER_FRAME;

            if (offset.y < self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.bounds)) {
                self.collectionView.contentOffset = offset;

                CGPoint center = self.movingView.center;

                center.y              += SCROLL_PER_FRAME;
                self.movingView.center = center;
            } else {
                [self stopScrolling];

                CGPoint currentLocation = [self.moveGestureRecognizer locationInView:self.collectionView];

                [self updateLayoutAtMovingLocation:currentLocation];
            }

            break;
        }

        default:
            break;
    }
}

- (UIImage*)screenshotImageOfItem:(UICollectionViewCell*)item {
    UIGraphicsBeginImageContextWithOptions(item.bounds.size, item.isOpaque, 0.0f);

    [item.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (void)updateLayoutAtMovingLocation:(CGPoint)movingLocation {
    NSIndexPath* oldMovingIndexPath = self.movingIndexPath;
    NSIndexPath* newMovingIndexPath = [self.collectionView indexPathForItemAtPoint:movingLocation];

    if ([self.delegate respondsToSelector:@selector(stackLayout:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)]) {
        newMovingIndexPath = [self.delegate stackLayout:self targetIndexPathForMoveFromItemAtIndexPath:oldMovingIndexPath toProposedIndexPath:newMovingIndexPath];
    }

    if (newMovingIndexPath != nil && ![newMovingIndexPath isEqual:oldMovingIndexPath]) {
        __weak typeof(self) weakSelf = self;

        [self.collectionView performBatchUpdates:^(void) {
            [weakSelf.collectionView deleteItemsAtIndexPaths:@[ oldMovingIndexPath ]];

            weakSelf.movingIndexPath = newMovingIndexPath;

            if ([weakSelf.delegate respondsToSelector:@selector(stackLayout:moveItemAtIndexPath:toIndexPath:)]) {
                [weakSelf.delegate stackLayout:weakSelf moveItemAtIndexPath:oldMovingIndexPath toIndexPath:newMovingIndexPath];
            }

            [weakSelf.collectionView insertItemsAtIndexPaths:@[ newMovingIndexPath ]];
        }
                                      completion:nil];
    }
}

#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer {
    if (![gestureRecognizer isEqual:self.deletePanGesture]) {
        return YES;
    }

    CGPoint attachmentPoint       = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath* touchedIndexPath = [self.collectionView indexPathForItemAtPoint:attachmentPoint];

    if (!touchedIndexPath) {
        return NO;
    }

    if ([self.delegate respondsToSelector:@selector(stackLayout:canDeleteItemAtIndexPath:)] && ![self.delegate stackLayout:self canDeleteItemAtIndexPath:touchedIndexPath]) {
        return NO;
    }

    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self.collectionView];
    if (velocity.y > 0 || velocity.y < 0) {
        return NO;
    }

    return YES;
}

#pragma mark - Pan Action

- (IBAction)panWithGesture:(UIPanGestureRecognizer*)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            CGPoint attachmentPoint = [pan locationInView:self.collectionView];

            NSIndexPath* touchedIndexPath = [self.collectionView indexPathForItemAtPoint:attachmentPoint];
            if (!touchedIndexPath) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            UICollectionViewLayoutAttributes* attributes = [self layoutAttributesForItemAtIndexPath:touchedIndexPath];

            if (!attributes) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            self.panningIndexPath = touchedIndexPath;
            [self invalidateLayout];
        }
        break;

        case UIGestureRecognizerStateChanged:
        {
            [self invalidateLayout];
        }
        break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGPoint translation = [pan translationInView:self.collectionView];
            CGFloat originalX   = [super layoutAttributesForItemAtIndexPath:self.panningIndexPath].frame.origin.x;

            if (translation.x >= (originalX + self.collectionView.bounds.size.width / 2)) {
                [self completeDeletionPanAnimation];
                return;
            }

            CGPoint velocity = [pan velocityInView:self.collectionView];
            if (velocity.x > 500) {
                [self completeDeletionPanAnimation];
                return;
            }

            [self cancelDeletionPanAnimation];
        }
        break;

        default:
            break;
    }
}

- (void)cancelTouchesInGestureRecognizer:(UIGestureRecognizer*)gesture {
    gesture.enabled = NO;
    gesture.enabled = YES;
}

- (void)completeDeletionPanAnimation {
    self.deletingIndexPath = self.panningIndexPath;
    self.panningIndexPath  = nil;

    [self.collectionView performBatchUpdates:^{
        UICollectionViewLayoutAttributes* item = [self layoutAttributesForItemAtIndexPath:self.deletingIndexPath];
        [self resetAttibutesWithPanTranslation:item];

        [self.collectionView deleteItemsAtIndexPaths:@[self.deletingIndexPath]];
        if ([self.delegate respondsToSelector:@selector(stackLayout:deleteItemAtIndexPath:)]) {
            [self.delegate stackLayout:self deleteItemAtIndexPath:self.deletingIndexPath];
        }
    } completion:^(BOOL finished) {
        self.deletingIndexPath = nil;
    }];
}

- (void)cancelDeletionPanAnimation {
    self.panningIndexPath = nil;

    [self.collectionView performBatchUpdates:^{
        [self invalidateLayout];
    } completion:nil];
}

@end
