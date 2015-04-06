//
//  TFHppleElement.h
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


@interface TFHppleElement : NSObject {
@private
  
  NSDictionary * node;
  __unsafe_unretained TFHppleElement *parent;
}

- (id) initWithNode:(NSDictionary *) theNode;

+ (TFHppleElement *) hppleElementWithNode:(NSDictionary *) theNode;

@property (nonatomic, copy, readonly) NSString *raw;
// Returns this tag's innerHTML content.
@property (nonatomic, copy, readonly) NSString *content;

// Returns the name of the current tag, such as "h3".
@property (nonatomic, copy, readonly) NSString *tagName;

// Returns tag attributes with name as key and content as value.
//   href  = 'http://peepcode.com'
//   class = 'highlight'
@property (nonatomic, strong, readonly) NSDictionary *attributes;

// Returns the children of a given node
@property (nonatomic, strong, readonly) NSArray *children;

// Returns the first child of a given node
@property (nonatomic, strong, readonly) TFHppleElement *firstChild;

// the parent of a node
@property (nonatomic, unsafe_unretained, readonly) TFHppleElement *parent;

// Returns YES if the node has any child
// This is more efficient than using the children property since no NSArray is constructed
- (BOOL)hasChildren;

// Returns YES if this is a text node
- (BOOL)isTextNode;

// Provides easy access to the content of a specific attribute, 
// such as 'href' or 'class'.
- (NSString *) objectForKey:(NSString *) theKey;

// Returns the children whose tag name equals the given string
// (comparison is performed with NSString's isEqualToString)
// Returns an empty array if no matching child is found
- (NSArray *) childrenWithTagName:(NSString *)tagName;

// Returns the first child node whose tag name equals the given string
// (comparison is performed with NSString's isEqualToString)
// Returns nil if no matching child is found
- (TFHppleElement *) firstChildWithTagName:(NSString *)tagName;

// Returns the children whose class equals the given string
// (comparison is performed with NSString's isEqualToString)
// Returns an empty array if no matching child is found
- (NSArray *) childrenWithClassName:(NSString *)className;

// Returns the first child whose class requals the given string
// (comparison is performed with NSString's isEqualToString)
// Returns nil if no matching child is found
- (TFHppleElement *) firstChildWithClassName:(NSString*)className;

// Returns the first text node from this element's children
// Returns nil if there is no text node among the children
- (TFHppleElement *) firstTextChild;

// Returns the string contained by the first text node from this element's children
// Convenience method which can be used instead of firstTextChild.content
- (NSString *) text;

@end
