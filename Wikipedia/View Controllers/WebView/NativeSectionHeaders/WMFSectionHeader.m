//  Created by Monte Hurd on 8/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "WMFSectionHeader.h"
#import "UIButton+WMFButton.h"

@interface WMFSectionHeader ()

@property (nonatomic, strong) IBOutlet UIButton* button;
@property (nonatomic, strong) IBOutlet UILabel* label;

@end

@implementation WMFSectionHeader

- (void)setTitle:(NSString*)title {
    self.label.text = title;

    // Force layout to prevent bug detailed here:
    // https://github.com/wikimedia/wikipedia-ios/commit/8d963d40a91476958933d9e5973f5f56b7531653
    [self.label layoutIfNeeded];
    [self layoutIfNeeded];
}

- (NSString*)title {
    return self.label.text;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.button wmf_setButtonType:WMFButtonTypePencil];
}

- (void)willMoveToSuperview:(UIView*)newSuperview {
    [super willMoveToSuperview:newSuperview];
    self.button.enabled = [self.editSectionDelegate isArticleEditable];
}

- (IBAction)editPencilTapped:(id)sender {
    [self.editSectionDelegate editSection:self.sectionId];
}

@end
