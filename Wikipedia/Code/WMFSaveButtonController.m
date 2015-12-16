#import "WMFSaveButtonController.h"
#import "MWKTitle.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKUserDataStore.h"
#import "SavedPagesFunnel.h"
#import "PiwikTracker+WMFExtensions.h"

@interface WMFSaveButtonController ()

@property (nonatomic, strong) SavedPagesFunnel* savedPagesFunnel;

@end


@implementation WMFSaveButtonController

- (instancetype)initWithButton:(UIButton*)button
                 savedPageList:(MWKSavedPageList*)savedPageList
                         title:(MWKTitle*)title {
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.button        = button;
        self.title         = title;
        self.savedPageList = savedPageList;
    }
    return self;
}

- (instancetype)initWithBarButtonItem:(UIBarButtonItem*)barButtonItem
                        savedPageList:(MWKSavedPageList*)savedPageList
                                title:(MWKTitle*)title {
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.barButtonItem = barButtonItem;
        self.title         = title;
        self.savedPageList = savedPageList;
    }
    return self;
}

- (void)dealloc {
    [self unobserveSavedPages];
}

#pragma mark - Accessors

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList {
    if (self.savedPageList == savedPageList) {
        return;
    }
    [self unobserveSavedPages];
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

- (void)setBarButtonItem:(UIBarButtonItem*)barButtonItem {
    [_barButtonItem setTarget:nil];
    [_barButtonItem setAction:nil];
    _barButtonItem = barButtonItem;
    [_barButtonItem setTarget:self];
    [_barButtonItem setAction:@selector(toggleSave:)];
    [self updateSavedButtonState];
}

- (SavedPagesFunnel*)savedPagesFunnel {
    if (!_savedPagesFunnel) {
        _savedPagesFunnel = [[SavedPagesFunnel alloc] init];
    }
    return _savedPagesFunnel;
}

#pragma mark - KVO

- (void)observeSavedPages {
    if (!self.savedPageList) {
        return;
    }
    [self.KVOControllerNonRetaining observe:self.savedPageList
                                    keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)
                                    options:NSKeyValueObservingOptionInitial
                                      block:^(WMFSaveButtonController* observer, id object, NSDictionary* change) {
        [observer updateSavedButtonState];
    }];
}

- (void)unobserveSavedPages {
    if (!self.savedPageList) {
        return;
    }
    [self.KVOControllerNonRetaining unobserve:self.savedPageList keyPath:WMF_SAFE_KEYPATH(self.savedPageList, entries)];
}

#pragma mark - Save State

- (void)updateSavedButtonState {
    BOOL isSaved = [self isSaved];
    self.button.selected = isSaved;
    if (isSaved) {
        self.barButtonItem.image = [UIImage imageNamed:@"save-filled"];
    } else {
        self.barButtonItem.image = [UIImage imageNamed:@"save"];
    }
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.title];
}

- (void)toggleSave:(id)sender {
    [self unobserveSavedPages];
    [self.savedPageList toggleSavedPageForTitle:self.title];
    [self.savedPageList save];

    BOOL isSaved = [self.savedPageList isSaved:self.title];
    if (isSaved) {
        [self.savedPagesFunnel logSaveNew];
        [[PiwikTracker sharedInstance] wmf_logActionSaveTitle:self.title fromSource:self.analyticsSource];
    } else {
        [self.savedPagesFunnel logDelete];
        [[PiwikTracker sharedInstance] wmf_logActionUnsaveTitle:self.title fromSource:self.analyticsSource];
    }

    [self observeSavedPages];
}

@end
