#import "WMFSaveableTitleCollectionViewCell+Subclass.h"
#import "UIView+WMFShadow.h"
#import "WMFSaveButtonController.h"
#import "UIButton+WMFButton.h"
#import "WMFSaveButtonController.h"
#import "MWKTitle.h"

@interface WMFSaveableTitleCollectionViewCell ()

@property (strong, nonatomic) WMFSaveButtonController* saveButtonController;

@end

@implementation WMFSaveableTitleCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit {
    [self configureContentView];
    [self.saveButton wmf_setButtonType:WMFButtonTypeBookmark];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.contentView wmf_setupShadow];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.title = nil;
}

#pragma mark - Accessors

- (void)setSaveButton:(UIButton *)saveButton {
    self.saveButtonController.button = saveButton;
}

- (UIButton*)saveButton {
    return self.saveButtonController.button;
}

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList {
    self.saveButtonController.savedPageList = savedPageList;
}

- (WMFSaveButtonController*)saveButtonController {
    if (!_saveButtonController) {
        self.saveButtonController = [[WMFSaveButtonController alloc] init];
    }
    return _saveButtonController;
}

- (void)setTitle:(MWKTitle*)title {
    self.saveButtonController.title = title;
    self.titleLabel.text = title.text;
}

- (MWKTitle*)title {
    return self.saveButtonController.title;
}

@end
