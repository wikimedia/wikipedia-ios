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
#define SEARCH_RESULT_HEIGHT (74.0 * MENUS_SCALE_MULTIPLIER)
#define SEARCH_MAX_RESULTS 24

#define SEARCH_TEXT_FIELD_FONT [UIFont systemFontOfSize:(14.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_TEXT_FIELD_HIGHLIGHTED_COLOR [UIColor blackColor]

#define SEARCH_RESULT_FONT [UIFont systemFontOfSize:(16.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_RESULT_FONT_COLOR [UIColor colorWithWhite:0.15 alpha:1.0]

#define SEARCH_RESULT_DESCRIPTION_FONT [UIFont systemFontOfSize:(12.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_RESULT_DESCRIPTION_FONT_COLOR [UIColor colorWithWhite:0.4 alpha:1.0]

#define SEARCH_RESULT_SNIPPET_FONT [UIFont italicSystemFontOfSize:(12.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_RESULT_SNIPPET_FONT_COLOR [UIColor blackColor]
#define SEARCH_RESULT_SNIPPET_HIGHLIGHT_COLOR WMF_COLOR_BLUE

#define SEARCH_RESULT_FONT_HIGHLIGHTED [UIFont boldSystemFontOfSize:(16.0 * MENUS_SCALE_MULTIPLIER)]
#define SEARCH_RESULT_FONT_HIGHLIGHTED_COLOR [UIColor blackColor]

#define SEARCH_RESULT_PADDING_ABOVE_DESCRIPTION 2.0f
#define SEARCH_RESULT_PADDING_ABOVE_SNIPPET 3.0f

#define SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0]

#define SEARCH_BUTTON_BACKGROUND_COLOR [UIColor grayColor]

#define HIDE_KEYBOARD_ON_SCROLL_THRESHOLD 55.0f

#define THUMBNAIL_MINIMUM_SIZE_TO_CACHE CGSizeMake(100, 100)

#define EDIT_SUMMARY_DOCK_DISTANCE_FROM_BOTTOM 68.0f

#define MENU_TOP_GLYPH_FONT_SIZE (34.0 * MENUS_SCALE_MULTIPLIER)

#define MENU_TOP_FONT_SIZE_CANCEL (17.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_NEXT (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_SAVE (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_DONE (14.0 * MENUS_SCALE_MULTIPLIER)
#define MENU_TOP_FONT_SIZE_CHECK (25.0 * MENUS_SCALE_MULTIPLIER)

#define MENU_BOTTOM_GLYPH_FONT_SIZE (34.0 * MENUS_SCALE_MULTIPLIER)

#define CHROME_COLOR [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0]

#define ALERT_FONT_SIZE (12.0 * MENUS_SCALE_MULTIPLIER)
#define ALERT_BACKGROUND_COLOR [UIColor grayColor]
#define ALERT_TEXT_COLOR [UIColor whiteColor]
#define ALERT_PADDING UIEdgeInsetsMake(2.0, 10.0, 2.0, 10.0)

#define CHROME_OUTLINE_COLOR ALERT_BACKGROUND_COLOR
#define CHROME_OUTLINE_WIDTH (1.0f / [UIScreen mainScreen].scale)

#define SEARCH_DELAY_PREFIX 0.4
#define SEARCH_DELAY_FULL_TEXT 1.0

// Temporary flags for hiding full text search interface and wikidata
// descriptions (in search results) until both are production ready.
// Full text search interface has a couple UX changes brewing and
// wikidata awaits api "prop=pageterms" going live so we don't have
// to do separate non-performant request to get descriptions.
#define ENABLE_FULL_TEXT_SEARCH NO
#define ENABLE_WIKIDATA_DESCRIPTIONS NO


