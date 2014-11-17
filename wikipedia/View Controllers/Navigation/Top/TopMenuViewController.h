//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

typedef enum {
    NAVBAR_BUTTON_UNKNOWN,
    NAVBAR_BUTTON_X,
    NAVBAR_BUTTON_CHECK,
    NAVBAR_BUTTON_ARROW_LEFT,
    NAVBAR_BUTTON_ARROW_RIGHT,
    NAVBAR_BUTTON_LOGO_W,
    NAVBAR_BUTTON_EYE,
    NAVBAR_BUTTON_TOC,
    NAVBAR_BUTTON_MAGNIFY,
    NAVBAR_BUTTON_BLANK,
    NAVBAR_BUTTON_CANCEL,
    NAVBAR_BUTTON_NEXT,
    NAVBAR_BUTTON_SAVE,
    NAVBAR_BUTTON_DONE,
    NAVBAR_BUTTON_TRASH,
    NAVBAR_TEXT_FIELD,
    NAVBAR_LABEL
} NavBarItemTag;

typedef enum {
    NAVBAR_MODE_UNKNOWN,
    NAVBAR_MODE_DEFAULT,
    NAVBAR_MODE_DEFAULT_WITH_TOC,
    NAVBAR_MODE_EDIT_WIKITEXT,
    NAVBAR_MODE_EDIT_WIKITEXT_WARNING,
    NAVBAR_MODE_EDIT_WIKITEXT_DISALLOW,
    NAVBAR_MODE_LOGIN,
    NAVBAR_MODE_CREATE_ACCOUNT,
    NAVBAR_MODE_CREATE_ACCOUNT_CAPTCHA,
    NAVBAR_MODE_EDIT_WIKITEXT_PREVIEW,
    NAVBAR_MODE_EDIT_WIKITEXT_CAPTCHA,
    NAVBAR_MODE_EDIT_WIKITEXT_SUMMARY,
    NAVBAR_MODE_SEARCH,
    NAVBAR_MODE_X_WITH_LABEL,
    NAVBAR_MODE_X_WITH_TEXT_FIELD,
    NAVBAR_MODE_PAGES_HISTORY,
    NAVBAR_MODE_PAGES_SAVED
} NavBarMode;

typedef enum {
    NAVBAR_STYLE_UNKNOWN,
    NAVBAR_STYLE_DAY,
    NAVBAR_STYLE_NIGHT
} NavBarStyle;

@class TopMenuContainerView, SearchResultsController;

@interface TopMenuViewController : UIViewController <UITextFieldDelegate, UISearchBarDelegate>

@property (strong, nonatomic) SearchResultsController *searchResultsController;

@property (nonatomic) NavBarStyle navBarStyle;
@property (nonatomic) NavBarMode navBarMode;

-(id)getNavBarItem:(NavBarItemTag)tag;
-(void)updateTOCButtonVisibility;

@property (strong, nonatomic) IBOutlet TopMenuContainerView *navBarContainer;

@property (nonatomic) BOOL statusBarHidden;

@end
