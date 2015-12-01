//  Created by Monte Hurd on 6/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class PreviewAndSaveViewController;
@interface EditSummaryViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) PreviewAndSaveViewController* previewVC;

@property (strong, nonatomic) NSString* summaryText;

@end
