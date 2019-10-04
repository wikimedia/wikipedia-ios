(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["pagelib"] = factory();
	else
		root["pagelib"] = factory();
})(this, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = "./src/transform/index.js");
/******/ })
/************************************************************************/
/******/ ({

/***/ "./src/transform/BodySpacingTransform.ts":
/*!***********************************************!*\
  !*** ./src/transform/BodySpacingTransform.ts ***!
  \***********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Sets the margins on an element via inline styles.
 * @param {!HTMLBodyElement} bodyElement the element that needs the margins adjusted.
 *   For the apps this is usually the body element.
 * @param {Spacing} values { top, right, bottom, left }
 *   Use value strings with units, e.g. '16px'. Undefined values are ignored.
 * @param callback callback function
 * @return {void}
 */
var setMargins = function (bodyElement, values, callback) {
    if (values.top !== undefined) {
        bodyElement.style.marginTop = values.top;
    }
    if (values.right !== undefined) {
        bodyElement.style.marginRight = values.right;
    }
    if (values.bottom !== undefined) {
        bodyElement.style.marginBottom = values.bottom;
    }
    if (values.left !== undefined) {
        bodyElement.style.marginLeft = values.left;
    }
    if (callback) {
        callback();
    }
};
/**
 * Sets padding on an element via inline styles.
 * @param {!HTMLBodyElement} bodyElement the element that needs the padding adjusted.
 *   For the apps this is usually the body element.
 * @param {Spacing} values { top, right, bottom, left }
 *   Use value strings with units, e.g. '16px'. Undefined values are ignored.
 * @param callback callback function
 * @return {void}
 */
var setPadding = function (bodyElement, values, callback) {
    if (values.top !== undefined) {
        bodyElement.style.paddingTop = values.top;
    }
    if (values.right !== undefined) {
        bodyElement.style.paddingRight = values.right;
    }
    if (values.bottom !== undefined) {
        bodyElement.style.paddingBottom = values.bottom;
    }
    if (values.left !== undefined) {
        bodyElement.style.paddingLeft = values.left;
    }
    if (callback) {
        callback();
    }
};
exports.default = {
    setMargins: setMargins,
    setPadding: setPadding
};


/***/ }),

/***/ "./src/transform/CollapseTable.css":
/*!*****************************************!*\
  !*** ./src/transform/CollapseTable.css ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/CollapseTable.js":
/*!****************************************!*\
  !*** ./src/transform/CollapseTable.js ***!
  \****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./CollapseTable.css */ "./src/transform/CollapseTable.css");

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

var _NodeUtilities = __webpack_require__(/*! ./NodeUtilities */ "./src/transform/NodeUtilities.js");

var _NodeUtilities2 = _interopRequireDefault(_NodeUtilities);

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var NODE_TYPE = _NodeUtilities2.default.NODE_TYPE;

var SECTION_TOGGLED_EVENT_TYPE = 'section-toggled';
var BREAKING_SPACE = ' ';
var CLASS = {
  ICON: 'pagelib_collapse_table_icon',
  CONTAINER: 'pagelib_collapse_table_container',
  COLLAPSED_CONTAINER: 'pagelib_collapse_table_collapsed_container',
  COLLAPSED: 'pagelib_collapse_table_collapsed',
  COLLAPSED_BOTTOM: 'pagelib_collapse_table_collapsed_bottom',
  COLLAPSE_TEXT: 'pagelib_collapse_table_collapse_text',
  EXPANDED: 'pagelib_collapse_table_expanded'

  /**
   * Determine if we want to extract text from this header.
   * @param {!Element} header
   * @return {!boolean}
   */
};var isHeaderEligible = function isHeaderEligible(header) {
  return header.childNodes && _Polyfill2.default.querySelectorAll(header, 'a').length < 3;
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
  return node.nodeType === NODE_TYPE.ELEMENT_NODE && node.tagName === 'BR';
};

/**
 * Replace node with a text node bearing a single breaking space.
 * @param {!Document} document
 * @param  {!Node} node
 * @return {void}
 */
var replaceNodeWithBreakingSpaceTextNode = function replaceNodeWithBreakingSpaceTextNode(document, node) {
  node.parentNode.replaceChild(document.createTextNode(BREAKING_SPACE), node);
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

  _Polyfill2.default.querySelectorAll(fragmentHeader, '.geo, .coordinates, sup.reference, ol, ul').forEach(function (el) {
    return el.remove();
  });

  var childNodesArray = Array.prototype.slice.call(fragmentHeader.childNodes);
  if (pageTitle) {
    childNodesArray.filter(_NodeUtilities2.default.isNodeTypeElementOrText).filter(function (node) {
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
 * @return {!number}
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
  var headers = _Polyfill2.default.querySelectorAll(element, 'th');
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
    header.classList.remove(CLASS.COLLAPSED);
    header.classList.remove(CLASS.ICON);
    header.classList.add(CLASS.EXPANDED);
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
    header.classList.remove(CLASS.EXPANDED);
    header.classList.add(CLASS.COLLAPSED);
    header.classList.add(CLASS.ICON);
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
  return element.classList.contains('infobox') || element.classList.contains('infobox_v3');
};

/**
 * @param {!Document} document
 * @param {!DocumentFragment} content
 * @return {!HTMLDivElement}
 */
var newCollapsedHeaderDiv = function newCollapsedHeaderDiv(document, content) {
  var div = document.createElement('div');
  div.classList.add(CLASS.COLLAPSED_CONTAINER);
  div.classList.add(CLASS.EXPANDED);
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
  div.classList.add(CLASS.COLLAPSED_BOTTOM);
  div.classList.add(CLASS.ICON);
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
  span.classList.add(CLASS.COLLAPSE_TEXT);
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
 * @param {!Document} document
 * @param {?string} pageTitle use title for this not `display title` (which can contain tags)
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @return {void}
 */
var prepareTables = function prepareTables(document, pageTitle, infoboxTitle, otherTitle, footerTitle) {
  var tables = document.querySelectorAll('table, .infobox_v3');
  for (var i = 0; i < tables.length; ++i) {
    var table = tables[i];

    if (_ElementUtilities2.default.findClosestAncestor(table, '.' + CLASS.CONTAINER) || !shouldTableBeCollapsed(table)) {
      continue;
    }

    var headerTextArray = getTableHeaderTextArray(document, table, pageTitle);
    if (!headerTextArray.length && !isInfobox(table)) {
      continue;
    }
    var captionFragment = newCaptionFragment(document, isInfobox(table) ? infoboxTitle : otherTitle, headerTextArray);

    // create the container div that will contain both the original table
    // and the collapsed version.
    var containerDiv = document.createElement('div');
    containerDiv.className = CLASS.CONTAINER;
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
  }
};

/**
 * @param {!Window} window
 * @param {!Element} container root element to search from
 * @param {?boolean} isInitiallyCollapsed
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {void}
 */
var setupEventHandling = function setupEventHandling(window, container, isInitiallyCollapsed, footerDivClickCallback) {
  /**
   * @param {boolean} collapsed
   * @return {boolean}
   */
  var dispatchSectionToggledEvent = function dispatchSectionToggledEvent(collapsed) {
    return window.dispatchEvent(new _Polyfill2.default.CustomEvent(SECTION_TOGGLED_EVENT_TYPE, { collapsed: collapsed }));
  };

  // assign click handler to the collapsed divs
  var collapsedHeaderDivs = _Polyfill2.default.querySelectorAll(container, '.' + CLASS.COLLAPSED_CONTAINER);
  collapsedHeaderDivs.forEach(function (collapsedHeaderDiv) {
    collapsedHeaderDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedHeaderDiv)();
      dispatchSectionToggledEvent(collapsed);
    };
  });

  var collapsedFooterDivs = _Polyfill2.default.querySelectorAll(container, '.' + CLASS.COLLAPSED_BOTTOM);
  collapsedFooterDivs.forEach(function (collapsedFooterDiv) {
    collapsedFooterDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedFooterDiv, footerDivClickCallback)();
      dispatchSectionToggledEvent(collapsed);
    };
  });

  if (!isInitiallyCollapsed) {
    var containerDivs = _Polyfill2.default.querySelectorAll(container, '.' + CLASS.CONTAINER);
    containerDivs.forEach(function (containerDiv) {
      toggleCollapsedForContainer(containerDiv);
    });
  }
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

  prepareTables(document, pageTitle, infoboxTitle, otherTitle, footerTitle);
  setupEventHandling(window, document, isInitiallyCollapsed, footerDivClickCallback);
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
    var containerSelector = '[class*="' + CLASS.CONTAINER + '"]';
    var container = _ElementUtilities2.default.findClosestAncestor(element, containerSelector);
    if (container) {
      var collapsedDiv = container.firstElementChild;
      if (collapsedDiv && collapsedDiv.classList.contains(CLASS.EXPANDED)) {
        collapsedDiv.click();
      }
    }
  }
};

exports.default = {
  SECTION_TOGGLED_EVENT_TYPE: SECTION_TOGGLED_EVENT_TYPE,
  toggleCollapseClickCallback: toggleCollapseClickCallback,
  collapseTables: collapseTables,
  adjustTables: adjustTables,
  prepareTables: prepareTables,
  setupEventHandling: setupEventHandling,
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

/***/ }),

/***/ "./src/transform/CollectionUtilities.js":
/*!**********************************************!*\
  !*** ./src/transform/CollectionUtilities.js ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Extracts array of page issues from element
 * @param {!Document} document
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssues = function collectPageIssues(document) {
  if (!document) {
    return [];
  }
  return _Polyfill2.default.querySelectorAll(document, '.mbox-text-span').map(function (el) {
    _Polyfill2.default.querySelectorAll(el, '.hide-when-compact, .collapsed').forEach(function (el) {
      return el.remove();
    });
    return el;
  });
};

/**
 * Extracts array of page issues HTML from element
 * @param {!Document} document
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssuesHTML = function collectPageIssuesHTML(document) {
  return collectPageIssues(document).map(function (el) {
    return el.innerHTML.trim();
  });
};

/**
 * Extracts array of page issues text from element
 * @param {!Document} document
 * @return {!Array.<string>} Return empty array if nothing is extracted
 */
var collectPageIssuesText = function collectPageIssuesText(document) {
  return collectPageIssues(document).map(function (el) {
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
  return _Polyfill2.default.querySelectorAll(element, 'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function (el) {
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
  return _Polyfill2.default.querySelectorAll(element, 'div.hatnote').map(function (el) {
    return el.innerHTML.trim();
  });
};

exports.default = {
  collectDisambiguationTitles: collectDisambiguationTitles,
  collectDisambiguationHTML: collectDisambiguationHTML,
  collectPageIssuesHTML: collectPageIssuesHTML,
  collectPageIssuesText: collectPageIssuesText,
  test: {
    collectPageIssues: collectPageIssues
  }
};

/***/ }),

/***/ "./src/transform/CompatibilityTransform.js":
/*!*************************************************!*\
  !*** ./src/transform/CompatibilityTransform.js ***!
  \*************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
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

exports.default = {
  COMPATIBILITY: COMPATIBILITY,
  enableSupport: enableSupport
};

/***/ }),

/***/ "./src/transform/DimImagesTransform.css":
/*!**********************************************!*\
  !*** ./src/transform/DimImagesTransform.css ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/DimImagesTransform.js":
/*!*********************************************!*\
  !*** ./src/transform/DimImagesTransform.js ***!
  \*********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./DimImagesTransform.css */ "./src/transform/DimImagesTransform.css");

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

exports.default = {
  CLASS: CLASS,
  isDim: isDim,
  dim: dim
};

/***/ }),

/***/ "./src/transform/EditTransform.css":
/*!*****************************************!*\
  !*** ./src/transform/EditTransform.css ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/EditTransform.js":
/*!****************************************!*\
  !*** ./src/transform/EditTransform.js ***!
  \****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./EditTransform.css */ "./src/transform/EditTransform.css");

var CLASS = {
  SECTION_HEADER: 'pagelib_edit_section_header',
  TITLE: 'pagelib_edit_section_title',
  LINK_CONTAINER: 'pagelib_edit_section_link_container',
  LINK: 'pagelib_edit_section_link',
  PROTECTION: { UNPROTECTED: '', PROTECTED: 'page-protected', FORBIDDEN: 'no-editing' }
};

var IDS = {
  TITLE_DESCRIPTION: 'pagelib_edit_section_title_description',
  ADD_TITLE_DESCRIPTION: 'pagelib_edit_section_add_title_description',
  DIVIDER: 'pagelib_edit_section_divider',
  PRONUNCIATION: 'pagelib_edit_section_title_pronunciation'
};

var DATA_ATTRIBUTE = { SECTION_INDEX: 'data-id', ACTION: 'data-action' };
var ACTION_EDIT_SECTION = 'edit_section';
var ACTION_TITLE_PRONUNCIATION = 'title_pronunciation';
var ACTION_ADD_TITLE_DESCRIPTION = 'add_title_description';

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
  link.classList.add(CLASS.LINK);
  return link;
};

/**
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @return {!HTMLSpanElement}
 */
var newEditSectionButton = function newEditSectionButton(document, index) {
  var container = document.createElement('span');
  container.classList.add(CLASS.LINK_CONTAINER);

  var link = newEditSectionLink(document, index);
  container.appendChild(link);

  return container;
};

/**
 * As a client, you may wish to set the ID attribute.
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @param {!number} level The *one-based* header or table of contents level.
 * @param {?string} titleHTML Title of this section header.
 * @param {?boolean} showEditPencil Whether to show the "edit" pencil (default is true).
 * @return {!HTMLElement}
 */
var newEditSectionHeader = function newEditSectionHeader(document, index, level, titleHTML) {
  var showEditPencil = arguments.length > 4 && arguments[4] !== undefined ? arguments[4] : true;

  var element = document.createElement('div');
  element.className = CLASS.SECTION_HEADER;

  var title = document.createElement('h' + level);
  title.innerHTML = titleHTML || '';
  title.className = CLASS.TITLE;
  title.setAttribute(DATA_ATTRIBUTE.SECTION_INDEX, index);
  element.appendChild(title);

  if (showEditPencil) {
    var button = newEditSectionButton(document, index);
    element.appendChild(button);
  }
  return element;
};

/**
 * Elements needed to show or add page title description.
 * @param {!Document} document
 * @param {?string} titleDescription Page title description.
 * @param {?string} addTitleDescriptionString Localized string e.g. 'Add title description'.
 * @param {?boolean} isTitleDescriptionEditable Whether title description is editable.
 * @return {?HTMLElement}
 */
var titleDescriptionElements = function titleDescriptionElements(document, titleDescription, addTitleDescriptionString, isTitleDescriptionEditable) {
  var descriptionExists = titleDescription !== undefined && titleDescription.length > 0;
  if (descriptionExists) {
    var p = document.createElement('p');
    p.id = IDS.TITLE_DESCRIPTION;
    p.innerHTML = titleDescription;
    return p;
  }
  if (isTitleDescriptionEditable) {
    var a = document.createElement('a');
    a.href = '#';
    a.setAttribute(DATA_ATTRIBUTE.ACTION, ACTION_ADD_TITLE_DESCRIPTION);
    var _p = document.createElement('p');
    _p.id = IDS.ADD_TITLE_DESCRIPTION;
    _p.innerHTML = addTitleDescriptionString;
    a.appendChild(_p);
    return a;
  }
  return null;
};

/**
 * Lead section header is a special case as it needs to show page title and description too,
 * and in addition to the lead edit pencil, the description can also be editable.
 * As a client, you may wish to set the ID attribute.
 * @param {!Document} document
 * @param {?string} pageDisplayTitle Page display title.
 * @param {?string} titleDescription Page title description.
 * @param {?string} addTitleDescriptionString Localized string e.g. 'Add title description'.
 * @param {?boolean} isTitleDescriptionEditable Whether title description is editable.
 * @param {?boolean} showEditPencil Whether to show the "edit" pencil (default is true).
 * @param {?boolean} hasPronunciation Whether to show pronunciation speaker icon (default is false).
 * @return {!HTMLElement}
 */
var newEditLeadSectionHeader = function newEditLeadSectionHeader(document, pageDisplayTitle, titleDescription, addTitleDescriptionString, isTitleDescriptionEditable) {
  var showEditPencil = arguments.length > 5 && arguments[5] !== undefined ? arguments[5] : true;
  var hasPronunciation = arguments.length > 6 && arguments[6] !== undefined ? arguments[6] : false;


  var container = document.createDocumentFragment();

  var header = newEditSectionHeader(document, 0, 1, pageDisplayTitle, showEditPencil);

  if (hasPronunciation) {
    var a = document.createElement('a');
    a.setAttribute(DATA_ATTRIBUTE.ACTION, ACTION_TITLE_PRONUNCIATION);
    a.id = IDS.PRONUNCIATION;
    header.querySelector('h1').appendChild(a);
  }

  container.appendChild(header);

  var descriptionElements = titleDescriptionElements(document, titleDescription, addTitleDescriptionString, isTitleDescriptionEditable);

  if (descriptionElements) {
    container.appendChild(descriptionElements);
  }

  var divider = document.createElement('hr');
  divider.id = IDS.DIVIDER;
  container.appendChild(divider);

  return container;
};

exports.default = {
  CLASS: CLASS,
  newEditSectionButton: newEditSectionButton,
  newEditSectionHeader: newEditSectionHeader,
  newEditLeadSectionHeader: newEditLeadSectionHeader
};

/***/ }),

/***/ "./src/transform/ElementGeometry.js":
/*!******************************************!*\
  !*** ./src/transform/ElementGeometry.js ***!
  \******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/** CSS length value and unit of measure. */
var DimensionUnit = function () {
  _createClass(DimensionUnit, null, [{
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
    _classCallCheck(this, DimensionUnit);

    this._value = Number(value);
    this._unit = unit || 'px';
  }

  /** @return {!number} NaN if unknown. */


  _createClass(DimensionUnit, [{
    key: 'toString',


    /** @return {!string} */
    value: function toString() {
      return isNaN(this.value) ? '' : '' + this.value + this.unit;
    }
  }, {
    key: 'value',
    get: function get() {
      return this._value;
    }

    /** @return {!string} */

  }, {
    key: 'unit',
    get: function get() {
      return this._unit;
    }
  }]);

  return DimensionUnit;
}();

/** Element width and height dimensions and units. */


var ElementGeometry = function () {
  _createClass(ElementGeometry, null, [{
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
    _classCallCheck(this, ElementGeometry);

    this._width = width;
    this._height = height;
  }

  /**
   * @return {?DimensionUnit}
   */


  _createClass(ElementGeometry, [{
    key: 'width',
    get: function get() {
      return this._width;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'widthValue',
    get: function get() {
      return this._width && !isNaN(this._width.value) ? this._width.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'widthUnit',
    get: function get() {
      return this._width && this._width.unit || 'px';
    }

    /**
     * @return {?DimensionUnit}
     */

  }, {
    key: 'height',
    get: function get() {
      return this._height;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'heightValue',
    get: function get() {
      return this._height && !isNaN(this._height.value) ? this._height.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'heightUnit',
    get: function get() {
      return this._height && this._height.unit || 'px';
    }
  }]);

  return ElementGeometry;
}();

exports.default = ElementGeometry;

/***/ }),

/***/ "./src/transform/ElementUtilities.js":
/*!*******************************************!*\
  !*** ./src/transform/ElementUtilities.js ***!
  \*******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
  for (parentElement = el.parentElement; parentElement && !_Polyfill2.default.matchesSelector(parentElement, selector); parentElement = parentElement.parentElement) {
    // Intentionally empty.
  }
  return parentElement;
};

/**
 * @param {?Element} element
 * @param {!string} property
 * @param {?string} value
 * @return {?Element} The inclusive first element with an inline style (and optional value) or
 * undefined.
 */
var closestInlineStyle = function closestInlineStyle(element, property, value) {
  for (var el = element; el; el = el.parentElement) {
    var thisValue = el.style[property];
    if (thisValue) {
      if (value === undefined) {
        return el;
      }
      if (value === thisValue) {
        return el;
      }
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

exports.default = {
  findClosestAncestor: findClosestAncestor,
  isNestedInTable: isNestedInTable,
  closestInlineStyle: closestInlineStyle,
  isVisible: isVisible,
  copyAttributesToDataAttributes: copyAttributesToDataAttributes,
  copyDataAttributesToAttributes: copyDataAttributesToAttributes
};

/***/ }),

/***/ "./src/transform/FooterContainer.css":
/*!*******************************************!*\
  !*** ./src/transform/FooterContainer.css ***!
  \*******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/FooterContainer.js":
/*!******************************************!*\
  !*** ./src/transform/FooterContainer.js ***!
  \******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./FooterContainer.css */ "./src/transform/FooterContainer.css");

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
  var elements = _Polyfill2.default.querySelectorAll(document, selectors.join());
  elements.forEach(function (element) {
    element.style.marginLeft = margin + 'px';
    element.style.marginRight = margin + 'px';
  });
  var rightOrLeft = document.querySelector('html').dir === 'rtl' ? 'right' : 'left';
  _Polyfill2.default.querySelectorAll(document, '.pagelib_footer_menu_item').forEach(function (element) {
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

exports.default = {
  containerFragment: containerFragment,
  isContainerAttached: isContainerAttached, // todo: rename isAttached()?
  updateBottomPaddingToAllowReadMoreToScrollToTop: updateBottomPaddingToAllowReadMoreToScrollToTop,
  updateLeftAndRightMargin: updateLeftAndRightMargin
};

/***/ }),

/***/ "./src/transform/FooterLegal.css":
/*!***************************************!*\
  !*** ./src/transform/FooterLegal.css ***!
  \***************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/FooterLegal.js":
/*!**************************************!*\
  !*** ./src/transform/FooterLegal.js ***!
  \**************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./FooterLegal.css */ "./src/transform/FooterLegal.css");

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

exports.default = {
  add: add
};

/***/ }),

/***/ "./src/transform/FooterMenu.css":
/*!**************************************!*\
  !*** ./src/transform/FooterMenu.css ***!
  \**************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/FooterMenu.js":
/*!*************************************!*\
  !*** ./src/transform/FooterMenu.js ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

__webpack_require__(/*! ./FooterMenu.css */ "./src/transform/FooterMenu.css");

var _CollectionUtilities = __webpack_require__(/*! ./CollectionUtilities */ "./src/transform/CollectionUtilities.js");

var _CollectionUtilities2 = _interopRequireDefault(_CollectionUtilities);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

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
   */
  function MenuItem(title, subtitle, itemType, clickHandler) {
    _classCallCheck(this, MenuItem);

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


  _createClass(MenuItem, [{
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
          return _CollectionUtilities2.default.collectPageIssuesText;
        case MenuItemType.disambiguation:
          return _CollectionUtilities2.default.collectDisambiguationTitles;
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
    item.payload = extractor(document);
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

exports.default = {
  MenuItemType: MenuItemType, // todo: rename to just ItemType?
  setHeading: setHeading,
  maybeAddItem: maybeAddItem
};

/***/ }),

/***/ "./src/transform/FooterReadMore.css":
/*!******************************************!*\
  !*** ./src/transform/FooterReadMore.css ***!
  \******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/FooterReadMore.js":
/*!*****************************************!*\
  !*** ./src/transform/FooterReadMore.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./FooterReadMore.css */ "./src/transform/FooterReadMore.css");

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

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
 * @param {!string} displayTitle
 * @param {?string} thumbnail
 * @param {?string} description
 * @param {?string} extract
 */
function ReadMorePage(title, displayTitle, thumbnail, description, extract) {
  _classCallCheck(this, ReadMorePage);

  this.title = title;
  this.displayTitle = displayTitle;
  this.thumbnail = thumbnail;
  this.description = description;
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
  outerAnchorContainer.href = '/wiki/' + encodeURI(readMorePage.title) + '?event_logging_label=read_more';

  var titleToShow = void 0;
  if (readMorePage.displayTitle) {
    titleToShow = readMorePage.displayTitle;
  } else if (readMorePage.title) {
    titleToShow = readMorePage.title;
  }

  if (titleToShow) {
    var title = document.createElement('div');
    title.id = index;
    title.className = 'pagelib_footer_readmore_page_title';
    title.innerHTML = titleToShow.replace(/_/g, ' ');
    outerAnchorContainer.title = readMorePage.title.replace(/_/g, ' ');
    innerDivContainer.appendChild(title);
  }

  var description = void 0;
  if (readMorePage.description) {
    description = readMorePage.description;
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
    var pageModel = new ReadMorePage(title, page.pageprops.displaytitle, page.thumbnail, page.description, page.extract);
    var pageFragment = documentFragmentForReadMorePage(pageModel, index, saveButtonClickHandler, document);
    container.appendChild(pageFragment);
  });
  titlesShownHandler(shownTitles);
};

/**
 * Makes 'Read more' query parameters object for a title.
 * @param {!string} title
 * @param {!number} count
 * @return {!Object.<string, string|number>}
 */
var queryParameters = function queryParameters(title, count) {
  return {
    action: 'query',
    format: 'json',
    formatversion: 2,
    prop: 'extracts|pageimages|description|pageprops',

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
    pithumbsize: 120 // Limit thumbnail dimensions.
  };
};

/**
 * Converts query parameter object to string.
 * @param {!Object.<string, string|number>} parameters
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
 * @return {!string}
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
var add = function add(title, count, containerID, baseURL, saveButtonClickHandler, titlesShownHandler, document) {
  fetchReadMore(title, count, containerID, baseURL, showReadMorePages, saveButtonClickHandler, titlesShownHandler, document);
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

exports.default = {
  add: add,
  setHeading: setHeading,
  updateSaveButtonForTitle: updateSaveButtonForTitle,
  test: {
    cleanExtract: cleanExtract,
    safelyRemoveEnclosures: safelyRemoveEnclosures
  }
};

/***/ }),

/***/ "./src/transform/FooterTransformer.js":
/*!********************************************!*\
  !*** ./src/transform/FooterTransformer.js ***!
  \********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _FooterContainer = __webpack_require__(/*! ./FooterContainer */ "./src/transform/FooterContainer.js");

var _FooterContainer2 = _interopRequireDefault(_FooterContainer);

var _FooterLegal = __webpack_require__(/*! ./FooterLegal */ "./src/transform/FooterLegal.js");

var _FooterLegal2 = _interopRequireDefault(_FooterLegal);

var _FooterReadMore = __webpack_require__(/*! ./FooterReadMore */ "./src/transform/FooterReadMore.js");

var _FooterReadMore2 = _interopRequireDefault(_FooterReadMore);

var _Throttle = __webpack_require__(/*! ./Throttle */ "./src/transform/Throttle.js");

var _Throttle2 = _interopRequireDefault(_Throttle);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

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
    _classCallCheck(this, _class);

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


  _createClass(_class, [{
    key: 'add',
    value: function add(window, container, baseURL, title, readMoreHeader, readMoreLimit, license, licenseSubstitutionString, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler, titlesShownHandler, saveButtonClickHandler) {
      this.remove(window);
      container.appendChild(_FooterContainer2.default.containerFragment(window.document));

      _FooterLegal2.default.add(window.document, license, licenseSubstitutionString, ID_LEGAL_CONTAINER, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler);

      _FooterReadMore2.default.setHeading(readMoreHeader, ID_READ_MORE_HEADER, window.document);
      _FooterReadMore2.default.add(title, readMoreLimit, ID_READ_MORE_CONTAINER, baseURL, saveButtonClickHandler, function (titles) {
        _FooterContainer2.default.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
        titlesShownHandler(titles);
      }, window.document);

      this._resizeListener = _Throttle2.default.wrap(window, RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS, function () {
        return _FooterContainer2.default.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
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

exports.default = _class;

/***/ }),

/***/ "./src/transform/LazyLoadTransform.css":
/*!*********************************************!*\
  !*** ./src/transform/LazyLoadTransform.css ***!
  \*********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/LazyLoadTransform.ts":
/*!********************************************!*\
  !*** ./src/transform/LazyLoadTransform.ts ***!
  \********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
__webpack_require__(/*! ./LazyLoadTransform.css */ "./src/transform/LazyLoadTransform.css");
// todo: use imports when other modules are TypeScript.
var ElementGeometry = __webpack_require__(/*! ./ElementGeometry */ "./src/transform/ElementGeometry.js").default;
var ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js").default;
var Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js").default;
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
var COPY_ATTRIBUTES = ['class', 'style', 'src', 'srcset', 'width', 'height', 'alt',
    'usemap', 'data-file-width', 'data-file-height', 'data-image-gallery'
];
// Small images, especially icons, are quickly downloaded and may appear in many places. Lazily
// loading these images degrades the experience with little gain. Always eagerly load these images.
// Example: flags in the medal count for the "1896 Summer Olympics medal table."
// https://en.m.wikipedia.org/wiki/1896_Summer_Olympics_medal_table?oldid=773498394#Medal_count
var UNIT_TO_MINIMUM_LAZY_LOAD_SIZE = {
    px: 50,
    ex: 10,
    em: 5 // 1ex ≈ .5em; https://developer.mozilla.org/en-US/docs/Web/CSS/length#Units
};
/**
 * Replace an image with a placeholder.
 * @param {!Document} document
 * @param {!HTMLImageElement} image The image to be replaced.
 * @return {!HTMLSpanElement} The placeholder replacing image.
 */
var convertImageToPlaceholder = function (document, image) {
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
        placeholder.setAttribute('class', image.getAttribute('class') || '');
    }
    placeholder.classList.add(PLACEHOLDER_CLASS);
    placeholder.classList.add(PLACEHOLDER_PENDING_CLASS);
    // Match the image's width, if specified. If image widening is used, this width will be overridden
    // by !important priority.
    var geometry = ElementGeometry.from(image);
    if (geometry.width) {
        placeholder.style.setProperty('width', "" + geometry.width);
    }
    // Save the image's attributes to data-* attributes for later restoration.
    ElementUtilities.copyAttributesToDataAttributes(image, placeholder, COPY_ATTRIBUTES);
    // Create a spacer and match the aspect ratio of the original image, if determinable. If image
    // widening is used, this spacer will scale with the width proportionally.
    var spacing = document.createElement('span');
    if (geometry.width && geometry.height) {
        // Assume units are identical.
        var ratio = geometry.heightValue / geometry.widthValue;
        spacing.style.setProperty('padding-top', ratio * 100 + "%");
    }
    // Append the spacer to the placeholder and replace the image with the placeholder.
    placeholder.appendChild(spacing);
    if (image.parentNode)
        image.parentNode.replaceChild(placeholder, image);
    return placeholder;
};
/**
 * @param {!HTMLImageElement} image The image to be considered.
 * @return {!boolean} true if image download can be deferred, false if image should be eagerly
 *                    loaded.
 */
var isLazyLoadable = function (image) {
    var geometry = ElementGeometry.from(image);
    if (!geometry.width || !geometry.height) {
        return true;
    }
    var minWidth = UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.widthUnit] || Infinity;
    var minHeight = UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.heightUnit] || Infinity;
    return geometry.widthValue >= minWidth && geometry.heightValue >= minHeight;
};
/**
 * @param {!Element} element
 * @return {!Array.<HTMLImageElement>} Convertible images descendent from but not including element.
 */
var queryLazyLoadableImages = function (element) {
    return Polyfill.querySelectorAll(element, 'img').filter(function (image) { return isLazyLoadable(image); });
};
/**
 * Convert images with placeholders. The transformation is inverted by calling loadImage().
 * @param {!Document} document
 * @param {!Array.<HTMLImageElement>} images The images to lazily load.
 * @return {!Array.<HTMLSpanElement>} The placeholders replacing images.
 */
var convertImagesToPlaceholders = function (document, images) {
    return images.map(function (image) { return convertImageToPlaceholder(document, image); });
};
/**
 * Start downloading image resources associated with a given placeholder and replace the placeholder
 * with a new image element when the download is complete.
 * @param {!Document} document
 * @param {!HTMLSpanElement} placeholder
 * @return {!HTMLImageElement} A new image element.
 */
var loadPlaceholder = function (document, placeholder) {
    placeholder.classList.add(PLACEHOLDER_LOADING_CLASS);
    placeholder.classList.remove(PLACEHOLDER_PENDING_CLASS);
    var image = document.createElement('img');
    var retryListener = function (event) {
        image.setAttribute('src', image.getAttribute('src') || '');
        event.stopPropagation();
        event.preventDefault();
    };
    // Add the download listener prior to setting the src attribute to avoid missing the load event.
    image.addEventListener('load', function () {
        placeholder.removeEventListener('click', retryListener);
        if (placeholder.parentNode)
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
    ElementUtilities.copyDataAttributesToAttributes(placeholder, image, COPY_ATTRIBUTES);
    // Append to the class list after copying over any preexisting classes.
    image.classList.add(IMAGE_LOADING_CLASS);
    return image;
};
exports.default = {
    PLACEHOLDER_CLASS: PLACEHOLDER_CLASS,
    queryLazyLoadableImages: queryLazyLoadableImages,
    convertImagesToPlaceholders: convertImagesToPlaceholders,
    loadPlaceholder: loadPlaceholder
};


/***/ }),

/***/ "./src/transform/LazyLoadTransformer.js":
/*!**********************************************!*\
  !*** ./src/transform/LazyLoadTransformer.js ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _CollapseTable = __webpack_require__(/*! ./CollapseTable */ "./src/transform/CollapseTable.js");

var _CollapseTable2 = _interopRequireDefault(_CollapseTable);

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

var _LazyLoadTransform = __webpack_require__(/*! ./LazyLoadTransform */ "./src/transform/LazyLoadTransform.ts");

var _LazyLoadTransform2 = _interopRequireDefault(_LazyLoadTransform);

var _Throttle = __webpack_require__(/*! ./Throttle */ "./src/transform/Throttle.js");

var _Throttle2 = _interopRequireDefault(_Throttle);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var EVENT_TYPES = ['scroll', 'resize', _CollapseTable2.default.SECTION_TOGGLED_EVENT_TYPE];
var THROTTLE_PERIOD_MILLISECONDS = 100;

/**
 * This class subscribes to key page events, applying lazy load transforms or inversions as
 * applicable. It has external dependencies on the section-toggled custom event and the following
 * standard browser events: resize, scroll.
 */

var _class = function () {
  /**
   * @param {!Window} window
   * @param {!number} loadDistanceMultiplier Images within this multiple of the screen height are
   *                                         loaded in either direction.
   */
  function _class(window, loadDistanceMultiplier) {
    var _this = this;

    _classCallCheck(this, _class);

    this._window = window;
    this._loadDistanceMultiplier = loadDistanceMultiplier;

    this._placeholders = [];
    this._registered = false;
    this._throttledLoadPlaceholders = _Throttle2.default.wrap(window, THROTTLE_PERIOD_MILLISECONDS, function () {
      return _this._loadPlaceholders();
    });
  }

  /**
   * Convert images with placeholders. Calling this function may register this instance to listen to
   * page events.
   * @param {!Element} element
   * @return {void}
   */


  _createClass(_class, [{
    key: 'convertImagesToPlaceholders',
    value: function convertImagesToPlaceholders(element) {
      var images = _LazyLoadTransform2.default.queryLazyLoadableImages(element);
      var placeholders = _LazyLoadTransform2.default.convertImagesToPlaceholders(this._window.document, images);
      this._placeholders = this._placeholders.concat(placeholders);
      this._register();
    }

    /**
     * Searches for existing placeholders in the DOM Document.
     * This is an alternative to #convertImagesToPlaceholders if that was already done server-side.
     * @param {!Element} element root element to start searching for placeholders
     * @return {void}
     */

  }, {
    key: 'collectExistingPlaceholders',
    value: function collectExistingPlaceholders(element) {
      var placeholders = Array.from(element.querySelectorAll('.' + _LazyLoadTransform2.default.PLACEHOLDER_CLASS));
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
          _LazyLoadTransform2.default.loadPlaceholder(_this4._window.document, placeholder);
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
      return _ElementUtilities2.default.isVisible(placeholder) && this._isPlaceholderWithinLoadDistance(placeholder);
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

exports.default = _class;

/***/ }),

/***/ "./src/transform/LeadIntroductionTransform.js":
/*!****************************************************!*\
  !*** ./src/transform/LeadIntroductionTransform.js ***!
  \****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ELEMENT_NODE = 1;

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
  } while (node && !(node.nodeType === ELEMENT_NODE && node.tagName === 'P'));
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
  return _Polyfill2.default.querySelectorAll(document, '#' + containerID + ' > p').find(isParagraphEligible);
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

exports.default = {
  moveLeadIntroductionUp: moveLeadIntroductionUp,
  test: {
    isParagraphEligible: isParagraphEligible,
    extractLeadIntroductionNodes: extractLeadIntroductionNodes,
    getEligibleParagraph: getEligibleParagraph
  }
};

/***/ }),

/***/ "./src/transform/NodeUtilities.js":
/*!****************************************!*\
  !*** ./src/transform/NodeUtilities.js ***!
  \****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
// Node is undefined in Node.js
var NODE_TYPE = {
  ELEMENT_NODE: 1,
  TEXT_NODE: 3

  /**
   * Determines if node is either an element or text node.
   * @param  {!Node} node
   * @return {!boolean}
   */
};var isNodeTypeElementOrText = function isNodeTypeElementOrText(node) {
  return node.nodeType === NODE_TYPE.ELEMENT_NODE || node.nodeType === NODE_TYPE.TEXT_NODE;
};

exports.default = {
  isNodeTypeElementOrText: isNodeTypeElementOrText,
  NODE_TYPE: NODE_TYPE
};

/***/ }),

/***/ "./src/transform/OrderedList.css":
/*!***************************************!*\
  !*** ./src/transform/OrderedList.css ***!
  \***************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/PlatformTransform.js":
/*!********************************************!*\
  !*** ./src/transform/PlatformTransform.js ***!
  \********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var CLASS = { ANDROID: 'pagelib_platform_android', IOS: 'pagelib_platform_ios'

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
    html.classList.add(CLASS.ANDROID);
  }
  if (isIOs(window)) {
    html.classList.add(CLASS.IOS);
  }
};

exports.default = {
  CLASS: CLASS,
  classify: classify
};

/***/ }),

/***/ "./src/transform/Polyfill.js":
/*!***********************************!*\
  !*** ./src/transform/Polyfill.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
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

exports.default = {
  matchesSelector: matchesSelector,
  querySelectorAll: querySelectorAll,
  CustomEvent: CustomEvent
};

/***/ }),

/***/ "./src/transform/RedLinks.js":
/*!***********************************!*\
  !*** ./src/transform/RedLinks.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
  return _Polyfill2.default.querySelectorAll(content, 'a.new');
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

exports.default = {
  hideRedLinks: hideRedLinks,
  test: {
    configureRedLinkTemplate: configureRedLinkTemplate,
    redLinkAnchorsInDocument: redLinkAnchorsInDocument,
    newRedLinkTemplate: newRedLinkTemplate,
    replaceAnchorWithSpan: replaceAnchorWithSpan
  }
};

/***/ }),

/***/ "./src/transform/ReferenceCollection.js":
/*!**********************************************!*\
  !*** ./src/transform/ReferenceCollection.js ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

var _NodeUtilities = __webpack_require__(/*! ./NodeUtilities */ "./src/transform/NodeUtilities.js");

var _NodeUtilities2 = _interopRequireDefault(_NodeUtilities);

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var REFERENCE_SELECTOR = '.reference, .mw-ref';
var CITE_HASH_PREFIX = '#cite_note';

/**
 * Is Citation.
 * @param {!string} href
 * @return {!boolean}
 */
var isCitation = function isCitation(href) {
  return href.indexOf(CITE_HASH_PREFIX) > -1;
};

/**
 * Determines if node is a text node containing only whitespace.
 * @param {!Node} node
 * @return {!boolean}
 */
var isWhitespaceTextNode = function isWhitespaceTextNode(node) {
  return Boolean(node) && node.nodeType === Node.TEXT_NODE && Boolean(node.textContent.match(/^\s+$/));
};

/**
 * Checks if element has a child anchor with a citation link.
 * @param {!Element} element
 * @return {!boolean}
 */
var hasCitationLink = function hasCitationLink(element) {
  var anchor = element.querySelector('a');
  return anchor && isCitation(anchor.hash);
};

/**
 * Get the reference text container.
 * @param {!Document} document
 * @param {!Element} source
 * @return {?HTMLElement}
 */
var getRefTextContainer = function getRefTextContainer(document, source) {
  var refTextContainerID = source.querySelector('A').getAttribute('href').slice(1);
  var refTextContainer = document.getElementById(refTextContainerID) || document.getElementById(decodeURIComponent(refTextContainerID));

  return refTextContainer;
};

/**
 * Extract reference text free of backlinks.
 * @param {!Document} document
 * @param {!Element} source
 * @return {!string}
 */
var collectRefText = function collectRefText(document, source) {
  var refTextContainer = getRefTextContainer(document, source);
  if (!refTextContainer) {
    return '';
  }

  // Clone what we're interested in into a frag so we can easily
  // remove things without consequence to the 'live' document.
  var frag = document.createDocumentFragment();
  var fragDiv = document.createElement('div');
  frag.appendChild(fragDiv);
  // eslint-disable-next-line require-jsdoc
  var cloneNodeIntoFragmentDiv = function cloneNodeIntoFragmentDiv(node) {
    return fragDiv.appendChild(node.cloneNode(true));
  };
  Array.prototype.slice.call(refTextContainer.childNodes).filter(_NodeUtilities2.default.isNodeTypeElementOrText).forEach(cloneNodeIntoFragmentDiv);

  var removalSelector = 'link, style, sup[id^=cite_ref], .mw-cite-backlink';
  _Polyfill2.default.querySelectorAll(fragDiv, removalSelector).forEach(function (node) {
    return node.remove();
  });

  return fragDiv.innerHTML.trim();
};

/**
 * Get closest element to node which has class `reference`. If node itself has class `reference`
 * returns the node.
 * @param {!Node} sourceNode
 * @return {?HTMLElement}
 */
var closestReferenceClassElement = function closestReferenceClassElement(sourceNode) {
  if (_Polyfill2.default.matchesSelector(sourceNode, REFERENCE_SELECTOR)) {
    return sourceNode;
  }
  return _ElementUtilities2.default.findClosestAncestor(sourceNode, REFERENCE_SELECTOR);
};

/**
 * Reference item model.
 */

var ReferenceItem =
/**
 * ReferenceItem construtor.
 * @param {!string} id
 * @param {!DOMRect} rect
 * @param {?string} text
 * @param {?string} html
 */
function ReferenceItem(id, rect, text, html) {
  _classCallCheck(this, ReferenceItem);

  this.id = id;
  this.rect = rect;
  this.text = text;
  this.html = html;
};

/**
 * Converts node to ReferenceItem.
 * @param {!Document} document
 * @param {!Node} node
 * @return {!ReferenceItem}
 */


var referenceItemForNode = function referenceItemForNode(document, node) {
  return new ReferenceItem(closestReferenceClassElement(node).id, node.getBoundingClientRect(), node.textContent, collectRefText(document, node));
};

/**
 * Container for nearby references including the index of the selected reference.
 */

var NearbyReferences =
/**
 * @param {!number} selectedIndex
 * @param {!Array.<ReferenceItem>} referencesGroup
 * @return {!NearbyReferences}
 */
function NearbyReferences(selectedIndex, referencesGroup) {
  _classCallCheck(this, NearbyReferences);

  this.selectedIndex = selectedIndex;
  this.referencesGroup = referencesGroup;
};

/**
 * Closure around a node for getting previous or next sibling.
 *
 * @typedef SiblingGetter
 * @param {!Node} node
 * @return {?Node}
 */

/**
  * Closure around `collectedNodes` for collecting reference nodes.
  *
  * @typedef Collector
  * @param {!Node} node
  * @return {void}
  */

/**
 * Get adjacent non-whitespace node.
 * @param {!Node} node
 * @param {!SiblingGetter} siblingGetter
 * @return {?Node}
 */


var adjacentNonWhitespaceNode = function adjacentNonWhitespaceNode(node, siblingGetter) {
  var currentNode = node;
  do {
    currentNode = siblingGetter(currentNode);
  } while (isWhitespaceTextNode(currentNode));
  return currentNode;
};

/**
 * Collect adjacent reference nodes. The starting node is not collected.
 * @param {!Node} node
 * @param {!SiblingGetter} siblingGetter
 * @param {!Collector} nodeCollector
 * @return {void}
 */
var collectAdjacentReferenceNodes = function collectAdjacentReferenceNodes(node, siblingGetter, nodeCollector) {
  var currentNode = node;
  while (true) {
    currentNode = adjacentNonWhitespaceNode(currentNode, siblingGetter);
    if (!currentNode || currentNode.nodeType !== Node.ELEMENT_NODE || !hasCitationLink(currentNode)) {
      break;
    }
    nodeCollector(currentNode);
  }
};

/* eslint-disable valid-jsdoc */
/** @type {SiblingGetter} */
var prevSiblingGetter = function prevSiblingGetter(node) {
  return node.previousSibling;
};

/** @type {SiblingGetter} */
var nextSiblingGetter = function nextSiblingGetter(node) {
  return node.nextSibling;
};
/* eslint-enable valid-jsdoc */

/**
 * Collect nearby reference nodes.
 * @param {!Node} sourceNode
 * @return {!Array.<Node>}
 */
var collectNearbyReferenceNodes = function collectNearbyReferenceNodes(sourceNode) {
  var collectedNodes = [sourceNode];

  /* eslint-disable require-jsdoc */
  // These are `Collector`s.
  var collectedNodesUnshifter = function collectedNodesUnshifter(node) {
    return collectedNodes.unshift(node);
  };
  var collectedNodesPusher = function collectedNodesPusher(node) {
    return collectedNodes.push(node);
  };
  /* eslint-enable require-jsdoc */

  collectAdjacentReferenceNodes(sourceNode, prevSiblingGetter, collectedNodesUnshifter);
  collectAdjacentReferenceNodes(sourceNode, nextSiblingGetter, collectedNodesPusher);

  return collectedNodes;
};

/**
 * Collect nearby references.
 * @param {!Document} document
 * @param {!Node} sourceNode
 * @return {!NearbyReferences}
 */
var collectNearbyReferences = function collectNearbyReferences(document, sourceNode) {
  var sourceNodeParent = sourceNode.parentElement;
  var referenceNodes = collectNearbyReferenceNodes(sourceNodeParent);
  var selectedIndex = referenceNodes.indexOf(sourceNodeParent);
  var referencesGroup = referenceNodes.map(function (node) {
    return referenceItemForNode(document, node);
  });
  return new NearbyReferences(selectedIndex, referencesGroup);
};

exports.default = {
  collectNearbyReferences: collectNearbyReferences,
  isCitation: isCitation,
  test: {
    adjacentNonWhitespaceNode: adjacentNonWhitespaceNode,
    closestReferenceClassElement: closestReferenceClassElement,
    collectAdjacentReferenceNodes: collectAdjacentReferenceNodes,
    collectNearbyReferenceNodes: collectNearbyReferenceNodes,
    collectRefText: collectRefText,
    getRefTextContainer: getRefTextContainer,
    hasCitationLink: hasCitationLink,
    isWhitespaceTextNode: isWhitespaceTextNode,
    nextSiblingGetter: nextSiblingGetter,
    prevSiblingGetter: prevSiblingGetter
  }
};

/***/ }),

/***/ "./src/transform/ThemeTransform.css":
/*!******************************************!*\
  !*** ./src/transform/ThemeTransform.css ***!
  \******************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/ThemeTransform.js":
/*!*****************************************!*\
  !*** ./src/transform/ThemeTransform.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./ThemeTransform.css */ "./src/transform/ThemeTransform.css");

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
  return !_ElementUtilities2.default.closestInlineStyle(image, 'background');
};

/**
 * Annotate elements with CSS classes that can be used by CSS rules. The classes themselves are not
 * theme-dependent so classification only need only occur once after the content is loaded, not
 * every time the theme changes.
 * @param {!Element} element
 * @return {void}
 */
var classifyElements = function classifyElements(element) {
  _Polyfill2.default.querySelectorAll(element, 'img').filter(imagePresumesWhiteBackground).forEach(function (image) {
    image.classList.add(CONSTRAINT.IMAGE_PRESUMES_WHITE_BACKGROUND);
  });
  /* en > Away colours > 793128975 */
  /* en > Manchester United F.C. > 793244653 */
  /* en > Pantone > 792312384 */
  /* en > Wikipedia:Graphs_and_charts > 801754530 */
  /* en > PepsiCo > 807406166 */
  /* en > Lua_(programming_language) > 809310207 */
  var selector = ['div.color_swatch div', 'div[style*="position: absolute"]', 'div.barbox table div[style*="background:"]', 'div.chart div[style*="background-color"]', 'div.chart ul li span[style*="background-color"]', 'span.legend-color', 'div.mw-highlight span', 'code.mw-highlight span', '.BrickChartTemplate div', '.PieChartTemplate div', '.BarChartTemplate div', '.StackedBarTemplate td', '.chess-board div'].join();
  _Polyfill2.default.querySelectorAll(element, selector).forEach(function (element) {
    return element.classList.add(CONSTRAINT.DIV_DO_NOT_APPLY_BASELINE);
  });
};

exports.default = {
  CONSTRAINT: CONSTRAINT,
  THEME: THEME,
  setTheme: setTheme,
  classifyElements: classifyElements
};

/***/ }),

/***/ "./src/transform/Throttle.js":
/*!***********************************!*\
  !*** ./src/transform/Throttle.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

/** Function rate limiter. */
var Throttle = function () {
  _createClass(Throttle, null, [{
    key: "wrap",

    /**
     * The function to invoke when not throttled.
     *
     * @callback NotThrottledFunction
     */

    /**
     * A function wrapped in a Throttle.
     *
     * @callback WrappedFunction
     */

    /**
     * Wraps a function in a Throttle.
     * @param {!Window} window
     * @param {!number} period The nonnegative minimum number of milliseconds between function
     *                         invocations.
     * @param {!NotThrottledFunction} funktion
     * @return {!WrappedFunction}
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
     * @param {!NotThrottledFunction} funktion
     */

  }]);

  function Throttle(window, period, funktion) {
    _classCallCheck(this, Throttle);

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


  _createClass(Throttle, [{
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
    get: function get() {
      return this._result;
    }
  }]);

  return Throttle;
}();

exports.default = Throttle;

/***/ }),

/***/ "./src/transform/WidenImage.css":
/*!**************************************!*\
  !*** ./src/transform/WidenImage.css ***!
  \**************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ "./src/transform/WidenImage.js":
/*!*************************************!*\
  !*** ./src/transform/WidenImage.js ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(/*! ./WidenImage.css */ "./src/transform/WidenImage.css");

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

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
  var parentAnchor = _ElementUtilities2.default.findClosestAncestor(element, 'a.image');
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
  if (_ElementUtilities2.default.findClosestAncestor(image, "[class*='noresize']")) {
    return false;
  }

  // Side-by-side images should not be widened. Often their captions mention 'left' and 'right', so
  // we don't want to widen these as doing so would stack them vertically.
  // Examples exhibiting side-by-side images:
  //    'enwiki > Cold Comfort (Inside No. 9) > Casting'
  //    'enwiki > Vincent van Gogh > Letters'
  if (_ElementUtilities2.default.findClosestAncestor(image, "div[class*='tsingle']")) {
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
  if (_ElementUtilities2.default.isNestedInTable(image)) {
    return false;
  }

  // Widening absolutely positioned images can cause overlapping with adjacent text.
  // Example can be found on `ja > 今治城 > 71804195`, which has a Mapplot template which outputs
  // an image nested in an absolutely positioned div.
  if (_ElementUtilities2.default.closestInlineStyle(image, 'position', 'absolute')) {
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

exports.default = {
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

/***/ }),

/***/ "./src/transform/index.js":
/*!********************************!*\
  !*** ./src/transform/index.js ***!
  \********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _ThemeTransform = __webpack_require__(/*! ./ThemeTransform */ "./src/transform/ThemeTransform.js");

var _ThemeTransform2 = _interopRequireDefault(_ThemeTransform);

var _BodySpacingTransform = __webpack_require__(/*! ./BodySpacingTransform */ "./src/transform/BodySpacingTransform.ts");

var _BodySpacingTransform2 = _interopRequireDefault(_BodySpacingTransform);

var _CollapseTable = __webpack_require__(/*! ./CollapseTable */ "./src/transform/CollapseTable.js");

var _CollapseTable2 = _interopRequireDefault(_CollapseTable);

var _CollectionUtilities = __webpack_require__(/*! ./CollectionUtilities */ "./src/transform/CollectionUtilities.js");

var _CollectionUtilities2 = _interopRequireDefault(_CollectionUtilities);

var _CompatibilityTransform = __webpack_require__(/*! ./CompatibilityTransform */ "./src/transform/CompatibilityTransform.js");

var _CompatibilityTransform2 = _interopRequireDefault(_CompatibilityTransform);

var _DimImagesTransform = __webpack_require__(/*! ./DimImagesTransform */ "./src/transform/DimImagesTransform.js");

var _DimImagesTransform2 = _interopRequireDefault(_DimImagesTransform);

var _EditTransform = __webpack_require__(/*! ./EditTransform */ "./src/transform/EditTransform.js");

var _EditTransform2 = _interopRequireDefault(_EditTransform);

var _ElementGeometry = __webpack_require__(/*! ./ElementGeometry */ "./src/transform/ElementGeometry.js");

var _ElementGeometry2 = _interopRequireDefault(_ElementGeometry);

var _ElementUtilities = __webpack_require__(/*! ./ElementUtilities */ "./src/transform/ElementUtilities.js");

var _ElementUtilities2 = _interopRequireDefault(_ElementUtilities);

var _LeadIntroductionTransform = __webpack_require__(/*! ./LeadIntroductionTransform */ "./src/transform/LeadIntroductionTransform.js");

var _LeadIntroductionTransform2 = _interopRequireDefault(_LeadIntroductionTransform);

var _FooterContainer = __webpack_require__(/*! ./FooterContainer */ "./src/transform/FooterContainer.js");

var _FooterContainer2 = _interopRequireDefault(_FooterContainer);

var _FooterLegal = __webpack_require__(/*! ./FooterLegal */ "./src/transform/FooterLegal.js");

var _FooterLegal2 = _interopRequireDefault(_FooterLegal);

var _FooterMenu = __webpack_require__(/*! ./FooterMenu */ "./src/transform/FooterMenu.js");

var _FooterMenu2 = _interopRequireDefault(_FooterMenu);

var _FooterReadMore = __webpack_require__(/*! ./FooterReadMore */ "./src/transform/FooterReadMore.js");

var _FooterReadMore2 = _interopRequireDefault(_FooterReadMore);

var _FooterTransformer = __webpack_require__(/*! ./FooterTransformer */ "./src/transform/FooterTransformer.js");

var _FooterTransformer2 = _interopRequireDefault(_FooterTransformer);

var _LazyLoadTransform = __webpack_require__(/*! ./LazyLoadTransform */ "./src/transform/LazyLoadTransform.ts");

var _LazyLoadTransform2 = _interopRequireDefault(_LazyLoadTransform);

var _LazyLoadTransformer = __webpack_require__(/*! ./LazyLoadTransformer */ "./src/transform/LazyLoadTransformer.js");

var _LazyLoadTransformer2 = _interopRequireDefault(_LazyLoadTransformer);

var _PlatformTransform = __webpack_require__(/*! ./PlatformTransform */ "./src/transform/PlatformTransform.js");

var _PlatformTransform2 = _interopRequireDefault(_PlatformTransform);

var _Polyfill = __webpack_require__(/*! ./Polyfill */ "./src/transform/Polyfill.js");

var _Polyfill2 = _interopRequireDefault(_Polyfill);

var _RedLinks = __webpack_require__(/*! ./RedLinks */ "./src/transform/RedLinks.js");

var _RedLinks2 = _interopRequireDefault(_RedLinks);

var _ReferenceCollection = __webpack_require__(/*! ./ReferenceCollection */ "./src/transform/ReferenceCollection.js");

var _ReferenceCollection2 = _interopRequireDefault(_ReferenceCollection);

var _Throttle = __webpack_require__(/*! ./Throttle */ "./src/transform/Throttle.js");

var _Throttle2 = _interopRequireDefault(_Throttle);

var _WidenImage = __webpack_require__(/*! ./WidenImage */ "./src/transform/WidenImage.js");

var _WidenImage2 = _interopRequireDefault(_WidenImage);

__webpack_require__(/*! ./OrderedList.css */ "./src/transform/OrderedList.css");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/* eslint-disable sort-imports */

// We want the theme transform to be first. This is because the theme transform CSS has to use
// some '!important' CSS modifiers to reliably set themes on elements which may contain inline
// styles. Moving it to the top of the file is necessary so other transforms can override
// these '!important' themes transform CSS bits if needed. Note - if other transforms have trouble
// overriding things changed by theme transform remember to match or exceed the selector specificity
// used by the theme transform for whatever it is you are trying to override.
exports.default = {
  BodySpacingTransform: _BodySpacingTransform2.default,
  // todo: rename CollapseTableTransform.
  CollapseTable: _CollapseTable2.default,
  CollectionUtilities: _CollectionUtilities2.default,
  CompatibilityTransform: _CompatibilityTransform2.default,
  DimImagesTransform: _DimImagesTransform2.default,
  EditTransform: _EditTransform2.default,
  // todo: rename Footer.ContainerTransform, Footer.LegalTransform, Footer.MenuTransform,
  //       Footer.ReadMoreTransform.
  LeadIntroductionTransform: _LeadIntroductionTransform2.default,
  FooterContainer: _FooterContainer2.default,
  FooterLegal: _FooterLegal2.default,
  FooterMenu: _FooterMenu2.default,
  FooterReadMore: _FooterReadMore2.default,
  FooterTransformer: _FooterTransformer2.default,
  LazyLoadTransform: _LazyLoadTransform2.default,
  LazyLoadTransformer: _LazyLoadTransformer2.default,
  PlatformTransform: _PlatformTransform2.default,
  // todo: rename RedLinkTransform.
  RedLinks: _RedLinks2.default,
  ReferenceCollection: _ReferenceCollection2.default,
  ThemeTransform: _ThemeTransform2.default,
  // todo: rename WidenImageTransform.
  WidenImage: _WidenImage2.default,
  test: {
    ElementGeometry: _ElementGeometry2.default,
    ElementUtilities: _ElementUtilities2.default,
    Polyfill: _Polyfill2.default,
    Throttle: _Throttle2.default
  }
};

/***/ })

/******/ })["default"];
});

},{}],2:[function(require,module,exports){

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
},{}],3:[function(require,module,exports){
const wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.utilities = require('./js/utilities')
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform

window.wmf = wmf
},{"./js/utilities":2,"wikimedia-page-library":1}]},{},[3,2]);
