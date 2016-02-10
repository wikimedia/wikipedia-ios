
#import "WMFSettingsMenuItem.h"

@interface WMFSettingsMenuItem ()

@property (nonatomic, copy, readwrite) NSString* title;

@property (nonatomic, copy, readwrite) NSString* iconName;

@property (nonatomic, copy, readwrite) UIColor* iconColor;

@property (nonatomic, assign, readwrite) WMFSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readwrite) NSString* disclosureText;

@end

@implementation WMFSettingsMenuItem

- (instancetype)initWithTitle:(NSString*)title
                     iconName:(NSString*)iconName
                     iconColor:(UIColor*)iconColor
               disclosureType:(WMFSettingsMenuItemDisclosureType)disclosureType
               disclosureText:(NSString*)disclosureText {
    self = [super init];
    if (self) {
        self.title          = title;
        self.iconName       = iconName;
        self.iconColor      = iconColor;
        self.disclosureType = disclosureType;
        self.disclosureText = disclosureText;
    }
    return self;
}

@end
