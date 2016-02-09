#import "WMFSettingsDataSource.h"
#import "WMFSettingsTableViewCell.h"
#import "WMFSettingsMenuItem.h"

@implementation WMFSettingsDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cellClass          = [WMFSettingsTableViewCell class];
        self.cellConfigureBlock = ^(WMFSettingsTableViewCell* cell, WMFSettingsMenuItem* menuItem, UITableView* tableView, NSIndexPath* indexPath) {
            cell.title     = menuItem.title;
            cell.iconName  = menuItem.iconName;
            cell.disclosureType = menuItem.disclosureType;
            cell.disclosureText = menuItem.disclosureText;
        };

        self.tableActionBlock = ^BOOL (SSCellActionType action, UITableView* tableView, NSIndexPath* indexPath) {
            return NO;
        };
        
        NSArray<NSArray<WMFSettingsMenuItem*>*>* sections = @[[self sectionOne], [self sectionTwo]];
        [self insertSections:sections
                   atIndexes:[NSIndexSet indexSetWithIndexesInRange:
                              NSMakeRange(0, sections.count)]];
    }
    return self;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    return @"Placeholder Header";
}

- (NSString *)titleForFooterInSection:(NSInteger)section {
    return @"Placeholder Footer with a really long string that should wrap to many lines because the translation is very long";
}

- (NSArray<NSArray<WMFSettingsMenuItem*>*>*)sectionsX{
    return @[[self sectionOne], [self sectionTwo]];
}

WMFSettingsMenuItem* (^ makeItem)(NSString*, NSString*, WMFSettingsMenuItemDisclosureType, NSString*) = ^WMFSettingsMenuItem*(NSString* title, NSString* iconName, WMFSettingsMenuItemDisclosureType disclosureType, NSString* disclosureText) {
    return [[WMFSettingsMenuItem alloc] initWithTitle:title
                                             iconName:iconName
                                       disclosureType:disclosureType
                                       disclosureText:disclosureText];
};

-(NSArray<WMFSettingsMenuItem*>*)sectionOne {
    return @[
             makeItem(@"title one", @"good", WMFSettingsMenuItemDisclosureType_ViewController, @""),
             makeItem(@"title two with a really long string that should wrap to many lines because the translation is very long and so on and so forth", @"bad", WMFSettingsMenuItemDisclosureType_Switch, @""),
             makeItem(@"title three", @"star", WMFSettingsMenuItemDisclosureType_ExternalLink, @""),
             makeItem(@"title four", @"mic", WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText, @"EN")
            ];
}

-(NSArray<WMFSettingsMenuItem*>*)sectionTwo {
    return @[
             makeItem(@"title 1", @"good", WMFSettingsMenuItemDisclosureType_ViewController, @""),
             makeItem(@"title 2", @"bad", WMFSettingsMenuItemDisclosureType_Switch, @""),
             makeItem(@"title 3", @"star", WMFSettingsMenuItemDisclosureType_ExternalLink, @""),
             makeItem(@"another title two with a really long string that should wrap to many lines because the translation is very long and so on and so forth", @"mic", WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText, @"EN")
             ];
}

@end
