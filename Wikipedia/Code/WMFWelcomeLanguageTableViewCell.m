
#import "WMFWelcomeLanguageTableViewCell.h"
#import "Wikipedia-Swift.h"

@implementation WMFWelcomeLanguageTableViewCell

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.showsReorderControl    = YES;
        self.allowsSwipeWhenEditing = YES;
    }
    return self;
}

- (void)setDeleteButtonTapped:(dispatch_block_t)deleteButtonTapped {
    _deleteButtonTapped = [deleteButtonTapped copy];
    if (_deleteButtonTapped == NULL) {
        self.rightButtons = nil;
    } else {
        MGSwipeButton* delete = [MGSwipeButton buttonWithTitle:MWLocalizedString(@"menu-trash-accessibility-label", nil) backgroundColor:[UIColor redColor]];
        self.rightSwipeSettings.transition = MGSwipeTransitionBorder;
        self.rightButtons                  = @[delete];
        @weakify(self);
        delete.callback = ^BOOL (MGSwipeTableCell* sender){
            @strongify(self);
            if (self.deleteButtonTapped) {
                self.deleteButtonTapped();
            }
            return YES;
        };
    }
}

-(IBAction)minusButtonTapped:(id)sender {
    [self showSwipe:MGSwipeDirectionRightToLeft animated:YES];
}

- (BOOL)shouldIndentWhileEditing {
    return NO;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.deleteButtonTapped = NULL;
}

@end
