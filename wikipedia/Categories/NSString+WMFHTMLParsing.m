#import "NSString+WMFHTMLParsing.h"
#import "WikipediaAppUtils.h"
#import <hpple/TFHpple.h>

@implementation NSString (WMFHTMLParsing)

- (NSArray*)wmf_htmlTextNodes
{
    return [[[[TFHpple alloc]
            initWithHTMLData:[self dataUsingEncoding:NSUTF8StringEncoding]]
            searchWithXPathQuery:@"//text()"]
            valueForKey:WMF_SAFE_KEYPATH([TFHppleElement new], content)];
}

- (NSString*)wmf_joinedHtmlTextNodes
{
    return [self wmf_joinedHtmlTextNodesWithDelimiter:@" "];
}

- (NSString*)wmf_joinedHtmlTextNodesWithDelimiter:(NSString*)delimiter
{
    return [[self wmf_htmlTextNodes] componentsJoinedByString:delimiter];
}

@end
