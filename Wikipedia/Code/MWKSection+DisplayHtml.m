#import "MWKSection+DisplayHtml.h"
#import "SessionSingleton.h"
#import "NSString+WMFExtras.h"

@implementation MWKSection (DisplayHtml)

- (NSString *)displayHTML {
    NSString *html = nil;

    @try {
        html = [self getHTMLWrappedInTablesIfNeeded];
    } @catch (NSException *exception) {
        NSAssert(html, @"html was not created from section %@: %@", self.url, self.text);
    }

    if (!html) {
        html = WMFLocalizedStringWithDefaultValue(@"article-unable-to-load-section", nil, nil, @"Unable to load this section. Try refreshing the article to see if it fixes the problem.", @"Displayed within the article content when a section fails to render for some reason.");
        ;
    }

    BOOL isMainPage = [SessionSingleton sharedInstance].currentArticle.isMain;

    return [NSString stringWithFormat:
                         @"<div id='section_heading_and_content_block_%d'>%@<div id='content_block_%d' class='content_block'>%@%@%@</div></div>",
                         self.sectionId,
                         (isMainPage ? @"" : [self getHeaderTag]),
                         self.sectionId,
                         (([self isLeadSection]) && !isMainPage) ? @"<hr id='content_block_0_hr'>" : @"",
                         (([self isLeadSection]) && !isMainPage) ? [self getEditPencilAnchor] : @"",
                         html];
}

- (NSString *)getHeaderTag {
    if ([self isLeadSection]) {
        return [NSString stringWithFormat:
                             @"<h1 class='section_heading' %@ sectionId='%d'>%@</h1>%@",
                             self.anchorAsElementId,
                             self.sectionId,
                             self.article.displaytitle ? self.article.displaytitle : self.url.wmf_title,
                             [self articleEntityDescriptionAsParagraph]];
    } else {
        short headingTagSize = [self getHeadingTagSize];
        return [NSString stringWithFormat:
                             @"<h%d class='section_heading' data-id='%d' id='%@'>%@%@</h%d>",
                             headingTagSize,
                             self.sectionId,
                             self.anchor,
                             self.line,
                             [self getEditPencilAnchor],
                             headingTagSize];
    }
}

- (NSString *)anchorAsElementId {
    return self.anchor.length > 0 ? [NSString stringWithFormat:@"id='%@'", self.anchor] : @"";
}

- (NSString *)articleEntityDescriptionAsParagraph {
    if (self.article.entityDescription.length == 0) {
        return @"";
    } else {
        return [NSString stringWithFormat:@"<p id='entity_description'>%@</p>", [self.article.entityDescription wmf_stringByCapitalizingFirstCharacter]];
    }
}

- (short)getHeadingTagSize {
    return WMFStrictClamp(1, self.level.integerValue, 6);
}

- (NSString *)getEditPencilAnchor {
    return [NSString stringWithFormat:
                         @"<a class='edit_section_button' data-action='edit_section' data-id='%d' id='edit_section_button_%d'></a>",
                         self.sectionId,
                         self.sectionId];
}

- (NSString *)getHTMLWrappedInTablesIfNeeded {
    NSString *tableFormatString = @"<table><th>%@</th><tr><td>%@</td></tr></table>";
    NSArray *titlesToWrap = @[@"References", @"External links", @"Notes", @"Further reading", @"Bibliography"];
    for (NSString *sectionTitle in titlesToWrap) {
        if ([self.line isEqualToString:sectionTitle]) {
            return [NSString stringWithFormat:tableFormatString, sectionTitle, self.text];
        }
    }
    return self.text;
}

@end
