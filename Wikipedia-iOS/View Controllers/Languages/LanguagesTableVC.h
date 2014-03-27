//  Created by Monte Hurd on 1/23/14.

#import <UIKit/UIKit.h>

@interface LanguagesTableVC : UITableViewController<UITextFieldDelegate>

-(CATransition *)getTransition;

@property (nonatomic) BOOL downloadLanguagesForCurrentArticle;

@property (nonatomic, copy) void (^selectionBlock)(NSDictionary *);

@end
