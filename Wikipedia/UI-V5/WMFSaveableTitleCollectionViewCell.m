#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

#import "Wikipedia-Swift.h"

#import "WMFSaveButtonController.h"
#import "MWKTitle.h"

#import "UIImageView+WMFImageFetching.h"
#import "UIButton+WMFButton.h"

#import "UIColor+WMFStyle.h"
#import "UIColor+WMFHexColor.h"
#import "UICollectionViewCell+WMFExtensions.h"

@interface WMFSaveableTitleCollectionViewCell ()

@property (strong, nonatomic) WMFSaveButtonController* saveButtonController;

@end

@implementation WMFSaveableTitleCollectionViewCell

- (void)configureImageViewWithPlaceholder {
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.backgroundColor = [UIColor wmf_colorWithHex:0xF5F5F5 alpha:1.0];
    self.imageView.image = [UICollectionViewCell wmf_placeholderImage];
}

- (void)configureCell {
    [super configureCell];
    [self configureContentView];
    [self configureImageViewWithPlaceholder];
    [self.saveButton wmf_setButtonType:WMFButtonTypeBookmarkMini];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.title = nil;
    [self.imageView wmf_reset];
    [self configureImageViewWithPlaceholder];
}

#pragma mark - Accessors

- (void)setSaveButton:(UIButton*)saveButton {
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
    [self updateTitleLabel];
}

- (void)updateTitleLabel {
    self.titleLabel.text = self.title.text;
}

- (MWKTitle*)title {
    return self.saveButtonController.title;
}

- (void)setImageURL:(NSURL*)imageURL {
    [self.imageView wmf_setImageWithURL:imageURL detectFaces:YES];
}

- (void)setImage:(MWKImage*)image {
    [self.imageView wmf_setImageWithMetadata:image detectFaces:YES];
}

@end
