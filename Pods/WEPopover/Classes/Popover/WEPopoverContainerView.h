//
//  WEPopoverContainerView.h
//  WEPopover
//
//  Created by Werner Altewischer on 02/09/10.
//  Copyright 2010 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WEPopoverContainerViewProperties.h"

@class WEPopoverContainerView;

@protocol WEPopoverContainerViewDelegate <NSObject>

/**
 Implement to override the frame being set in setFrame:
 */
- (CGRect)popoverContainerView:(WEPopoverContainerView *)view willChangeFrame:(CGRect)newFrame;

@end


/**
 * Container/background view for displaying a popover view.
 */
@interface WEPopoverContainerView : UIView

@property (nonatomic, weak) id <WEPopoverContainerViewDelegate> delegate;

/**
 * The current arrow direction for the popover.
 */
@property (nonatomic, readonly) UIPopoverArrowDirection arrowDirection;

/**
 * The content view being displayed.
 */
@property (nonatomic, strong) UIView *contentView;

/**
 Whether or not the arrow is collapsed.
 */
@property (nonatomic, assign, getter=isArrowCollapsed) BOOL arrowCollapsed;

/**
 * Initializes the position of the popover with a size, anchor rect, display area and permitted arrow directions and optionally the properties. 
 * If the last is not supplied the defaults are taken (requires images to be present in bundle representing a black rounded background with partial transparency).
 */
- (id)initWithSize:(CGSize)theSize 
		anchorRect:(CGRect)anchorRect 
	   displayArea:(CGRect)displayArea
permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
		properties:(WEPopoverContainerViewProperties *)properties;

/**
 * To update the position of the popover with a new anchor rect, display area and permitted arrow directions
 */
- (void)updatePositionWithSize:(CGSize)theSize
                    anchorRect:(CGRect)anchorRect
                   displayArea:(CGRect)displayArea
      permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections;

/**
 Calculated from for position.
 */
- (CGRect)calculatedFrame;

/**
 Method to animate the transition to a new content view with the specified animation duration.
 */
- (void)setContentView:(UIView *)v withAnimationDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Set frame optionally sending a notification to the delegate.
 
 By default setFrame: does send a notification.
 */
- (void)setFrame:(CGRect)frame sendNotification:(BOOL)sendNotification;

@end
