//
//  WEPopoverContainerViewProperties.h
//  WEPopover
//
//  Created by Werner Altewischer on 19/11/15.
//  Copyright © 2015 Werner IT Consultancy. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Properties for the container view determining the area where the actual content view can/may be displayed. Also Images can be supplied for the arrow images and background.
 */
@interface WEPopoverContainerViewProperties : NSObject

/**
 Margins for offsetting the background view for the content.
 */
@property(nonatomic, assign) UIEdgeInsets backgroundMargins;

/**
 Margins for insetting the content view within the container view.
 */
@property(nonatomic, assign) UIEdgeInsets contentMargins;

/**
 Top cap size for resizing the background image.
 */
@property(nonatomic, assign) NSInteger topBgCapSize;

/**
 Left cap size for resizing the background image.
 */
@property(nonatomic, assign) NSInteger leftBgCapSize;

/**
 Arrow margin to offset the arrow sideways from the borders of the content view.
 */
@property(nonatomic, assign) CGFloat arrowMargin;

/**
 If set with non-zero boder width, a border with the specified color is applied to the background.
 */
@property(nonatomic, strong) UIColor *maskBorderColor;

/**
 The width for the border.
 */
@property(nonatomic, assign) CGFloat maskBorderWidth;

/**
 Corner radios for the background.
 */
@property(nonatomic, assign) CGFloat maskCornerRadius;

/**
 Background color for the container view.
 */
@property(nonatomic, strong) UIColor *backgroundColor;

/**
 Image for the up arrow.
 */
@property(nonatomic, strong) UIImage *upArrowImage;

/**
 Image for the down arrow.
 */
@property(nonatomic, strong) UIImage *downArrowImage;

/**
 Image for the left arrow.
 */
@property(nonatomic, strong) UIImage *leftArrowImage;

/**
 Image for the right arrow.
 */
@property(nonatomic, strong) UIImage *rightArrowImage;

/**
 * If set a shadow will be applied around the background for the popover with this color
 */
@property(nonatomic, strong) UIColor *shadowColor;

/**
 * Radius for the shadow, requires shadowColor to be set. Defaults to 3.0
 */
@property(nonatomic, assign) CGFloat shadowRadius;

/**
 * Offset for the shadow, requires shadowColor to be set. Defaults to CGSizeZero
 */
@property(nonatomic, assign) CGSize shadowOffset;

/**
 * Opacity for the shadow, requires shadowColor to be set. Defaults to 0.5
 */
@property(nonatomic, assign) CGFloat shadowOpacity;

/**
 Image to apply as background.
 
 Is resized automatically using the topBgCapSize and leftBgCapSize.
 */
@property(nonatomic, strong) UIImage *bgImage;

//Deprecated: use upArrowImage, downArrowImage, etc instead.
@property(nonatomic, strong) NSString *upArrowImageName;
@property(nonatomic, strong) NSString *downArrowImageName;
@property(nonatomic, strong) NSString *leftArrowImageName;
@property(nonatomic, strong) NSString *rightArrowImageName;
@property(nonatomic, strong) NSString *bgImageName;

@end

