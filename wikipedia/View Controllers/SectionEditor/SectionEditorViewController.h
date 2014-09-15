//  Created by Monte Hurd on 1/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "EditFunnel.h"
#import "SavedPagesFunnel.h"

@class NSManagedObjectID;

@interface SectionEditorViewController : UIViewController <UITextViewDelegate, UIScrollViewDelegate, NetworkOpDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;
@property EditFunnel *funnel;
@property SavedPagesFunnel *savedPagesFunnel;

@end
