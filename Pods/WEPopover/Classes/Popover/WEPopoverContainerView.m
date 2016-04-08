//
//  WEPopoverContainerViewProperties.m
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WEPopoverContainerView.h"
#import <QuartzCore/QuartzCore.h>

@interface WEPopoverContainerView()

@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UIImageView *bgImageView;

@end

@interface WEPopoverContainerView(Private)

- (void)determineGeometryForSize:(CGSize)theSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;
- (CGRect)contentRect;
- (CGSize)contentSize;
- (void)setProperties:(WEPopoverContainerViewProperties *)props;
- (void)initFrame;
- (CGFloat)shadowInset;

@end

@implementation WEPopoverContainerView {
    UIImage *_bgImage;
    UIImage *_arrowImage;
    
    WEPopoverContainerViewProperties *_properties;
    
    CGRect _arrowRect;
    CGRect _bgRect;
    CGPoint _offset;
    CGPoint _arrowOffset;
    
    CGSize _correctedSize;
    CGRect _calculatedFrame;
    
    BOOL _arrowCollapsed;
}

- (id)initWithSize:(CGSize)theSize
        anchorRect:(CGRect)anchorRect
       displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
        properties:(WEPopoverContainerViewProperties *)theProperties {
    if ((self = [super initWithFrame:CGRectZero])) {
        
        [self setProperties:theProperties];
        _correctedSize = CGSizeMake(theSize.width + _properties.backgroundMargins.left + _properties.backgroundMargins.right + _properties.contentMargins.left + _properties.contentMargins.right,
                                    theSize.height + _properties.backgroundMargins.top + _properties.backgroundMargins.bottom + _properties.contentMargins.top + _properties.contentMargins.bottom);
        [self determineGeometryForSize:_correctedSize anchorRect:anchorRect displayArea:displayArea permittedArrowDirections:permittedArrowDirections];
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *theImage = _properties.bgImage;
        _bgImage = [theImage stretchableImageWithLeftCapWidth:_properties.leftBgCapSize topCapHeight:_properties.topBgCapSize];
        
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        
        self.shadowView = [UIView new];
        self.shadowView.backgroundColor = [UIColor clearColor];
        self.shadowView.clipsToBounds = NO;
        self.shadowView.layer.masksToBounds = NO;

        [self addSubview:self.shadowView];
        
        self.arrowImageView = [[UIImageView alloc] init];
        self.arrowImageView.hidden = YES;
        self.arrowImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.arrowImageView];

        self.bgView = [UIView new];
        self.bgView.clipsToBounds = YES;
        self.bgView.layer.masksToBounds = YES;
        self.bgView.backgroundColor = _properties.backgroundColor == nil ? [UIColor clearColor] : _properties.backgroundColor;
        [self addSubview:self.bgView];

        self.bgImageView = [[UIImageView alloc] initWithFrame:self.bgView.bounds];
        self.bgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.bgImageView.contentMode = UIViewContentModeScaleToFill;
        [self.bgView addSubview:self.bgImageView];

        CGFloat borderWidth = _properties.maskBorderWidth;
        UIColor *borderColor = _properties.maskBorderColor;

        if (borderWidth > 0.0f && borderColor != nil) {
            self.bgView.layer.borderColor = [borderColor CGColor];
            self.bgView.layer.borderWidth = borderWidth;
        }

        if (_properties.maskCornerRadius > 0.0f) {
            self.bgView.layer.cornerRadius = _properties.maskCornerRadius;
            self.shadowView.layer.cornerRadius = _properties.maskCornerRadius;
        }

        if (_properties.shadowColor != nil) {
            self.shadowView.layer.shadowColor = [_properties.shadowColor CGColor];
            self.shadowView.layer.shadowRadius = _properties.shadowRadius;
            self.shadowView.layer.shadowOffset = _properties.shadowOffset;
            self.shadowView.layer.shadowOpacity = _properties.shadowOpacity;
        }

        [self initFrame];
    }
    return self;
}

- (void)setArrowCollapsed:(BOOL)collapsed {
    if (collapsed != _arrowCollapsed) {
        _arrowCollapsed = collapsed;
        self.arrowImageView.frame = self.arrowRect;
    }
}

- (CGRect)arrowRect {
    CGRect rect = _arrowRect;
    
    CGPoint shift = CGPointZero;
    CGFloat margin = 1.0f;
    
    if (_arrowCollapsed) {
        switch (_arrowDirection) {
            case UIPopoverArrowDirectionDown:
                
                shift = CGPointMake(0, -_arrowRect.size.height - margin);
                break;
                
            case UIPopoverArrowDirectionUp:
                
                shift = CGPointMake(0, _arrowRect.size.height + margin);
                break;

            case UIPopoverArrowDirectionLeft:
                
                shift = CGPointMake(_arrowRect.size.width + margin, 0);
                break;

            case UIPopoverArrowDirectionRight:
                
                shift = CGPointMake(-_arrowRect.size.width - margin, 0);
                break;
                
            default:
                break;
        }
    }
    rect = CGRectOffset(_arrowRect, shift.x, shift.y);
    return rect;
}

- (void)updatePositionWithSize:(CGSize)theSize
                    anchorRect:(CGRect)anchorRect
                   displayArea:(CGRect)displayArea
      permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections {
    
    _correctedSize = CGSizeMake(theSize.width + _properties.backgroundMargins.left + _properties.backgroundMargins.right + _properties.contentMargins.left + _properties.contentMargins.right,
                                theSize.height + _properties.backgroundMargins.top + _properties.backgroundMargins.bottom + _properties.contentMargins.top + _properties.contentMargins.bottom);
    
    [self determineGeometryForSize:_correctedSize anchorRect:anchorRect displayArea:displayArea permittedArrowDirections:permittedArrowDirections];
    [self initFrame];
    [self setNeedsDisplay];
    
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(self.contentRect, point);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void)setContentView:(UIView *)v {
    [self setContentView:v withAnimationDuration:0.0];
}

- (void)setContentView:(UIView *)v withAnimationDuration:(NSTimeInterval)duration {
    [self setContentView:v withAnimationDuration:duration completion:nil];
}

- (void)setContentView:(UIView *)v withAnimationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion {
    if (v != _contentView) {
        UIView *oldContentView = _contentView;
        _contentView = v;
        CGRect rect = [self convertRect:self.contentRect toView:self.bgView];
        _contentView.frame = rect;
        if (duration > 0.0) {
            [UIView transitionFromView:oldContentView toView:_contentView duration:duration
                               options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState |
                            UIViewAnimationCurveEaseInOut completion:^(BOOL finished) {
                        if (completion) {
                            completion();
                        }
                    }];
        } else {
            [oldContentView removeFromSuperview];
            if (_contentView) {
                [self.bgView addSubview:_contentView];
            }
            if (completion) {
                completion();
            }
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = [self convertRect:self.contentRect toView:self.bgView];
    _contentView.frame = rect;
}

- (CGRect)calculatedFrame {
    return _calculatedFrame;
}

- (void)setFrame:(CGRect)frame sendNotification:(BOOL)sendNotification {
    if (sendNotification) {
        if ([self.delegate respondsToSelector:@selector(popoverContainerView:willChangeFrame:)]) {
            frame = [self.delegate popoverContainerView:self willChangeFrame:frame];
        }
    }
    [super setFrame:frame];
}

- (void)setFrame:(CGRect)frame {
    [self setFrame:frame sendNotification:YES];
}

@end

@implementation WEPopoverContainerView(Private)

- (CGFloat)shadowInset {
    CGFloat ret = 0.0;
    if (_properties.shadowColor != nil) {
        ret = ceil(_properties.shadowRadius);
    }
    return ret;
}

- (void)initFrame {
    CGRect theFrame = CGRectOffset(CGRectUnion(_bgRect, _arrowRect), _offset.x, _offset.y);
    
    //If arrow rect origin is < 0 the frame above is extended to include it so we should offset the other rects
    _arrowOffset = CGPointMake(MAX(0, -_arrowRect.origin.x), MAX(0, -_arrowRect.origin.y));
    _bgRect = CGRectOffset(_bgRect, _arrowOffset.x, _arrowOffset.y);
    _arrowRect = CGRectOffset(_arrowRect, _arrowOffset.x, _arrowOffset.y);
    
    CGFloat delta = self.shadowInset;
    theFrame = CGRectInset(theFrame, -delta, -delta);
    _bgRect = CGRectOffset(_bgRect, delta, delta);
    _arrowRect = CGRectOffset(_arrowRect, delta, delta);
    _calculatedFrame = CGRectIntegral(theFrame);
    
    _arrowImageView.hidden = (_arrowImage == nil);
    _arrowImageView.image = _arrowImage;
    _arrowImageView.frame = self.arrowRect;
    
    _bgImageView.image = _bgImage;
    _bgImageView.hidden = (_bgImage == nil);
    _bgView.frame = _bgRect;
    _shadowView.frame = _bgRect;
}

- (CGSize)contentSize {
    return self.contentRect.size;
}

- (CGRect)contentRect {
    CGRect rect = CGRectMake(_properties.backgroundMargins.left + _properties.contentMargins.left + _arrowOffset.x,
                             _properties.backgroundMargins.top + _properties.contentMargins.top + _arrowOffset.y,
                             _bgRect.size.width - _properties.backgroundMargins.left - _properties.backgroundMargins.right - _properties.contentMargins.left - _properties.contentMargins.right,
                             _bgRect.size.height - _properties.backgroundMargins.top - _properties.backgroundMargins.bottom - _properties.contentMargins.top - _properties.contentMargins.bottom);
    
    CGFloat shadowInset = self.shadowInset;
    rect = CGRectOffset(rect, shadowInset, shadowInset);
    
    return rect;
}

- (void)setProperties:(WEPopoverContainerViewProperties *)props {
    if (_properties != props) {
        _properties = props;
    }
}

- (CGRect)roundedRect:(CGRect)rect {
    return CGRectMake(roundf(rect.origin.x), roundf(rect.origin.y), roundf(rect.size.width), roundf(rect.size.height));
}

- (void)determineGeometryForSize:(CGSize)theSize anchorRect:(CGRect)anchorRect displayArea:(CGRect)displayArea permittedArrowDirections:(UIPopoverArrowDirection)supportedArrowDirections {
    
    theSize.width = MIN(displayArea.size.width, theSize.width);
    theSize.height = MIN(displayArea.size.height, theSize.height);
    
    //Determine the frame, it should not go outside the display area
    UIPopoverArrowDirection theArrowDirection = UIPopoverArrowDirectionUp;
    
    _offset =  CGPointZero;
    _bgRect = CGRectZero;
    _arrowRect = CGRectZero;
    _arrowDirection = UIPopoverArrowDirectionUnknown;
    
    CGFloat biggestSurface = 0.0f;
    CGFloat currentMinMargin = 0.0f;
    
    UIImage *upArrowImage = _properties.upArrowImage;
    UIImage *downArrowImage = _properties.downArrowImage;
    UIImage *leftArrowImage = _properties.leftArrowImage;
    UIImage *rightArrowImage = _properties.rightArrowImage;
    
    while (theArrowDirection <= UIPopoverArrowDirectionRight) {
        
        if ((supportedArrowDirections & theArrowDirection)) {

            CGRect theBgRect = CGRectMake(0, 0, theSize.width, theSize.height);
            CGRect theArrowRect = CGRectZero;
            CGPoint theOffset = CGPointZero;
            CGFloat xArrowOffset = 0.0;
            CGFloat yArrowOffset = 0.0;
            CGPoint anchorPoint = CGPointZero;
            
            switch (theArrowDirection) {
                case UIPopoverArrowDirectionUp:
                    
                    anchorPoint = CGPointMake(CGRectGetMidX(anchorRect) - displayArea.origin.x, CGRectGetMaxY(anchorRect) - displayArea.origin.y);
                    
                    xArrowOffset = theSize.width / 2 - upArrowImage.size.width / 2;
                    yArrowOffset = _properties.backgroundMargins.top - upArrowImage.size.height;
                    
                    theOffset = CGPointMake(anchorPoint.x - xArrowOffset - upArrowImage.size.width / 2, anchorPoint.y  - yArrowOffset);
                    
                    if (theOffset.x < 0) {
                        xArrowOffset += theOffset.x;
                        theOffset.x = 0;
                    } else if (theOffset.x + theSize.width > displayArea.size.width) {
                        xArrowOffset += (theOffset.x + theSize.width - displayArea.size.width);
                        theOffset.x = displayArea.size.width - theSize.width;
                    }
                    
                    //Cap the arrow offset
                    xArrowOffset = MAX(xArrowOffset, _properties.backgroundMargins.left + _properties.arrowMargin);
                    xArrowOffset = MIN(xArrowOffset, theSize.width - _properties.backgroundMargins.right - _properties.arrowMargin - upArrowImage.size.width);
                    
                    theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, upArrowImage.size.width, upArrowImage.size.height);
                    
                    break;
                case UIPopoverArrowDirectionDown:
                    
                    anchorPoint = CGPointMake(CGRectGetMidX(anchorRect)  - displayArea.origin.x, CGRectGetMinY(anchorRect) - displayArea.origin.y);
                    
                    xArrowOffset = theSize.width / 2 - downArrowImage.size.width / 2;
                    yArrowOffset = theSize.height - _properties.backgroundMargins.bottom;
                    
                    theOffset = CGPointMake(anchorPoint.x - xArrowOffset - downArrowImage.size.width / 2, anchorPoint.y - yArrowOffset - downArrowImage.size.height);
                    
                    if (theOffset.x < 0) {
                        xArrowOffset += theOffset.x;
                        theOffset.x = 0;
                    } else if (theOffset.x + theSize.width > displayArea.size.width) {
                        xArrowOffset += (theOffset.x + theSize.width - displayArea.size.width);
                        theOffset.x = displayArea.size.width - theSize.width;
                    }
                    
                    //Cap the arrow offset
                    xArrowOffset = MAX(xArrowOffset, _properties.backgroundMargins.left + _properties.arrowMargin);
                    xArrowOffset = MIN(xArrowOffset, theSize.width - _properties.backgroundMargins.right - _properties.arrowMargin - downArrowImage.size.width);
                    
                    theArrowRect = CGRectMake(xArrowOffset , yArrowOffset, downArrowImage.size.width, downArrowImage.size.height);
                    
                    break;
                case UIPopoverArrowDirectionLeft:
                    
                    anchorPoint = CGPointMake(CGRectGetMaxX(anchorRect) - displayArea.origin.x, CGRectGetMidY(anchorRect) - displayArea.origin.y);
                    
                    xArrowOffset = _properties.backgroundMargins.left - leftArrowImage.size.width;
                    yArrowOffset = theSize.height / 2  - leftArrowImage.size.height / 2;
                    
                    theOffset = CGPointMake(anchorPoint.x - xArrowOffset, anchorPoint.y - yArrowOffset - leftArrowImage.size.height / 2);
                    
                    if (theOffset.y < 0) {
                        yArrowOffset += theOffset.y;
                        theOffset.y = 0;
                    } else if (theOffset.y + theSize.height > displayArea.size.height) {
                        yArrowOffset += (theOffset.y + theSize.height - displayArea.size.height);
                        theOffset.y = displayArea.size.height - theSize.height;
                    }
                    
                    //Cap the arrow offset
                    yArrowOffset = MAX(yArrowOffset, _properties.backgroundMargins.top + _properties.arrowMargin);
                    yArrowOffset = MIN(yArrowOffset, theSize.height - _properties.backgroundMargins.bottom - _properties.arrowMargin - leftArrowImage.size.height);
                    
                    theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, leftArrowImage.size.width, leftArrowImage.size.height);
                    
                    break;
                case UIPopoverArrowDirectionRight:
                    
                    anchorPoint = CGPointMake(CGRectGetMinX(anchorRect) - displayArea.origin.x, CGRectGetMidY(anchorRect) - displayArea.origin.y);
                    
                    xArrowOffset = theSize.width - _properties.backgroundMargins.right;
                    yArrowOffset = theSize.height / 2  - rightArrowImage.size.width / 2;
                    
                    theOffset = CGPointMake(anchorPoint.x - xArrowOffset - rightArrowImage.size.width, anchorPoint.y - yArrowOffset - rightArrowImage.size.height / 2);
                    
                    if (theOffset.y < 0) {
                        yArrowOffset += theOffset.y;
                        theOffset.y = 0;
                    } else if (theOffset.y + theSize.height > displayArea.size.height) {
                        yArrowOffset += (theOffset.y + theSize.height - displayArea.size.height);
                        theOffset.y = displayArea.size.height - theSize.height;
                    }
                    
                    //Cap the arrow offset
                    yArrowOffset = MAX(yArrowOffset, _properties.backgroundMargins.top + _properties.arrowMargin);
                    yArrowOffset = MIN(yArrowOffset, theSize.height - _properties.backgroundMargins.bottom - _properties.arrowMargin - rightArrowImage.size.height);
                    
                    theArrowRect = CGRectMake(xArrowOffset, yArrowOffset, rightArrowImage.size.width, rightArrowImage.size.height);
                    
                    break;
                default:
                    break;
            }
            
            CGRect bgFrame = CGRectOffset(theBgRect, theOffset.x, theOffset.y);
            
            CGFloat minMarginLeft = CGRectGetMinX(bgFrame);
            CGFloat minMarginRight = CGRectGetWidth(displayArea) - CGRectGetMaxX(bgFrame);
            CGFloat minMarginTop = CGRectGetMinY(bgFrame);
            CGFloat minMarginBottom = CGRectGetHeight(displayArea) - CGRectGetMaxY(bgFrame);
            
            BOOL adjustRightArrow = NO;
            if (minMarginLeft < 0) {
                // Popover is clipped on the left;
                // move it to the right
                theOffset.x -= minMarginLeft;
                minMarginRight += minMarginLeft;
                minMarginLeft = 0;
                adjustRightArrow = YES;
            }
            if (minMarginRight < 0) {
                theBgRect.size.width += minMarginRight;
                minMarginRight = 0;
                adjustRightArrow = YES;
            }
            
            if (adjustRightArrow && theArrowDirection == UIPopoverArrowDirectionRight) {
                theArrowRect.origin.x = CGRectGetMaxX(theBgRect) - _properties.backgroundMargins.right;
            }

            BOOL adjustDownArrow = NO;
            if (minMarginTop < 0) {
                // Popover is clipped at the top
                
                // Move it down
                theOffset.y -= minMarginTop;
                minMarginBottom += minMarginTop;
                minMarginTop = 0;
                adjustDownArrow = YES;
            }
            if (minMarginBottom < 0) {
                // Popover is clipped at the bottom:
                
                // Decrease the height:
                theBgRect.size.height += minMarginBottom;
                minMarginBottom = 0;
                adjustDownArrow = YES;
            }
            
            if (adjustDownArrow && theArrowDirection == UIPopoverArrowDirectionDown) {
                //Move the arrow to proper position for clipping at the bottom
                theArrowRect.origin.y = CGRectGetMaxY(theBgRect) - _properties.backgroundMargins.bottom;
            }
            
            
            CGFloat minMargin = MIN(minMarginLeft, minMarginRight);
            minMargin = MIN(minMargin, minMarginTop);
            minMargin = MIN(minMargin, minMarginBottom);
            
            // Calculate intersection and surface
            CGFloat surface = theBgRect.size.width * theBgRect.size.height;
            
            if (surface >= biggestSurface && minMargin >= currentMinMargin) {
                biggestSurface = surface;
                _offset = CGPointMake(roundf(theOffset.x + displayArea.origin.x), roundf(theOffset.y + displayArea.origin.y));
                _arrowRect = [self roundedRect:theArrowRect];
                _bgRect = [self roundedRect:theBgRect];
                _arrowDirection = theArrowDirection;
                currentMinMargin = minMargin;
            }
        }
        
        theArrowDirection <<= 1;
    }
    
    switch (_arrowDirection) {
        case UIPopoverArrowDirectionUp:
            _arrowImage = upArrowImage;
            break;
        case UIPopoverArrowDirectionDown:
            _arrowImage = downArrowImage;
            break;
        case UIPopoverArrowDirectionLeft:
            _arrowImage = leftArrowImage;
            break;
        case UIPopoverArrowDirectionRight:
            _arrowImage = rightArrowImage;
            break;
        default:
            break;
    }
}

@end