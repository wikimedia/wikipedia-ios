//
//  _OALayoutGuide.m
//  Pods
//

#import "_OALayoutGuide.h"
#import "OATransformLayer.h"

@interface _OALayoutGuide ()

@property (nonatomic) BOOL propertiesAreLocked;

@end

@implementation _OALayoutGuide

+ (Class)layerClass
{
  return [OATransformLayer class];
}

+ (BOOL)requiresConstraintBasedLayout
{
  return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self  = [super initWithCoder:aDecoder];
  if (!self) { return nil; }

  [self commonInit];

  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  self  = [super initWithFrame:frame];
  if (!self) { return nil; }

  [self commonInit];

  return self;
}

- (void)commonInit
{
  self.translatesAutoresizingMaskIntoConstraints = NO;
  self.userInteractionEnabled = NO;
  self.hidden = YES;

  self.propertiesAreLocked = YES;
}

- (void)setHidden:(BOOL)hidden
{
  NSAssert(!self.propertiesAreLocked, @"Properties are no longer mutable");
  [super setHidden:hidden];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
  NSAssert(!self.propertiesAreLocked, @"Properties are no longer mutable");
  [super setUserInteractionEnabled:userInteractionEnabled];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {}

- (void)setOpaque:(BOOL)opaque {}

- (void)setClipsToBounds:(BOOL)clipsToBounds {}

@end
