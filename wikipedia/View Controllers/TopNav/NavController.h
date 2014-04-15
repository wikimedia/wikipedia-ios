//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

typedef enum {
    NAVBAR_BUTTON_X = 0,
    NAVBAR_BUTTON_PENCIL = 1,
    NAVBAR_BUTTON_CHECK = 2,
    NAVBAR_BUTTON_ARROW_LEFT = 3,
    NAVBAR_BUTTON_ARROW_RIGHT = 4,
    NAVBAR_BUTTON_LOGO_W = 5,
    NAVBAR_BUTTON_EYE = 6,
    NAVBAR_BUTTON_CC = 7,
    NAVBAR_TEXT_FIELD = 8,
    NAVBAR_LABEL = 9,
    NAVBAR_VERTICAL_LINE = 10
} NavBarItemTag;

typedef enum {
    NAVBAR_MODE_SEARCH = 0,
    NAVBAR_MODE_EDIT_WIKITEXT = 1,
    NAVBAR_MODE_EDIT_WIKITEXT_WARNING = 2,
    NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW = 3,
    NAVBAR_MODE_LOGIN = 4,
    NAVBAR_MODE_CREATE_ACCOUNT = 5,
    NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW = 6,
    NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA = 7,
    NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY = 8,
    NAVBAR_MODE_EDIT_WIKITEXT_LOGIN_OR_SAVE_ANONYMOUSLY = 9
} NavBarMode;

typedef enum {
    NAVBAR_STYLE_UNKNOWN = 0,
    NAVBAR_STYLE_DAY = 1,
    NAVBAR_STYLE_NIGHT = 2
} NavBarStyle;

typedef enum {
    DISCOVERY_METHOD_SEARCH = 0,
    DISCOVERY_METHOD_RANDOM = 1,
    DISCOVERY_METHOD_LINK = 2
} ArticleDiscoveryMethod;

@interface NavController : UINavigationController <UITextFieldDelegate, UISearchBarDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, atomic) NSMutableArray *currentSearchResultsOrdered;

@property (nonatomic) NavBarStyle navBarStyle;
@property (nonatomic) NavBarMode navBarMode;
@property (nonatomic, readonly) BOOL isEditorOnNavstack;

-(id)getNavBarItem:(NavBarItemTag)tag;

-(void)loadArticleWithTitle: (NSString *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod;

-(void) promptFirstTimeZeroOnWithMessageIfAppropriate:(NSString *) message;
-(void) promptFirstTimeZeroOffIfAppropriate;

@end

//TODO: maybe use currentNavBarTextFieldText instead of currentSearchString?
