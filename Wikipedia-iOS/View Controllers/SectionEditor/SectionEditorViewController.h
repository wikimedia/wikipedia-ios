//  Created by Monte Hurd on 1/13/14.

#import <UIKit/UIKit.h>

@class NSManagedObjectID;

@interface SectionEditorViewController : UIViewController <UITextViewDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITextView *editTextView;

- (IBAction)savePushed:(id)sender;
- (IBAction)cancelPushed:(id)sender;

@end
