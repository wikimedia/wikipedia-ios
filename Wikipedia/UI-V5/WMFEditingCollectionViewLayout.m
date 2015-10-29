
#import "WMFEditingCollectionViewLayout.h"
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

@interface WMFEditingCollectionViewLayout ()<UIGestureRecognizerDelegate>

@property (assign, nonatomic) TGLStackedViewControllerScrollDirection scrollDirection;
@property (strong, nonatomic) CADisplayLink* scrollDisplayLink;

@property (strong, nonatomic) UILongPressGestureRecognizer* moveGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer* deletePanGesture;

@property (assign, nonatomic) CGPoint gestureStartLocation;

@property (strong, nonatomic) NSIndexPath* movingIndexPath;
@property (assign, nonatomic) CGPoint movingCellCenter;
@property (strong, nonatomic) UIView* movingSnapshotView;
@property (strong, nonatomic) UIView* bottomSnapshotView;

@end

@implementation WMFEditingCollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];

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
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* layoutAttributes = [super layoutAttributesForElementsInRect:rect];
    [layoutAttributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes* attributes, NSUInteger idx, BOOL* _Nonnull stop) {
        attributes.hidden = [attributes.indexPath isEqual:self.movingIndexPath];
    }];
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes*)layoutAttributesForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewLayoutAttributes* attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    attributes.hidden = [attributes.indexPath isEqual:self.movingIndexPath];
    return attributes;
}

- (void)prepareForTransitionToLayout:(UICollectionViewLayout*)newLayout {
    [super prepareForTransitionToLayout:newLayout];

    [self.collectionView removeGestureRecognizer:self.moveGestureRecognizer];
    [self.collectionView removeGestureRecognizer:self.deletePanGesture];
    self.moveGestureRecognizer = nil;
    self.deletePanGesture      = nil;
}

#pragma mark - Drag Action

- (IBAction)handleLongPress:(UILongPressGestureRecognizer*)recognizer {
    static CGPoint startCenter;
    static CGPoint startLocation;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            startLocation = [recognizer locationInView:self.collectionView];

            NSIndexPath* indexPath = [self.collectionView indexPathForItemAtPoint:startLocation];

            BOOL canMove = [self.editingDelegate respondsToSelector:@selector(editingLayout:canMoveItemAtIndexPath:)] ? [self.editingDelegate editingLayout : self canMoveItemAtIndexPath:indexPath] : YES;

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

    if ([self.editingDelegate respondsToSelector:@selector(editingLayout:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)]) {
        newMovingIndexPath = [self.editingDelegate editingLayout:self targetIndexPathForMoveFromItemAtIndexPath:oldMovingIndexPath toProposedIndexPath:newMovingIndexPath];
    }

    if (newMovingIndexPath != nil && ![newMovingIndexPath isEqual:oldMovingIndexPath]) {
        __weak typeof(self) weakSelf = self;

        [self.collectionView performBatchUpdates:^(void) {
            [weakSelf.collectionView deleteItemsAtIndexPaths:@[ oldMovingIndexPath ]];

            weakSelf.movingIndexPath = newMovingIndexPath;

            if ([weakSelf.editingDelegate respondsToSelector:@selector(editingLayout:moveItemAtIndexPath:toIndexPath:)]) {
                [weakSelf.editingDelegate editingLayout:weakSelf moveItemAtIndexPath:oldMovingIndexPath toIndexPath:newMovingIndexPath];
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
        if (velocity.y > 50 || velocity.y < -50) {
            return NO;
        } else {
            return YES;
        }
    }
    if (self.previewingEnabled) {
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

            //bail if no index path
            if (!touchedIndexPath) {
                [self cancelTouchesInGestureRecognizer:pan];
                return;
            }

            //bail if we can't move
            if ([self.editingDelegate respondsToSelector:@selector(editingLayout:canDeleteItemAtIndexPath:)] && ![self.editingDelegate editingLayout:self canDeleteItemAtIndexPath:touchedIndexPath]) {
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

                CGFloat percentageOnScreen = CGRectGetMaxX(self.movingSnapshotView.frame) / self.collectionView.bounds.size.width;

                if (percentageOnScreen > 1) {
                    //If greater than 1, it means we are moving the left instead of right
                    //Instead lets subtract to get the proper alpha
                    percentageOnScreen = 1 - (percentageOnScreen - 1);
                }
                self.movingSnapshotView.alpha = percentageOnScreen;
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
            if ([self.editingDelegate respondsToSelector:@selector(editingLayout:deleteItemAtIndexPath:)]) {
                [self.editingDelegate editingLayout:self deleteItemAtIndexPath:indexPath];
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
