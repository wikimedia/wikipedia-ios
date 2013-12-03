//
//  PageTitle.m
//  Wikipedia-iOS
//
//  Created by Brion on 11/1/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "MWPageTitle.h"

@implementation MWPageTitle {
    NSString *_namespace;
    NSString *_text;
}

+(MWPageTitle *)titleFromNamespace:(NSString *)namespace text:(NSString *)text
{
    return [[MWPageTitle alloc] initFromNamespace:namespace text:text];
}

-(id)initFromNamespace:(NSString *)namespace text:(NSString *)text
{
    self = [self init];
    if (self) {
        _namespace = namespace;
        _text = text;
    }
    return self;
}

-(NSString *)namespace
{
    return _namespace;
}

-(NSString *)text
{
    return _text;
}

-(NSString *)prefix
{
    if (self.namespace.length == 0) {
        return @"";
    } else {
        return [self.namespace stringByAppendingString:@":"];
    }
}
-(NSString *)prefixedText
{
    return [self.prefix stringByAppendingString:self.text];
}

@end
