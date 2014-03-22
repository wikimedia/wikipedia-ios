//  Created by Monte Hurd on 1/13/14.

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"

@class NSManagedObjectID;

@interface SectionEditorViewController : UIViewController <UITextViewDelegate, UIScrollViewDelegate, NetworkOpDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;

@end
