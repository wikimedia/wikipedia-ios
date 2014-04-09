//  Created by Monte Hurd on 3/10/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface EditSummaryViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>

-(NSString *)getSummary;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

@end
