//
//  WETouchableView.m
//  WEPopover
//
//  Created by Werner Altewischer on 12/21/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import "WETouchableView.h"
#import "WEBlockingGestureRecognizer.h"

@interface WETouchableView()

@property (nonatomic, strong) WEBlockingGestureRecognizer *blockingGestureRecognizer;

@end

@interface WETouchableView(Private)

- (BOOL)isPassthroughView:(UIView *)v;

@end

@implementation WETouchableView {
    BOOL _testHits;
    BOOL _gestureBlockingEnabled;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        WEBlockingGestureRecognizer *gr = [[WEBlockingGestureRecognizer alloc] init];
        [self addGestureRecognizer:gr];
        gr.enabled = YES;
        self.blockingGestureRecognizer = gr;
        self.backgroundColor = [UIColor clearColor];
        
        self.fillView = [[UIView alloc] init];
        self.fillView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.fillView];
        
        _gestureBlockingEnabled = YES;
    }
    return self;
}

- (void)setGestureBlockingEnabled:(BOOL)gestureBlockingEnabled {
    if (_gestureBlockingEnabled != gestureBlockingEnabled) {
        _gestureBlockingEnabled = gestureBlockingEnabled;
        self.blockingGestureRecognizer.enabled = gestureBlockingEnabled;
    }
}

- (BOOL)gestureBlockingEnabled {
    return _gestureBlockingEnabled;
}

- (void)setFillView:(UIView *)fillView {
    if (_fillView != fillView) {
        [_fillView removeFromSuperview];
        _fillView = fillView;
        if (_fillView != nil) {
            [self addSubview:_fillView];
            [self setNeedsLayout];
        }
    }
}

- (void)setFillColor:(UIColor *)fillColor {
    self.fillView.backgroundColor = fillColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect fillRect = self.bounds;
    if ([self.delegate respondsToSelector:@selector(fillRectForView:)]) {
        fillRect = [self.delegate fillRectForView:self];
    }
    self.fillView.frame = fillRect;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (_testHits) {
        return nil;
    } else if (_touchForwardingDisabled) {
        return self;
    } else {
        UIView *hitView = [super hitTest:point withEvent:event];
        
        if (hitView == self || hitView == self.fillView) {
            //Test whether any of the passthrough views would handle this touch
            _testHits = YES;
            UIView *superHitView = [self.superview hitTest:point withEvent:event];
            _testHits = NO;
            
            if ([self isPassthroughView:superHitView]) {
                hitView = superHitView;
            }
        }
        
        return hitView;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(viewWasTouched:)]) {
        [self.delegate viewWasTouched:self];
    }
}

@end

@implementation WETouchableView(Private)

- (BOOL)isPassthroughView:(UIView *)v {
    
    if (v == nil) {
        return NO;
    }
    
    if ([_passthroughViews containsObject:v]) {
        return YES;
    }
    
    return [self isPassthroughView:v.superview];
}

@end
