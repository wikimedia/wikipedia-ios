//  Created by Monte Hurd on 12/26/13.

#import <UIKit/UIKit.h>

@interface TOCViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *scrollContainer;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

-(void)hideTOC;

@end
