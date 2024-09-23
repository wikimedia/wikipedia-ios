//
//  RMessageView.m
//  RMessage
//
//  Created by Adonis Peralta on 12/7/15.
//  Copyright © 2015 Adonis Peralta. All rights reserved.
//

#import "RMessageView.h"
#import "Wikipedia-Swift.h"

static NSString *const RDesignFileName = @"RMessageDefaultDesign";

/** Animation constants */
static double const kRMessageAnimationDuration = 0.3f;
static double const kRMessageDisplayTime = 1.5f;
static double const kRMessageExtraDisplayTimePerPixel = 0.04f;

/** Contains the global design dictionary specified in the entire design RDesignFile */
static NSMutableDictionary *globalDesignDictionary;

@interface RMessageView () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *titleSubtitleContainerView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleSubtitleContainerViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, strong) UIImage *iconImage;

/** Contains the appropriate design dictionary for the specified message view type */
@property (nonatomic, strong) NSDictionary *messageViewDesignDictionary;

/** The displayed title of this message */
@property (nonatomic, strong) NSString *title;

/** The displayed subtitle of this message view */
@property (nonatomic, strong) NSString *subtitle;

/** The title of the added button */
@property (nonatomic, strong) NSString *buttonTitle;

/** The view controller this message is displayed in */
@property (nonatomic, strong) UIViewController *viewController;

/** Activated for top banners only, this is the constraint that pins a banner to the top safe area */
@property (nonatomic, strong) NSLayoutConstraint *topToVCTopLayoutConstraint;

/** Activated for bottom banners only, this is the constraint that pins a banner to the bottom safe area */
@property (nonatomic, strong) NSLayoutConstraint *bottomToVCBottomLayoutConstraint;

@property (nonatomic, copy) void (^callback)(void);

@property (nonatomic, copy) void (^buttonCallback)(void);

@property (nonatomic, assign) CGFloat iconRelativeCornerRadius;
@property (nonatomic, assign) RMessageType messageType;
@property (nonatomic, copy) NSString *customTypeName;

@property (nonatomic, assign) BOOL shouldBlurBackground;

@end

@implementation RMessageView

#pragma mark - Class Methods

+ (NSError *)setupGlobalDesignDictionary
{
  if (!globalDesignDictionary) {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:RDesignFileName ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSAssert(data != nil, @"Could not read RMessage config file from main bundle with name %@.json", RDesignFileName);
    if (!data) {
      NSString *configFileErrorMessage = [NSString stringWithFormat:@"There seems to be an error"
                                                                    @"with the %@ configuration file",
                                                                    RDesignFileName];
      return [NSError errorWithDomain:[NSBundle bundleForClass:[self class]].bundleIdentifier
                                 code:0
                             userInfo:@{ NSLocalizedDescriptionKey: configFileErrorMessage }];
    }
    globalDesignDictionary = [NSMutableDictionary
      dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]];
  }
  return nil;
}

+ (void)addDesignsFromFileWithName:(NSString *)filename inBundle:(NSBundle *)bundle;
{
  [RMessageView setupGlobalDesignDictionary];
  NSString *path = [bundle pathForResource:filename ofType:@"json"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
    NSDictionary *newDesignStyle =
      [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:kNilOptions error:nil];
    [globalDesignDictionary addEntriesFromDictionary:newDesignStyle];
  } else {
    NSAssert(NO, @"Error loading design file with name %@", filename);
  }
}

+ (BOOL)isNavigationBarHiddenForNavigationController:(UINavigationController *)navController
{
  if (navController.navigationBarHidden) {
    return YES;
  } else if (navController.navigationBar.isHidden) {
    return YES;
  } else {
    return NO;
  }
}

+ (BOOL)compilingForHigherThanIosVersion:(CGFloat)version
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= version * 10000
  return YES;
#else
  return NO;
#endif
}

+ (UIViewController *)defaultViewController
{
    UIViewController *viewController = [UIApplication sharedApplication].workaroundKeyWindow.rootViewController;
    if (!viewController) {
        return nil;
    }
    UIViewController *presentedViewController = nil;
    do {
        if (![viewController.presentedViewController conformsToProtocol:@protocol(RMessageSuppressProtocol)]) {
            presentedViewController = viewController.presentedViewController;
        } else {
            presentedViewController = nil;
        }
        
        if (presentedViewController) {
            if (presentedViewController.popoverPresentationController != nil) {
                break;
            }
            viewController = presentedViewController;
        }
    } while (presentedViewController != nil);
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)viewController).viewControllers.lastObject;
    } else {
        return viewController;
    }
}

/**
 Method which determines if viewController edges extend under top bars
 (navigation bars for example). There are various scenarios and even iOS bugs in which view
 controllers that ask to present under top bars don't truly do but this method hopes to properly
 catch all these bugs and scenarios and let its caller know.
 @return YES if viewController
 */
+ (BOOL)viewControllerEdgesExtendUnderTopBars:(UIViewController *)viewController
{
  if (viewController.edgesForExtendedLayout == UIRectEdgeTop ||
      viewController.edgesForExtendedLayout == UIRectEdgeAll) {
    /* viewController is asking to extend under top bars */
  } else {
    /* viewController isn't asking to extend under top bars */
    return NO;
  }

  /* When a table view controller asks to extend under top bars, if the navigation bar is
   translucent iOS will not extend the edges of the table view controller under the top bars. */
  if ([viewController isKindOfClass:[UITableViewController class]] &&
      !viewController.navigationController.navigationBar.translucent) {
    return NO;
  }

  return YES;
}

- (UIColor *)colorForString:(NSString *)string
{
  return [self colorForString:string alpha:1.0];
}

/**
 @param string A hex string representation of a color.
 @return nil or a color.
 */
- (UIColor *)colorForString:(NSString *)string alpha:(CGFloat)alpha
{
    if (string == nil) {
        return nil;
    }
    return [[UIColor alloc] initWithHexString:string alpha:alpha];
}

#pragma mark - Get Image From Resource Bundle

+ (UIImage *)bundledImageNamed:(NSString *)name
{
  NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:nil];
  return [[UIImage alloc] initWithContentsOfFile:imagePath];
}

+ (void)activateConstraints:(NSArray *)constraints inSuperview:(UIView *)superview
{
  if ([RMessageView compilingForHigherThanIosVersion:8.f]) {
    for (NSLayoutConstraint *constraint in constraints) constraint.active = YES;
  } else {
    [superview addConstraints:constraints];
  }
}

#pragma mark - Instance Methods

- (instancetype)initWithDelegate:(id<RMessageViewProtocol>)delegate
                           title:(NSString *)title
                        subtitle:(NSString *)subtitle
                       iconImage:(UIImage *)iconImage
                            type:(RMessageType)messageType
                  customTypeName:(NSString *)customTypeName
                        duration:(CGFloat)duration
                inViewController:(UIViewController *)viewController
                        callback:(void (^)(void))callback
                     buttonTitle:(NSString *)buttonTitle
                  buttonCallback:(void (^)(void))buttonCallback
                      atPosition:(RMessagePosition)position
            canBeDismissedByUser:(BOOL)dismissingEnabled
{
  self = [[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil]
           .firstObject;
  if (self) {
    _delegate = delegate;
    _title = title;
    _buttonTitle = buttonTitle;
    _subtitle = subtitle;
    _iconImage = iconImage;
    _duration = duration;
    viewController ? _viewController = viewController : (_viewController = [RMessageView defaultViewController]);
    _messagePosition = position;
    _callback = callback;
    _messageType = messageType;
    _customTypeName = customTypeName;
    _buttonCallback = buttonCallback;

    NSError *designError = [self setupDesignDictionariesWithMessageType:_messageType customTypeName:customTypeName];
    if (designError) return nil;

    [self setupDesign];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self addToSuperviewForPresentation];
      
      // This check fixes an NSLayoutConstraint crash
      // https://phabricator.wikimedia.org/T323163
      if (self.superview) {
          [self setupLayout];
      } else {
          [self removeFromSuperview];
          return nil;
      }
      
    if (dismissingEnabled) {
        [self.closeButton setTitle:nil forState:UIControlStateNormal];
        [self.closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
      [self setupGestureRecognizers];
    } else {
        self.closeButton.hidden = YES;
    }
  }
  return self;
}

- (void)setMessageOpacity:(CGFloat)messageOpacity
{
  _messageOpacity = messageOpacity;
  self.alpha = _messageOpacity;
}

- (void)setTitleFont:(UIFont *)aTitleFont
{
  _titleFont = aTitleFont;
  [self.titleLabel setFont:_titleFont];
}

- (void)setTitleAlignment:(NSTextAlignment)titleAlignment
{
  _titleAlignment = titleAlignment;
  self.titleLabel.textAlignment = _titleAlignment;
}

- (void)setTitleTextColor:(UIColor *)aTextColor
{
  _titleTextColor = aTextColor;
  [self.titleLabel setTextColor:_titleTextColor];
}

- (void)setImageViewTintColor:(UIColor *)imageViewTintColor {
    _imageViewTintColor = imageViewTintColor;
    [self.iconImageView setTintColor:_imageViewTintColor];
}

- (void)setButtonFont:(UIFont *)buttonFont {
    _buttonFont = buttonFont;
    [self.button.titleLabel  setFont:_buttonFont];
}

- (void)setCloseIconColor:(UIColor *)closeIconColor
{
    _closeIconColor = closeIconColor;
    [self.closeButton setTintColor:closeIconColor];
}


- (void)setSubtitleFont:(UIFont *)subtitleFont
{
  _subtitleFont = subtitleFont;
  [self.subtitleLabel setFont:subtitleFont];
}

- (void)setSubtitleAlignment:(NSTextAlignment)subtitleAlignment
{
  _subtitleAlignment = subtitleAlignment;
  self.subtitleLabel.textAlignment = _subtitleAlignment;
}

- (void)setSubtitleTextColor:(UIColor *)subtitleTextColor
{
  _subtitleTextColor = subtitleTextColor;
  [self.subtitleLabel setTextColor:_subtitleTextColor];
}

- (void)setButtonTitleColor:(UIColor *)buttonTitleColor {
    _buttonTitleColor = buttonTitleColor;
    [self.button setTitleColor:_buttonTitleColor forState:UIControlStateNormal];
}

- (void)setMessageIcon:(UIImage *)messageIcon
{
  _messageIcon = messageIcon;
  [self updateCurrentIconIfNeeded];
}

- (void)setErrorIcon:(UIImage *)errorIcon
{
  _errorIcon = errorIcon;
  [self updateCurrentIconIfNeeded];
}

- (void)setSuccessIcon:(UIImage *)successIcon
{
  _successIcon = successIcon;
  [self updateCurrentIconIfNeeded];
}

- (void)setWarningIcon:(UIImage *)warningIcon
{
  _warningIcon = warningIcon;
  [self updateCurrentIconIfNeeded];
}

- (void)updateCurrentIconIfNeeded
{
  switch (self.messageType) {
  case RMessageTypeNormal: {
    self.iconImageView.image = _messageIcon;
    break;
  }
  case RMessageTypeError: {
    self.iconImageView.image = _errorIcon;
    break;
  }
  case RMessageTypeSuccess: {
    self.iconImageView.image = _successIcon;
    break;
  }
  case RMessageTypeWarning: {
      self.iconImageView.image = _warningIcon;
      break;
  }
  case RMessageTypeCustom: {
    self.iconImageView.image = _successIcon;
    break;
  }
  default:
    break;
  }
}

- (NSError *)setupDesignDictionariesWithMessageType:(RMessageType)messageType customTypeName:(NSString *)customTypeName
{
  [RMessageView setupGlobalDesignDictionary];
  NSString *messageTypeDesignString;
  switch (messageType) {
  case RMessageTypeNormal:
    messageTypeDesignString = @"normal";
    break;
  case RMessageTypeError:
    messageTypeDesignString = @"error";
    break;
  case RMessageTypeSuccess:
    messageTypeDesignString = @"success";
    break;
  case RMessageTypeWarning:
    messageTypeDesignString = @"warning";
    break;
  case RMessageTypeCustom:
    NSParameterAssert(customTypeName != nil);
    NSParameterAssert(![customTypeName isEqualToString:@""]);
    if (!customTypeName || [customTypeName isEqualToString:@""]) {
      return
        [NSError errorWithDomain:[NSBundle bundleForClass:[self class]].bundleIdentifier
                            code:0
                        userInfo:@{
                          NSLocalizedDescriptionKey: @"When specifying a type RMessageTypeCustom make sure to pass in "
                                                     @"a valid argument for customTypeName parameter. This string "
                                                     @"should match a Key in your custom design file."
                        }];
    }
    messageTypeDesignString = customTypeName;
    break;
  default:
    break;
  }

  _messageViewDesignDictionary = [globalDesignDictionary valueForKey:messageTypeDesignString];
  NSParameterAssert(_messageViewDesignDictionary != nil);
  if (!_messageViewDesignDictionary) {
    return
      [NSError errorWithDomain:[NSBundle bundleForClass:[self class]].bundleIdentifier
                          code:0
                      userInfo:@{
                        NSLocalizedDescriptionKey: @"When specifying a type RMessageTypeCustom make sure to pass in a "
                                                   @"valid argument for customTypeName parameter. This string should "
                                                   @"match a Key in your custom design file."
                      }];
  }
  return nil;
}

- (void)setupDesign
{
  [self setupDesignDefaults];
  [self setupImagesAndBackground];
  [self setupTitleLabel];
  [self setupSubTitleLabel];
  [self setupButton];

  if (self.messagePosition != RMessagePositionBottom) {
    self.layer.shadowOffset = CGSizeMake(0, 2);
  } else {
    self.layer.shadowOffset = CGSizeMake(0, -2);
  }
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 1.0;

    self.clipsToBounds = NO;
}

- (void)setupLayout
{
  if (self.messagePosition != RMessagePositionBottom) {
    self.topToVCTopLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.superview
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.f
                                                                 constant:0.f];
  } else {
    self.bottomToVCBottomLayoutConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.superview
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.f
                                                                 constant:0.f];
  }

  NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.superview
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1.f
                                                                        constant:0.f];
  NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.superview
                                                                        attribute:NSLayoutAttributeTrailing
                                                                       multiplier:1.f
    
                                                                         constant:0.f];
    if (self.messagePosition != RMessagePositionBottom) {
        [[self class] activateConstraints:@[leadingConstraint, trailingConstraint, self.topToVCTopLayoutConstraint] inSuperview:self];
    } else {
        [[self class] activateConstraints:@[leadingConstraint, trailingConstraint, self.bottomToVCBottomLayoutConstraint] inSuperview:self];
    }
  if (self.shouldBlurBackground) [self setupBlurBackground];
    
    // Initially set it off screen
    [self setNeedsLayout];
    [self layoutIfNeeded];
    self.topToVCTopLayoutConstraint.constant = self.bounds.size.height - [self customVerticalOffset];
    self.bottomToVCBottomLayoutConstraint.constant = self.bounds.size.height - [self customVerticalOffset];
}

- (void)setupBackgroundImageViewWithImage:(UIImage *)image
{
  _backgroundImageView = [[UIImageView alloc] initWithImage:image];
  _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _backgroundImageView.contentMode = UIViewContentModeScaleToFill;
  [self insertSubview:_backgroundImageView atIndex:0];
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[backgroundImageView]-0-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{
                                                                      @"backgroundImageView": _backgroundImageView
                                                                    }];
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[backgroundImageView]-0-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{
                                                                      @"backgroundImageView": _backgroundImageView
                                                                    }];
  [[self class] activateConstraints:hConstraints inSuperview:self];
  [[self class] activateConstraints:vConstraints inSuperview:self];
}

- (void)setupBlurBackground
{
  UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
  blurView.translatesAutoresizingMaskIntoConstraints = NO;
  [self insertSubview:blurView atIndex:0];
  NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[blurBackgroundView]-0-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{
                                                                      @"blurBackgroundView": blurView
                                                                    }];
  NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[blurBackgroundView]-0-|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{
                                                                      @"blurBackgroundView": blurView
                                                                    }];
  [[self class] activateConstraints:hConstraints inSuperview:self];
  [[self class] activateConstraints:vConstraints inSuperview:self];
}

- (void)executeMessageViewCallBack
{
  if (self.callback) self.callback();
}

- (void)executeMessageViewButtonCallBack
{
  if (self.buttonCallback) self.buttonCallback();
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (self.duration == RMessageDurationEndless && self.superview && !self.window) {
    if (self.delegate && [self.delegate respondsToSelector:@selector(windowRemovedForEndlessDurationMessageView:)]) {
      [self.delegate windowRemovedForEndlessDurationMessageView:self];
    }
  }
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  if (self.iconRelativeCornerRadius > 0) {
    self.iconImageView.layer.cornerRadius = self.iconRelativeCornerRadius * self.iconImageView.bounds.size.width;
  }
  [self setPositioningConstraintsAndLayout];
}

- (void)setupDesignDefaults
{
  self.backgroundColor = nil;
  self.messageOpacity = 0.97f;
  _shouldBlurBackground = NO;
  _titleLabel.numberOfLines = 0;
  _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _titleLabel.font = [WMFFontWrapper fontFor:WMFFontsSubheadline compatibleWithTraitCollection:self.traitCollection];
  _titleLabel.textAlignment = NSTextAlignmentLeft;
  _titleLabel.textColor = [UIColor blackColor];
  _titleLabel.shadowColor = nil;
  _titleLabel.shadowOffset = CGSizeZero;
  _titleLabel.backgroundColor = nil;

  _subtitleLabel.numberOfLines = 0;
  _subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _subtitleLabel.font = [WMFFontWrapper fontFor:WMFFontsCaption1 compatibleWithTraitCollection:self.traitCollection];
  _subtitleLabel.textAlignment = NSTextAlignmentLeft;
  _subtitleLabel.textColor = [UIColor darkGrayColor];
  _subtitleLabel.shadowColor = nil;
  _subtitleLabel.shadowOffset = CGSizeZero;
  _subtitleLabel.backgroundColor = nil;

    _button.titleLabel.numberOfLines = 0;
    _button.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _button.titleLabel.font = [WMFFontWrapper fontFor:WMFFontsCaption1 compatibleWithTraitCollection:self.traitCollection];
    _button.titleLabel.textAlignment = NSTextAlignmentLeft;
    _button.titleLabel.textColor = [UIColor darkGrayColor];
    _button.titleLabel.shadowColor = nil;
    _button.titleLabel.shadowOffset = CGSizeZero;
    _button.titleLabel.backgroundColor = nil;

  _iconImageView.clipsToBounds = NO;
}

- (void)setupImagesAndBackground
{
  UIColor *backgroundColor;
  if (_messageViewDesignDictionary[@"backgroundColor"] && _messageViewDesignDictionary[@"backgroundColorAlpha"]) {
    backgroundColor = [self colorForString:_messageViewDesignDictionary[@"backgroundColor"]
                                     alpha:[_messageViewDesignDictionary[@"backgroundColorAlpha"] floatValue]];
  } else if (_messageViewDesignDictionary[@"backgroundColor"]) {
    backgroundColor = [self colorForString:_messageViewDesignDictionary[@"backgroundColor"]];
  }

  if (backgroundColor) self.backgroundColor = backgroundColor;
  if (_messageViewDesignDictionary[@"opacity"]) {
    self.messageOpacity = [_messageViewDesignDictionary[@"opacity"] floatValue];
  }

  if ([_messageViewDesignDictionary[@"blurBackground"] floatValue] == 1) {
    _shouldBlurBackground = YES;
    /* As per apple docs when using UIVisualEffectView and blurring the superview of the blur view
    must have an opacity of 1.f */
    self.messageOpacity = 1.f;
  }

  if (!_iconImage && ((NSString *)[_messageViewDesignDictionary valueForKey:@"iconImage"]).length > 0) {
    _iconImage = [RMessageView bundledImageNamed:[_messageViewDesignDictionary valueForKey:@"iconImage"]];
    if (!_iconImage) {
      _iconImage = [UIImage imageNamed:[_messageViewDesignDictionary valueForKey:@"iconImage"]];
    }
  }

  if (_iconImage) {
    _iconImageView = [[UIImageView alloc] initWithImage:_iconImage];
    if ([_messageViewDesignDictionary valueForKey:@"iconImageRelativeCornerRadius"]) {
      self.iconRelativeCornerRadius =
        [[_messageViewDesignDictionary valueForKey:@"iconImageRelativeCornerRadius"] floatValue];
      _iconImageView.clipsToBounds = YES;
    } else {
      self.iconRelativeCornerRadius = 0.f;
      _iconImageView.clipsToBounds = YES;
    }
    [self setupIconImageView];
  }

  UIImage *backgroundImage =
    [RMessageView bundledImageNamed:[_messageViewDesignDictionary valueForKey:@"backgroundImage"]];
  if (backgroundImage) {
    backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)
                                                      resizingMode:UIImageResizingModeStretch];
    [self setupBackgroundImageViewWithImage:backgroundImage];
  }
}

- (void)setupTitleLabel
{
  [_titleLabel setHidden:_title == NULL];
  CGFloat titleFontSize = [[_messageViewDesignDictionary valueForKey:@"titleFontSize"] floatValue];
  NSString *titleFontName = [_messageViewDesignDictionary valueForKey:@"titleFontName"];
  if (titleFontName) {
    _titleLabel.font = [UIFont fontWithName:titleFontName size:titleFontSize];
  } else if (titleFontSize) {
    _titleLabel.font = [UIFont boldSystemFontOfSize:titleFontSize];
  }

  self.titleLabel.textAlignment =
    [self textAlignmentForString:[_messageViewDesignDictionary valueForKey:@"titleTextAlignment"]];

  UIColor *titleTextColor = [self colorForString:[_messageViewDesignDictionary valueForKey:@"titleTextColor"]];
  _titleLabel.text = _title ? _title : @"";
    if (titleTextColor) {
        _titleLabel.textColor = titleTextColor;
    }

  UIColor *titleShadowColor = [self colorForString:[_messageViewDesignDictionary valueForKey:@"titleShadowColor"]];
  if (titleShadowColor) _titleLabel.shadowColor = titleShadowColor;
  id titleShadowOffsetX = [_messageViewDesignDictionary valueForKey:@"titleShadowOffsetX"];
  id titleShadowOffsetY = [_messageViewDesignDictionary valueForKey:@"titleShadowOffsetY"];
  if (titleShadowOffsetX && titleShadowOffsetY) {
    _titleLabel.shadowOffset = CGSizeMake([titleShadowOffsetX floatValue], [titleShadowOffsetY floatValue]);
  }
}

-(void)setupButton {
    if (_buttonTitle) {
        [_button setHidden:NO];
        [_button setTitle:_buttonTitle forState:UIControlStateNormal];
        _stackView.spacing = -5;
        [_button addTarget:self action:@selector(executeMessageViewButtonCallBack) forControlEvents:UIControlEventTouchUpInside];
        _button.titleLabel.font = [WMFFontWrapper fontFor:WMFFontsSubheadline compatibleWithTraitCollection:self.traitCollection];
    } else {
        [_button setHidden:YES];
        _stackView.spacing = 5;
    }
}

- (void)setupSubTitleLabel
{
  [_subtitleLabel setHidden:_subtitle == NULL];
  id subTitleFontSizeValue = [_messageViewDesignDictionary valueForKey:@"subTitleFontSize"];
  if (!subTitleFontSizeValue) {
    subTitleFontSizeValue = [_messageViewDesignDictionary valueForKey:@"subtitleFontSize"];
  }

  CGFloat subTitleFontSize = [subTitleFontSizeValue floatValue];
  NSString *subTitleFontName = [_messageViewDesignDictionary valueForKey:@"subTitleFontName"];
  if (!subTitleFontName) {
    subTitleFontName = [_messageViewDesignDictionary valueForKey:@"subtitleFontName"];
  }

  if (subTitleFontName) {
    _subtitleLabel.font = [UIFont fontWithName:subTitleFontName size:subTitleFontSize];
  } else if (subTitleFontSize) {
    _subtitleLabel.font = [UIFont systemFontOfSize:subTitleFontSize];
  }

  self.subtitleLabel.textAlignment =
    [self textAlignmentForString:[_messageViewDesignDictionary valueForKey:@"subtitleTextAlignment"]];

  UIColor *subTitleTextColor = [self colorForString:[_messageViewDesignDictionary valueForKey:@"subTitleTextColor"]];
  if (!subTitleTextColor) {
    subTitleTextColor = [self colorForString:[_messageViewDesignDictionary valueForKey:@"subtitleTextColor"]];
  }
  if (!subTitleTextColor) {
    subTitleTextColor = _titleLabel.textColor;
  }

  _subtitleLabel.text = _subtitle ? _subtitle : @"";
  if (subTitleTextColor) _subtitleLabel.textColor = subTitleTextColor;

  UIColor *subTitleShadowColor =
    [self colorForString:[_messageViewDesignDictionary valueForKey:@"subTitleShadowColor"]];
  if (!subTitleShadowColor) {
    subTitleShadowColor = [self colorForString:[_messageViewDesignDictionary valueForKey:@"subtitleShadowColor"]];
  }

  if (subTitleShadowColor) _subtitleLabel.shadowColor = subTitleShadowColor;
  id subTitleShadowOffsetX = [_messageViewDesignDictionary valueForKey:@"subTitleShadowOffsetX"];
  id subTitleShadowOffsetY = [_messageViewDesignDictionary valueForKey:@"subTitleShadowOffsetY"];
  if (!subTitleShadowOffsetX) {
    subTitleShadowOffsetX = [_messageViewDesignDictionary valueForKey:@"subtitleShadowOffsetX"];
  }
  if (!subTitleShadowOffsetY) {
    subTitleShadowOffsetY = [_messageViewDesignDictionary valueForKey:@"subtitleShadowOffsetY"];
  }
  if (subTitleShadowOffsetX && subTitleShadowOffsetY) {
    _subtitleLabel.shadowOffset = CGSizeMake([subTitleShadowOffsetX floatValue], [subTitleShadowOffsetY floatValue]);
  }
}

- (void)setupIconImageView
{
  self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
  self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;

  NSLayoutConstraint *imgViewCenterY = [NSLayoutConstraint constraintWithItem:self.iconImageView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.titleSubtitleContainerView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.f
                                                                     constant:0.f];
  NSLayoutConstraint *imgViewLeading = [NSLayoutConstraint constraintWithItem:self.iconImageView
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.safeAreaLayoutGuide
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.f
                                                                     constant:15.f];
  NSLayoutConstraint *imgViewTrailing = [NSLayoutConstraint constraintWithItem:self.iconImageView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                        toItem:self.titleSubtitleContainerView
                                                                     attribute:NSLayoutAttributeLeading
                                                                    multiplier:1.f
                                                                      constant:-10.f];
  NSLayoutConstraint *imgViewHeight = [NSLayoutConstraint constraintWithItem:self.iconImageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.iconImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                    multiplier:1.f
                                                                      constant:1.f];
  self.titleSubtitleContainerViewLeadingConstraint.constant = 55.0;
    
  [self addSubview:self.iconImageView];
  [[self class] activateConstraints:@[imgViewCenterY, imgViewLeading, imgViewTrailing, imgViewHeight] inSuperview:self];
}

- (void)setupGestureRecognizers
{
  UISwipeGestureRecognizer *gestureRecognizer =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeToDismissMessageView:)];
  [gestureRecognizer
   setDirection:(self.messagePosition == RMessagePositionBottom) ? UISwipeGestureRecognizerDirectionDown : UISwipeGestureRecognizerDirectionUp];
  [self addGestureRecognizer:gestureRecognizer];

  UITapGestureRecognizer *tapRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapMessageView:)];
  [self addGestureRecognizer:tapRecognizer];
}

#pragma mark - Gesture Recognizers

/* called after the following gesture depending on message position during initialization
 UISwipeGestureRecognizerDirectionUp when message position set to Top,
 UISwipeGestureRecognizerDirectionDown when message position set to bottom */
- (void)didSwipeToDismissMessageView:(UISwipeGestureRecognizer *)swipeGesture
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(didSwipeToDismissMessageView:)]) {
    [self.delegate didSwipeToDismissMessageView:self];
  }
}

- (void)didTapMessageView:(UITapGestureRecognizer *)tapGesture
{
  if (self.delegate && [self.delegate respondsToSelector:@selector(didTapMessageView:)]) {
    [self.delegate didTapMessageView:self];
  }
}

- (void)closeButtonTapped:(UIButton *)sender {

    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapCloseButtonOnMessageView:)]) {
      [self.delegate didTapCloseButtonOnMessageView:self];
    }

}

#pragma mark - Presentation Methods

- (void)present
{
  [self animateMessage];

  if (self.duration == RMessageDurationAutomatic) {
    self.duration =
      kRMessageAnimationDuration + kRMessageDisplayTime + self.frame.size.height * kRMessageExtraDisplayTimePerPixel;
  }

  if (self.duration != RMessageDurationEndless) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSelector:@selector(dismiss) withObject:self afterDelay:self.duration];
    });
  }
}

- (void)addToSuperviewForPresentation
{
    [self.viewController.view addSubview:self];
}

- (void)animateMessage
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.superview layoutIfNeeded];
    if (!self.shouldBlurBackground) self.alpha = 0.f;
    [UIView animateWithDuration:kRMessageAnimationDuration + 0.2f
                          delay:0.f
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.f
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.isPresenting = YES;
                       if ([self.delegate respondsToSelector:@selector(messageViewIsPresenting:)]) {
                         [self.delegate messageViewIsPresenting:self];
                       }
                       if (!self.shouldBlurBackground) self.alpha = self.messageOpacity;
                       [self setPositioningConstraintsAndLayout];
                     }
                     completion:^(BOOL finished) {
                       self.isPresenting = NO;
                       self.messageIsFullyDisplayed = YES;
                       if ([self.delegate respondsToSelector:@selector(messageViewDidPresent:)]) {
                         [self.delegate messageViewDidPresent:self];
                       }
                     }];
  });
}

- (void)setPositioningConstraintsAndLayout {
    self.topToVCTopLayoutConstraint.constant = 0 + [self customVerticalOffset];
    self.bottomToVCBottomLayoutConstraint.constant = 0 + [self customVerticalOffset];
    [self.superview layoutIfNeeded];
}

- (void)dismiss
{
  [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void (^)(void))completionBlock
{
  self.messageIsFullyDisplayed = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:self];

    [UIView animateWithDuration:kRMessageAnimationDuration
                     animations:^{
                       if (!self.shouldBlurBackground) self.alpha = 0.f;
                        self.topToVCTopLayoutConstraint.constant = self.bounds.size.height - [self customVerticalOffset];
                        self.bottomToVCBottomLayoutConstraint.constant = self.bounds.size.height - [self customVerticalOffset];
                       [self.superview layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                       [self removeFromSuperview];
                       if ([self.delegate respondsToSelector:@selector(messageViewDidDismiss:)]) {
                         [self.delegate messageViewDidDismiss:self];
                       }
                       if (completionBlock) completionBlock();
                     }];
  });
}

#pragma mark - Misc methods

- (void)interfaceDidRotate
{
  if (self.isPresenting) [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:self];
}

/**
 Get the custom vertical offset from the delegate if any
 @return a custom vertical offset or 0.f
 */
- (CGFloat)customVerticalOffset
{
  CGFloat customVerticalOffset = 0.f;
  if (self.delegate && [self.delegate respondsToSelector:@selector(customVerticalOffsetForMessageView:)]) {
    customVerticalOffset = [self.delegate customVerticalOffsetForMessageView:self];
  }
  return customVerticalOffset;
}

- (NSTextAlignment)textAlignmentForString:(NSString *)textAlignment
{
  if ([textAlignment isEqualToString:@"left"]) {
    return NSTextAlignmentLeft;
  } else if ([textAlignment isEqualToString:@"right"]) {
    return NSTextAlignmentRight;
  } else if ([textAlignment isEqualToString:@"center"]) {
    return NSTextAlignmentCenter;
  } else if ([textAlignment isEqualToString:@"justified"]) {
    return NSTextAlignmentJustified;
  } else if ([textAlignment isEqualToString:@"natural"]) {
    return NSTextAlignmentNatural;
  } else {
    return NSTextAlignmentLeft;
  }
}

@end
