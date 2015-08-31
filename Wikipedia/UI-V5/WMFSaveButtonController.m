//  Created by Monte Hurd on 8/19/15.2//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSaveButtonController.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKUserDataStore.h"

@interface WMFSaveButtonController ()

@property (strong, nonatomic) MWKSavedPageList* savedPageList;

@end

@implementation WMFSaveButtonController

- (instancetype)initWithButton:(UIButton*)button
                 savedPageList:(MWKSavedPageList*)savedPageList
                         title:(MWKTitle*)title {
    self = [super init];
    if (self) {
        self.savedPageList = savedPageList;
        self.button        = button;
        self.title         = title;
        [self observeSavedPages];
        [self updateSavedButtonState];
    }
    return self;
}

- (void)observeSavedPages {
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:0
                                      block:^(WMFSaveButtonController* observer, id object, NSDictionary* change) {
        [observer updateSavedButtonState];
    }];
}

- (void)unobserveSavedPages {
    [self.KVOControllerNonRetaining unobserve:self.savedPageList keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)];
}

- (void)toggleSave:(id)sender {
    [self unobserveSavedPages];
    [self.savedPageList toggleSavedPageForTitle:self.title];
    [self.savedPageList save];
    [self observeSavedPages];
    [self updateSavedButtonState];
}

- (void)setTitle:(MWKTitle*)title {
    _title = title;
    [self updateSavedButtonState];
}

- (void)setButton:(UIButton*)button {
    [_button removeTarget:self
                   action:@selector(toggleSave:)
         forControlEvents:UIControlEventTouchUpInside];

    [button addTarget:self
               action:@selector(toggleSave:)
     forControlEvents:UIControlEventTouchUpInside];

    _button = button;
}

- (void)updateSavedButtonState {
    self.button.selected = [self isSaved];
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.title];
}

- (void)dealloc {
    [self unobserveSavedPages];
}

@end
