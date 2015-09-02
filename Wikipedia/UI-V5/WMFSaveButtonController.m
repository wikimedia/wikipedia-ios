#import "WMFSaveButtonController.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKUserDataStore.h"

@implementation WMFSaveButtonController

- (instancetype)initWithButton:(UIButton*)button
                 savedPageList:(MWKSavedPageList*)savedPageList
                         title:(MWKTitle*)title {
    self = [super init];
    if (self) {
        self.button        = button;
        self.title         = title;
        self.savedPageList = savedPageList;
    }
    return self;
}

- (void)dealloc {
    [self unobserveSavedPages];
}

#pragma mark - Accessors

- (void)setSavedPageList:(MWKSavedPageList *)savedPageList {
    if (self.savedPageList == savedPageList) {
        return;
    }
    _savedPageList = savedPageList;
    [self observeSavedPages];
}

- (void)setTitle:(MWKTitle*)title {
    if (WMF_EQUAL(self.title, isEqualToTitle:, title)) {
        return;
    }
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
    [self updateSavedButtonState];
}

#pragma mark - KVO

- (void)observeSavedPages {
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFSaveButtonController* observer, id object, NSDictionary* change) {
                                          [observer updateSavedButtonState];
                                      }];
}

- (void)unobserveSavedPages {
    [self.KVOControllerNonRetaining unobserve:self.savedPageList keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)];
}

#pragma mark - Save State

- (void)updateSavedButtonState {
    self.button.selected = [self isSaved];
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.title];
}

- (void)toggleSave:(id)sender {
    [self unobserveSavedPages];
    [self.savedPageList toggleSavedPageForTitle:self.title];
    [self.savedPageList save];
    [self observeSavedPages];
}

@end
