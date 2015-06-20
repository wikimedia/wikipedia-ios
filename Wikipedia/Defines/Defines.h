#pragma mark Defines

#import "WMF_Colors.h"

#define CHROME_MENUS_HEIGHT_TABLET 66.0
#define CHROME_MENUS_HEIGHT_PHONE 46.0

#define CHROME_MENUS_HEIGHT ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CHROME_MENUS_HEIGHT_TABLET : CHROME_MENUS_HEIGHT_PHONE)

// Use this and UIView+ConstraintsScale to make scale for iPads.
// Make layouts work for phone first, then apply multiplier to scalar values
// and use UIView+ConstraintsScale methods to make layout also work with iPads.
#define MENUS_SCALE_MULTIPLIER (CHROME_MENUS_HEIGHT / CHROME_MENUS_HEIGHT_PHONE)

#define SEARCH_THUMBNAIL_WIDTH (48 * 3)
#define SEARCH_MAX_RESULTS 24

#define HIDE_KEYBOARD_ON_SCROLL_THRESHOLD 55.0f

#define THUMBNAIL_MINIMUM_SIZE_TO_CACHE CGSizeMake(35, 35)

#define CHROME_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]

#define ALERT_FONT_SIZE (12.0 * MENUS_SCALE_MULTIPLIER)
#define ALERT_BACKGROUND_COLOR [UIColor grayColor]
#define ALERT_TEXT_COLOR [UIColor whiteColor]
#define ALERT_PADDING UIEdgeInsetsMake(2.0, 10.0, 2.0, 10.0)

#define CHROME_OUTLINE_COLOR ALERT_BACKGROUND_COLOR
#define CHROME_OUTLINE_WIDTH (1.0f / [UIScreen mainScreen].scale)
