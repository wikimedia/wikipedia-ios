#import "WMFSaveableTitleCollectionViewCell+Subclass.h"

#import "Wikipedia-Swift.h"
#import "PromiseKit.h"
#import "WMFSaveButtonController.h"
#import "MWKTitle.h"

#import "UIView+WMFShadow.h"
#import "UIImageView+MWKImage.h"
#import "UIButton+WMFButton.h"

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
    self.imageView.image = [UIImage imageNamed:[[self class] defaultImageName]];
    [self.saveButton wmf_setButtonType:WMFButtonTypeBookmark];
}

- (void)configureContentView {
    self.clipsToBounds               = NO;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.contentView wmf_setupShadow];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.title           = nil;
    self.imageURL        = nil;
    self.imageView.image = [UIImage imageNamed:[[self class] defaultImageName]];
}

#pragma mark - Accessors

+ (NSString*)defaultImageName {
    return @"lead-default";
}

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
    [[WMFImageController sharedInstance] cancelFetchForURL:self.imageURL];
    [self.imageView wmf_resetImageMetadata];

    _imageURL = imageURL;
    @weakify(self);
    [[WMFImageController sharedInstance] fetchImageWithURL:imageURL]
    .then(^id (WMFImageDownload* download) {
        @strongify(self);
        if ([self.imageURL isEqual:imageURL]) {
            self.imageView.image = download.image;
        }
        return nil;
    })
    .catch(^(NSError* error){
        //TODO: Show placeholder
    });
}

- (void)setImage:(MWKImage*)image {
    if (image) {
        [self.imageView wmf_setImageWithFaceDetectionFromMetadata:image];
    }
}

@end
