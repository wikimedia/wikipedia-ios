//
//  WETouchDownGestureRecognizer.m
//  WEPopover
//
//  Created by Werner Altewischer on 18/09/14.
//  Copyright (c) 2014 Werner IT Consultancy. All rights reserved.
//

#import "WEBlockingGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation WEBlockingGestureRecognizer {
    NSMutableArray *_disabledGestureRecognizers;
}

- (id)init {
    return [self initWithTarget:self action:@selector(__dummyAction)];
}

- (void)dealloc {
    [self restoreDisabledGestureRecognizers];
}

- (id)initWithTarget:(id)target action:(SEL)action {
    if ((self = [super initWithTarget:target action:action])) {
        self.cancelsTouchesInView = NO;
        _disabledGestureRecognizers = [NSMutableArray new];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if (self.state == UIGestureRecognizerStatePossible) {
        self.state = UIGestureRecognizerStateBegan;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.state = UIGestureRecognizerStateRecognized;
    [self restoreDisabledGestureRecognizers];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
    [self restoreDisabledGestureRecognizers];
}

- (void)restoreDisabledGestureRecognizers {
    for (UIGestureRecognizer *gr in _disabledGestureRecognizers) {
        gr.enabled = YES;
    }
    [_disabledGestureRecognizers removeAllObjects];
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return [self shouldBeRequiredToFailByGestureRecognizer:preventedGestureRecognizer];
}

- (BOOL)shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    BOOL allowed = [self isGestureRecognizerAllowed:otherGestureRecognizer];
    if (!allowed) {
        if (otherGestureRecognizer.isEnabled) {
            otherGestureRecognizer.enabled = NO;
            [_disabledGestureRecognizers addObject:otherGestureRecognizer];
        }
    }
    return !allowed;
}

- (BOOL)shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)isGestureRecognizerAllowed:(UIGestureRecognizer *)gr {
    return [gr.view isDescendantOfView:self.view];
}

- (void)__dummyAction {
    
}

@end
