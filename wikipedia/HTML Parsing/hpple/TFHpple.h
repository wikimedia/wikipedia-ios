//
//  TFHpple.h
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


#import <Foundation/Foundation.h>

#import "TFHppleElement.h"

@interface TFHpple : NSObject 

- (id) initWithData:(NSData *)theData encoding:(NSString *)encoding isXML:(BOOL)isDataXML;
- (id) initWithData:(NSData *)theData isXML:(BOOL)isDataXML;
- (id) initWithXMLData:(NSData *)theData encoding:(NSString *)encoding;
- (id) initWithXMLData:(NSData *)theData;
- (id) initWithHTMLData:(NSData *)theData encoding:(NSString *)encoding;
- (id) initWithHTMLData:(NSData *)theData;

+ (TFHpple *) hppleWithData:(NSData *)theData encoding:(NSString *)encoding isXML:(BOOL)isDataXML;
+ (TFHpple *) hppleWithData:(NSData *)theData isXML:(BOOL)isDataXML;
+ (TFHpple *) hppleWithXMLData:(NSData *)theData encoding:(NSString *)encoding;
+ (TFHpple *) hppleWithXMLData:(NSData *)theData;
+ (TFHpple *) hppleWithHTMLData:(NSData *)theData encoding:(NSString *)encoding;
+ (TFHpple *) hppleWithHTMLData:(NSData *)theData;

- (NSArray *) searchWithXPathQuery:(NSString *)xPathOrCSS;
- (TFHppleElement *) peekAtSearchWithXPathQuery:(NSString *)xPathOrCSS;

@property (nonatomic, readonly) NSData * data;
@property (nonatomic, readonly) NSString * encoding;

@end
