#import "WMFSaveButtonController.h"
#import "MWKSavedPageList.h"
#import "MWKArticle.h"
#import "MWKUserDataStore.h"
#import "SavedPagesFunnel.h"
#import "PiwikTracker+WMFExtensions.h"

@interface WMFSaveButtonController ()

@property (nonatomic, strong) SavedPagesFunnel* savedPagesFunnel;

@end


@implementation WMFSaveButtonController

- (instancetype)initWithControl:(UIControl*)button
                  savedPageList:(MWKSavedPageList*)savedPageList
                            url:(NSURL*)url {
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.control       = button;
        self.url           = url;
        self.savedPageList = savedPageList;
    }
    return self;
}

- (instancetype)initWithBarButtonItem:(UIBarButtonItem*)barButtonItem
                        savedPageList:(MWKSavedPageList*)savedPageList
                                  url:(NSURL*)url {
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.barButtonItem = barButtonItem;
        self.url           = url;
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

- (void)setUrl:(NSURL*)url {
    if (WMF_EQUAL(self.url, isEqual:, url)) {
        return;
    }
    _url = url;
    [self updateSavedButtonState];
}

- (void)setControl:(UIButton*)button {
    [_control removeTarget:self
                    action:@selector(toggleSave:)
          forControlEvents:UIControlEventTouchUpInside];

    [button addTarget:self
               action:@selector(toggleSave:)
     forControlEvents:UIControlEventTouchUpInside];

    _control = button;
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
    self.control.selected = isSaved;
    if (isSaved) {
        self.barButtonItem.image = [UIImage imageNamed:@"save-filled"];
    } else {
        self.barButtonItem.image = [UIImage imageNamed:@"save"];
    }
}

- (BOOL)isSaved {
    return [self.savedPageList isSaved:self.url];
}

- (void)toggleSave:(id)sender {
    [self unobserveSavedPages];
    [self.savedPageList toggleSavedPageForURL:self.url];
    [self.savedPageList save];

    BOOL isSaved = [self.savedPageList isSaved:self.url];
    if (isSaved) {
        [self.savedPagesFunnel logSaveNew];
        [[PiwikTracker wmf_configuredInstance] wmf_logActionSaveInContext:self.analyticsContext contentType:self.analyticsContentType];
    } else {
        [self.savedPagesFunnel logDelete];
        [[PiwikTracker wmf_configuredInstance] wmf_logActionUnsaveInContext:self.analyticsContext contentType:self.analyticsContentType];
    }

    [self observeSavedPages];
}

@end
