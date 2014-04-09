//
//  XPathQuery.h
//  FuelFinder
//
//  Created by Matt Gallagher on 4/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

NSArray *PerformHTMLXPathQuery(NSData *document, NSString *query);
NSArray *PerformHTMLXPathQueryWithEncoding(NSData *document, NSString *query,NSString *encoding);
NSArray *PerformXMLXPathQuery(NSData *document, NSString *query);
NSArray *PerformXMLXPathQueryWithEncoding(NSData *document, NSString *query,NSString *encoding);
