//  Created by Monte Hurd on 10/24/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIWebView+LoadAssetsHtml.h"

@implementation UIWebView (LoadAssetsHtml)

-(void)loadHTMLFromAssetsFile:(NSString *)fileName
{
    NSString *filePath = [[self getAssetsPath] stringByAppendingPathComponent:fileName];
    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath: filePath];
    
    [self loadData: fileData
          MIMEType: @"text/html"
  textEncodingName: @"UTF-8"
           baseURL: [NSURL URLWithString:filePath]];
}

-(void)loadHTML:(NSString *)string withAssetsFile:(NSString *)fileName
{
    if (!string) string = @"";
    
    NSString *path = [[self getAssetsPath] stringByAppendingPathComponent:fileName];
    
    NSMutableString *fileContents =
    [NSMutableString stringWithContentsOfFile: path
                                     encoding: NSUTF8StringEncoding
                                        error: nil];
    
    [fileContents replaceOccurrencesOfString: @"#INJECTION_POINT#"
                                  withString: string
                                     options: (NSLiteralSearch | NSBackwardsSearch)
                                       range: NSMakeRange(0, fileContents.length)];
    
    // Seems audio/video tags can't be completely hidden via JS
    // for some reason. So brute-force hobble the tags for now.
    // [self disableAudioVideoTagsInString:fileContents];
    
    [self loadHTMLString: fileContents
                 baseURL: [NSURL URLWithString:path]];
}

-(NSString *)getAssetsPath
{
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    return [[documentsPath firstObject] stringByAppendingPathComponent:@"assets"];
}

-(void)disableAudioVideoTagsInString:(NSMutableString *)mutableString
{
    static NSString *pattern = @"(</?)(audio|video)(\\s|>)";
    static NSString *format = @"$1$2_SNIP$3";
    [mutableString replaceOccurrencesOfString: pattern
                                   withString: format
                                      options: (NSRegularExpressionSearch | NSCaseInsensitiveSearch)
                                        range: NSMakeRange(0, mutableString.length)];
}

@end
