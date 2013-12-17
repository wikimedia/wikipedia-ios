//  Created by Monte Hurd on 12/16/13.

#import <UIKit/UIKit.h>

@class SearchBarTextField;

@interface SearchNavController : UINavigationController <UITextFieldDelegate, UISearchBarDelegate>

@property (strong, nonatomic) NSString *currentSearchString;
@property (strong, nonatomic) NSArray *currentSearchStringWordsToHighlight;

-(void)resignSearchFieldFirstResponder;
-(BOOL)isSearchFieldFirstResponder;

@end
