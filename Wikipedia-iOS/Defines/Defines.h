#pragma mark Defines

//TODO: go through each of these, consolidate & return to respective files!

#define SEARCH_THUMBNAIL_WIDTH 110
#define SEARCH_RESULT_HEIGHT 60
#define SEARCH_MAX_RESULTS @"25"

#define SEARCH_FONT [UIFont fontWithName:@"HelveticaNeue" size:16.0]
#define SEARCH_FONT_COLOR [UIColor colorWithWhite:0.0 alpha:0.85]

#define SEARCH_FONT_HIGHLIGHTED [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0]
#define SEARCH_FONT_HIGHLIGHTED_COLOR [UIColor blackColor]

#define SEARCH_FIELD_PLACEHOLDER_TEXT @"Search Wikipedia"
#define SEARCH_FIELD_PLACEHOLDER_TEXT_COLOR [UIColor colorWithRed:0.57 green:0.58 blue:0.59 alpha:1.0]

#define SEARCH_API_URL @"https://en.m.wikipedia.org/w/api.php"

#define SEARCH_LOADING_MSG_SECTION_ZERO @"Loading first section of the article..."
#define SEARCH_LOADING_MSG_SECTION_REMAINING @"Loading the rest of the article..."
#define SEARCH_LOADING_MSG_ARTICLE_LOADED @"Article loaded."
#define SEARCH_LOADING_MSG_SEARCHING @"Searching..."

#define DISCOVERY_METHOD_SEARCH @"search"
#define DISCOVERY_METHOD_RANDOM @"random"
#define DISCOVERY_METHOD_LINK   @"link"

#define HISTORY_THUMBNAIL_WIDTH 110
#define HISTORY_RESULT_HEIGHT 66

#define HISTORY_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define HISTORY_DATE_HEADER_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.6f]
#define HISTORY_DATE_HEADER_BACKGROUND_COLOR [UIColor colorWithWhite:1.0f alpha:0.97f]
#define HISTORY_DATE_HEADER_HEIGHT 51.0f
#define HISTORY_DATE_HEADER_LEFT_PADDING 37.0f

#define SAVED_PAGES_TITLE_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:0.7f]
#define SAVED_PAGES_TEXT_COLOR [UIColor colorWithWhite:0.0f alpha:1.0f]
#define SAVED_PAGES_RESULT_HEIGHT 116

#define HIDE_KEYBOARD_ON_SCROLL_THRESHOLD 55.0f
