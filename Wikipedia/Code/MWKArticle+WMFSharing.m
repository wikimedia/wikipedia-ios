#import <WMF/MWKArticle+WMFSharing.h>
#import <WMF/NSString+WMFHTMLParsing.h>
#import <WMF/MWKSectionList.h>
#import <WMF/MWKSection.h>

#define MWKArticleMainPageLeadingHTMLXPath @"/html/body/div/div/p[1]"
static NSString *const MWKArticleMainPageLeadingTextXPath = MWKArticleMainPageLeadingHTMLXPath "//text()";

@implementation MWKArticle (WMFSharing)

- (NSString *)firstNonEmptyResultFromIteratingSectionsWithBlock:(NSString * (^)(MWKSection *))block {
    NSString *result;
    for (MWKSection *section in self.sections) {
        result = block(section);
        if (result) {
            return result;
        }
    }
    return @"";
}

- (NSString *)shareSnippet {
    if ([self isMain]) {
        return [self firstNonEmptyResultFromIteratingSectionsWithBlock:^NSString *(MWKSection *section) {
            return [[section textForXPath:MWKArticleMainPageLeadingTextXPath] wmf_shareSnippetFromText];
        }];
    } else {
        return [self firstNonEmptyResultFromIteratingSectionsWithBlock:^NSString *(MWKSection *section) {
            return [section shareSnippet];
        }];
    }
}

@end
