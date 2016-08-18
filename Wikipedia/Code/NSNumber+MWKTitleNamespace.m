#import "NSNumber+MWKTitleNamespace.h"

@implementation NSNumber (MWKTitleNamespace)

- (MWKTitleNamespace)wmf_titleNamespaceValue {
    MWKTitleNamespace ns = self.integerValue;
    if (ns >= MWKTitleNamespaceMedia && ns <= MWKTitleNamespaceCategoryTalk) {
        return ns;
    } else {
        DDLogWarn(@"Unexpected title namespace: %ld", (long)ns);
        return MWKTitleNamespaceUnknown;
    }
}

- (BOOL)wmf_isMainNamespace {
    return [self wmf_titleNamespaceValue] == MWKTitleNamespaceMain;
}

@end
