//  Created by Monte Hurd on 12/16/13.

typedef enum {
    NAVBAR_BUTTON_X = 0,
    NAVBAR_BUTTON_PENCIL = 1,
    NAVBAR_BUTTON_CHECK = 2,
    NAVBAR_BUTTON_ARROW_LEFT = 3,
    NAVBAR_BUTTON_ARROW_RIGHT = 4,
    NAVBAR_BUTTON_LOGO_W = 5,
    NAVBAR_BUTTON_EYE = 6,
    NAVBAR_TEXT_FIELD = 7,
    NAVBAR_LABEL = 8,
    NAVBAR_VERTICAL_LINE = 9
} NavBarItemTag;

typedef enum {
    NAVBAR_MODE_SEARCH = 0,
    NAVBAR_MODE_EDIT_WIKITEXT = 1,
    NAVBAR_MODE_EDIT_WIKITEXT_WARNING = 2,
    NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW = 3,
    NAVBAR_MODE_LOGIN = 4,
    NAVBAR_MODE_CREATE_ACCOUNT = 5
} NavBarMode;

typedef enum {
    NAVBAR_STYLE_UNKNOWN = 0,
    NAVBAR_STYLE_DAY = 1,
    NAVBAR_STYLE_NIGHT = 2
} NavBarStyle;

@interface NavController : UINavigationController <UITextFieldDelegate, UISearchBarDelegate>

@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, atomic) NSMutableArray *currentSearchResultsOrdered;

@property (nonatomic) NavBarStyle navBarStyle;
@property (nonatomic) NavBarMode navBarMode;

-(id)getNavBarItem:(NavBarItemTag)tag;

@end

//TODO: maybe use currentNavBarTextFieldText instead of currentSearchString?
