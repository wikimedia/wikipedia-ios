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
#import "UICollectionView+WMFExtensions.h"

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


@property (assign, nonatomic) TGLStackedViewControllerScrollDirection scrollDirection;
@property (strong, nonatomic) CADisplayLink* scrollDisplayLink;


@property (strong, nonatomic) UILongPressGestureRecognizer* moveGestureRecognizer;

@property (nonatomic, strong) UIPanGestureRecognizer* deletePanGesture;

@property (assign, nonatomic) CGPoint gestureStartLocation;

/** Index path of item currently being moved, and thus being hidden */
@property (strong, nonatomic) NSIndexPath* movingIndexPath;
@property (assign, nonatomic) CGPoint movingCellCenter;
@property (strong, nonatomic) UIView* movingSnapshotView;
@property (strong, nonatomic) UIView* bottomSnapshotView;

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
    self.layoutMargin = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    self.topReveal    = 140.0;
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
        }
    }];

    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* item = self.layoutAttributes[indexPath];
    return item;
}

- (void)prepareForTransitionToLayout:(UICollectionViewLayout*)newLayout {
    [self.collectionView removeGestureRecognizer:self.moveGestureRecognizer];
    [self.collectionView removeGestureRecognizer:self.deletePanGesture];
    self.moveGestureRecognizer = nil;
    self.deletePanGesture      = nil;
}

#pragma mark - Update Attributes

- (void)updateAttibutesWithPanTranslation:(UICollectionViewLayoutAttributes*)item {
    CGPoint translation = [self.deletePanGesture translationInView:self.collectionView];

    CGRect frame = item.frame;
    frame.origin.x = translation.x;
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

                self.movingSnapshotView       = [movingCell snapshotViewAfterScreenUpdates:YES];
                self.movingSnapshotView.frame = movingCell.frame;

                startCenter = self.movingSnapshotView.center;

                self.movingSnapshotView.alpha = 0.0f;
                [self.collectionView addSubview:self.movingSnapshotView];

                self.movingIndexPath = indexPath;

                __weak typeof(self) weakSelf = self;

                [UIView animateWithDuration:0.3
                                      delay:0.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^(void) {
                    __strong typeof(self) strongSelf = weakSelf;

                    if (strongSelf) {
                        strongSelf.movingSnapshotView.transform = CGAffineTransformMakeScale(MOVE_ZOOM, MOVE_ZOOM);
                        strongSelf.movingSnapshotView.alpha = 1.0f;
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

                self.movingSnapshotView.center = currentCenter;

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
                        strongSelf.movingSnapshotView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                        strongSelf.movingSnapshotView.frame = layoutAttributes.frame;
                    }
                }
                                 completion:^(BOOL finished) {
                    __strong typeof(self) strongSelf = weakSelf;

                    if (strongSelf) {
                        [strongSelf.movingSnapshotView removeFromSuperview];
                        strongSelf.movingSnapshotView = nil;

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

                CGPoint center = self.movingSnapshotView.center;

                center.y                      -= SCROLL_PER_FRAME;
                self.movingSnapshotView.center = center;
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

                CGPoint center = self.movingSnapshotView.center;

                center.y                      += SCROLL_PER_FRAME;
                self.movingSnapshotView.center = center;
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
    if ([gestureRecognizer isEqual:self.deletePanGesture]) {
        CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self.collectionView];
        if (velocity.y > 0 || velocity.y < 0) {
            return NO;
        }
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

            //bail if no index path
            if (!touchedIndexPath) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            //bail if we can't move
            if ([self.delegate respondsToSelector:@selector(stackLayout:canDeleteItemAtIndexPath:)] && ![self.delegate stackLayout:self canDeleteItemAtIndexPath:touchedIndexPath]) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            UICollectionViewCell* movingCell = [self.collectionView cellForItemAtIndexPath:touchedIndexPath];

            //bail if there is no cell
            if (!movingCell) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            self.movingSnapshotView       = [self.collectionView wmf_snapshotOfCellAtIndexPath:touchedIndexPath];
            self.movingSnapshotView.frame = movingCell.frame;
            self.movingCellCenter         = self.movingSnapshotView.center;
            self.movingIndexPath          = touchedIndexPath;

            self.bottomSnapshotView       = [self.collectionView wmf_snapshotOfCellsAfterIndexPath:touchedIndexPath];
            self.bottomSnapshotView.frame = [self.collectionView wmf_rectEnclosingCellsAtIndexPaths:[self.collectionView wmf_visibleIndexPathsOfItemsAfterIndexPath:touchedIndexPath]];

            [self.collectionView addSubview:self.movingSnapshotView];
            [self.collectionView addSubview:self.bottomSnapshotView];

            [self invalidateLayout];
        }
        break;

        case UIGestureRecognizerStateChanged:
        {
            if (self.movingIndexPath) {
                CGPoint translation   = [pan translationInView:self.collectionView];
                CGPoint currentCenter = self.movingCellCenter;
                currentCenter.x               += translation.x;
                self.movingSnapshotView.center = currentCenter;
            }
        }
        break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            if (self.movingIndexPath) {
                CGPoint translation = [pan translationInView:self.collectionView];

                if (fabs(translation.x) >= self.collectionView.bounds.size.width / 2) {
                    [self completeDeletionPanAnimationWithGestureRecognizer:pan];
                    return;
                }

                CGPoint velocity = [pan velocityInView:self.collectionView];
                if (fabs(velocity.x) > 500) {
                    [self completeDeletionPanAnimationWithGestureRecognizer:pan];
                    return;
                }

                [self cancelDeletionPanAnimationWithGestureRecognizer:pan];
            }
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

- (void)completeDeletionPanAnimationWithGestureRecognizer:(UIPanGestureRecognizer*)pan {
    CGPoint velocity         = [pan velocityInView:self.collectionView];
    CGPoint finalDestination = self.movingCellCenter;

    if (velocity.x > 0) {
        finalDestination.x += CGRectGetWidth(self.collectionView.bounds);
    } else {
        finalDestination.x -= CGRectGetWidth(self.collectionView.bounds);
    }

    NSIndexPath* indexPath = self.movingIndexPath;

    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:velocity.x / finalDestination.x options:0 animations:^{
        self.movingSnapshotView.center = finalDestination;
    } completion:^(BOOL finished) {
        self.movingIndexPath = nil;
        self.gestureStartLocation = CGPointZero;
        self.movingCellCenter = CGPointZero;
        [self.movingSnapshotView removeFromSuperview];
        self.movingSnapshotView = nil;
        [self.bottomSnapshotView removeFromSuperview];
        self.bottomSnapshotView = nil;

        [self.collectionView performBatchUpdates:^{
            if ([self.delegate respondsToSelector:@selector(stackLayout:deleteItemAtIndexPath:)]) {
                [self.delegate stackLayout:self deleteItemAtIndexPath:indexPath];
            }

            [self invalidateLayout];
        } completion:^(BOOL finished) {
        }];
    }];
}

- (void)cancelDeletionPanAnimationWithGestureRecognizer:(UIPanGestureRecognizer*)pan {
    CGPoint velocity         = [pan velocityInView:self.collectionView];
    CGPoint finalDestination = self.movingCellCenter;

    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:velocity.x / finalDestination.x options:0 animations:^{
        self.movingSnapshotView.center = finalDestination;
    } completion:^(BOOL finished) {
        self.movingIndexPath = nil;
        self.gestureStartLocation = CGPointZero;
        self.movingCellCenter = CGPointZero;

        [self.collectionView performBatchUpdates:^{
            [self invalidateLayout];
        } completion:^(BOOL finished) {
            //For some reason this completion blick fires before the layout is finished resulting in a flicker when updating the moving view.
            // To compensate, we add a delay in to be sure it is finished before moving
            dispatchOnMainQueueAfterDelayInSeconds(0.1, ^{
                [self.movingSnapshotView removeFromSuperview];
                self.movingSnapshotView = nil;
                [self.bottomSnapshotView removeFromSuperview];
                self.bottomSnapshotView = nil;
            });
        }];
    }];
}

@end
