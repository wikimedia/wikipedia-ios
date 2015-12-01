//  Created by Monte Hurd on 1/13/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "FetcherBase.h"
#import "EditFunnel.h"
#import "SavedPagesFunnel.h"

@class MWKSection, SectionEditorViewController;

@protocol SectionEditorViewControllerDelegate <NSObject>

- (void)sectionEditorFinishedEditing:(SectionEditorViewController*)sectionEditorViewController;

@end

@interface SectionEditorViewController : UIViewController <UITextViewDelegate, UIScrollViewDelegate, FetchFinishedDelegate, UITextFieldDelegate>

@property (strong, nonatomic) MWKSection* section;
@property (strong, nonatomic) EditFunnel* funnel;
@property (strong, nonatomic) SavedPagesFunnel* savedPagesFunnel;

@property (weak, nonatomic) id<SectionEditorViewControllerDelegate> delegate;


@end
