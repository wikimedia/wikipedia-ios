(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

// Implementation of https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
const findClosest = (el, selector) => {
  while ((el = el.parentElement) && !el.matches(selector));
  return el
}

const setLanguage = (lang, dir, uidir) => {
  const html = document.querySelector( 'html' )
  html.lang = lang
  html.dir = dir
  html.classList.add( 'content-' + dir )
  html.classList.add( 'ui-' + uidir )
}

const setPageProtected =
  isProtected => document.querySelector( 'html' ).classList[isProtected ? 'add' : 'remove']('page-protected')

const scrollToFragment = fragmentId => {
  location.hash = ''
  location.hash = fragmentId
}

const accessibilityCursorToFragment = fragmentId => {
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
  const focus_element = document.getElementById(fragmentId)
  const other_element = document.body
  other_element.setAttribute('tabindex', 0)
  other_element.focus()
  focus_element.setAttribute('tabindex', 0)
  focus_element.focus()
}

exports.accessibilityCursorToFragment = accessibilityCursorToFragment
exports.scrollToFragment = scrollToFragment
exports.setPageProtected = setPageProtected
exports.setLanguage = setLanguage
exports.findClosest = findClosest
},{}],2:[function(require,module,exports){
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.pagelib = factory());
}(this, (function () { 'use strict';

// This file exists for CSS packaging only. It imports the CSS which is to be
// packaged in the override CSS build product.

// todo: delete Empty.css when other overrides exist

/**
 * Polyfill function that tells whether a given element matches a selector.
 * @param {!Element} el Element
 * @param {!string} selector Selector to look for
 * @return {!boolean} Whether the element matches the selector
 */
var matchesSelector = function matchesSelector(el, selector) {
  if (el.matches) {
    return el.matches(selector);
  }
  if (el.matchesSelector) {
    return el.matchesSelector(selector);
  }
  if (el.webkitMatchesSelector) {
    return el.webkitMatchesSelector(selector);
  }
  return false;
};

/**
 * @param {!Element} element
 * @param {!string} selector
 * @return {!Array.<Element>}
 */
var querySelectorAll = function querySelectorAll(element, selector) {
  return Array.prototype.slice.call(element.querySelectorAll(selector));
};

// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
// Required by Android API 16 AOSP Nexus S emulator.
// eslint-disable-next-line no-undef
var CustomEvent = typeof window !== 'undefined' && window.CustomEvent || function (type) {
  var parameters = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : { bubbles: false, cancelable: false, detail: undefined };

  // eslint-disable-next-line no-undef
  var event = document.createEvent('CustomEvent');
  event.initCustomEvent(type, parameters.bubbles, parameters.cancelable, parameters.detail);
  return event;
};

var Polyfill = {
  matchesSelector: matchesSelector,
  querySelectorAll: querySelectorAll,
  CustomEvent: CustomEvent
};

// todo: drop ancestor consideration and move to Polyfill.closest().
/**
 * Returns closest ancestor of element which matches selector.
 * Similar to 'closest' methods as seen here:
 *  https://api.jquery.com/closest/
 *  https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
 * @param  {!Element} el        Element
 * @param  {!string} selector   Selector to look for in ancestors of 'el'
 * @return {?HTMLElement}       Closest ancestor of 'el' matching 'selector'
 */
var findClosestAncestor = function findClosestAncestor(el, selector) {
  var parentElement = void 0;
  for (parentElement = el.parentElement; parentElement && !Polyfill.matchesSelector(parentElement, selector); parentElement = parentElement.parentElement) {
    // Intentionally empty.
  }
  return parentElement;
};

/**
 * @param {?Element} element
 * @param {!string} property
 * @return {?Element} The inclusive first element with an inline style or undefined.
 */
var closestInlineStyle = function closestInlineStyle(element, property) {
  for (var el = element; el; el = el.parentElement) {
    if (el.style[property]) {
      return el;
    }
  }
  return undefined;
};

/**
 * Determines if element has a table ancestor.
 * @param  {!Element}  el   Element
 * @return {!boolean}       Whether table ancestor of 'el' is found
 */
var isNestedInTable = function isNestedInTable(el) {
  return Boolean(findClosestAncestor(el, 'table'));
};

/**
 * @param {!HTMLElement} element
 * @return {!boolean} true if element affects layout, false otherwise.
 */
var isVisible = function isVisible(element) {
  return (
    // https://github.com/jquery/jquery/blob/305f193/src/css/hiddenVisibleSelectors.js#L12
    Boolean(element.offsetWidth || element.offsetHeight || element.getClientRects().length)
  );
};

/**
 * Copy existing attributes from source to destination as data-* attributes.
 * @param {!HTMLElement} source
 * @param {!HTMLElement} destination
 * @param {!Array.<string>} attributes
 * @return {void}
 */
var copyAttributesToDataAttributes = function copyAttributesToDataAttributes(source, destination, attributes) {
  attributes.filter(function (attribute) {
    return source.hasAttribute(attribute);
  }).forEach(function (attribute) {
    return destination.setAttribute('data-' + attribute, source.getAttribute(attribute));
  });
};

/**
 * Copy existing data-* attributes from source to destination as attributes.
 * @param {!HTMLElement} source
 * @param {!HTMLElement} destination
 * @param {!Array.<string>} attributes
 * @return {void}
 */
var copyDataAttributesToAttributes = function copyDataAttributesToAttributes(source, destination, attributes) {
  attributes.filter(function (attribute) {
    return source.hasAttribute('data-' + attribute);
  }).forEach(function (attribute) {
    return destination.setAttribute(attribute, source.getAttribute('data-' + attribute));
  });
};

var elementUtilities = {
  findClosestAncestor: findClosestAncestor,
  isNestedInTable: isNestedInTable,
  closestInlineStyle: closestInlineStyle,
  isVisible: isVisible,
  copyAttributesToDataAttributes: copyAttributesToDataAttributes,
  copyDataAttributesToAttributes: copyDataAttributesToAttributes
};

// Elements marked with these classes indicate certain ancestry constraints that are
// difficult to describe as CSS selectors.
var CONSTRAINT = {
  IMAGE_PRESUMES_WHITE_BACKGROUND: 'pagelib_theme_image_presumes_white_background',
  DIV_DO_NOT_APPLY_BASELINE: 'pagelib_theme_div_do_not_apply_baseline'

  // Theme to CSS classes.
};var THEME = {
  DEFAULT: 'pagelib_theme_default',
  DARK: 'pagelib_theme_dark',
  SEPIA: 'pagelib_theme_sepia',
  BLACK: 'pagelib_theme_black'

  /**
   * @param {!Document} document
   * @param {!string} theme
   * @return {void}
   */
};var setTheme = function setTheme(document, theme) {
  var html = document.querySelector('html');

  // Set the new theme.
  html.classList.add(theme);

  // Clear any previous theme.
  for (var key in THEME) {
    if (Object.prototype.hasOwnProperty.call(THEME, key) && THEME[key] !== theme) {
      html.classList.remove(THEME[key]);
    }
  }
};

/**
 * Football template image filename regex.
 * https://en.wikipedia.org/wiki/Template:Football_kit/pattern_list
 * @type {RegExp}
 */
var footballTemplateImageFilenameRegex = new RegExp('Kit_(body|socks|shorts|right_arm|left_arm)(.*).png$');

/* en > Away colours > 793128975 */
/* en > Manchester United F.C. > 793244653 */
/**
 * Determines whether white background should be added to image.
 * @param  {!HTMLImageElement} image
 * @return {!boolean}
 */
var imagePresumesWhiteBackground = function imagePresumesWhiteBackground(image) {
  if (footballTemplateImageFilenameRegex.test(image.src)) {
    return false;
  }
  if (image.classList.contains('mwe-math-fallback-image-inline')) {
    return false;
  }
  return !elementUtilities.closestInlineStyle(image, 'background');
};

/**
 * Annotate elements with CSS classes that can be used by CSS rules. The classes themselves are not
 * theme-dependent so classification only need only occur once after the content is loaded, not
 * every time the theme changes.
 * @param {!Element} element
 * @return {void}
 */
var classifyElements = function classifyElements(element) {
  Polyfill.querySelectorAll(element, 'img').filter(imagePresumesWhiteBackground).forEach(function (image) {
    image.classList.add(CONSTRAINT.IMAGE_PRESUMES_WHITE_BACKGROUND);
  });
  /* en > Away colours > 793128975 */
  /* en > Manchester United F.C. > 793244653 */
  /* en > Pantone > 792312384 */
  /* en > Wikipedia:Graphs_and_charts > 801754530 */
  /* en > PepsiCo > 807406166 */
  /* en > Lua_(programming_language) > 809310207 */
  var selector = ['div.color_swatch div', 'div[style*="position: absolute"]', 'div.barbox table div[style*="background:"]', 'div.chart div[style*="background-color"]', 'div.chart ul li span[style*="background-color"]', 'span.legend-color', 'div.mw-highlight span', 'code.mw-highlight span'].join();
  Polyfill.querySelectorAll(element, selector).forEach(function (element) {
    return element.classList.add(CONSTRAINT.DIV_DO_NOT_APPLY_BASELINE);
  });
};

var ThemeTransform = {
  CONSTRAINT: CONSTRAINT,
  THEME: THEME,
  setTheme: setTheme,
  classifyElements: classifyElements
};

var SECTION_TOGGLED_EVENT_TYPE = 'section-toggled';
var ELEMENT_NODE = 1;
var TEXT_NODE = 3;
var BREAKING_SPACE = ' ';

/**
 * Determine if we want to extract text from this header.
 * @param {!Element} header
 * @return {!boolean}
 */
var isHeaderEligible = function isHeaderEligible(header) {
  return header.childNodes && Polyfill.querySelectorAll(header, 'a').length < 3;
};

/**
 * Determine eligibility of extracted text.
 * @param {?string} headerText
 * @return {!boolean}
 */
var isHeaderTextEligible = function isHeaderTextEligible(headerText) {
  return headerText && headerText.replace(/[\s0-9]/g, '').length > 0;
};

/**
 * Extracts first word from string. Returns null if for any reason it is unable to do so.
 * @param  {!string} string
 * @return {?string}
 */
var firstWordFromString = function firstWordFromString(string) {
  // 'If the global flag (g) is not set, Element zero of the array contains the entire match,
  // while elements 1 through n contain any submatches.'
  var matches = string.match(/\w+/); // Only need first match so not using 'g' option.
  if (!matches) {
    return undefined;
  }
  return matches[0];
};

/**
 * Is node's textContent too similar to pageTitle. Checks if the first word of the node's
 * textContent is found at the beginning of pageTitle.
 * @param  {!Node} node
 * @param  {!string} pageTitle
 * @return {!boolean}
 */
var isNodeTextContentSimilarToPageTitle = function isNodeTextContentSimilarToPageTitle(node, pageTitle) {
  var firstPageTitleWord = firstWordFromString(pageTitle);
  var firstNodeTextContentWord = firstWordFromString(node.textContent);
  // Don't claim similarity if 1st words were not extracted.
  if (!firstPageTitleWord || !firstNodeTextContentWord) {
    return false;
  }
  return firstPageTitleWord.toLowerCase() === firstNodeTextContentWord.toLowerCase();
};

/**
 * Determines if a node is an element or text node.
 * @param  {!Node} node
 * @return {!boolean}
 */
var nodeTypeIsElementOrText = function nodeTypeIsElementOrText(node) {
  return node.nodeType === ELEMENT_NODE || node.nodeType === TEXT_NODE;
};

/**
 * Removes leading and trailing whitespace and normalizes other whitespace - i.e. ensures
 * non-breaking spaces, tabs, etc are replaced with regular breaking spaces. 
 * @param  {!string} string
 * @return {!string}
 */
var stringWithNormalizedWhitespace = function stringWithNormalizedWhitespace(string) {
  return string.trim().replace(/\s/g, BREAKING_SPACE);
};

/**
 * Determines if node is a BR.
 * @param  {!Node}  node
 * @return {!boolean}
 */
var isNodeBreakElement = function isNodeBreakElement(node) {
  return node.nodeType === ELEMENT_NODE && node.tagName === 'BR';
};

/**
 * Replace node with a text node bearing a single breaking space.
 * @param {!Document} document
 * @param  {!Node} node
 * @return {void}
 */
var replaceNodeWithBreakingSpaceTextNode = function replaceNodeWithBreakingSpaceTextNode(document, node) {
  return node.parentNode.replaceChild(document.createTextNode(BREAKING_SPACE), node);
};

/**
 * Extracts any header text determined to be eligible.
 * @param {!Document} document
 * @param {!Element} header
 * @param {?string} pageTitle
 * @return {?string}
 */
var extractEligibleHeaderText = function extractEligibleHeaderText(document, header, pageTitle) {
  if (!isHeaderEligible(header)) {
    return null;
  }
  // Clone header into fragment. This is done so we can remove some elements we don't want
  // represented when "textContent" is used. Because we've cloned the header into a fragment, we are
  // free to strip out anything we want without worrying about affecting the visible document.
  var fragment = document.createDocumentFragment();
  fragment.appendChild(header.cloneNode(true));
  var fragmentHeader = fragment.querySelector('th');

  Polyfill.querySelectorAll(fragmentHeader, '.geo, .coordinates, sup.reference, ol, ul').forEach(function (el) {
    return el.remove();
  });

  var childNodesArray = Array.prototype.slice.call(fragmentHeader.childNodes);
  if (pageTitle) {
    childNodesArray.filter(nodeTypeIsElementOrText).filter(function (node) {
      return isNodeTextContentSimilarToPageTitle(node, pageTitle);
    }).forEach(function (node) {
      return node.remove();
    });
  }

  childNodesArray.filter(isNodeBreakElement).forEach(function (node) {
    return replaceNodeWithBreakingSpaceTextNode(document, node);
  });

  var headerText = fragmentHeader.textContent;
  if (isHeaderTextEligible(headerText)) {
    return stringWithNormalizedWhitespace(headerText);
  }
  return null;
};

/**
 * Used to sort array of Elements so those containing 'scope' attribute are moved to front of
 * array. Relative order between 'scope' elements is preserved. Relative order between non 'scope'
 * elements is preserved.
 * @param  {!Element} a
 * @param  {!Element} b
 * @return {!boolean}
 */
var elementScopeComparator = function elementScopeComparator(a, b) {
  var aHasScope = a.hasAttribute('scope');
  var bHasScope = b.hasAttribute('scope');
  if (aHasScope && bHasScope) {
    return 0;
  }
  if (aHasScope) {
    return -1;
  }
  if (bHasScope) {
    return 1;
  }
  return 0;
};

/**
 * Find an array of table header (TH) contents. If there are no TH elements in
 * the table or the header's link matches pageTitle, an empty array is returned.
 * @param {!Document} document
 * @param {!Element} element
 * @param {?string} pageTitle Unencoded page title; if this title matches the
 *                            contents of the header exactly, it will be omitted.
 * @return {!Array<string>}
 */
var getTableHeaderTextArray = function getTableHeaderTextArray(document, element, pageTitle) {
  var headerTextArray = [];
  var headers = Polyfill.querySelectorAll(element, 'th');
  headers.sort(elementScopeComparator);
  for (var i = 0; i < headers.length; ++i) {
    var headerText = extractEligibleHeaderText(document, headers[i], pageTitle);
    if (headerText && headerTextArray.indexOf(headerText) === -1) {
      headerTextArray.push(headerText);
      // 'newCaptionFragment' only ever uses the first 2 items.
      if (headerTextArray.length === 2) {
        break;
      }
    }
  }
  return headerTextArray;
};

/**
 * @typedef {function} FooterDivClickCallback
 * @param {!HTMLElement}
 * @return {void}
 */

/**
 * @param {!Element} container div
 * @param {?Element} trigger element that was clicked or tapped
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {boolean} true if collapsed, false if expanded.
 */
var toggleCollapsedForContainer = function toggleCollapsedForContainer(container, trigger, footerDivClickCallback) {
  var header = container.children[0];
  var table = container.children[1];
  var footer = container.children[2];
  var caption = header.querySelector('.app_table_collapsed_caption');
  var collapsed = table.style.display !== 'none';
  if (collapsed) {
    table.style.display = 'none';
    header.classList.remove('pagelib_collapse_table_collapsed');
    header.classList.remove('pagelib_collapse_table_icon');
    header.classList.add('pagelib_collapse_table_expanded');
    if (caption) {
      caption.style.visibility = 'visible';
    }
    footer.style.display = 'none';
    // if they clicked the bottom div, then scroll back up to the top of the table.
    if (trigger === footer && footerDivClickCallback) {
      footerDivClickCallback(container);
    }
  } else {
    table.style.display = 'block';
    header.classList.remove('pagelib_collapse_table_expanded');
    header.classList.add('pagelib_collapse_table_collapsed');
    header.classList.add('pagelib_collapse_table_icon');
    if (caption) {
      caption.style.visibility = 'hidden';
    }
    footer.style.display = 'block';
  }
  return collapsed;
};

/**
 * Ex: toggleCollapseClickCallback.bind(el, (container) => {
 *       window.scrollTo(0, container.offsetTop - transformer.getDecorOffset())
 *     })
 * @this HTMLElement
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {boolean} true if collapsed, false if expanded.
 */
var toggleCollapseClickCallback = function toggleCollapseClickCallback(footerDivClickCallback) {
  var container = this.parentNode;
  return toggleCollapsedForContainer(container, this, footerDivClickCallback);
};

/**
 * @param {!HTMLElement} table
 * @return {!boolean} true if table should be collapsed, false otherwise.
 */
var shouldTableBeCollapsed = function shouldTableBeCollapsed(table) {
  var classBlacklist = ['navbox', 'vertical-navbox', 'navbox-inner', 'metadata', 'mbox-small'];
  var blacklistIntersects = classBlacklist.some(function (clazz) {
    return table.classList.contains(clazz);
  });
  return table.style.display !== 'none' && !blacklistIntersects;
};

/**
 * @param {!Element} element
 * @return {!boolean} true if element is an infobox, false otherwise.
 */
var isInfobox = function isInfobox(element) {
  return element.classList.contains('infobox');
};

/**
 * @param {!Document} document
 * @param {!DocumentFragment} content
 * @return {!HTMLDivElement}
 */
var newCollapsedHeaderDiv = function newCollapsedHeaderDiv(document, content) {
  var div = document.createElement('div');
  div.classList.add('pagelib_collapse_table_collapsed_container');
  div.classList.add('pagelib_collapse_table_expanded');
  div.appendChild(content);
  return div;
};

/**
 * @param {!Document} document
 * @param {?string} content HTML string.
 * @return {!HTMLDivElement}
 */
var newCollapsedFooterDiv = function newCollapsedFooterDiv(document, content) {
  var div = document.createElement('div');
  div.classList.add('pagelib_collapse_table_collapsed_bottom');
  div.classList.add('pagelib_collapse_table_icon');
  div.innerHTML = content || '';
  return div;
};

/**
 * @param {!Document} document
 * @param {!string} title
 * @param {!Array.<string>} headerText
 * @return {!DocumentFragment}
 */
var newCaptionFragment = function newCaptionFragment(document, title, headerText) {
  var fragment = document.createDocumentFragment();

  var strong = document.createElement('strong');
  strong.innerHTML = title;
  fragment.appendChild(strong);

  var span = document.createElement('span');
  span.classList.add('pagelib_collapse_table_collapse_text');
  if (headerText.length > 0) {
    span.appendChild(document.createTextNode(': ' + headerText[0]));
  }
  if (headerText.length > 1) {
    span.appendChild(document.createTextNode(', ' + headerText[1]));
  }
  if (headerText.length > 0) {
    span.appendChild(document.createTextNode(' …'));
  }
  fragment.appendChild(span);

  return fragment;
};

/**
 * @param {!Window} window
 * @param {!Document} document
 * @param {?string} pageTitle use title for this not `display title` (which can contain tags)
 * @param {?boolean} isMainPage
 * @param {?boolean} isInitiallyCollapsed
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {void}
 */
var adjustTables = function adjustTables(window, document, pageTitle, isMainPage, isInitiallyCollapsed, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback) {
  if (isMainPage) {
    return;
  }

  var tables = document.querySelectorAll('table');

  var _loop = function _loop(i) {
    var table = tables[i];

    if (elementUtilities.findClosestAncestor(table, '.pagelib_collapse_table_container') || !shouldTableBeCollapsed(table)) {
      return 'continue';
    }

    var headerTextArray = getTableHeaderTextArray(document, table, pageTitle);
    if (!headerTextArray.length && !isInfobox(table)) {
      return 'continue';
    }
    var captionFragment = newCaptionFragment(document, isInfobox(table) ? infoboxTitle : otherTitle, headerTextArray);

    // create the container div that will contain both the original table
    // and the collapsed version.
    var containerDiv = document.createElement('div');
    containerDiv.className = 'pagelib_collapse_table_container';
    table.parentNode.insertBefore(containerDiv, table);
    table.parentNode.removeChild(table);

    // remove top and bottom margin from the table, so that it's flush with
    // our expand/collapse buttons
    table.style.marginTop = '0px';
    table.style.marginBottom = '0px';

    var collapsedHeaderDiv = newCollapsedHeaderDiv(document, captionFragment);
    collapsedHeaderDiv.style.display = 'block';

    var collapsedFooterDiv = newCollapsedFooterDiv(document, footerTitle);
    collapsedFooterDiv.style.display = 'none';

    // add our stuff to the container
    containerDiv.appendChild(collapsedHeaderDiv);
    containerDiv.appendChild(table);
    containerDiv.appendChild(collapsedFooterDiv);

    // set initial visibility
    table.style.display = 'none';

    // eslint-disable-next-line require-jsdoc, no-loop-func
    var dispatchSectionToggledEvent = function dispatchSectionToggledEvent(collapsed) {
      return (
        // eslint-disable-next-line no-undef
        window.dispatchEvent(new Polyfill.CustomEvent(SECTION_TOGGLED_EVENT_TYPE, { collapsed: collapsed }))
      );
    };

    // assign click handler to the collapsed divs
    collapsedHeaderDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedHeaderDiv)();
      dispatchSectionToggledEvent(collapsed);
    };
    collapsedFooterDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedFooterDiv, footerDivClickCallback)();
      dispatchSectionToggledEvent(collapsed);
    };

    if (!isInitiallyCollapsed) {
      toggleCollapsedForContainer(containerDiv);
    }
  };

  for (var i = 0; i < tables.length; ++i) {
    var _ret = _loop(i);

    if (_ret === 'continue') continue;
  }
};

/**
 * @param {!Window} window
 * @param {!Document} document
 * @param {?string} pageTitle use title for this not `display title` (which can contain tags)
 * @param {?boolean} isMainPage
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {void}
 */
var collapseTables = function collapseTables(window, document, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback) {
  adjustTables(window, document, pageTitle, isMainPage, true, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback);
};

/**
 * If you tap a reference targeting an anchor within a collapsed table, this
 * method will expand the references section. The client can then scroll to the
 * references section.
 *
 * The first reference (an "[A]") in the "enwiki > Airplane" article from ~June
 * 2016 exhibits this issue. (You can copy wikitext from this revision into a
 * test wiki page for testing.)
 * @param  {?Element} element
 * @return {void}
*/
var expandCollapsedTableIfItContainsElement = function expandCollapsedTableIfItContainsElement(element) {
  if (element) {
    var containerSelector = '[class*="pagelib_collapse_table_container"]';
    var container = elementUtilities.findClosestAncestor(element, containerSelector);
    if (container) {
      var collapsedDiv = container.firstElementChild;
      if (collapsedDiv && collapsedDiv.classList.contains('pagelib_collapse_table_expanded')) {
        collapsedDiv.click();
      }
    }
  }
};

var CollapseTable = {
  SECTION_TOGGLED_EVENT_TYPE: SECTION_TOGGLED_EVENT_TYPE,
  toggleCollapseClickCallback: toggleCollapseClickCallback,
  collapseTables: collapseTables,
  adjustTables: adjustTables,
  expandCollapsedTableIfItContainsElement: expandCollapsedTableIfItContainsElement,
  test: {
    elementScopeComparator: elementScopeComparator,
    extractEligibleHeaderText: extractEligibleHeaderText,
    firstWordFromString: firstWordFromString,
    getTableHeaderTextArray: getTableHeaderTextArray,
    shouldTableBeCollapsed: shouldTableBeCollapsed,
    isHeaderEligible: isHeaderEligible,
    isHeaderTextEligible: isHeaderTextEligible,
    isInfobox: isInfobox,
    newCollapsedHeaderDiv: newCollapsedHeaderDiv,
    newCollapsedFooterDiv: newCollapsedFooterDiv,
    newCaptionFragment: newCaptionFragment,
    isNodeTextContentSimilarToPageTitle: isNodeTextContentSimilarToPageTitle,
    stringWithNormalizedWhitespace: stringWithNormalizedWhitespace,
    replaceNodeWithBreakingSpaceTextNode: replaceNodeWithBreakingSpaceTextNode
  }
};

/**
 * Extracts array of page issues from element
 * @param {!Document} document
 * @param {?Element} element
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssues = function collectPageIssues(document, element) {
  if (!element) {
    return [];
  }
  var tables = Polyfill.querySelectorAll(element, 'table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)');
  // Get the tables into a fragment so we can remove some elements without triggering a layout
  var fragment = document.createDocumentFragment();
  var cloneTableIntoFragment = function cloneTableIntoFragment(table) {
    return fragment.appendChild(table.cloneNode(true));
  }; // eslint-disable-line require-jsdoc
  tables.forEach(cloneTableIntoFragment);
  // Remove some elements we don't want when "textContent" or "innerHTML" are used
  Polyfill.querySelectorAll(fragment, '.hide-when-compact, .collapsed').forEach(function (el) {
    return el.remove();
  });
  return Polyfill.querySelectorAll(fragment, 'td[class*=mbox-text] > *[class*=mbox-text]');
};

/**
 * Extracts array of page issues HTML from element
 * @param {!Document} document
 * @param {?Element} element
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssuesHTML = function collectPageIssuesHTML(document, element) {
  return collectPageIssues(document, element).map(function (el) {
    return el.innerHTML;
  });
};

/**
 * Extracts array of page issues text from element
 * @param {!Document} document
 * @param {?Element} element
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssuesText = function collectPageIssuesText(document, element) {
  return collectPageIssues(document, element).map(function (el) {
    return el.textContent.trim();
  });
};

/**
 * Extracts array of disambiguation titles from an element
 * @param {?Element} element
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectDisambiguationTitles = function collectDisambiguationTitles(element) {
  if (!element) {
    return [];
  }
  return Polyfill.querySelectorAll(element, 'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function (el) {
    return el.href;
  });
};

/**
 * Extracts array of disambiguation items html from an element
 * @param {?Element} element
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectDisambiguationHTML = function collectDisambiguationHTML(element) {
  if (!element) {
    return [];
  }
  return Polyfill.querySelectorAll(element, 'div.hatnote').map(function (el) {
    return el.innerHTML;
  });
};

var CollectionUtilities = {
  collectDisambiguationTitles: collectDisambiguationTitles,
  collectDisambiguationHTML: collectDisambiguationHTML,
  collectPageIssuesHTML: collectPageIssuesHTML,
  collectPageIssuesText: collectPageIssuesText,
  test: {
    collectPageIssues: collectPageIssues
  }
};

var COMPATIBILITY = {
  FILTER: 'pagelib_compatibility_filter'

  /**
   * @param {!Document} document
   * @param {!Array.<string>} properties
   * @param {!string} value
   * @return {void}
   */
};var isStyleSupported = function isStyleSupported(document, properties, value) {
  var element = document.createElement('span');
  return properties.some(function (property) {
    element.style[property] = value;
    return element.style.cssText;
  });
};

/**
 * @param {!Document} document
 * @return {void}
 */
var isFilterSupported = function isFilterSupported(document) {
  return isStyleSupported(document, ['webkitFilter', 'filter'], 'blur(0)');
};

/**
 * @param {!Document} document
 * @return {void}
 */
var enableSupport = function enableSupport(document) {
  var html = document.querySelector('html');
  if (!isFilterSupported(document)) {
    html.classList.add(COMPATIBILITY.FILTER);
  }
};

var CompatibilityTransform = {
  COMPATIBILITY: COMPATIBILITY,
  enableSupport: enableSupport
};

var CLASS = 'pagelib_dim_images';

// todo: only require a Document
/**
 * @param {!Window} window
 * @param {!boolean} enable
 * @return {void}
 */
var dim = function dim(window, enable) {
  window.document.querySelector('html').classList[enable ? 'add' : 'remove'](CLASS);
};

// todo: only require a Document
/**
 * @param {!Window} window
 * @return {boolean}
 */
var isDim = function isDim(window) {
  return window.document.querySelector('html').classList.contains(CLASS);
};

var DimImagesTransform = {
  CLASS: CLASS,
  isDim: isDim,
  dim: dim
};

var CLASS$1 = {
  CONTAINER: 'pagelib_edit_section_link_container',
  LINK: 'pagelib_edit_section_link',
  PROTECTION: { UNPROTECTED: '', PROTECTED: 'page-protected', FORBIDDEN: 'no-editing' }
};

var DATA_ATTRIBUTE = { SECTION_INDEX: 'data-id', ACTION: 'data-action' };
var ACTION_EDIT_SECTION = 'edit_section';

/**
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @return {!HTMLAnchorElement}
 */
var newEditSectionLink = function newEditSectionLink(document, index) {
  var link = document.createElement('a');
  link.href = '';
  link.setAttribute(DATA_ATTRIBUTE.SECTION_INDEX, index);
  link.setAttribute(DATA_ATTRIBUTE.ACTION, ACTION_EDIT_SECTION);
  link.classList.add(CLASS$1.LINK);
  return link;
};

/**
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @return {!HTMLSpanElement}
 */
var newEditSectionButton = function newEditSectionButton(document, index) {
  var container = document.createElement('span');
  container.classList.add(CLASS$1.CONTAINER);

  var link = newEditSectionLink(document, index);
  container.appendChild(link);

  return container;
};

var EditTransform = {
  CLASS: CLASS$1,
  newEditSectionButton: newEditSectionButton
};

var classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
};

var createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps);
    return Constructor;
  };
}();

/** CSS length value and unit of measure. */
var DimensionUnit = function () {
  createClass(DimensionUnit, null, [{
    key: 'fromElement',

    /**
     * Returns the dimension and units of an Element, usually width or height, as specified by inline
     * style or attribute. This is a pragmatic not bulletproof implementation.
     * @param {!Element} element
     * @param {!string} property
     * @return {?DimensionUnit}
     */
    value: function fromElement(element, property) {
      return element.style.getPropertyValue(property) && DimensionUnit.fromStyle(element.style.getPropertyValue(property)) || element.hasAttribute(property) && new DimensionUnit(element.getAttribute(property)) || undefined;
    }

    /**
     * This is a pragmatic not bulletproof implementation.
     * @param {!string} property
     * @return {!DimensionUnit}
     */

  }, {
    key: 'fromStyle',
    value: function fromStyle(property) {
      var matches = property.match(/(-?\d*\.?\d*)(\D+)?/) || [];
      return new DimensionUnit(matches[1], matches[2]);
    }

    /**
     * @param {!string} value
     * @param {?string} unit Defaults to pixels.
     */

  }]);

  function DimensionUnit(value, unit) {
    classCallCheck(this, DimensionUnit);

    this._value = Number(value);
    this._unit = unit || 'px';
  }

  /** @return {!number} NaN if unknown. */


  createClass(DimensionUnit, [{
    key: 'toString',


    /** @return {!string} */
    value: function toString() {
      return isNaN(this.value) ? '' : '' + this.value + this.unit;
    }
  }, {
    key: 'value',
    get: function get$$1() {
      return this._value;
    }

    /** @return {!string} */

  }, {
    key: 'unit',
    get: function get$$1() {
      return this._unit;
    }
  }]);
  return DimensionUnit;
}();

/** Element width and height dimensions and units. */


var ElementGeometry = function () {
  createClass(ElementGeometry, null, [{
    key: 'from',

    /**
     * @param {!Element} element
     * @return {!ElementGeometry}
     */
    value: function from(element) {
      return new ElementGeometry(DimensionUnit.fromElement(element, 'width'), DimensionUnit.fromElement(element, 'height'));
    }

    /**
     * @param {?DimensionUnit} width
     * @param {?DimensionUnit} height
     */

  }]);

  function ElementGeometry(width, height) {
    classCallCheck(this, ElementGeometry);

    this._width = width;
    this._height = height;
  }

  /**
   * @return {?DimensionUnit}
   */


  createClass(ElementGeometry, [{
    key: 'width',
    get: function get$$1() {
      return this._width;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'widthValue',
    get: function get$$1() {
      return this._width && !isNaN(this._width.value) ? this._width.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'widthUnit',
    get: function get$$1() {
      return this._width && this._width.unit || 'px';
    }

    /**
     * @return {?DimensionUnit}
     */

  }, {
    key: 'height',
    get: function get$$1() {
      return this._height;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'heightValue',
    get: function get$$1() {
      return this._height && !isNaN(this._height.value) ? this._height.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'heightUnit',
    get: function get$$1() {
      return this._height && this._height.unit || 'px';
    }
  }]);
  return ElementGeometry;
}();

var ELEMENT_NODE$1 = 1;

/**
 * Determine if paragraph is the one we are interested in.
 * @param  {!HTMLParagraphElement}  paragraphElement
 * @return {!boolean}
 */
var isParagraphEligible = function isParagraphEligible(paragraphElement) {
  // Ignore 'coordinates' which are presently hidden. See enwiki 'Bolton Field' and 'Sharya Forest
  // Museum Railway'. Not counting coordinates towards the eligible P min textContent length
  // heuristic has dual effect of P's containing only coordinates being rejected, and P's containing
  // coordinates but also other elements meeting the eligible P min textContent length being
  // accepted.
  var coordElement = paragraphElement.querySelector('[id="coordinates"]');
  var coordTextLength = !coordElement ? 0 : coordElement.textContent.length;

  // Ensures the paragraph has at least a little text. Otherwise silly things like a empty P or P
  // which only contains a BR tag will get pulled up. See enwiki 'Hawaii', 'United States',
  // 'Academy (educational institution)', 'Lovászpatona'
  var minEligibleTextLength = 50;
  var hasEnoughEligibleText = paragraphElement.textContent.length - coordTextLength >= minEligibleTextLength;
  return hasEnoughEligibleText;
};

/**
 * Nodes we want to move up. This includes the `eligibleParagraph` and everything up to (but not
 * including) the next paragraph.
 * @param  {!HTMLParagraphElement} eligibleParagraph
 * @return {!Array.<Node>} Array of text nodes, elements, etc...
 */
var extractLeadIntroductionNodes = function extractLeadIntroductionNodes(eligibleParagraph) {
  var introNodes = [];
  var node = eligibleParagraph;
  do {
    introNodes.push(node);
    node = node.nextSibling;
  } while (node && !(node.nodeType === ELEMENT_NODE$1 && node.tagName === 'P'));
  return introNodes;
};

/**
 * Locate first eligible paragraph. We don't want paragraphs from somewhere in the middle of a
 * table, so only paragraphs which are direct children of `containerID` element are considered. 
 * @param  {!Document} document
 * @param  {!string} containerID ID of the section under examination.
 * @return {?HTMLParagraphElement}
 */
var getEligibleParagraph = function getEligibleParagraph(document, containerID) {
  return Polyfill.querySelectorAll(document, '#' + containerID + ' > p').find(isParagraphEligible);
};

/**
 * Instead of moving the infobox down beneath the first P tag, move the first eligible P tag
 * (and related elements) up. This ensures some text will appear above infoboxes, tables, images
 * etc. This method does not do a 'mainpage' check - do so before calling it.
 * @param  {!Document} document
 * @param  {!string} containerID ID of the section under examination.
 * @param  {?Element} afterElement Element after which paragraph will be moved. If not specified
 * paragraph will be move to top of `containerID` element.
 * @return {void}
 */
var moveLeadIntroductionUp = function moveLeadIntroductionUp(document, containerID, afterElement) {
  var eligibleParagraph = getEligibleParagraph(document, containerID);
  if (!eligibleParagraph) {
    return;
  }

  // A light-weight fragment to hold everything we want to move up.
  var fragment = document.createDocumentFragment();
  // DocumentFragment's `appendChild` attaches the element to the fragment AND removes it from DOM.
  extractLeadIntroductionNodes(eligibleParagraph).forEach(function (element) {
    return fragment.appendChild(element);
  });

  var container = document.getElementById(containerID);
  var insertBeforeThisElement = !afterElement ? container.firstChild : afterElement.nextSibling;

  // Attach the fragment just before `insertBeforeThisElement`. Conveniently, `insertBefore` on a
  // DocumentFragment inserts 'the children of the fragment, not the fragment itself.', so no
  // unnecessary container element is introduced.
  // https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
  container.insertBefore(fragment, insertBeforeThisElement);
};

var LeadIntroductionTransform = {
  moveLeadIntroductionUp: moveLeadIntroductionUp,
  test: {
    isParagraphEligible: isParagraphEligible,
    extractLeadIntroductionNodes: extractLeadIntroductionNodes,
    getEligibleParagraph: getEligibleParagraph
  }
};

/**
 * Ensures the 'Read more' section header can always be scrolled to the top of the screen.
 * @param {!Window} window
 * @return {void}
 */
var updateBottomPaddingToAllowReadMoreToScrollToTop = function updateBottomPaddingToAllowReadMoreToScrollToTop(window) {
  var div = window.document.getElementById('pagelib_footer_container_ensure_can_scroll_to_top');
  var currentPadding = parseInt(div.style.paddingBottom, 10) || 0;
  var height = div.clientHeight - currentPadding;
  var newPadding = Math.max(0, window.innerHeight - height);
  div.style.paddingBottom = newPadding + 'px';
};

/**
 * Allows native code to adjust footer container margins without having to worry about
 * implementation details.
 * @param {!number} margin
 * @param {!Document} document
 * @return {void}
 */
var updateLeftAndRightMargin = function updateLeftAndRightMargin(margin, document) {
  var selectors = ['#pagelib_footer_container_menu_heading', '#pagelib_footer_container_readmore', '#pagelib_footer_container_legal'];
  var elements = Polyfill.querySelectorAll(document, selectors.join());
  elements.forEach(function (element) {
    element.style.marginLeft = margin + 'px';
    element.style.marginRight = margin + 'px';
  });
  var rightOrLeft = document.querySelector('html').dir === 'rtl' ? 'right' : 'left';
  Polyfill.querySelectorAll(document, '.pagelib_footer_menu_item').forEach(function (element) {
    element.style.backgroundPosition = rightOrLeft + ' ' + margin + 'px center';
    element.style.paddingLeft = margin + 'px';
    element.style.paddingRight = margin + 'px';
  });
};

/**
 * Returns a fragment containing structural footer html which may be inserted where needed.
 * @param {!Document} document
 * @return {!DocumentFragment}
 */
var containerFragment = function containerFragment(document) {
  var containerDiv = document.createElement('div');
  var containerFragment = document.createDocumentFragment();
  containerFragment.appendChild(containerDiv);
  containerDiv.innerHTML = '<div id=\'pagelib_footer_container\' class=\'pagelib_footer_container\'>\n    <div id=\'pagelib_footer_container_section_0\'>\n      <div id=\'pagelib_footer_container_menu\'>\n        <div id=\'pagelib_footer_container_menu_heading\' class=\'pagelib_footer_container_heading\'>\n        </div>\n        <div id=\'pagelib_footer_container_menu_items\'>\n        </div>\n      </div>\n    </div>\n    <div id=\'pagelib_footer_container_ensure_can_scroll_to_top\'>\n      <div id=\'pagelib_footer_container_section_1\'>\n        <div id=\'pagelib_footer_container_readmore\'>\n          <div\n            id=\'pagelib_footer_container_readmore_heading\' class=\'pagelib_footer_container_heading\'>\n          </div>\n          <div id=\'pagelib_footer_container_readmore_pages\'>\n          </div>\n        </div>\n      </div>\n      <div id=\'pagelib_footer_container_legal\'></div>\n    </div>\n  </div>';
  return containerFragment;
};

/**
 * Indicates whether container is has already been added.
 * @param {!Document} document
 * @return {boolean}
 */
var isContainerAttached = function isContainerAttached(document) {
  return Boolean(document.querySelector('#pagelib_footer_container'));
};

var FooterContainer = {
  containerFragment: containerFragment,
  isContainerAttached: isContainerAttached, // todo: rename isAttached()?
  updateBottomPaddingToAllowReadMoreToScrollToTop: updateBottomPaddingToAllowReadMoreToScrollToTop,
  updateLeftAndRightMargin: updateLeftAndRightMargin
};

/**
 * @typedef {function} FooterLegalClickCallback
 * @return {void}
 */

/**
  * @typedef {function} FooterBrowserClickCallback
  * @return {void}
  */

/**
 * Adds legal footer html to 'containerID' element.
 * @param {!Element} content
 * @param {?string} licenseString
 * @param {?string} licenseSubstitutionString
 * @param {!string} containerID
 * @param {!FooterLegalClickCallback} licenseLinkClickHandler
 * @param {!string} viewInBrowserString
 * @param {!FooterBrowserClickCallback} browserLinkClickHandler
 * @return {void}
 */
var add = function add(content, licenseString, licenseSubstitutionString, containerID, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler) {
  // todo: don't manipulate the selector. The client can make this an ID if they want it to be.
  var container = content.querySelector('#' + containerID);
  var licenseStringHalves = licenseString.split('$1');

  container.innerHTML = '<div class=\'pagelib_footer_legal_contents\'>\n    <hr class=\'pagelib_footer_legal_divider\'>\n    <span class=\'pagelib_footer_legal_license\'>\n      ' + licenseStringHalves[0] + '\n      <a class=\'pagelib_footer_legal_license_link\'>\n        ' + licenseSubstitutionString + '\n      </a>\n      ' + licenseStringHalves[1] + '\n      <br>\n      <div class="pagelib_footer_browser">\n        <a class=\'pagelib_footer_browser_link\'>\n          ' + viewInBrowserString + '\n        </a>\n      </div>\n    </span>\n  </div>';

  container.querySelector('.pagelib_footer_legal_license_link').addEventListener('click', function () {
    licenseLinkClickHandler();
  });

  container.querySelector('.pagelib_footer_browser_link').addEventListener('click', function () {
    browserLinkClickHandler();
  });
};

var FooterLegal = {
  add: add
};

/**
 * @typedef {function} FooterMenuItemClickCallback
 * @param {!Array.<string>} payload Important - should return empty array if no payload strings.
 * @return {void}
 */

/**
 * @typedef {number} MenuItemType
 */

/**
 * Type representing kinds of menu items.
 * @enum {MenuItemType}
 */
var MenuItemType = {
  languages: 1,
  lastEdited: 2,
  pageIssues: 3,
  disambiguation: 4,
  coordinate: 5,
  talkPage: 6

  /**
   * Menu item model.
   */
};
var MenuItem = function () {
  /**
   * MenuItem constructor.
   * @param {!string} title
   * @param {?string} subtitle
   * @param {!MenuItemType} itemType
   * @param {FooterMenuItemClickCallback} clickHandler
   * @return {void}
   */
  function MenuItem(title, subtitle, itemType, clickHandler) {
    classCallCheck(this, MenuItem);

    this.title = title;
    this.subtitle = subtitle;
    this.itemType = itemType;
    this.clickHandler = clickHandler;
    this.payload = [];
  }

  /**
   * Returns icon CSS class for this menu item based on its type.
   * @return {!string}
   */


  createClass(MenuItem, [{
    key: 'iconClass',
    value: function iconClass() {
      switch (this.itemType) {
        case MenuItemType.languages:
          return 'pagelib_footer_menu_icon_languages';
        case MenuItemType.lastEdited:
          return 'pagelib_footer_menu_icon_last_edited';
        case MenuItemType.talkPage:
          return 'pagelib_footer_menu_icon_talk_page';
        case MenuItemType.pageIssues:
          return 'pagelib_footer_menu_icon_page_issues';
        case MenuItemType.disambiguation:
          return 'pagelib_footer_menu_icon_disambiguation';
        case MenuItemType.coordinate:
          return 'pagelib_footer_menu_icon_coordinate';
        default:
          return '';
      }
    }

    /**
     * Extracts array of page issues, disambiguation titles, etc from element.
     * @typedef {function} PayloadExtractor
     * @param {!Document} document
     * @param {?Element} element
     * @return {!Array.<string>} Return empty array if nothing is extracted
     */

    /**
     * Returns reference to function for extracting payload when this menu item is tapped.
     * @return {?PayloadExtractor}
     */

  }, {
    key: 'payloadExtractor',
    value: function payloadExtractor() {
      switch (this.itemType) {
        case MenuItemType.pageIssues:
          return CollectionUtilities.collectPageIssuesText;
        case MenuItemType.disambiguation:
          // Adapt 'collectDisambiguationTitles' method signature to conform to PayloadExtractor type.
          return function (_, element) {
            return CollectionUtilities.collectDisambiguationTitles(element);
          };
        default:
          return undefined;
      }
    }
  }]);
  return MenuItem;
}();

/**
 * Makes document fragment for a menu item.
 * @param {!MenuItem} menuItem
 * @param {!Document} document
 * @return {!DocumentFragment}
 */


var documentFragmentForMenuItem = function documentFragmentForMenuItem(menuItem, document) {
  var item = document.createElement('div');
  item.className = 'pagelib_footer_menu_item';

  var containerAnchor = document.createElement('a');
  containerAnchor.addEventListener('click', function () {
    menuItem.clickHandler(menuItem.payload);
  });

  item.appendChild(containerAnchor);

  if (menuItem.title) {
    var title = document.createElement('div');
    title.className = 'pagelib_footer_menu_item_title';
    title.innerText = menuItem.title;
    containerAnchor.title = menuItem.title;
    containerAnchor.appendChild(title);
  }

  if (menuItem.subtitle) {
    var subtitle = document.createElement('div');
    subtitle.className = 'pagelib_footer_menu_item_subtitle';
    subtitle.innerText = menuItem.subtitle;
    containerAnchor.appendChild(subtitle);
  }

  var iconClass = menuItem.iconClass();
  if (iconClass) {
    item.classList.add(iconClass);
  }

  return document.createDocumentFragment().appendChild(item);
};

/**
 * Adds a MenuItem to a container.
 * @param {!MenuItem} menuItem
 * @param {!string} containerID
 * @param {!Document} document
 * @return {void}
 */
var addItem = function addItem(menuItem, containerID, document) {
  document.getElementById(containerID).appendChild(documentFragmentForMenuItem(menuItem, document));
};

/**
 * Conditionally adds a MenuItem to a container.
 * @param {!string} title
 * @param {!string} subtitle
 * @param {!MenuItemType} itemType
 * @param {!string} containerID
 * @param {FooterMenuItemClickCallback} clickHandler
 * @param {!Document} document
 * @return {void}
 */
var maybeAddItem = function maybeAddItem(title, subtitle, itemType, containerID, clickHandler, document) {
  var item = new MenuItem(title, subtitle, itemType, clickHandler);

  // Items are not added if they have a payload extractor which fails to extract anything.
  var extractor = item.payloadExtractor();
  if (extractor) {
    item.payload = extractor(document, document.querySelector('div#content_block_0'));
    if (item.payload.length === 0) {
      return;
    }
  }

  addItem(item, containerID, document);
};

/**
 * Sets heading element string.
 * @param {!string} headingString
 * @param {!string} headingID
 * @param {!Document} document
 * @return {void}
 */
var setHeading = function setHeading(headingString, headingID, document) {
  var headingElement = document.getElementById(headingID);
  headingElement.innerText = headingString;
  headingElement.title = headingString;
};

var FooterMenu = {
  MenuItemType: MenuItemType, // todo: rename to just ItemType?
  setHeading: setHeading,
  maybeAddItem: maybeAddItem
};

/**
 * @typedef {function} SaveButtonClickHandler
 * @param {!string} title
 * @return {void}
 */

/**
 * @typedef {function} TitlesShownHandler
 * @param {!Array.<string>} titles
 * @return {void}
 */

/**
 * Display fetched read more pages.
 * @typedef {function} ShowReadMorePagesHandler
 * @param {!Array.<object>} pages
 * @param {!string} containerID
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */

var SAVE_BUTTON_ID_PREFIX = 'pagelib_footer_read_more_save_';

/**
 * Removes parenthetical enclosures from string.
 * @param {!string} string
 * @param {!string} opener
 * @param {!string} closer
 * @return {!string}
 */
var safelyRemoveEnclosures = function safelyRemoveEnclosures(string, opener, closer) {
  var enclosureRegex = new RegExp('\\s?[' + opener + '][^' + opener + closer + ']+[' + closer + ']', 'g');
  var counter = 0;
  var safeMaxTries = 30;
  var stringToClean = string;
  var previousString = '';
  do {
    previousString = stringToClean;
    stringToClean = stringToClean.replace(enclosureRegex, '');
    counter++;
  } while (previousString !== stringToClean && counter < safeMaxTries);
  return stringToClean;
};

/**
 * Removes '(...)' and '/.../' parenthetical enclosures from string.
 * @param {!string} string
 * @return {!string}
 */
var cleanExtract = function cleanExtract(string) {
  var stringToClean = string;
  stringToClean = safelyRemoveEnclosures(stringToClean, '(', ')');
  stringToClean = safelyRemoveEnclosures(stringToClean, '/', '/');
  return stringToClean;
};

/**
 * Read more page model.
 */

var ReadMorePage =
/**
 * ReadMorePage constructor.
 * @param {!string} title
 * @param {?string} thumbnail
 * @param {?object} terms
 * @param {?string} extract
 * @return {void}
 */
function ReadMorePage(title, thumbnail, terms, extract) {
  classCallCheck(this, ReadMorePage);

  this.title = title;
  this.thumbnail = thumbnail;
  this.terms = terms;
  this.extract = extract;
};

/**
 * Makes document fragment for a read more page.
 * @param {!ReadMorePage} readMorePage
 * @param {!number} index
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!Document} document
 * @return {!DocumentFragment}
 */


var documentFragmentForReadMorePage = function documentFragmentForReadMorePage(readMorePage, index, saveButtonClickHandler, document) {
  var outerAnchorContainer = document.createElement('a');
  outerAnchorContainer.id = index;
  outerAnchorContainer.className = 'pagelib_footer_readmore_page';

  var hasImage = readMorePage.thumbnail && readMorePage.thumbnail.source;
  if (hasImage) {
    var image = document.createElement('div');
    image.style.backgroundImage = 'url(' + readMorePage.thumbnail.source + ')';
    image.classList.add('pagelib_footer_readmore_page_image');
    outerAnchorContainer.appendChild(image);
  }

  var innerDivContainer = document.createElement('div');
  innerDivContainer.classList.add('pagelib_footer_readmore_page_container');
  outerAnchorContainer.appendChild(innerDivContainer);
  outerAnchorContainer.href = '/wiki/' + encodeURI(readMorePage.title);

  if (readMorePage.title) {
    var title = document.createElement('div');
    title.id = index;
    title.className = 'pagelib_footer_readmore_page_title';
    var displayTitle = readMorePage.title.replace(/_/g, ' ');
    title.innerHTML = displayTitle;
    outerAnchorContainer.title = displayTitle;
    innerDivContainer.appendChild(title);
  }

  var description = void 0;
  if (readMorePage.terms) {
    description = readMorePage.terms.description[0];
  }
  if ((!description || description.length < 10) && readMorePage.extract) {
    description = cleanExtract(readMorePage.extract);
  }
  if (description) {
    var descriptionEl = document.createElement('div');
    descriptionEl.id = index;
    descriptionEl.className = 'pagelib_footer_readmore_page_description';
    descriptionEl.innerHTML = description;
    innerDivContainer.appendChild(descriptionEl);
  }

  var saveButton = document.createElement('div');
  saveButton.id = '' + SAVE_BUTTON_ID_PREFIX + encodeURI(readMorePage.title);
  saveButton.className = 'pagelib_footer_readmore_page_save';
  saveButton.addEventListener('click', function (event) {
    event.stopPropagation();
    event.preventDefault();
    saveButtonClickHandler(readMorePage.title);
  });
  innerDivContainer.appendChild(saveButton);

  return document.createDocumentFragment().appendChild(outerAnchorContainer);
};

// eslint-disable-next-line valid-jsdoc
/**
 * @type {ShowReadMorePagesHandler}
 */
var showReadMorePages = function showReadMorePages(pages, containerID, saveButtonClickHandler, titlesShownHandler, document) {
  var shownTitles = [];
  var container = document.getElementById(containerID);
  pages.forEach(function (page, index) {
    var title = page.title.replace(/ /g, '_');
    shownTitles.push(title);
    var pageModel = new ReadMorePage(title, page.thumbnail, page.terms, page.extract);
    var pageFragment = documentFragmentForReadMorePage(pageModel, index, saveButtonClickHandler, document);
    container.appendChild(pageFragment);
  });
  titlesShownHandler(shownTitles);
};

/**
 * Makes 'Read more' query parameters object for a title.
 * @param {!string} title
 * @param {!number} count
 * @return {!object}
 */
var queryParameters = function queryParameters(title, count) {
  return {
    action: 'query',
    format: 'json',
    formatversion: 2,
    prop: 'extracts|pageimages|pageterms',

    // https://www.mediawiki.org/wiki/API:Search
    // https://www.mediawiki.org/wiki/Help:CirrusSearch
    generator: 'search',
    gsrlimit: count, // Limit search results by count.
    gsrprop: 'redirecttitle', // Include a a parsed snippet of the redirect title property.
    gsrsearch: 'morelike:' + title, // Weight search with the title.
    gsrwhat: 'text', // Search the text then titles of pages.

    // https://www.mediawiki.org/wiki/Extension:TextExtracts
    exchars: 256, // Limit number of characters returned.
    exintro: '', // Only content before the first section.
    exlimit: count, // Limit extract results by count.
    explaintext: '', // Strip HTML.

    // https://www.mediawiki.org/wiki/Extension:PageImages
    pilicense: 'any', // Include non-free images.
    pilimit: count, // Limit thumbnail results by count.
    piprop: 'thumbnail', // Include URL and dimensions of thumbnail.
    pithumbsize: 120, // Limit thumbnail dimensions.

    // https://en.wikipedia.org/w/api.php?action=help&modules=query%2Bpageterms
    wbptterms: 'description'
  };
};

/**
 * Converts query parameter object to string.
 * @param {!object} parameters
 * @return {!string}
 */
var stringFromQueryParameters = function stringFromQueryParameters(parameters) {
  return Object.keys(parameters).map(function (key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(parameters[key]);
  }).join('&');
};

/**
 * URL for retrieving 'Read more' pages for a given title.
 * Leave 'baseURL' null if you don't need to deal with proxying.
 * @param {!string} title
 * @param {!number} count Number of `Read more` items to fetch for this title
 * @param {?string} baseURL
 * @return {!sring}
 */
var readMoreQueryURL = function readMoreQueryURL(title, count, baseURL) {
  return (baseURL || '') + '/w/api.php?' + stringFromQueryParameters(queryParameters(title, count));
};

/**
 * Fetch error handler.
 * @param {!string} statusText
 * @return {void}
 */
var fetchErrorHandler = function fetchErrorHandler(statusText) {
  // TODO: figure out if we want to hide the 'Read more' header in cases when fetch fails.
  console.log('statusText = ' + statusText); // eslint-disable-line no-console
};

/**
 * Fetches 'Read more' pages.
 * @param {!string} title
 * @param {!number} count
 * @param {!string} containerID
 * @param {?string} baseURL
 * @param {!ShowReadMorePagesHandler} showReadMorePagesHandler
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */
var fetchReadMore = function fetchReadMore(title, count, containerID, baseURL, showReadMorePagesHandler, saveButtonClickHandler, titlesShownHandler, document) {
  var xhr = new XMLHttpRequest(); // eslint-disable-line no-undef
  xhr.open('GET', readMoreQueryURL(title, count, baseURL), true);
  xhr.onload = function () {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      // eslint-disable-line no-undef
      if (xhr.status === 200) {
        showReadMorePagesHandler(JSON.parse(xhr.responseText).query.pages, containerID, saveButtonClickHandler, titlesShownHandler, document);
      } else {
        fetchErrorHandler(xhr.statusText);
      }
    }
  };
  xhr.onerror = function () {
    return fetchErrorHandler(xhr.statusText);
  };
  try {
    xhr.send();
  } catch (error) {
    fetchErrorHandler(error.toString());
  }
};

/**
 * Updates save button bookmark icon for saved state.
 * @param {!HTMLDivElement} button
 * @param {!boolean} isSaved
 * @return {void}
 */
var updateSaveButtonBookmarkIcon = function updateSaveButtonBookmarkIcon(button, isSaved) {
  var unfilledClass = 'pagelib_footer_readmore_bookmark_unfilled';
  var filledClass = 'pagelib_footer_readmore_bookmark_filled';
  button.classList.remove(filledClass, unfilledClass);
  button.classList.add(isSaved ? filledClass : unfilledClass);
};

/**
 * Updates save button text and bookmark icon for saved state.
 * Safe to call even for titles for which there is not currently a 'Read more' item.
 * @param {!string} title
 * @param {!string} text
 * @param {!boolean} isSaved
 * @param {!Document} document
 * @return {void}
*/
var updateSaveButtonForTitle = function updateSaveButtonForTitle(title, text, isSaved, document) {
  var saveButton = document.getElementById('' + SAVE_BUTTON_ID_PREFIX + encodeURI(title));
  if (!saveButton) {
    return;
  }
  saveButton.innerText = text;
  saveButton.title = text;
  updateSaveButtonBookmarkIcon(saveButton, isSaved);
};

/**
 * Adds 'Read more' for 'title' to 'containerID' element.
 * Leave 'baseURL' null if you don't need to deal with proxying.
 * @param {!string} title
 * @param {!number} count
 * @param {!string} containerID
 * @param {?string} baseURL
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */
var add$1 = function add(title, count, containerID, baseURL, saveButtonClickHandler, titlesShownHandler, document) {
  fetchReadMore(title, count, containerID, baseURL, showReadMorePages, saveButtonClickHandler, titlesShownHandler, document);
};

/**
 * Sets heading element string.
 * @param {!string} headingString
 * @param {!string} headingID
 * @param {!Document} document
 * @return {void}
 */
var setHeading$1 = function setHeading(headingString, headingID, document) {
  var headingElement = document.getElementById(headingID);
  headingElement.innerText = headingString;
  headingElement.title = headingString;
};

var FooterReadMore = {
  add: add$1,
  setHeading: setHeading$1,
  updateSaveButtonForTitle: updateSaveButtonForTitle,
  test: {
    cleanExtract: cleanExtract,
    safelyRemoveEnclosures: safelyRemoveEnclosures
  }
};

/** Function rate limiter. */
var Throttle = function () {
  createClass(Throttle, null, [{
    key: "wrap",

    /**
     * Wraps a function in a Throttle.
     * @param {!Window} window
     * @param {!number} period The nonnegative minimum number of milliseconds between function
     *                         invocations.
     * @param {!function} funktion The function to invoke when not throttled.
     * @return {!function} A function wrapped in a Throttle.
     */
    value: function wrap(window, period, funktion) {
      var throttle = new Throttle(window, period, funktion);
      var throttled = function Throttled() {
        return throttle.queue(this, arguments);
      };
      throttled.result = function () {
        return throttle.result;
      };
      throttled.pending = function () {
        return throttle.pending();
      };
      throttled.delay = function () {
        return throttle.delay();
      };
      throttled.cancel = function () {
        return throttle.cancel();
      };
      throttled.reset = function () {
        return throttle.reset();
      };
      return throttled;
    }

    /**
     * @param {!Window} window
     * @param {!number} period The nonnegative minimum number of milliseconds between function
     *                         invocations.
     * @param {!function} funktion The function to invoke when not throttled.
     */

  }]);

  function Throttle(window, period, funktion) {
    classCallCheck(this, Throttle);

    this._window = window;
    this._period = period;
    this._function = funktion;

    // The upcoming invocation's context and arguments.
    this._context = undefined;
    this._arguments = undefined;

    // The previous invocation's result, timeout identifier, and last run timestamp.
    this._result = undefined;
    this._timeout = 0;
    this._timestamp = 0;
  }

  /**
   * The return value of the initial run is always undefined. The return value of subsequent runs is
   * always a previous result. The context and args used by a future invocation are always the most
   * recently supplied. Invocations, even if immediately eligible, are dispatched.
   * @param {?any} context
   * @param {?any} args The arguments passed to the underlying function.
   * @return {?any} The cached return value of the underlying function.
   */


  createClass(Throttle, [{
    key: "queue",
    value: function queue(context, args) {
      var _this = this;

      // Always update the this and arguments to the latest supplied.
      this._context = context;
      this._arguments = args;

      if (!this.pending()) {
        // Queue a new invocation.
        this._timeout = this._window.setTimeout(function () {
          _this._timeout = 0;
          _this._timestamp = Date.now();
          _this._result = _this._function.apply(_this._context, _this._arguments);
        }, this.delay());
      }

      // Always return the previous result.
      return this.result;
    }

    /** @return {?any} The cached return value of the underlying function. */

  }, {
    key: "pending",


    /** @return {!boolean} true if an invocation is queued. */
    value: function pending() {
      return Boolean(this._timeout);
    }

    /**
     * @return {!number} The nonnegative number of milliseconds until an invocation is eligible to
     *                   run.
     */

  }, {
    key: "delay",
    value: function delay() {
      if (!this._timestamp) {
        return 0;
      }
      return Math.max(0, this._period - (Date.now() - this._timestamp));
    }

    /**
     * Clears any pending invocation but doesn't clear time last invoked or prior result.
     * @return {void}
     */

  }, {
    key: "cancel",
    value: function cancel() {
      if (this._timeout) {
        this._window.clearTimeout(this._timeout);
      }
      this._timeout = 0;
    }

    /**
     * Clears any pending invocation, time last invoked, and prior result.
     * @return {void}
     */

  }, {
    key: "reset",
    value: function reset() {
      this.cancel();
      this._result = undefined;
      this._timestamp = 0;
    }
  }, {
    key: "result",
    get: function get$$1() {
      return this._result;
    }
  }]);
  return Throttle;
}();

var RESIZE_EVENT_TYPE = 'resize';
var RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS = 100;

var ID_CONTAINER = 'pagelib_footer_container';
var ID_LEGAL_CONTAINER = 'pagelib_footer_container_legal';

var ID_READ_MORE_CONTAINER = 'pagelib_footer_container_readmore_pages';
var ID_READ_MORE_HEADER = 'pagelib_footer_container_readmore_heading';

/** */

var _class = function () {
  /** */
  function _class() {
    classCallCheck(this, _class);

    this._resizeListener = undefined;
  }

  /**
   * @param {!Window} window
   * @param {!Element} container
   * @param {!string} baseURL
   * @param {!string} title
   * @param {!string} readMoreHeader
   * @param {!number} readMoreLimit
   * @param {!string} license
   * @param {!string} licenseSubstitutionString
   * @param {!FooterLegalClickCallback} licenseLinkClickHandler
   * @param {!string} viewInBrowserString
   * @param {!FooterBrowserClickCallback} browserLinkClickHandler
   * @param {!TitlesShownHandler} titlesShownHandler
   * @param {!SaveButtonClickHandler} saveButtonClickHandler
   * @return {void}
   */


  createClass(_class, [{
    key: 'add',
    value: function add(window, container, baseURL, title, readMoreHeader, readMoreLimit, license, licenseSubstitutionString, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler, titlesShownHandler, saveButtonClickHandler) {
      this.remove(window);
      container.appendChild(FooterContainer.containerFragment(window.document));

      FooterLegal.add(window.document, license, licenseSubstitutionString, ID_LEGAL_CONTAINER, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler);

      FooterReadMore.setHeading(readMoreHeader, ID_READ_MORE_HEADER, window.document);
      FooterReadMore.add(title, readMoreLimit, ID_READ_MORE_CONTAINER, baseURL, saveButtonClickHandler, function (titles) {
        FooterContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
        titlesShownHandler(titles);
      }, window.document);

      this._resizeListener = Throttle.wrap(window, RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS, function () {
        return FooterContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
      });
      window.addEventListener(RESIZE_EVENT_TYPE, this._resizeListener);
    }

    /**
     * @param {!Window} window
     * @return {void}
     */

  }, {
    key: 'remove',
    value: function remove(window) {
      if (this._resizeListener) {
        window.removeEventListener(RESIZE_EVENT_TYPE, this._resizeListener);
        this._resizeListener.cancel();
        this._resizeListener = undefined;
      }

      var footer = window.document.getElementById(ID_CONTAINER);
      if (footer) {
        // todo: support recycling.
        footer.parentNode.removeChild(footer);
      }
    }
  }]);
  return _class;
}();

// CSS classes used to identify and present lazily loaded images. Placeholders are members of
// PLACEHOLDER_CLASS and one state class: pending, loading, or error. Images are members of either
// loading or loaded state classes. Class names should match those in LazyLoadTransform.css.
var PLACEHOLDER_CLASS = 'pagelib_lazy_load_placeholder';
var PLACEHOLDER_PENDING_CLASS = 'pagelib_lazy_load_placeholder_pending'; // Download pending.
var PLACEHOLDER_LOADING_CLASS = 'pagelib_lazy_load_placeholder_loading'; // Download started.
var PLACEHOLDER_ERROR_CLASS = 'pagelib_lazy_load_placeholder_error'; // Download failure.
var IMAGE_LOADING_CLASS = 'pagelib_lazy_load_image_loading'; // Download started.
var IMAGE_LOADED_CLASS = 'pagelib_lazy_load_image_loaded'; // Download completed.

// Attributes copied from images to placeholders via data-* attributes for later restoration. The
// image's classes and dimensions are also set on the placeholder.
// The 3 data-* items are used by iOS.
var COPY_ATTRIBUTES = ['class', 'style', 'src', 'srcset', 'width', 'height', 'alt', 'usemap', 'data-file-width', 'data-file-height', 'data-image-gallery'];

// Small images, especially icons, are quickly downloaded and may appear in many places. Lazily
// loading these images degrades the experience with little gain. Always eagerly load these images.
// Example: flags in the medal count for the "1896 Summer Olympics medal table."
// https://en.m.wikipedia.org/wiki/1896_Summer_Olympics_medal_table?oldid=773498394#Medal_count
var UNIT_TO_MINIMUM_LAZY_LOAD_SIZE = {
  px: 50, // https://phabricator.wikimedia.org/diffusion/EMFR/browse/master/includes/MobileFormatter.php;c89f371ea9e789d7e1a827ddfec7c8028a549c12$22
  ex: 10, // ''
  em: 5 // 1ex ≈ .5em; https://developer.mozilla.org/en-US/docs/Web/CSS/length#Units


  /**
   * Replace an image with a placeholder.
   * @param {!Document} document
   * @param {!HTMLImageElement} image The image to be replaced.
   * @return {!HTMLSpanElement} The placeholder replacing image.
   */
};var convertImageToPlaceholder = function convertImageToPlaceholder(document, image) {
  // There are a number of possible implementations for placeholders including:
  //
  // - [MobileFrontend] Replace the original image with a span and replace the span with a new
  //   downloaded image.
  //   This option has a good fade-in but has some CSS concerns for the placeholder, particularly
  //   `max-width`, and causes significant reflows when used with image widening.
  //
  // - [Previous] Replace the original image with a span and append a new downloaded image to the
  //   span.
  //   This option has the best cross-fading and extensibility but makes duplicating all the CSS
  //   rules for the appended image impractical.
  //
  // - [Previous] Replace the original image's source with a transparent image and update the source
  //   from a new downloaded image.
  //   This option has a good fade-in and minimal CSS concerns for the placeholder and image but
  //   causes significant reflows when used with image widening.
  //
  // - [Current] Replace the original image with a couple spans and replace the spans with a new
  //   downloaded image.
  //   This option is about the same as MobileFrontend but supports image widening without reflows.

  // Create the root placeholder.
  var placeholder = document.createElement('span');

  // Copy the image's classes and append the placeholder and current state (pending) classes.
  if (image.hasAttribute('class')) {
    placeholder.setAttribute('class', image.getAttribute('class'));
  }
  placeholder.classList.add(PLACEHOLDER_CLASS);
  placeholder.classList.add(PLACEHOLDER_PENDING_CLASS);

  // Match the image's width, if specified. If image widening is used, this width will be overridden
  // by !important priority.
  var geometry = ElementGeometry.from(image);
  if (geometry.width) {
    placeholder.style.setProperty('width', '' + geometry.width);
  }

  // Save the image's attributes to data-* attributes for later restoration.
  elementUtilities.copyAttributesToDataAttributes(image, placeholder, COPY_ATTRIBUTES);

  // Create a spacer and match the aspect ratio of the original image, if determinable. If image
  // widening is used, this spacer will scale with the width proportionally.
  var spacing = document.createElement('span');
  if (geometry.width && geometry.height) {
    // Assume units are identical.
    var ratio = geometry.heightValue / geometry.widthValue;
    spacing.style.setProperty('padding-top', ratio * 100 + '%');
  }

  // Append the spacer to the placeholder and replace the image with the placeholder.
  placeholder.appendChild(spacing);
  image.parentNode.replaceChild(placeholder, image);

  return placeholder;
};

/**
 * @param {!HTMLImageElement} image The image to be considered.
 * @return {!boolean} true if image download can be deferred, false if image should be eagerly
 *                    loaded.
 */
var isLazyLoadable = function isLazyLoadable(image) {
  var geometry = ElementGeometry.from(image);
  if (!geometry.width || !geometry.height) {
    return true;
  }
  return geometry.widthValue >= UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.widthUnit] && geometry.heightValue >= UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.heightUnit];
};

/**
 * @param {!Element} element
 * @return {!Array.<HTMLImageElement>} Convertible images descendent from but not including element.
 */
var queryLazyLoadableImages = function queryLazyLoadableImages(element) {
  return Polyfill.querySelectorAll(element, 'img').filter(function (image) {
    return isLazyLoadable(image);
  });
};

/**
 * Convert images with placeholders. The transformation is inverted by calling loadImage().
 * @param {!Document} document
 * @param {!Array.<HTMLImageElement>} images The images to lazily load.
 * @return {!Array.<HTMLSpanElement>} The placeholders replacing images.
 */
var convertImagesToPlaceholders = function convertImagesToPlaceholders(document, images) {
  return images.map(function (image) {
    return convertImageToPlaceholder(document, image);
  });
};

/**
 * Start downloading image resources associated with a given placeholder and replace the placeholder
 * with a new image element when the download is complete.
 * @param {!Document} document
 * @param {!HTMLSpanElement} placeholder
 * @return {!HTMLImageElement} A new image element.
 */
var loadPlaceholder = function loadPlaceholder(document, placeholder) {
  placeholder.classList.add(PLACEHOLDER_LOADING_CLASS);
  placeholder.classList.remove(PLACEHOLDER_PENDING_CLASS);

  var image = document.createElement('img');

  var retryListener = function retryListener(event) {
    // eslint-disable-line require-jsdoc
    image.setAttribute('src', image.getAttribute('src'));
    event.stopPropagation();
    event.preventDefault();
  };

  // Add the download listener prior to setting the src attribute to avoid missing the load event.
  image.addEventListener('load', function () {
    placeholder.removeEventListener('click', retryListener);
    placeholder.parentNode.replaceChild(image, placeholder);
    image.classList.add(IMAGE_LOADED_CLASS);
    image.classList.remove(IMAGE_LOADING_CLASS);
  }, { once: true });

  image.addEventListener('error', function () {
    placeholder.classList.add(PLACEHOLDER_ERROR_CLASS);
    placeholder.classList.remove(PLACEHOLDER_LOADING_CLASS);
    placeholder.addEventListener('click', retryListener);
  }, { once: true });

  // Set src and other attributes, triggering a download.
  elementUtilities.copyDataAttributesToAttributes(placeholder, image, COPY_ATTRIBUTES);

  // Append to the class list after copying over any preexisting classes.
  image.classList.add(IMAGE_LOADING_CLASS);

  return image;
};

var LazyLoadTransform = {
  queryLazyLoadableImages: queryLazyLoadableImages,
  convertImagesToPlaceholders: convertImagesToPlaceholders,
  loadPlaceholder: loadPlaceholder
};

var EVENT_TYPES = ['scroll', 'resize', CollapseTable.SECTION_TOGGLED_EVENT_TYPE];
var THROTTLE_PERIOD_MILLISECONDS = 100;

/**
 * This class subscribes to key page events, applying lazy load transforms or inversions as
 * applicable. It has external dependencies on the section-toggled custom event and the following
 * standard browser events: resize, scroll.
 */

var _class$1 = function () {
  /**
   * @param {!Window} window
   * @param {!number} loadDistanceMultiplier Images within this multiple of the screen height are
   *                                         loaded in either direction.
   */
  function _class(window, loadDistanceMultiplier) {
    var _this = this;

    classCallCheck(this, _class);

    this._window = window;
    this._loadDistanceMultiplier = loadDistanceMultiplier;

    this._placeholders = [];
    this._registered = false;
    this._throttledLoadPlaceholders = Throttle.wrap(window, THROTTLE_PERIOD_MILLISECONDS, function () {
      return _this._loadPlaceholders();
    });
  }

  /**
   * Convert images with placeholders. Calling this function may register this instance to listen to
   * page events.
   * @param {!Element} element
   * @return {void}
   */


  createClass(_class, [{
    key: 'convertImagesToPlaceholders',
    value: function convertImagesToPlaceholders(element) {
      var images = LazyLoadTransform.queryLazyLoadableImages(element);
      var placeholders = LazyLoadTransform.convertImagesToPlaceholders(this._window.document, images);
      this._placeholders = this._placeholders.concat(placeholders);
      this._register();
    }

    /**
     * Manually trigger a load images check. Calling this function may deregister this instance from
     * listening to page events.
     * @return {void}
     */

  }, {
    key: 'loadPlaceholders',
    value: function loadPlaceholders() {
      this._throttledLoadPlaceholders();
    }

    /**
     * This method may be safely called even when already unregistered. This function clears the
     * record of placeholders.
     * @return {void}
     */

  }, {
    key: 'deregister',
    value: function deregister() {
      var _this2 = this;

      if (!this._registered) {
        return;
      }

      EVENT_TYPES.forEach(function (eventType) {
        return _this2._window.removeEventListener(eventType, _this2._throttledLoadPlaceholders);
      });
      this._throttledLoadPlaceholders.reset();

      this._placeholders = [];
      this._registered = false;
    }

    /**
     * This method may be safely called even when already registered.
     * @return {void}
     */

  }, {
    key: '_register',
    value: function _register() {
      var _this3 = this;

      if (this._registered || !this._placeholders.length) {
        return;
      }
      this._registered = true;

      EVENT_TYPES.forEach(function (eventType) {
        return _this3._window.addEventListener(eventType, _this3._throttledLoadPlaceholders);
      });
    }

    /** @return {void} */

  }, {
    key: '_loadPlaceholders',
    value: function _loadPlaceholders() {
      var _this4 = this;

      this._placeholders = this._placeholders.filter(function (placeholder) {
        var pending = true;
        if (_this4._isPlaceholderEligibleToLoad(placeholder)) {
          LazyLoadTransform.loadPlaceholder(_this4._window.document, placeholder);
          pending = false;
        }
        return pending;
      });

      if (this._placeholders.length === 0) {
        this.deregister();
      }
    }

    /**
     * @param {!HTMLSpanElement} placeholder
     * @return {!boolean}
     */

  }, {
    key: '_isPlaceholderEligibleToLoad',
    value: function _isPlaceholderEligibleToLoad(placeholder) {
      return elementUtilities.isVisible(placeholder) && this._isPlaceholderWithinLoadDistance(placeholder);
    }

    /**
     * @param {!HTMLSpanElement} placeholder
     * @return {!boolean}
     */

  }, {
    key: '_isPlaceholderWithinLoadDistance',
    value: function _isPlaceholderWithinLoadDistance(placeholder) {
      var bounds = placeholder.getBoundingClientRect();
      var range = this._window.innerHeight * this._loadDistanceMultiplier;
      return !(bounds.top > range || bounds.bottom < -range);
    }
  }]);
  return _class;
}();

var CLASS$2 = { ANDROID: 'pagelib_platform_android', IOS: 'pagelib_platform_ios'

  // Regular expressions from https://phabricator.wikimedia.org/diffusion/EMFR/browse/master/resources/mobile.startup/browser.js;c89f371ea9e789d7e1a827ddfec7c8028a549c12.
  /**
   * @param {!Window} window
   * @return {!boolean} true if the user agent is Android, false otherwise.
   */
};var isAndroid = function isAndroid(window) {
  return (/android/i.test(window.navigator.userAgent)
  );
};

/**
 * @param {!Window} window
 * @return {!boolean} true if the user agent is iOS, false otherwise.
 */
var isIOs = function isIOs(window) {
  return (/ipad|iphone|ipod/i.test(window.navigator.userAgent)
  );
};

/**
 * @param {!Window} window
 * @return {void}
 */
var classify = function classify(window) {
  var html = window.document.querySelector('html');
  if (isAndroid(window)) {
    html.classList.add(CLASS$2.ANDROID);
  }
  if (isIOs(window)) {
    html.classList.add(CLASS$2.IOS);
  }
};

var PlatformTransform = {
  CLASS: CLASS$2,
  classify: classify
};

/**
 * Configures span to be suitable replacement for red link anchor.
 * @param {!HTMLSpanElement} span The span element to configure as anchor replacement.
 * @param {!HTMLAnchorElement} anchor The anchor element being replaced.
 * @return {void}
 */
var configureRedLinkTemplate = function configureRedLinkTemplate(span, anchor) {
  span.innerHTML = anchor.innerHTML;
  span.setAttribute('class', anchor.getAttribute('class'));
};

/**
 * Finds red links in a document.
 * @param {!Document} content Document in which to seek red links.
 * @return {!Array.<HTMLAnchorElement>} Array of zero or more red link anchors.
 */
var redLinkAnchorsInDocument = function redLinkAnchorsInDocument(content) {
  return Polyfill.querySelectorAll(content, 'a.new');
};

/**
 * Makes span to be used as cloning template for red link anchor replacements.
 * @param  {!Document} document Document to use to create span element.
 * @return {!HTMLSpanElement} Span element suitable for use as template for red link anchor
 * replacements.
 */
var newRedLinkTemplate = function newRedLinkTemplate(document) {
  return document.createElement('span');
};

/**
 * Replaces anchor with span.
 * @param  {!HTMLAnchorElement} anchor Anchor element.
 * @param  {!HTMLSpanElement} span Span element.
 * @return {void}
 */
var replaceAnchorWithSpan = function replaceAnchorWithSpan(anchor, span) {
  return anchor.parentNode.replaceChild(span, anchor);
};

/**
 * Hides red link anchors in a document so they are unclickable and unfocusable.
 * @param {!Document} document Document in which to hide red links.
 * @return {void}
 */
var hideRedLinks = function hideRedLinks(document) {
  var spanTemplate = newRedLinkTemplate(document);
  redLinkAnchorsInDocument(document).forEach(function (redLink) {
    var span = spanTemplate.cloneNode(false);
    configureRedLinkTemplate(span, redLink);
    replaceAnchorWithSpan(redLink, span);
  });
};

var RedLinks = {
  hideRedLinks: hideRedLinks,
  test: {
    configureRedLinkTemplate: configureRedLinkTemplate,
    redLinkAnchorsInDocument: redLinkAnchorsInDocument,
    newRedLinkTemplate: newRedLinkTemplate,
    replaceAnchorWithSpan: replaceAnchorWithSpan
  }
};

/**
 * Gets array of ancestors of element which need widening.
 * @param  {!HTMLElement} element
 * @return {!Array.<HTMLElement>} Zero length array is returned if no elements should be widened.
 */
var ancestorsToWiden = function ancestorsToWiden(element) {
  var widenThese = [];
  var el = element;
  while (el.parentElement) {
    el = el.parentElement;
    // No need to walk above 'content_block'.
    if (el.classList.contains('content_block')) {
      break;
    }
    widenThese.push(el);
  }
  return widenThese;
};

/**
 * Sets style value.
 * @param {!CSSStyleDeclaration} style
 * @param {!string} key
 * @param {*} value
 * @return {void}
 */
var updateStyleValue = function updateStyleValue(style, key, value) {
  style[key] = value;
};

/**
 * Sets style value only if value for given key already exists.
 * @param {CSSStyleDeclaration} style
 * @param {!string} key
 * @param {*} value
 * @return {void}
 */
var updateExistingStyleValue = function updateExistingStyleValue(style, key, value) {
  var valueExists = Boolean(style[key]);
  if (valueExists) {
    updateStyleValue(style, key, value);
  }
};

/**
 * Image widening CSS key/value pairs.
 * @type {Object}
 */
var styleWideningKeysAndValues = {
  width: '100%',
  height: 'auto',
  maxWidth: '100%',
  float: 'none'

  /**
   * Perform widening on an element. Certain style properties are updated, but only if existing values
   * for these properties already exist.
   * @param  {!HTMLElement} element
   * @return {void}
   */
};var widenElementByUpdatingExistingStyles = function widenElementByUpdatingExistingStyles(element) {
  Object.keys(styleWideningKeysAndValues).forEach(function (key) {
    return updateExistingStyleValue(element.style, key, styleWideningKeysAndValues[key]);
  });
};

/**
 * Perform widening on an element.
 * @param  {!HTMLElement} element
 * @return {void}
 */
var widenElementByUpdatingStyles = function widenElementByUpdatingStyles(element) {
  Object.keys(styleWideningKeysAndValues).forEach(function (key) {
    return updateStyleValue(element.style, key, styleWideningKeysAndValues[key]);
  });
};

/**
 * To widen an image element a css class called 'pagelib_widen_image_override' is applied to the
 * image element, however, ancestors of the image element can prevent the widening from taking
 * effect. This method makes minimal adjustments to ancestors of the image element being widened so
 * the image widening can take effect.
 * @param  {!HTMLElement} element Element whose ancestors will be widened
 * @return {void}
 */
var widenAncestors = function widenAncestors(element) {
  ancestorsToWiden(element).forEach(widenElementByUpdatingExistingStyles);

  // Without forcing widening on the parent anchor, lazy image loading placeholders
  // aren't correctly widened on iOS for some reason.
  var parentAnchor = elementUtilities.findClosestAncestor(element, 'a.image');
  if (parentAnchor) {
    widenElementByUpdatingStyles(parentAnchor);
  }
};

/**
 * Some images should not be widened. This method makes that determination.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether 'image' should be widened
 */
var shouldWidenImage = function shouldWidenImage(image) {
  // Images within a "<div class='noresize'>...</div>" should not be widened.
  // Example exhibiting links overlaying such an image:
  //   'enwiki > Counties of England > Scope and structure > Local government'
  if (elementUtilities.findClosestAncestor(image, "[class*='noresize']")) {
    return false;
  }

  // Side-by-side images should not be widened. Often their captions mention 'left' and 'right', so
  // we don't want to widen these as doing so would stack them vertically.
  // Examples exhibiting side-by-side images:
  //    'enwiki > Cold Comfort (Inside No. 9) > Casting'
  //    'enwiki > Vincent van Gogh > Letters'
  if (elementUtilities.findClosestAncestor(image, "div[class*='tsingle']")) {
    return false;
  }

  // Imagemaps, which expect images to be specific sizes, should not be widened.
  // Examples can be found on 'enwiki > Kingdom (biology)':
  //    - first non lead image is an image map
  //    - 'Three domains of life > Phylogenetic Tree of Life' image is an image map
  if (image.hasAttribute('usemap')) {
    return false;
  }

  // Images in tables should not be widened - doing so can horribly mess up table layout.
  if (elementUtilities.isNestedInTable(image)) {
    return false;
  }

  return true;
};

/**
 * Widens the image.
 * @param  {!HTMLElement} image   The image in question
 * @return {void}
 */
var widenImage = function widenImage(image) {
  widenAncestors(image);
  image.classList.add('pagelib_widen_image_override');
};

/**
 * Widens an image if the image is found to be fit for widening.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether or not 'image' was widened
 */
var maybeWidenImage = function maybeWidenImage(image) {
  if (shouldWidenImage(image)) {
    widenImage(image);
    return true;
  }
  return false;
};

var WidenImage = {
  maybeWidenImage: maybeWidenImage,
  test: {
    ancestorsToWiden: ancestorsToWiden,
    shouldWidenImage: shouldWidenImage,
    updateExistingStyleValue: updateExistingStyleValue,
    widenAncestors: widenAncestors,
    widenElementByUpdatingExistingStyles: widenElementByUpdatingExistingStyles,
    widenElementByUpdatingStyles: widenElementByUpdatingStyles
  }
};

/* eslint-disable sort-imports */

// We want the theme transform to be first. This is because the theme transform CSS has to use
// some '!important' CSS modifiers to reliably set themes on elements which may contain inline
// styles. Moving it to the top of the file is necessary so other transforms can override
// these '!important' themes transform CSS bits if needed. Note - if other transforms have trouble
// overriding things changed by theme transform remember to match or exceed the selector specificity
// used by the theme transform for whatever it is you are trying to override.
var pagelib$1 = {
  // todo: rename CollapseTableTransform.
  CollapseTable: CollapseTable,
  CollectionUtilities: CollectionUtilities,
  CompatibilityTransform: CompatibilityTransform,
  DimImagesTransform: DimImagesTransform,
  EditTransform: EditTransform,
  // todo: rename Footer.ContainerTransform, Footer.LegalTransform, Footer.MenuTransform,
  //       Footer.ReadMoreTransform.
  LeadIntroductionTransform: LeadIntroductionTransform,
  FooterContainer: FooterContainer,
  FooterLegal: FooterLegal,
  FooterMenu: FooterMenu,
  FooterReadMore: FooterReadMore,
  FooterTransformer: _class,
  LazyLoadTransform: LazyLoadTransform,
  LazyLoadTransformer: _class$1,
  PlatformTransform: PlatformTransform,
  // todo: rename RedLinkTransform.
  RedLinks: RedLinks,
  ThemeTransform: ThemeTransform,
  // todo: rename WidenImageTransform.
  WidenImage: WidenImage,
  test: {
    ElementGeometry: ElementGeometry,
    ElementUtilities: elementUtilities,
    Polyfill: Polyfill,
    Throttle: Throttle
  }
};

// This file exists for CSS packaging only. It imports the override CSS
// JavaScript index file, which also exists only for packaging, as well as the
// real JavaScript, transform/index, it simply re-exports.

return pagelib$1;

})));


},{}],3:[function(require,module,exports){
const wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.utilities = require('./js/utilities')
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform

window.wmf = wmf
},{"./js/utilities":1,"wikimedia-page-library":2}]},{},[3,1]);
