
// From: https://trello.com/c/IRqbu8p4/15-color-swatches

#define WMF_COLOR_GREEN [UIColor colorWithRed:0.00 green:0.69 blue:0.54 alpha:1.0]
#define WMF_COLOR_GREEN_DARK [UIColor colorWithRed:0.05 green:0.44 blue:0.31 alpha:1.0]
#define WMF_COLOR_BLUE [UIColor colorWithRed:0.2039 green:0.4824 blue:1.0 alpha:1.0]
#define WMF_COLOR_BLUE_DARK [UIColor colorWithRed:0.0980 green:0.2667 blue:0.7608 alpha:1.0]
#define WMF_COLOR_RED [UIColor colorWithRed:0.82 green:0.09 blue:0.07 alpha:1.0]
#define WMF_COLOR_RED_DARK [UIColor colorWithRed:0.55 green:0.00 blue:0.00 alpha:1.0]
#define WMF_COLOR_ORANGE [UIColor colorWithRed:1.00 green:0.36 blue:0.00 alpha:1.0]
#define WMF_COLOR_ORANGE_DARK [UIColor colorWithRed:0.88 green:0.25 blue:0.00 alpha:1.0]
#define WMF_COLOR_YELLOW [UIColor colorWithRed:1.00 green:0.71 blue:0.05 alpha:1.0]
#define WMF_COLOR_YELLOW_DARK [UIColor colorWithRed:0.88 green:0.59 blue:0.00 alpha:1.0]


// RGB color macro with alpha. From http://cocoamatic.blogspot.com/2010/07/uicolor-macro-with-hex-values.html

#define UIColorFromRGBWithAlpha(rgbValue, a) [UIColor \
colorWithRed: ((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green: ((float)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue: ((float)(rgbValue & 0xFF)) / 255.0 alpha : a]
