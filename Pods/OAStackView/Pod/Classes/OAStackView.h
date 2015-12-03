//
//  OAStackView.h
//  OAStackView
//
//  Created by Omar Abdelhafith on 14/06/2015.
//  Copyright © 2015 Omar Abdelhafith. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OAStackViewDistribution) {
  
  /* When items do not fit (overflow) or fill (underflow) the space available
   adjustments occur according to compressionResistance or hugging
   priorities of items, or when that is ambiguous, according to arrangement
   order.
   */
  OAStackViewDistributionFill = 0,
  
  /* Items are all the same size.
   When space allows, this will be the size of the item with the largest
   intrinsicContentSize (along the axis of the stack).
   Overflow or underflow adjustments are distributed equally among the items.
   */
  OAStackViewDistributionFillEqually,
  
  /* Overflow or underflow adjustments are distributed among the items proportional
   to their intrinsicContentSizes.
   */
  OAStackViewDistributionFillProportionally,
  
  /* Additional underflow spacing is divided equally in the spaces between the items.
   Overflow squeezing is controlled by compressionResistance priorities followed by
   arrangement order.
   */
  OAStackViewDistributionEqualSpacing,
  
  /* Equal center-to-center spacing of the items is maintained as much
   as possible while still maintaining a minimum edge-to-edge spacing within the
   allowed area.
   Additional underflow spacing is divided equally in the spacing. Overflow
   squeezing is distributed first according to compressionResistance priorities
   of items, then according to subview order while maintaining the configured
   (edge-to-edge) spacing as a minimum.
   */
  OAStackViewDistributionEqualCentering,
};

typedef NS_ENUM(NSInteger, OAStackViewAlignment) {
  OAStackViewAlignmentFill,
  
  /* Align the leading edges of vertically stacked items
   or the top edges of horizontally stacked items tightly to the relevant edge
   of the container
   */
  OAStackViewAlignmentLeading,
  OAStackViewAlignmentTop = OAStackViewAlignmentLeading,
  OAStackViewAlignmentFirstBaseline NS_ENUM_AVAILABLE_IOS(8_0), // Valid for horizontal axis only
  
  /* Center the items in a vertical stack horizontally
   or the items in a horizontal stack vertically
   */
  OAStackViewAlignmentCenter,
  
  /* Align the trailing edges of vertically stacked items
   or the bottom edges of horizontally stacked items tightly to the relevant
   edge of the container
   */
  OAStackViewAlignmentTrailing,
  OAStackViewAlignmentBottom = OAStackViewAlignmentTrailing,
  OAStackViewAlignmentBaseline,
  OAStackViewAlignmentLastBaseline = OAStackViewAlignmentBaseline, // Valid for horizontal axis only
};

// Keep older versions of the compiler happy
#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define nullable
#define nonnullable
#define __nullable
#endif

NS_ASSUME_NONNULL_BEGIN

// Define the `OAStackViewDisableForwardToUIStackViewSentinel` to disable the automatic forwarding to OAStackView on iOS 7+. (Copy below line into your AppDelegate.m)
//@interface OAStackViewDisableForwardToUIStackViewSentinel : NSObject @end
//@implementation OAStackViewDisableForwardToUIStackViewSentinel @end

@interface OAStackView : UIView

@property(nonatomic,readonly,copy) NSArray<__kindof UIView *> *arrangedSubviews;

//Default is Vertical
@property(nonatomic) UILayoutConstraintAxis axis;
@property(nonatomic) IBInspectable NSInteger axisValue;

@property(nonatomic) IBInspectable CGFloat spacing;

//Default is Fill
@property(nonatomic) OAStackViewAlignment alignment;
@property(nonatomic) IBInspectable NSInteger alignmentValue;


@property(nonatomic) OAStackViewDistribution distribution;
@property(nonatomic) IBInspectable NSInteger distributionValue;

//layoutMargins has been added to OAStackView since iOS 7 does not include a layout margin
@property(nonatomic) UIEdgeInsets layoutMargins;

@property(nonatomic, getter=isLayoutMarginsRelativeArrangement) BOOL layoutMarginsRelativeArrangement;

- (instancetype)initWithArrangedSubviews:(NSArray<__kindof UIView *> *)views NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (void)addArrangedSubview:(UIView *)view;
- (void)removeArrangedSubview:(UIView *)view;
- (void)insertArrangedSubview:(UIView *)view atIndex:(NSUInteger)stackIndex;

@end
NS_ASSUME_NONNULL_END
