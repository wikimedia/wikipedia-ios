#pragma mark Defines

#define CHROME_MENUS_HEIGHT_TABLET 66.0
#define CHROME_MENUS_HEIGHT_PHONE 46.0

#define CHROME_MENUS_HEIGHT ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? CHROME_MENUS_HEIGHT_TABLET : CHROME_MENUS_HEIGHT_PHONE)

// Use this and UIView+ConstraintsScale to make scale for iPads.
// Make layouts work for phone first, then apply multiplier to scalar values
// and use UIView+ConstraintsScale methods to make layout also work with iPads.
#define MENUS_SCALE_MULTIPLIER (CHROME_MENUS_HEIGHT / CHROME_MENUS_HEIGHT_PHONE)

#define CHROME_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]
