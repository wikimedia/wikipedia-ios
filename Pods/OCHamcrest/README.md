![ochamcrest](http://hamcrest.org/images/logo.jpg)

What is OCHamcrest?
-------------------

[![Build Status](https://travis-ci.org/hamcrest/OCHamcrest.svg?branch=master)](https://travis-ci.org/hamcrest/OCHamcrest) [![Coverage Status](https://coveralls.io/repos/hamcrest/OCHamcrest/badge.png?branch=master)](https://coveralls.io/r/hamcrest/OCHamcrest?branch=master) [![Cocoapods Version](https://cocoapod-badges.herokuapp.com/v/OCHamcrest/badge.png)](http://cocoapods.org/?q=ochamcrest)

OCHamcrest is an iOS and Mac OS X library providing:

* a library of "matcher" objects for declaring rules to check whether a given
  object matches those rules.
* a framework for writing your own matchers.

Matchers are useful for a variety of purposes, such as UI validation. But
they're most commonly used for writing unit tests that are expressive and
flexible.


How do I add OCHamcrest to my project?
--------------------------------------

The Examples folder shows projects using OCHamcrest either through CocoaPods or
through the prebuilt frameworks, for iOS and Mac OS X development.

### CocoaPods

If you want to add OCHamcrest using Cocoapods then add the following dependency
to your Podfile. Most people will want OCHamcrest in their test targets, and not
include any pods from their main targets:

```ruby
target :MyTests, :exclusive => true do
  pod 'OCHamcrest', '~> 4.0'
end
```

Use the following import:

    #define HC_SHORTHAND
    #import <OCHamcrest/OCHamcrest.h>

### Prebuilt Frameworks

Prebuilt binaries are available on [GitHub](https://github.com/hamcrest/OCHamcrest/releases/).
The binaries are packaged as frameworks:

* __OCHamcrestIOS.framework__ for iOS development
* __OCHamcrest.framework__ for Mac OS X development

Drag the appropriate framework into your project, specifying "Copy items into
destination group's folder". Then specify `-ObjC` in your "Other Linker Flags".

#### iOS Development:

Use the following import:

    #define HC_SHORTHAND
    #import <OCHamcrestIOS/OCHamcrestIOS.h>

#### Mac OS X Development:

Add a "Copy Files" build phase to copy OCHamcrest.framework to your Products
Directory.

Use the following import:

    #define HC_SHORTHAND
    #import <OCHamcrest/OCHamcrest.h>

### Build Your Own

If you want to build OCHamcrest yourself, clone the repo, then

```sh
$ git submodule update --init
$ cd Source
$ ./MakeDistribution.sh
```


My first OCHamcrest test
------------------------

We'll start by writing a very simple Xcode unit test, but instead of using
XCTest's `XCTAssertEqualObjects` function, we'll use OCHamcrest's `assertThat`
construct and a predefined matcher:

```obj-c
#import <SenTestingKit/SenTestingKit.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

@interface BiscuitTest : SenTestCase
@end

@implementation BiscuitTest

- (void)testEquals
{
    Biscuit* theBiscuit = [[Biscuit alloc] initWithName:@"Ginger"];
    Biscuit* myBiscuit = [[Biscuit alloc] initWithName:@"Ginger"];
    assertThat(theBiscuit, equalTo(myBiscuit));
}

@end
```

The `assertThat` function is a stylized sentence for making a test assertion. In
this example, the subject of the assertion is the object `theBiscuit`, which is
the first method parameter. The second method parameter is a matcher for
`Biscuit` objects, here a matcher that checks one object is equal to another
using the `-isEqual:` method. The test passes since the `Biscuit` class defines
an `-isEqual:` method.

OCHamcrest's functions are actually declared with an "HC" package prefix (such
as `HC_assertThat` and `HC_equalTo`) to avoid name clashes. To make test writing
faster and test code more legible, shorthand macros are provided if
`HC_SHORTHAND` is defined before including the OCHamcrest header. For example,
instead of writing `HC_assertThat`, simply write `assertThat`.


Predefined matchers
-------------------

OCHamcrest comes with a library of useful matchers:

* Object

  * `conformsTo` - match object that conforms to protocol
  * `equalTo` - match equal object
  * `hasDescription` - match object's `-description`
  * `hasProperty` - match return value of method with given name
  * `instanceOf` - match object type
  * `isA` - match object type precisely, no subclasses
  * `nilValue`, `notNilValue` - match `nil`, or not `nil`
  * `sameInstance` - match same object
  * `throwsException` - match block that throws an exception

* Number

  * `closeTo` - match number close to a given value
  * equalTo&lt;TypeName&gt; - match number equal to a primitive number (such as
  `equalToInt` for an `int`)
  * `greaterThan`, `greaterThanOrEqualTo`, `lessThan`,
  `lessThanOrEqualTo` - match numeric ordering
  * `isFalse` - match zero
  * `isTrue` - match non-zero

* Text

  * `containsString` - match part of a string
  * `endsWith` - match the end of a string
  * `equalToIgnoringCase` - match the complete string but ignore case
  * `equalToIgnoringWhitespace` - match the complete string but ignore extra
  whitespace
  * `startsWith` - match the beginning of a string
  * `stringContainsInOrder` - match parts of a string, in relative order

* Logical

  * `allOf` - "and" together all matchers
  * `anyOf` - "or" together all matchers
  * `anything` - match anything (useful in composite matchers when you don't
  care about a particular value)
  * `isNot` - negate the matcher

* Collection

  * `contains` - exactly match the entire collection
  * `containsInAnyOrder` - match the entire collection, but in any order
  * `everyItem` - match if every item in a collection satisfies a given matcher
  * `hasCount` - match number of elements against another matcher
  * `hasCountOf` - match collection with given number of elements
  * `hasEntries` - match dictionary with list of key-value pairs
  * `hasEntry` - match dictionary containing a key-value pair
  * `hasItem` - match if given item appears in the collection
  * `hasItems` - match if all given items appear in the collection, in any order
  * `hasKey` - match dictionary with a key
  * `hasValue` - match dictionary with a value
  * `isEmpty` - match empty collection
  * `onlyContains` - match if collection's items appear in given list

* Decorator

  * `describedAs` - give the matcher a custom failure description
  * `is` - decorator to improve readability - see "Syntactic sugar" below

The arguments for many of these matchers accept not just a matching value, but
another matcher, so matchers can be composed for greater flexibility. For
example, `only_contains(endsWith(@"."))` will match any collection where every
item is a string ending with period.


Syntactic sugar
---------------

OCHamcrest strives to make your tests as readable as possible. For example, the
`is` matcher is a wrapper that doesn't add any extra behavior to the underlying
matcher. The following assertions are all equivalent:

```obj-c
assertThat(theBiscuit, equalTo(myBiscuit));
assertThat(theBiscuit, is(equalTo(myBiscuit)));
assertThat(theBiscuit, is(myBiscuit));
```

The last form is allowed since `is` wraps non-matcher arguments with `equalTo`.
Other matchers that take matchers as arguments provide similar shortcuts,
wrapping non-matcher arguments in `equalTo`.


How can I assert on an asynchronous call?
-----------------------------------------

`assertThatAfter` will keep trying to evaluate an expression until the matcher
is satisfied or a timeout is reached. For example,

```obj-c
assertThatAfter(5, futureValueOf(self.someString), is(equalTo(@"expected")));
```

This checks several times for this string to be @"expected" before timing out
after 5 seconds. `futureValueOf` is a convenience function to create a block.


Writing custom matchers
-----------------------

OCHamcrest comes bundled with lots of useful matchers, but you'll probably find
that you need to create your own from time to time to fit your testing needs.
See the ["Writing Custom Matchers" guide for more information](https://github.com/hamcrest/OCHamcrest/wiki/Writing-Custom-Matchers
).


What about Swift?
-----------------

Try the [native Swift implementation of Hamcrest](https://github.com/nschum/SwiftHamcrest).
