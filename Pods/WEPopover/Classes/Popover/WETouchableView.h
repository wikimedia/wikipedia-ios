//
//  WETouchableView.h
//  WEPopover
//
//  Created by Werner Altewischer on 12/21/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WETouchableView;

/**
  * delegate to receive touch events
  */
@protocol WETouchableViewDelegate<NSObject>

@optional
- (void)viewWasTouched:(WETouchableView *)view;
- (CGRect)fillRectForView:(WETouchableView *)view;

@end

/**
 * View that can handle touch events and/or disable touch forwording to child views
 */
@interface WETouchableView : UIView

@property (nonatomic, assign) BOOL touchForwardingDisabled;
@property (nonatomic, weak) id <WETouchableViewDelegate> delegate;
@property (nonatomic, copy) NSArray *passthroughViews;
@property (nonatomic, strong) UIView *fillView;
@property (nonatomic, assign) BOOL gestureBlockingEnabled;

- (void)setFillColor:(UIColor *)fillColor;

@end
