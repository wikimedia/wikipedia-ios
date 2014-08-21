//
//  TFHpple.m
//  Hpple
//
//  Created by Geoffrey Grosenbach on 1/31/09.
//
//  Copyright (c) 2009 Topfunky Corporation, http://topfunky.com
//
//  MIT LICENSE
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TFHpple.h"
#import "XPathQuery.h"

@interface TFHpple ()
{
    NSData * data;
    NSString * encoding;
    BOOL isXML;
}

@end


@implementation TFHpple

@synthesize data;
@synthesize encoding;


- (id) initWithData:(NSData *)theData encoding:(NSString *)theEncoding isXML:(BOOL)isDataXML
{
  if (!(self = [super init])) {
    return nil;
  }

  data = theData;
  encoding = theEncoding;
  isXML = isDataXML;

  return self;
}

- (id) initWithData:(NSData *)theData isXML:(BOOL)isDataXML
{
    return [self initWithData:theData encoding:nil isXML:isDataXML];
}

- (id) initWithXMLData:(NSData *)theData encoding:(NSString *)theEncoding
{
  return [self initWithData:theData encoding:theEncoding isXML:YES];
}

- (id) initWithXMLData:(NSData *)theData
{
  return [self initWithData:theData encoding:nil isXML:YES];
}

- (id) initWithHTMLData:(NSData *)theData encoding:(NSString *)theEncoding
{
    return [self initWithData:theData encoding:theEncoding isXML:NO];
}

- (id) initWithHTMLData:(NSData *)theData
{
  return [self initWithData:theData encoding:nil isXML:NO];
}

+ (TFHpple *) hppleWithData:(NSData *)theData encoding:(NSString *)theEncoding isXML:(BOOL)isDataXML {
  return [[[self class] alloc] initWithData:theData encoding:theEncoding isXML:isDataXML];
}

+ (TFHpple *) hppleWithData:(NSData *)theData isXML:(BOOL)isDataXML {
  return [[self class] hppleWithData:theData encoding:nil isXML:isDataXML];
}

+ (TFHpple *) hppleWithHTMLData:(NSData *)theData encoding:(NSString *)theEncoding {
  return [[self class] hppleWithData:theData encoding:theEncoding isXML:NO];
}

+ (TFHpple *) hppleWithHTMLData:(NSData *)theData {
  return [[self class] hppleWithData:theData encoding:nil isXML:NO];
}

+ (TFHpple *) hppleWithXMLData:(NSData *)theData encoding:(NSString *)theEncoding {
  return [[self class] hppleWithData:theData encoding:theEncoding isXML:YES];
}

+ (TFHpple *) hppleWithXMLData:(NSData *)theData {
  return [[self class] hppleWithData:theData encoding:nil isXML:YES];
}

#pragma mark -

// Returns all elements at xPath.
- (NSArray *) searchWithXPathQuery:(NSString *)xPathOrCSS
{
  NSArray * detailNodes = nil;
  if (isXML) {
    detailNodes = PerformXMLXPathQueryWithEncoding(data, xPathOrCSS, encoding);
  } else {
    detailNodes = PerformHTMLXPathQueryWithEncoding(data, xPathOrCSS, encoding);
  }

  NSMutableArray * hppleElements = [NSMutableArray array];
  for (id node in detailNodes) {
    [hppleElements addObject:[TFHppleElement hppleElementWithNode:node isXML:isXML withEncoding:encoding]];
  }
  return hppleElements;
}

// Returns first element at xPath
- (TFHppleElement *) peekAtSearchWithXPathQuery:(NSString *)xPathOrCSS
{
  NSArray * elements = [self searchWithXPathQuery:xPathOrCSS];
  if ([elements count] >= 1) {
    return [elements objectAtIndex:0];
  }

  return nil;
}

@end
