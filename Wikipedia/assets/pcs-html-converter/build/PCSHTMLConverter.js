var PCSHTMLConverter =
/******/ (function(modules) { // webpackBootstrap
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
/******/ 	return __webpack_require__(__webpack_require__.s = "./PCSHTMLConverter.js");
/******/ })
/************************************************************************/
/******/ ({

/***/ "./PCSHTMLConverter.js":
/*!*****************************!*\
  !*** ./PCSHTMLConverter.js ***!
  \*****************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

var MobileHTML = __webpack_require__(/*! ./mobileapps/lib/mobile/MobileHTML */ "./mobileapps/lib/mobile/MobileHTML.js");

var MobileViewHTML = __webpack_require__(/*! ./mobileapps/lib/mobile/MobileViewHTML */ "./mobileapps/lib/mobile/MobileViewHTML.js");

function convertParsoidDocumentToMobileHTML(doc) {
  var metadata = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var mobileHTML = new MobileHTML(doc, metadata);
  mobileHTML.workSync();
  mobileHTML.finalizeSync();

  if (metadata.mw) {
    mobileHTML.addMediaWikiMetadata(metadata.mw);
  }

  return mobileHTML.doc.documentElement.outerHTML;
}

function convertParsoidHTMLToMobileHTML(parsoidHTML) {
  var metadata = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
  var parser = new DOMParser();
  var doc = parser.parseFromString(parsoidHTML, 'text/html');
  return convertParsoidDocumentToMobileHTML(doc, metadata);
}

function convertMobileViewJSONToMobileHTML(mobileViewJSON, domain, baseURI) {
  var parser = new DOMParser();
  var doc = parser.parseFromString('<html><head><meta charset="utf-8"><title></title></head><body></body></html>', 'text/html');
  var metadata = {
    domain: domain,
    baseURI: baseURI,
    mw: mwMetadataFromMobileViewJSON(mobileViewJSON)
  };
  var mobileView = mobileViewJSON.mobileview; // for some reason this is expected in both the param and in the metadata obj

  metadata.mobileview = mobileView;
  var parsoidDocument = MobileViewHTML.convertToParsoidDocument(doc, mobileView, metadata);
  return convertParsoidDocumentToMobileHTML(parsoidDocument, metadata);
}

function convertMobileSectionsJSONToMobileHTML(leadJSON, remainingJSON) {
  function getSectionHTML(section) {
    return "<section data-mw-section-id=\"" + section.id + "\">" + section.text + "</section>";
  }

  function reducer(acc, curr) {
    return acc + "\n" + getSectionHTML(curr);
  }

  var parsoidHTML = remainingJSON.sections.reduce(reducer, getSectionHTML(leadJSON.sections[0]));
  var meta = {
    mw: {
      pageid: leadJSON.id,
      ns: leadJSON.ns,
      displaytitle: leadJSON.displaytitle,
      protection: [],
      description: leadJSON.description,
      description_source: leadJSON.description_source
    }
  };
  return convertParsoidHTMLToMobileHTML(parsoidHTML, meta);
} //  *   {!array} protection
//  *   {?Object} originalimage
//  *   {!string} displaytitle
//  *   {?string} description
//  *   {?string} description_source


var mw = {
  "pageid": 4269567,
  "ns": 0,
  "title": "Dog",
  "displaytitle": "Dog",
  "contentmodel": "wikitext",
  "pagelanguage": "en",
  "pagelanguagehtmlcode": "en",
  "pagelanguagedir": "ltr",
  "touched": "2019-12-06T03:48:17Z",
  "lastrevid": 929485161,
  "length": 126950,
  "protection": [{
    "type": "edit",
    "level": "autoconfirmed",
    "expiry": "infinity"
  }, {
    "type": "move",
    "level": "sysop",
    "expiry": "infinity"
  }],
  "restrictiontypes": ["edit", "move"],
  "description": "domestic animal",
  "description_source": "central"
};

function testParsoid() {
  var url, meta, response, parsoidHTML, mobileHTML;
  return regeneratorRuntime.async(function testParsoid$(_context) {
    while (1) {
      switch (_context.prev = _context.next) {
        case 0:
          url = "https://en.wikipedia.org/api/rest_v1/page/html/Dog";
          meta = {
            baseURI: "http://localhost:6927/en.wikipedia.org/v1/",
            mw: mw
          };
          _context.next = 4;
          return regeneratorRuntime.awrap(fetch(url));

        case 4:
          response = _context.sent;
          _context.next = 7;
          return regeneratorRuntime.awrap(response.text());

        case 7:
          parsoidHTML = _context.sent;
          mobileHTML = convertParsoidHTMLToMobileHTML(parsoidHTML, meta);
          return _context.abrupt("return", mobileHTML);

        case 10:
        case "end":
          return _context.stop();
      }
    }
  });
}

function testMobileSections() {
  var leadURL, remainingURL, meta, leadResponse, remainingResponse, leadJSON, remainingJSON, mobileHTML;
  return regeneratorRuntime.async(function testMobileSections$(_context2) {
    while (1) {
      switch (_context2.prev = _context2.next) {
        case 0:
          leadURL = "https://en.wikipedia.org/api/rest_v1/page/mobile-sections-lead/Dog";
          remainingURL = "https://en.wikipedia.org/api/rest_v1/page/mobile-sections-remaining/Dog";
          meta = {
            baseURI: "http://localhost:6927/en.wikipedia.org/v1/",
            mw: mw
          };
          _context2.next = 5;
          return regeneratorRuntime.awrap(fetch(leadURL));

        case 5:
          leadResponse = _context2.sent;
          _context2.next = 8;
          return regeneratorRuntime.awrap(fetch(remainingURL));

        case 8:
          remainingResponse = _context2.sent;
          _context2.next = 11;
          return regeneratorRuntime.awrap(leadResponse.json());

        case 11:
          leadJSON = _context2.sent;
          _context2.next = 14;
          return regeneratorRuntime.awrap(remainingResponse.json());

        case 14:
          remainingJSON = _context2.sent;
          mobileHTML = convertMobileSectionsJSONToMobileHTML(leadJSON, remainingJSON, meta);
          return _context2.abrupt("return", mobileHTML);

        case 17:
        case "end":
          return _context2.stop();
      }
    }
  });
}

function mwMetadataFromMobileViewJSON(mobileViewJSON) {
  var protectionEntries = Object.entries(mobileViewJSON.mobileview.protection || {});

  var protection = function protection(e) {
    return {
      type: e[0],
      level: e[1][0],
      expiry: 'infinity'
    };
  };

  var restrictiontype = function restrictiontype(e) {
    return e[0];
  };

  return {
    "pageid": mobileViewJSON.mobileview.id,
    "ns": mobileViewJSON.mobileview.ns,
    "displaytitle": mobileViewJSON.mobileview.displaytitle,
    "contentmodel": "wikitext",
    "touched": mobileViewJSON.mobileview.lastmodified,
    "lastrevid": mobileViewJSON.mobileview.revision,
    "description": mobileViewJSON.mobileview.description,
    "description_source": mobileViewJSON.mobileview.descriptionsource,
    "protection": protectionEntries.map(protection),
    "restrictiontypes": protectionEntries.map(restrictiontype)
  };
}

function testMobileView() {
  var url, response, mobileViewJSON, domain, baseURI, mobileHTML;
  return regeneratorRuntime.async(function testMobileView$(_context3) {
    while (1) {
      switch (_context3.prev = _context3.next) {
        case 0:
          url = "https://en.wikipedia.org/w/api.php?action=mobileview&format=json&page=Dog&sections=all&prop=text%7Csections%7Clanguagecount%7Cthumb%7Cimage%7Cid%7Crevision%7Cdescription%7Cnamespace%7Cnormalizedtitle%7Cdisplaytitle%7Cprotection%7Ceditable&sectionprop=toclevel%7Cline%7Canchor&noheadings=1&thumbwidth=1024&origin=*";
          _context3.next = 3;
          return regeneratorRuntime.awrap(fetch(url));

        case 3:
          response = _context3.sent;
          _context3.next = 6;
          return regeneratorRuntime.awrap(response.json());

        case 6:
          mobileViewJSON = _context3.sent;
          domain = "en.wikipedia.org";
          baseURI = "http://localhost:6927/en.wikipedia.org/v1/";
          mobileHTML = convertMobileViewJSONToMobileHTML(mobileViewJSON, domain, baseURI);
          return _context3.abrupt("return", mobileHTML);

        case 11:
        case "end":
          return _context3.stop();
      }
    }
  });
}

module.exports = {
  convertParsoidHTMLToMobileHTML: convertParsoidHTMLToMobileHTML,
  convertMobileSectionsJSONToMobileHTML: convertMobileSectionsJSONToMobileHTML,
  convertMobileViewJSONToMobileHTML: convertMobileViewJSONToMobileHTML,
  testParsoid: testParsoid,
  testMobileView: testMobileView,
  testMobileSections: testMobileSections
}; // test

/***/ }),

/***/ "./mobileapps/lib/api-util-constants.js":
/*!**********************************************!*\
  !*** ./mobileapps/lib/api-util-constants.js ***!
  \**********************************************/
/*! no static exports found */
/***/ (function(module, exports) {

/**
 * Gets the externally visible REST API URI for the supplied domain.
 * Do not use this for actual requests made inside the DC.
 * @param {!string} domain the domain to issue the request for
 * @return {!string} the URI for externally visible RESTBase endpoints for the given domain
 */
function getExternalRestApiUri(domain) {
  return "https://".concat(domain, "/api/rest_v1/");
}

module.exports = {
  getExternalRestApiUri: getExternalRestApiUri
};

/***/ }),

/***/ "./mobileapps/lib/constants.js":
/*!*************************************!*\
  !*** ./mobileapps/lib/constants.js ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(process) {var DEFAULT_MAX_MS_PER_TICK = 100;
var maxMsPerTick = 0;

if (process.env.MAX_MS_PER_TICK) {
  maxMsPerTick = parseInt(process.env.MAX_MS_PER_TICK);
}

if (!maxMsPerTick || maxMsPerTick.isNan || maxMsPerTick <= 0) {
  maxMsPerTick = DEFAULT_MAX_MS_PER_TICK;
}

module.exports = {
  // rough maximum time in ms to run before letting the event loop continue
  MAX_MS_PER_TICK: maxMsPerTick
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../node_modules/process/browser.js */ "./node_modules/process/browser.js")))

/***/ }),

/***/ "./mobileapps/lib/domUtil.js":
/*!***********************************!*\
  !*** ./mobileapps/lib/domUtil.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var domUtil = {};
/**
 * Returns true if the nearest ancestor to the given element has a class set for Right-to-Left mode,
 * false otherwise.
 * @param {!Element} element a DOM element
 * @return {!boolean}
 */

domUtil.isRTL = function (element) {
  var closestDirectionalAncestor = element.closest('[dir]');

  if (closestDirectionalAncestor) {
    return closestDirectionalAncestor.getAttribute('dir') === 'rtl';
  }

  return false;
};
/**
 * Gets the base URI from a Parsoid document
 * <base href="//en.wikipedia.org/wiki/"/>
 * @param {!Document} doc Parsoid DOM document
 * @return {?string} Example: '//en.wikipedia.org/wiki/' or undefined
 */


domUtil.getBaseUri = function (doc) {
  var base = doc.head.querySelector('base');
  return base && base.getAttribute('href');
};
/**
 * Gets the absolute https base URI from a Parsoid document
 * <base href="//en.wikipedia.org/wiki/"/>
 * @param {!Document} doc Parsoid DOM document
 * @return {?string} Example: 'https://en.wikipedia.org/wiki/' or undefined
 */


domUtil.getHttpsBaseUri = function (doc) {
  var baseUri = domUtil.getBaseUri(doc);
  return baseUri && baseUri.startsWith('http') ? baseUri : "https:".concat(baseUri);
};
/**
 * Gets the plain, normalized title of the current page from a Parsoid document. This title string
 * may have spaces but no HTML tags.
 * Example: given a Parsoid document with
 * <title>Wreck-It Ralph</title>
 * @param {!Document} doc Parsoid DOM document
 * @return {?string} normalized title or undefined
 */


domUtil.getParsoidPlainTitle = function (doc) {
  var title = doc.head.querySelector('title');
  return title && title.textContent;
};
/**
 * Gets the title of the current page from a Parsoid document. This title string usually differs
 * from normalized titles in that it has spaces replaced with underscores.
 * Example: given a Parsoid document with
 * <link rel="dc:isVersionOf" href="//en.wikipedia.org/wiki/Hope_(painting)"/> and
 * <base href="//en.wikipedia.org/wiki/"/> this function returns the string 'Hope_(painting)'.
 * @param {!Document} doc Parsoid DOM document
 * @return {?string} Example: 'Hope_(painting)' or undefined
 */


domUtil.getParsoidLinkTitle = function (doc) {
  var link = doc.head.querySelector('link[rel="dc:isVersionOf"]');

  if (!link) {
    return;
  }

  var href = link.getAttribute('href');
  var baseUri = domUtil.getBaseUri(doc);
  var title = href.replace(baseUri, '');

  try {
    return decodeURIComponent(title);
  } catch (e) {
    // Update the error message to include the faulty base URI (T240274)
    e.message = "".concat(e.message, ": ").concat(title);
    throw e;
  }
};

module.exports = domUtil;

/***/ }),

/***/ "./mobileapps/lib/html/DocumentWorker.js":
/*!***********************************************!*\
  !*** ./mobileapps/lib/html/DocumentWorker.js ***!
  \***********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(setImmediate) {function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

var P = __webpack_require__(/*! bluebird */ "./mobileapps/node_modules/bluebird/js/browser/bluebird.js");

var constants = __webpack_require__(/*! ../constants */ "./mobileapps/lib/constants.js");
/**
 * DocumentWorker walks a Document tree to perform processing
 * @param {!Document} doc Parsoid document
 * @param {?DOMNode} node to walk
 */


var DocumentWorker =
/*#__PURE__*/
function () {
  function DocumentWorker(doc, node) {
    _classCallCheck(this, DocumentWorker);

    this.doc = doc;
    this.treeWalker = doc.createTreeWalker(node || doc);
  }
  /**
   * Return a promise for the processed and finalized worker
   * @return {!Promise}
   */


  _createClass(DocumentWorker, [{
    key: "process",

    /**
     * Process a given node. Subclassers should override this method
     * @param {!DOMNode} node
     */
    value: function process(node) {}
    /**
     * Perform the next finalization step. Subclassers should override this method
     * @return {!boolean} whether or not there are  more steps
     */

  }, {
    key: "finalizeStep",
    value: function finalizeStep() {}
    /**
     * Process the document for a given interval
     * @param {!limit} limit in ms for processing or -1 for no limit
     */

  }, {
    key: "workFor",
    value: function workFor(limit) {
      var node;
      var finished = true;
      var start = Date.now();

      while (node = this.treeWalker.nextNode()) {
        this.process(node);

        if (limit !== -1 && Date.now() - start >= limit) {
          finished = false;
          break;
        }
      }

      return finished;
    }
    /**
     * Process the entire document synchronously
     */

  }, {
    key: "workSync",
    value: function workSync() {
      this.workFor(-1);
    }
    /**
     * Process the entire document, taking a break with setImmediate after roughly the given interval
     * @param {!limit} limit in ms for processing or -1 for no limit
     * @param {!function} done to call when done
     */

  }, {
    key: "work",
    value: function work(limit, done) {
      var _this = this;

      if (this.workFor(limit)) {
        setImmediate(function () {
          done();
        });
      } else {
        setImmediate(function () {
          _this.work(limit, done);
        });
      }
    }
    /**
     * Finalize the document for a given interval
     * @param {!limit} limit in ms for processing or -1 for no limit
     */

  }, {
    key: "finalizeFor",
    value: function finalizeFor(limit) {
      var node;
      var finished = true;
      var start = Date.now();

      while (this.finalizeStep()) {
        if (limit !== -1 && Date.now() - start >= limit) {
          finished = false;
          break;
        }
      }

      return finished;
    }
    /**
     * Finalize synchronously
     */

  }, {
    key: "finalizeSync",
    value: function finalizeSync() {
      this.finalizeFor(-1);
    }
    /**
     * Finalize the work
     * @param {!limit} limit in ms for processing or -1 for no limit
     * @param {!function} done to call when done
     */

  }, {
    key: "finalize",
    value: function finalize(limit, done) {
      var _this2 = this;

      if (this.finalizeFor(limit)) {
        setImmediate(function () {
          done();
        });
      } else {
        setImmediate(function () {
          _this2.finalize(limit, done);
        });
      }
    }
  }, {
    key: "promise",
    get: function get() {
      var _this3 = this;

      var limit = constants.MAX_MS_PER_TICK;
      return new P(function (res) {
        _this3.work(limit, function () {
          _this3.finalize(limit, function () {
            res(_this3);
          });
        });
      });
    }
  }]);

  return DocumentWorker;
}();

module.exports = DocumentWorker;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../../node_modules/timers-browserify/main.js */ "./node_modules/timers-browserify/main.js").setImmediate))

/***/ }),

/***/ "./mobileapps/lib/mobile/MobileHTML.js":
/*!*********************************************!*\
  !*** ./mobileapps/lib/mobile/MobileHTML.js ***!
  \*********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

var P = __webpack_require__(/*! bluebird */ "./mobileapps/node_modules/bluebird/js/browser/bluebird.js");

var DocumentWorker = __webpack_require__(/*! ../html/DocumentWorker */ "./mobileapps/lib/html/DocumentWorker.js");

var thumbnail = __webpack_require__(/*! ../thumbnail */ "./mobileapps/lib/thumbnail.js");

var NodeType = __webpack_require__(/*! ../nodeType */ "./mobileapps/lib/nodeType.js");

var domUtil = __webpack_require__(/*! ../domUtil */ "./mobileapps/lib/domUtil.js");

var pagelib = __webpack_require__(/*! ../../pagelib/build/wikimedia-page-library-transform */ "./mobileapps/pagelib/build/wikimedia-page-library-transform.js");

var Edit = pagelib.EditTransform;
var WidenImage = pagelib.WidenImage;
var LazyLoad = pagelib.LazyLoadTransform;
var Table = pagelib.CollapseTable;
var LeadIntroduction = pagelib.LeadIntroductionTransform;

var constants = __webpack_require__(/*! ./MobileHTMLConstants */ "./mobileapps/lib/mobile/MobileHTMLConstants.js");

var head = __webpack_require__(/*! ../transformations/pcs/head */ "./mobileapps/lib/transformations/pcs/head.js");

var addPageHeader = __webpack_require__(/*! ../transformations/pcs/addPageHeader */ "./mobileapps/lib/transformations/pcs/addPageHeader.js");

var parseProperty = __webpack_require__(/*! ../parseProperty */ "./mobileapps/lib/parseProperty.js");
/**
 * MobileHTML is the prepareor for mobile html output.
 * It handles the expensive transforms that need to be
 * applied to a Parsoid document in preparation for mobile display,
 * @param {!Document} doc Parsoid document to process
 */


var MobileHTML =
/*#__PURE__*/
function (_DocumentWorker) {
  _inherits(MobileHTML, _DocumentWorker);

  _createClass(MobileHTML, [{
    key: "prepareElement",

    /**
     * prepareElement receives every element as it is iterated
     * over and performs the required transforms. The DOM should
     * not be manipulated inside of this method. Instead, save
     * items for manipulation and perform the manipulation in
     * finalize
     * @param {!Element} element element to process
     */
    value: function prepareElement(element) {
      var id = element.getAttribute('id');
      var tagName = element.tagName;
      var cls = element.getAttribute('class');

      if (this.isRemovableElement(element, tagName, id, cls)) {
        // save here to manipulate the dom later
        this.markForRemoval(element);
      } else if (this.isReference(element)) {
        // save here to manipulate the dom later
        this.referenceElements.push(element);
      } else {
        switch (tagName) {
          case 'A':
            this.prepareAnchor(element, cls);
            break;

          case 'LINK':
            this.makeSchemeless(element, 'href');
            break;

          case 'SCRIPT':
          case 'SOURCE':
            this.makeSchemeless(element, 'src');
            break;

          case 'SECTION':
            this.currentSectionId = element.getAttribute('data-mw-section-id'); // save for later due to DOM manipulation

            this.sections[this.currentSectionId] = element;
            break;

          case 'IMG':
            this.prepareImage(element);
            break;

          case 'DIV':
            this.prepareDiv(element, cls);
            break;

          case 'TABLE':
            // Images in tables should not be widened
            this.widenImageExcludedNode = element;
            this.prepareTable(element, cls);
            break;

          default:
            if (!this.headers[this.currentSectionId] && constants.headerTagRegex.test(tagName)) {
              this.headers[this.currentSectionId] = element;
            }

            break;
        }

        if (!this.widenImageExcludedNode && constants.widenImageExclusionClassRegex.test(cls)) {
          this.widenImageExcludedNode = element;
        }

        if (this.themeExcludedNode) {
          element.classList.add('notheme');
        } else {
          var style = element.getAttribute('style');

          if (style && constants.inlineBackgroundStyleRegex.test(style)) {
            this.themeExcludedNode = element;
            element.classList.add('notheme');
          }
        }

        var attributesToRemove = constants.attributesToRemoveFromElements[tagName];

        if (attributesToRemove) {
          var _iteratorNormalCompletion = true;
          var _didIteratorError = false;
          var _iteratorError = undefined;

          try {
            for (var _iterator = attributesToRemove[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
              var attrib = _step.value;
              element.removeAttribute(attrib);
            }
          } catch (err) {
            _didIteratorError = true;
            _iteratorError = err;
          } finally {
            try {
              if (!_iteratorNormalCompletion && _iterator.return != null) {
                _iterator.return();
              }
            } finally {
              if (_didIteratorError) {
                throw _iteratorError;
              }
            }
          }
        }

        if (id && constants.mwidRegex.test(id)) {
          element.removeAttribute('id');
        }
      }
    }
    /**
     * Run the next finalization step. All of the DOM manipulation occurs here because
     * manipulating the DOM while walking it will result in an incomplete walk.
     */

  }, {
    key: "finalizeStep",
    value: function finalizeStep() {
      var node;
      node = this.nodesToRemove.pop();

      if (node) {
        var ancestor = node.parentNode;

        if (ancestor) {
          ancestor.removeChild(node);
        }

        return true;
      }

      node = this.referenceElements.pop();

      if (node) {
        this.prepareReference(node, this.doc);
        return true;
      }

      node = this.infoboxes.pop();

      if (node) {
        this.prepareInfobox(node);
        return true;
      }

      node = this.redLinks.pop();

      if (node) {
        this.prepareRedLink(node, this.doc);
        return true;
      }

      node = this.lazyLoadableImages.pop();

      if (node) {
        LazyLoad.convertImageToPlaceholder(this.doc, node);
        return true;
      }

      if (!this.sectionIds) {
        this.sectionIds = Object.keys(this.sections);
      }

      var sectionId = this.sectionIds.pop();

      if (sectionId) {
        this.prepareSection(sectionId);
        return true;
      }

      var pcs = this.doc.createElement('div');
      pcs.setAttribute('id', 'pcs');
      var body = this.doc.body;
      var children = Array.from(body.children);

      for (var _i = 0, _children = children; _i < _children.length; _i++) {
        var child = _children[_i];
        pcs.appendChild(child);
      }

      body.appendChild(pcs);
      head.addCssLinks(this.doc, this.metadata);
      head.addMetaViewport(this.doc);
      head.addPageLibJs(this.doc, this.metadata);
      return false;
    }
    /**
     * Returns a MobileHTML object ready for processing
     * @param {!Document} doc document to process
     * @param {?Object} metadata metadata object that should include:
     *   {!string} baseURI the baseURI for the REST API
     *   {!string} revision the revision of the page
     *   {!string} tid the tid of the page
     */

  }]);

  function MobileHTML(doc, metadata) {
    var _this;

    _classCallCheck(this, MobileHTML);

    _this = _possibleConstructorReturn(this, _getPrototypeOf(MobileHTML).call(this, doc));

    _this.prepareDoc(doc);

    _this.nodesToRemove = [];
    _this.referenceElements = [];
    _this.lazyLoadableImages = [];
    _this.redLinks = [];
    _this.infoboxes = [];
    _this.headers = {};
    _this.sections = {};
    _this.currentSectionId = 0;
    _this.metadata = metadata || {};
    _this.metadata.pronunciation = parseProperty.parsePronunciation(doc);
    _this.metadata.linkTitle = domUtil.getParsoidLinkTitle(doc);
    _this.metadata.plainTitle = domUtil.getParsoidPlainTitle(doc);
    return _this;
  }
  /**
   * Adds metadata to the resulting document
   * @param {?Object} mw metadata from MediaWiki with:
   *   {!array} protection
   *   {?Object} originalimage
   *   {!string} displaytitle
   *   {?string} description
   *   {?string} description_source
   */


  _createClass(MobileHTML, [{
    key: "addMediaWikiMetadata",
    value: function addMediaWikiMetadata(mw) {
      this.metadata.mw = mw;
      head.addMetaTags(this.doc, this.metadata);
      addPageHeader(this.doc, this.metadata);
    }
    /**
     * Returns a promise that is fufilled when processing completes
     * See `constructor` for parameter documentation
     */

  }, {
    key: "process",

    /**
     * Run the next processing step.
     * @param {!DOMNode} node to process
     */
    value: function process(node) {
      while (this.ancestor && this.ancestor !== node.parentNode) {
        if (this.ancestor === this.themeExcludedNode) {
          this.themeExcludedNode = undefined;
        }

        if (this.ancestor === this.currentInfobox) {
          this.currentInfobox = undefined;
        }

        if (this.ancestor === this.widenImageExcludedNode) {
          this.widenImageExcludedNode = undefined;
        }

        this.ancestor = this.ancestor.parentNode;
      }

      if (node.nodeType === NodeType.ELEMENT_NODE) {
        this.prepareElement(node);
      } else if (node.nodeType === NodeType.COMMENT_NODE) {
        this.markForRemoval(node);
      }

      this.ancestor = node;
    } // Specific processing:

  }, {
    key: "markForRemoval",
    value: function markForRemoval(node) {
      this.nodesToRemove.push(node);
    }
  }, {
    key: "isReference",
    value: function isReference(node) {
      return node.getAttribute('typeof') === 'mw:Extension/references';
    }
  }, {
    key: "copyAttribute",
    value: function copyAttribute(src, dest, attr) {
      var value = src.getAttribute(attr);

      if (value !== null) {
        dest.setAttribute(attr, value);
      }
    }
  }, {
    key: "prepareSection",
    value: function prepareSection(sectionId) {
      var section = this.sections[sectionId];

      if (sectionId <= 0) {
        LeadIntroduction.moveLeadIntroductionUp(this.doc, section);
      }

      var header = this.headers[sectionId];
      this.prepareSectionHeader(header, section, sectionId, this.doc);
      var foundNonRefListSection = false;
      var cur = section.firstElementChild;

      while (cur) {
        if (!(cur.classList.contains('reflist') || cur.classList.contains('pcs-edit-esection-eheader'))) {
          foundNonRefListSection = true;
          break;
        }

        cur = cur.nextElementSibling;
      }

      if (!foundNonRefListSection) {
        section.classList.add('pcs-hide-esection');
      }
    }
  }, {
    key: "prepareDoc",
    value: function prepareDoc(doc) {
      var body = doc.body;
      body.classList.add('content');
      Edit.setEditButtons(doc, false, false);
    }
  }, {
    key: "prepareReference",
    value: function prepareReference(element, doc) {
      var placeholder = doc.createElement('div');
      placeholder.classList.add('mw-references-placeholder');
      this.copyAttribute(element, placeholder, 'about');
      element.parentNode.replaceChild(placeholder, element);
    }
  }, {
    key: "prepareRedLink",
    value: function prepareRedLink(element, doc) {
      var span = doc.createElement('span');
      span.innerHTML = element.innerHTML;
      span.setAttribute('class', element.getAttribute('class'));
      element.parentNode.replaceChild(span, element);
    }
  }, {
    key: "prepareSectionHeader",
    value: function prepareSectionHeader(header, section, sectionId, doc) {
      var headerWrapper;

      if (header) {
        headerWrapper = Edit.newEditSectionWrapper(doc, sectionId, header);

        if (header.parentNode === section) {
          section.insertBefore(headerWrapper, header);
        } else if (section.firstChild) {
          section.insertBefore(headerWrapper, section.firstChild);
        }

        Edit.appendEditSectionHeader(headerWrapper, header);
      }

      var href = this.metadata.linkTitle ? "/w/index.php?title=".concat(this.metadata.linkTitle, "&action=edit&section=").concat(sectionId) : '';
      var link = Edit.newEditSectionLink(doc, sectionId, href);
      var button = Edit.newEditSectionButton(doc, sectionId, link);

      if (headerWrapper) {
        headerWrapper.appendChild(button);
      }
    }
  }, {
    key: "isRemovableSpan",
    value: function isRemovableSpan(span, classList) {
      if (!span.firstChild) {
        return true;
      }

      if (this.isElementWithForbiddenClass(span, classList, constants.forbiddenSpanClasses)) {
        return true;
      }

      if (constants.bracketSpanRegex.test(span.text)) {
        return true;
      }

      return false;
    }
  }, {
    key: "isRemovableDiv",
    value: function isRemovableDiv(div, classList) {
      if (this.isElementWithForbiddenClass(div, classList, constants.forbiddenDivClasses)) {
        return true;
      }

      return false;
    }
  }, {
    key: "isElementWithForbiddenClass",
    value: function isElementWithForbiddenClass(element, classList, classes) {
      var substrings = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : [];
      var failed = false;

      if (!classList) {
        return false;
      }

      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = substrings[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var string = _step2.value;

          if (classList.includes(string)) {
            failed = true;
            break;
          }
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return != null) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }

      if (!failed) {
        var split = classList.split(' ');
        var _iteratorNormalCompletion3 = true;
        var _didIteratorError3 = false;
        var _iteratorError3 = undefined;

        try {
          for (var _iterator3 = split[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
            var cls = _step3.value;

            if (classes.has(cls)) {
              failed = true;
              break;
            }
          }
        } catch (err) {
          _didIteratorError3 = true;
          _iteratorError3 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion3 && _iterator3.return != null) {
              _iterator3.return();
            }
          } finally {
            if (_didIteratorError3) {
              throw _iteratorError3;
            }
          }
        }
      }

      return failed;
    }
  }, {
    key: "isRemovableLink",
    value: function isRemovableLink(element) {
      return element.getAttribute('rel') !== 'dc:isVersionOf';
    }
  }, {
    key: "isRemovableElement",
    value: function isRemovableElement(element, tagName, id, classList) {
      if (constants.forbiddenElementIDs.has(id)) {
        return true;
      }

      if (this.isElementWithForbiddenClass(element, classList, constants.forbiddenElementClasses, constants.forbiddenElementClassSubstrings)) {
        return true;
      }

      switch (tagName) {
        case 'DIV':
          return this.isRemovableDiv(element, classList);

        case 'SPAN':
          return this.isRemovableSpan(element, classList);

        case 'LINK':
          return this.isRemovableLink(element);

        default:
          return false;
      }
    }
  }, {
    key: "makeSchemeless",
    value: function makeSchemeless(element, attrib) {
      var value = element.getAttribute(attrib);

      if (!value) {
        return;
      }

      var schemelessValue = value.replace(constants.httpsRegex, '//');
      element.setAttribute(attrib, schemelessValue);
    }
  }, {
    key: "isGalleryImage",
    value: function isGalleryImage(image) {
      return image.width >= 128;
    }
  }, {
    key: "prepareImage",
    value: function prepareImage(image) {
      thumbnail.scaleElementIfNecessary(image);

      if (this.isGalleryImage(image)) {
        // Imagemaps, which expect images to be specific sizes, should not be widened.
        // Examples can be found on 'enwiki > Kingdom (biology)':
        //    - first non lead image is an image map
        //    - 'Three domains of life > Phylogenetic Tree of Life' image is an image map
        if (!this.widenImageExcludedNode && !image.hasAttribute('usemap')) {
          // Wrap in a try-catch block to avoid Domino crashing on a malformed style declaration.
          // T238700 which looks the same as T229521
          try {
            WidenImage.widenImage(image);
          } catch (e) {}
        }

        this.lazyLoadableImages.push(image);
      }
    }
  }, {
    key: "prepareAnchor",
    value: function prepareAnchor(element, cls) {
      if (constants.newClassRegex.test(cls)) {
        this.redLinks.push(element);
      }

      var rel = element.getAttribute('rel');

      if (rel !== 'nofollow' && rel !== 'mw:ExtLink') {
        element.removeAttribute('rel');
      }

      this.makeSchemeless(element, 'href');
    }
  }, {
    key: "prepareInfobox",
    value: function prepareInfobox(infobox) {
      var node = infobox.element;
      var isInfoBox = infobox.isInfoBox;
      /* TODO: I18N these strings */

      var pageTitle = this.metadata.plainTitle;
      var title = isInfoBox ? 'Quick facts' : 'More information';
      var footerTitle = 'Close';
      var boxClass = isInfoBox ? Table.CLASS.TABLE_INFOBOX : Table.CLASS.TABLE_OTHER;
      var headerText = Table.getTableHeaderTextArray(this.doc, node, pageTitle);

      if (!headerText.length && !isInfoBox) {
        return;
      }

      Table.prepareTable(node, this.doc, pageTitle, title, boxClass, headerText, footerTitle);
    }
  }, {
    key: "markInfobox",
    value: function markInfobox(element, cls, isDiv) {
      if (this.currentInfobox) {
        return;
      }

      var isInfoBox = constants.infoboxClassRegex.test(cls);

      if (isDiv && !isInfoBox) {
        return;
      }

      if (constants.infoboxClassExclusionRegex.test(cls)) {
        return;
      }

      var isHidden; // Wrap in a try-catch block to avoid Domino crashing on a malformed style declaration.
      // T229521

      try {
        isHidden = element.style.display === 'none';
      } catch (e) {
        // If Domino fails to parse styles, err on the safe side and don't transform
        isHidden = true;
      }

      if (isHidden) {
        return;
      }

      this.currentInfobox = element;
      this.infoboxes.push({
        element: element,
        isInfoBox: isInfoBox
      });
    }
  }, {
    key: "prepareDiv",
    value: function prepareDiv(element, cls) {
      this.markInfobox(element, cls, true);
    }
  }, {
    key: "prepareTable",
    value: function prepareTable(element, cls) {
      this.markInfobox(element, cls, false);
    }
  }], [{
    key: "promise",
    value: function promise(doc) {
      var metadata = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
      var mobileHTML = new MobileHTML(doc, metadata);
      return mobileHTML.promise;
    }
  }]);

  return MobileHTML;
}(DocumentWorker);

module.exports = MobileHTML;

/***/ }),

/***/ "./mobileapps/lib/mobile/MobileHTMLConstants.js":
/*!******************************************************!*\
  !*** ./mobileapps/lib/mobile/MobileHTMLConstants.js ***!
  \******************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

var constants = {};
constants.forbiddenElementClassSubstrings = new Set(['nomobile', 'navbox']);
constants.forbiddenElementClasses = new Set(['geo-nondefault', 'geo-multi-punct', 'hide-when-compact']);
constants.forbiddenElementIDs = new Set(['coordinates']);
constants.forbiddenDivClasses = new Set(['infobox', 'magnify']);
constants.forbiddenSpanClasses = new Set(['Z3988']);
constants.attributesToRemoveFromElements = {
  A: ['about', 'data-mw', 'typeof'],
  ABBR: ['title'],
  B: ['about', 'data-mw', 'typeof'],
  BLOCKQUOTE: ['about', 'data-mw', 'typeof'],
  BR: ['about', 'data-mw', 'typeof'],
  CITE: ['about', 'data-mw', 'typeof'],
  CODE: ['about', 'data-mw', 'typeof'],
  DIV: ['data-mw', 'typeof'],
  FIGURE: ['typeof'],
  'FIGURE-INLINE': ['about', 'data-file-type', 'data-mw', 'itemscope', 'itemtype', 'lang', 'rel', 'title', 'typeof'],
  I: ['about', 'data-mw', 'typeof'],
  IMG: ['about', 'alt', 'resource'],
  LI: ['about'],
  LINK: ['data-mw', 'typeof'],
  OL: ['about', 'data-mw', 'typeof'],
  P: ['data-mw', 'typeof'],
  SPAN: ['about', 'data-file-type', 'data-mw', 'itemscope', 'itemtype', 'lang', 'rel', 'title', 'typeof'],
  STYLE: ['about', 'data-mw'],
  SUP: ['about', 'data-mw', 'rel', 'typeof'],
  TABLE: ['about', 'data-mw', 'typeof'],
  UL: ['about', 'data-mw', 'typeof']
}; // TODO: Add tests for these regexes when output is finalized

constants.mwidRegex = /^mw[\w-]{2,3}$/;
constants.httpsRegex = /^https:\/\//;
constants.headerTagRegex = /^H[0-9]$/;
constants.bracketSpanRegex = /^(\[|\])$/;
constants.inlineBackgroundStyleRegex = /(?:^|\s|;)background(?:-color)?:\s*(?!(?:transparent)|(?:none)|(?:inherit)|(?:unset)|(?:#?$)|(?:#?;))/;
constants.infoboxClassRegex = /(?:^|\s)infobox(?:_v3)?(?:\s|$)/;
constants.infoboxClassExclusionRegex = /(?:^|\s)(?:metadata)|(?:mbox-small)(?:\s|$)/i;
constants.newClassRegex = /(?:^|\s)new(?:\s|$)/;
/**
 * Images within a "<div class='noresize'>...</div>" should not be widened.
 * Example exhibiting links overlaying such an image:
 *  'enwiki > Counties of England > Scope and structure > Local government'
 * Side-by-side images should not be widened. Often their captions mention 'left' and 'right', so
 * we don't want to widen these as doing so would stack them vertically.
 * Examples exhibiting side-by-side images:
 *  'enwiki > Cold Comfort (Inside No. 9) > Casting'
 *  'enwiki > Vincent van Gogh > Letters'
*/

constants.widenImageExclusionClassRegex = /(?:tsingle)|(?:noresize)|(?:noviewer)/;
module.exports = constants;

/***/ }),

/***/ "./mobileapps/lib/mobile/MobileViewHTML.js":
/*!*************************************************!*\
  !*** ./mobileapps/lib/mobile/MobileViewHTML.js ***!
  \*************************************************/
/*! no static exports found */
/***/ (function(module, exports) {

var TEXT_DIRECTION = 'ltr';
/**
 * Creates a single meta element with property and content
 * @param {!Document} document DOM document
 * @param {!string} property name of the meta property
 * @param {!string} content value of the meta property
 * @return {void}
 */

function createMetaElement(document, property, content) {
  var element = document.createElement('meta');
  element.setAttribute('property', property);
  element.setAttribute('content', content);
  return element;
}
/**
 * Adds a single link to a CSS stylesheet to html/head
 * @param {Document} document DOM document
 * @param {!object} mobileview response body from action=mobileview
 * @param {!object} metadata metadata object with the following properties:
 *   {?string} baseURI base URI for common links
 *   {?string} domain domain name of wiki
 *   {?object} mw mediawiki metadata
 * @return {void}
 */


function addParsoidHead(document, mobileview, metadata) {
  var normalizedtitle = metadata && metadata.mw && metadata.mw.normalizedtitle;

  if (mobileview) {
    document.documentElement.setAttribute('about', "http://".concat(metadata.domain, "/wiki/Special:Redirect/revision/").concat(mobileview.revision));
  }

  var charset = document.createElement('meta');
  charset.setAttribute('charset', 'utf-8');
  var head = document.head;

  if (!head) {
    return;
  }

  head.appendChild(createMetaElement(document, 'mw:pageNamespace', mobileview.ns));
  head.appendChild(createMetaElement(document, 'mw:pageId', mobileview.id));
  head.appendChild(createMetaElement(document, 'dc:modified', mobileview.lastmodified));
  var isVersionOf = document.createElement('link');
  isVersionOf.setAttribute('rel', 'dc:isVersionOf');
  isVersionOf.setAttribute('href', "//".concat(metadata.domain, "/wiki/").concat(encodeURIComponent(normalizedtitle)));
  head.appendChild(isVersionOf);
  head.querySelector('title').innerHTML = mobileview.displaytitle;
  var base = document.createElement('base');
  base.setAttribute('href', "//".concat(metadata.domain, "/wiki/"));
  head.appendChild(base);
}

function wrapImagesInFigureElements(document) {
  Array.from(document.querySelectorAll('a.image')).forEach(function (imageLink) {
    var figureElement = document.createElement('figure');
    figureElement.className = 'mw-default-size';
    figureElement.innerHTML = imageLink.outerHTML;
    imageLink.parentNode.replaceChild(figureElement, imageLink);
  });
}

function createHeadingHTML(document, section) {
  var level = section.toclevel + 1;
  return "<h".concat(level, " id=\"").concat(section.anchor, "\">").concat(section.line, "</h").concat(level, ">");
}

function buildSection(document, section) {
  var element = document.createElement('section');
  element.setAttribute('data-mw-section-id', section.id);

  if (section.id === 0) {
    element.setAttribute('id', 'content-block-0');
    element.innerHTML = section.text;
  } else {
    element.innerHTML = "".concat(createHeadingHTML(document, section)).concat(section.text);
  }

  return element;
}
/**
 * Opposite of rewriteUrlAttribute
 */


function rewriteWikiLinks(element, selector) {
  var ps = element.querySelectorAll(selector) || [];

  for (var _len = arguments.length, attributes = new Array(_len > 2 ? _len - 2 : 0), _key = 2; _key < _len; _key++) {
    attributes[_key - 2] = arguments[_key];
  }

  var _loop = function _loop(idx) {
    var node = ps[idx];
    attributes.forEach(function (attribute) {
      var value = node.getAttribute(attribute);

      if (value) {
        value = value.replace(/^\/wiki\//, './');
        node.setAttribute(attribute, value);
      }
    });
  };

  for (var idx = 0; idx < ps.length; idx++) {
    _loop(idx);
  }
}
/**
 * Scan the DOM for reference lists and wrap them in a div to be closer to the Parsoid DOM.
 * @param {!Document} document
 */


function wrapReferenceListsLikeParsoid(document) {
  var mwtCounter = 1000;
  var refLists = document.querySelectorAll('ol.references');
  var _iteratorNormalCompletion = true;
  var _didIteratorError = false;
  var _iteratorError = undefined;

  try {
    for (var _iterator = refLists[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
      var refList = _step.value;
      // add the mw-references class
      refList.classList.add('mw-references'); // wrap in inner DIV

      var wrapInner = document.createElement('DIV');
      wrapInner.classList.add('mw-references-wrap');
      wrapInner.setAttribute('typeof', 'mw:Extension/references');
      wrapInner.setAttribute('about', "#mwt".concat(mwtCounter++));
      refList.parentNode.replaceChild(wrapInner, refList);
      wrapInner.appendChild(refList);
    }
  } catch (err) {
    _didIteratorError = true;
    _iteratorError = err;
  } finally {
    try {
      if (!_iteratorNormalCompletion && _iterator.return != null) {
        _iterator.return();
      }
    } finally {
      if (_didIteratorError) {
        throw _iteratorError;
      }
    }
  }
}
/**
 * Creates a Parsoid document from the MobileView response
 * @param {!Document} document DOM document to insert into
 * @param {!object} mobileview mobileview response
 * @param {!object} metadata metadata object with the following properties:
 *   {?string} baseURI base URI for common links
 *   {?string} domain domain name of wiki
 *   {?object} mw mediawiki metadata
 * @return {void}
 */


function convertToParsoidDocument(document, mobileview, metadata) {
  addParsoidHead(document, mobileview, metadata);
  var content = document.body; // add dir property T229984

  content.setAttribute('dir', TEXT_DIRECTION);
  var _iteratorNormalCompletion2 = true;
  var _didIteratorError2 = false;
  var _iteratorError2 = undefined;

  try {
    for (var _iterator2 = mobileview.sections[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
      var section = _step2.value;
      content.appendChild(buildSection(document, section));
    }
  } catch (err) {
    _didIteratorError2 = true;
    _iteratorError2 = err;
  } finally {
    try {
      if (!_iteratorNormalCompletion2 && _iterator2.return != null) {
        _iterator2.return();
      }
    } finally {
      if (_didIteratorError2) {
        throw _iteratorError2;
      }
    }
  }

  rewriteWikiLinks(content, 'a', 'href');
  wrapImagesInFigureElements(document);
  wrapReferenceListsLikeParsoid(document);
  return document;
}

module.exports = {
  convertToParsoidDocument: convertToParsoidDocument,
  testing: {
    buildSection: buildSection,
    rewriteWikiLinks: rewriteWikiLinks,
    wrapImagesInFigureElements: wrapImagesInFigureElements
  }
};

/***/ }),

/***/ "./mobileapps/lib/mwapi-constants.js":
/*!*******************************************!*\
  !*** ./mobileapps/lib/mwapi-constants.js ***!
  \*******************************************/
/*! no static exports found */
/***/ (function(module, exports) {

var mwapi = {};
mwapi.CARD_THUMB_LIST_ITEM_SIZE = 320;
mwapi.CARD_THUMB_FEATURE_SIZE = 640;
mwapi.LEAD_IMAGE_S = 320;
mwapi.LEAD_IMAGE_M = 640;
mwapi.LEAD_IMAGE_L = 800;
mwapi.LEAD_IMAGE_XL = 1024;
module.exports = mwapi;

/***/ }),

/***/ "./mobileapps/lib/nodeType.js":
/*!************************************!*\
  !*** ./mobileapps/lib/nodeType.js ***!
  \************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
 // Node type constants
// https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType

module.exports = {
  ELEMENT_NODE: 1,
  // ATTRIBUTE_NODE              :  2, // deprecated
  TEXT_NODE: 3,
  // CDATA_SECTION_NODE          :  4, // deprecated
  // ENTITY_REFERENCE_NODE       :  5, // deprecated
  // ENTITY_NODE                 :  6, // deprecated
  PROCESSING_INSTRUCTION_NODE: 7,
  COMMENT_NODE: 8,
  DOCUMENT_NODE: 9,
  DOCUMENT_TYPE_NODE: 10,
  DOCUMENT_FRAGMENT_NODE: 11 // NOTATION_NODE               : 12  // deprecated

};

/***/ }),

/***/ "./mobileapps/lib/parseProperty.js":
/*!*****************************************!*\
  !*** ./mobileapps/lib/parseProperty.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Common DOM transformations for mobile apps.
 * We rearrange some content and remove content that is not shown/needed.
 */


var PronunciationParentSelector = __webpack_require__(/*! ./selectors */ "./mobileapps/lib/selectors.js").PronunciationParentSelector;

var PronunciationSelector = __webpack_require__(/*! ./selectors */ "./mobileapps/lib/selectors.js").PronunciationSelector;

var SpokenWikipediaId = __webpack_require__(/*! ./selectors */ "./mobileapps/lib/selectors.js").SpokenWikipediaId;

function parsePronunciation(doc) {
  var parent = doc.querySelector(PronunciationParentSelector);

  if (!parent) {
    return;
  }

  var pronunciationAnchor = parent.parentNode.querySelector(PronunciationSelector);
  var url = pronunciationAnchor && pronunciationAnchor.getAttribute('href');
  return url && {
    url: url
  };
}
/**
 * Get any spoken Wikipedia files in the article.
 * https://en.wikipedia.org/wiki/Wikipedia:WikiProject_Spoken_Wikipedia/Template_guidelines
 */


function parseSpokenWikipedia(doc) {
  var spokenSectionDiv = doc.querySelector("div".concat(SpokenWikipediaId));
  var result;

  if (spokenSectionDiv) {
    var dataMW = spokenSectionDiv.getAttribute('data-mw');
    var parsedData = dataMW && JSON.parse(dataMW);
    var firstPart = parsedData && parsedData.parts[0];
    var template = firstPart && firstPart.template;
    var target = template && template.target;

    if (target && target.wt) {
      var fileName;

      if (target.wt === 'Spoken Wikipedia') {
        // single audio file: use first param (2nd param is recording date)
        fileName = "File:".concat(template.params['1'].wt);
        result = {
          files: [fileName]
        };
      } else {
        var match = /Spoken Wikipedia-([2-5])/.exec(target.wt);

        if (match) {
          // multiple audio files: skip first param (recording date)
          var keyLength = Object.keys(template.params).length;
          result = {
            files: []
          };

          for (var key = 2; key <= keyLength; key++) {
            fileName = "File:".concat(template.params[key].wt);
            result.files.push(fileName);
          }
        }
      }
    }
  }

  return result;
}

module.exports = {
  parsePronunciation: parsePronunciation,
  parseSpokenWikipedia: parseSpokenWikipedia
};

/***/ }),

/***/ "./mobileapps/lib/selectors.js":
/*!*************************************!*\
  !*** ./mobileapps/lib/selectors.js ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var MATHOID_IMG_CLASS = 'mwe-math-fallback-image-inline';
var MediaSelectors = ['*[typeof^="mw:Image"]', '*[typeof^="mw:Video"]', '*[typeof^="mw:Audio"]', "img.".concat(MATHOID_IMG_CLASS)];
var VideoSelectors = MediaSelectors.filter(function (selector) {
  return selector.includes('Video');
});
var PronunciationParentSelector = 'span.IPA';
var PronunciationSelector = 'a[rel="mw:MediaLink"]';
var SpokenWikipediaId = '#section_SpokenWikipedia';
module.exports = {
  MediaSelectors: MediaSelectors,
  VideoSelectors: VideoSelectors,
  PronunciationParentSelector: PronunciationParentSelector,
  PronunciationSelector: PronunciationSelector,
  SpokenWikipediaId: SpokenWikipediaId,
  MATHOID_IMG_CLASS: MATHOID_IMG_CLASS
};

/***/ }),

/***/ "./mobileapps/lib/thumbnail.js":
/*!*************************************!*\
  !*** ./mobileapps/lib/thumbnail.js ***!
  \*************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

var mwapiConstants = __webpack_require__(/*! ./mwapi-constants */ "./mobileapps/lib/mwapi-constants.js");

var THUMB_URL_PATH_REGEX = /\/thumb\//;
var THUMB_WIDTH_REGEX = /(\d+)px-[^/]+$/;
var MIN_IMAGE_SIZE = 48; // Exclusions for various categories of content. See MMVB.isAllowedThumb in mediawiki-extensions-
// MultimediaViewer.

var EXCLUSION_SELECTOR = '.metadata,.noviewer';
var thumbBucketWidthCandidates = [mwapiConstants.LEAD_IMAGE_M, mwapiConstants.LEAD_IMAGE_S];
/**
 * Scales a single image thumbnail URL to another size, if possible.
 * @param {!string} initialUrl an initial thumbnail URL for an image, for example:
 *     https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Foo.jpg/640px-Foo.jpg
 * @param {!number} desiredWidth the desired width
 * @param {?number} originalWidth the original width, if known
 * @return {?string} URL updated with the desired size, if available
 */

var scaleURL = function scaleURL(initialUrl, desiredWidth, originalWidth) {
  if (!initialUrl.match(THUMB_URL_PATH_REGEX)) {
    // not a thumb URL
    return;
  }

  var match = THUMB_WIDTH_REGEX.exec(initialUrl);

  if (match) {
    var maxWidth = originalWidth || match[1];

    if (maxWidth > desiredWidth) {
      var newSubstring = match[0].replace(match[1], desiredWidth);
      return initialUrl.replace(THUMB_WIDTH_REGEX, newSubstring);
    }
  }
};
/**
 * Returns whether the on-page size of an <img> element is small enough to filter from the response
 * @param {!Element} img an <img> element
 */


var isTooSmall = function isTooSmall(img) {
  var width = img.getAttribute('width');
  var height = img.getAttribute('height');
  return width < MIN_IMAGE_SIZE || height < MIN_IMAGE_SIZE;
};
/**
 * Returns whether the element or an ancestor is part of a blacklisted class
 * @param {!Element} elem an HTML Element
 * @return {!boolean} true if the element or an ancestor is part of a blacklisted class
 */


var isDisallowed = function isDisallowed(elem) {
  return !!elem.closest(EXCLUSION_SELECTOR);
};

var isFromGallery = function isFromGallery(elem) {
  return !!elem.closest('.gallerybox');
};

var adjustSrcSet = function adjustSrcSet(srcSet, origWidth, candidateBucketWidth) {
  var srcSetEntries = srcSet.split(',').map(function (str) {
    return str.trim();
  });
  var updatedEntries = [];
  srcSetEntries.forEach(function (entry) {
    var entryParts = entry.split(' ');
    var src = entryParts[0];
    var res = entryParts[1];
    var multiplier = res.substring(0, res.toLowerCase().indexOf('x'));
    var desiredWidth = candidateBucketWidth * multiplier;

    if (desiredWidth < origWidth) {
      var scaledThumbUrl = scaleURL(src, desiredWidth, origWidth);

      if (scaledThumbUrl) {
        updatedEntries.push("".concat(scaledThumbUrl, " ").concat(res));
      }
    }
  });

  if (updatedEntries.length) {
    return updatedEntries.join(', ');
  }
};
/**
 * Scale thumbnail img
 * @param {!Element} img
 */


var scaleElementIfNecessary = function scaleElementIfNecessary(img) {
  if (isTooSmall(img) || isDisallowed(img) || isFromGallery(img)) {
    return;
  }

  var src = img.getAttribute('src');
  var srcSet = img.getAttribute('srcset');
  var width = img.getAttribute('width');
  var height = img.getAttribute('height');
  var origWidth = img.getAttribute('data-file-width');

  for (var i = 0; i < thumbBucketWidthCandidates.length; i++) {
    var candidateBucketWidth = thumbBucketWidthCandidates[i];

    if (candidateBucketWidth >= origWidth) {
      continue;
    }

    var scaledUrl = scaleURL(src, candidateBucketWidth, origWidth);

    if (scaledUrl) {
      img.setAttribute('src', scaledUrl);
      img.setAttribute('height', Math.round(height * candidateBucketWidth / width));
      img.setAttribute('width', candidateBucketWidth);

      if (srcSet) {
        var adjustedSrcSet = adjustSrcSet(srcSet, origWidth, candidateBucketWidth);

        if (adjustedSrcSet) {
          img.setAttribute('srcSet', adjustedSrcSet);
        } else {
          img.removeAttribute('srcSet');
        }
      }

      break;
    }
  }
};

module.exports = {
  isTooSmall: isTooSmall,
  isDisallowed: isDisallowed,
  isFromGallery: isFromGallery,
  scaleURL: scaleURL,
  scaleElementIfNecessary: scaleElementIfNecessary
};

/***/ }),

/***/ "./mobileapps/lib/transformations/pcs/addHrefToEditButton.js":
/*!*******************************************************************!*\
  !*** ./mobileapps/lib/transformations/pcs/addHrefToEditButton.js ***!
  \*******************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var pagelib = __webpack_require__(/*! ../../../pagelib/build/wikimedia-page-library-transform.js */ "./mobileapps/pagelib/build/wikimedia-page-library-transform.js");

var EditTransform = pagelib.EditTransform;

var domUtil = __webpack_require__(/*! ../../domUtil */ "./mobileapps/lib/domUtil.js");

var CLASS = EditTransform.CLASS;
/**
 * Adds section headings for valid sections (with id >= 0).
 * @param {!Element} sectionElement an ancestor element for the edit button
 * @param {!number} index the zero-based index of the section
 * @param {!string} linkTitle the title of the page used for the edit link
 */

module.exports = function (sectionElement, index, linkTitle) {
  sectionElement.querySelector(".".concat(CLASS.LINK)).href = "/w/index.php?title=".concat(linkTitle, "&action=edit&section=").concat(index);
};

/***/ }),

/***/ "./mobileapps/lib/transformations/pcs/addPageHeader.js":
/*!*************************************************************!*\
  !*** ./mobileapps/lib/transformations/pcs/addPageHeader.js ***!
  \*************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var pagelib = __webpack_require__(/*! ../../../pagelib/build/wikimedia-page-library-transform.js */ "./mobileapps/pagelib/build/wikimedia-page-library-transform.js");

var EditTransform = pagelib.EditTransform;

var addHrefToEditButton = __webpack_require__(/*! ./addHrefToEditButton */ "./mobileapps/lib/transformations/pcs/addHrefToEditButton.js");

var domUtil = __webpack_require__(/*! ../../domUtil */ "./mobileapps/lib/domUtil.js");
/**
 * Adds a page header with title, lead section edit button, and optional description and
 * button for the title pronunciation.
 * @param {!Document} doc Parsoid DOM document
 * @param {!object} meta meta object with pronunciation and mw
 */


module.exports = function (doc, meta) {
  var body = doc.getElementById('pcs') || doc.body;
  var headerElement = doc.createElement('header');
  var firstSection = body && body.querySelector('section');

  if (firstSection) {
    body.insertBefore(headerElement, firstSection);
  } else {
    body.appendChild(headerElement);
  }

  var pronunciationUrl = meta.pronunciation && meta.pronunciation.url;
  var content = EditTransform.newEditLeadSectionHeader(doc, meta.mw.displaytitle, meta.mw.description, meta.mw.description_source, 'Add a description', meta.mw.description === undefined || meta.mw.description_source === 'central', true, pronunciationUrl);
  headerElement.appendChild(content);
  var title = domUtil.getParsoidLinkTitle(doc);

  if (!title) {
    return;
  }

  addHrefToEditButton(headerElement, 0, title);
};

/***/ }),

/***/ "./mobileapps/lib/transformations/pcs/head.js":
/*!****************************************************!*\
  !*** ./mobileapps/lib/transformations/pcs/head.js ***!
  \****************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


var url = __webpack_require__(/*! url */ "./node_modules/url/url.js");

var apiConstants = __webpack_require__(/*! ../../api-util-constants */ "./mobileapps/lib/api-util-constants.js");

var dom = __webpack_require__(/*! ../../domUtil */ "./mobileapps/lib/domUtil.js");
/**
 * Adds a single link to a CSS stylesheet to html/head
 * @param {Document} document DOM document
 * @param {string} cssLink the link to the stylesheet
 * @return {Element} DOM Element
 */


function createStylesheetLinkElement(document, cssLink) {
  var linkEl = document.createElement('link');
  linkEl.setAttribute('rel', 'stylesheet');
  linkEl.setAttribute('href', cssLink);
  return linkEl;
}

var httpsRegex = /^https:\/\//;
/**
 * Adds links to the PCS CSS stylesheets to html/head/.
 * Example:
 * <link rel="stylesheet" href="https://meta.wikimedia.org/api/rest_v1/data/css/mobile/base">
 * <link rel="stylesheet" href="https://meta.wikimedia.org/api/rest_v1/data/css/mobile/pcs">
 * <link rel="stylesheet" href="https://en.wikipedia.org/api/rest_v1/data/css/mobile/site">
 * @param {Document} document DOM document
 * @param {!object} options options object with the following properties:
 *   {!string} baseURI base URI for common links
 */

function addCssLinks(document, options) {
  var headEl = document.head;
  var baseUri = dom.getHttpsBaseUri(document);

  if (headEl) {
    headEl.appendChild(createStylesheetLinkElement(document, "".concat(options.baseURI, "data/css/mobile/base").replace(httpsRegex, '//')));

    if (baseUri) {
      var localRestApiBaseUri = apiConstants.getExternalRestApiUri(url.parse(baseUri).hostname);
      headEl.appendChild(createStylesheetLinkElement(document, "".concat(localRestApiBaseUri, "data/css/mobile/site").replace(httpsRegex, '//')));
    }

    headEl.appendChild(createStylesheetLinkElement(document, "".concat(options.baseURI, "data/css/mobile/pcs").replace(httpsRegex, '//')));
  }
}
/**
 * Creates a single <meta> element setting the viewport for a mobile device.
 * @param {Document} document DOM document
 * @return {Element} DOM Element
 */


function createMetaViewportElement(document) {
  var el = document.createElement('meta');
  el.setAttribute('name', 'viewport');
  el.setAttribute('content', 'width=device-width, user-scalable=no, initial-scale=1, shrink-to-fit=no');
  return el;
}
/**
 * Adds the viewport meta element to html/head/
 * <meta name="viewport"
 *  content="width=device-width, user-scalable=no, initial-scale=1, shrink-to-fit=no" />
 * @param {Document} document DOM document
 */


function addMetaViewport(document) {
  var headEl = document.head;

  if (headEl) {
    headEl.appendChild(createMetaViewportElement(document));
  }
}

function addMetaTags(document, meta) {
  var head = document.head;

  if (!head) {
    return;
  }

  var protections = meta.mw.protection;
  protections.forEach(function (protection) {
    var meta = document.createElement('meta');
    meta.setAttribute('property', "mw:pageProtection:".concat(protection.type));
    meta.setAttribute('content', protection.level);
    head.appendChild(meta);
  });
  var originalimage = meta.mw.originalimage;

  if (originalimage) {
    var _meta = document.createElement('meta');

    _meta.setAttribute('property', 'mw:leadImage');

    _meta.setAttribute('content', originalimage.source);

    _meta.setAttribute('data-file-width', originalimage.width);

    _meta.setAttribute('data-file-height', originalimage.height);

    head.appendChild(_meta);
  }
}
/**
 * Adds the script element to html/head/
 * <script src=http://localhost:6927/meta.wikimedia.org/v1/data/javascript/mobile/pagelib></script>
 * @param {Document} document DOM document
 * @param {!object} options options object with the following properties:
 *   {!string} baseURI base URI for common links
 */


function createScriptElement(document, options) {
  var el = document.createElement('script');
  el.setAttribute('src', "".concat(options.baseURI, "data/javascript/mobile/pcs"));
  return el;
}
/**
 * Adds Javascript needed to use and trigger the page library client side functionality.
 * A reference to the actual JS file bundle from the wikimedia-page-library is added to the head.
 * A short inline script to trigger the loading of the lazy loaded images since the mobile-html
 * only contains the placeholders but not the image elements for the bigger images on a page.
 * @param {Document} document DOM document
 * @param {!object} options options object with the following properties:
 *   {!string} baseURI base URI for common links
 */


function addPageLibJs(document, options) {
  var headEl = document.head;

  if (headEl) {
    headEl.appendChild(createScriptElement(document, options));
  }

  var bodyEl = document.getElementById('pcs');

  if (bodyEl) {
    var sections = bodyEl.querySelectorAll('section');

    if (sections.length > 0) {
      var startScript = document.createElement('script');
      startScript.innerHTML = 'pcs.c1.Page.onBodyStart();';
      bodyEl.insertBefore(startScript, sections[0]);

      for (var i = 1; i < sections.length; i++) {
        sections[i].style.display = 'none';
      }
    }

    var endScript = document.createElement('script');
    endScript.setAttribute('defer', 'true');
    endScript.innerHTML = 'pcs.c1.Page.onBodyEnd();';
    bodyEl.appendChild(endScript);
  }
}

module.exports = {
  addCssLinks: addCssLinks,
  addMetaViewport: addMetaViewport,
  addPageLibJs: addPageLibJs,
  addMetaTags: addMetaTags
};

/***/ }),

/***/ "./mobileapps/node_modules/bluebird/js/browser/bluebird.js":
/*!*****************************************************************!*\
  !*** ./mobileapps/node_modules/bluebird/js/browser/bluebird.js ***!
  \*****************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(process, global, setImmediate) {/* @preserve
 * The MIT License (MIT)
 * 
 * Copyright (c) 2013-2018 Petka Antonov
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
/**
 * bluebird build version 3.7.2
 * Features enabled: core, race, call_get, generators, map, nodeify, promisify, props, reduce, settle, some, using, timers, filter, any, each
*/
!function(e){if(true)module.exports=e();else { var f; }}(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof _dereq_=="function"&&_dereq_;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof _dereq_=="function"&&_dereq_;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise) {
var SomePromiseArray = Promise._SomePromiseArray;
function any(promises) {
    var ret = new SomePromiseArray(promises);
    var promise = ret.promise();
    ret.setHowMany(1);
    ret.setUnwrap();
    ret.init();
    return promise;
}

Promise.any = function (promises) {
    return any(promises);
};

Promise.prototype.any = function () {
    return any(this);
};

};

},{}],2:[function(_dereq_,module,exports){
"use strict";
var firstLineError;
try {throw new Error(); } catch (e) {firstLineError = e;}
var schedule = _dereq_("./schedule");
var Queue = _dereq_("./queue");

function Async() {
    this._customScheduler = false;
    this._isTickUsed = false;
    this._lateQueue = new Queue(16);
    this._normalQueue = new Queue(16);
    this._haveDrainedQueues = false;
    var self = this;
    this.drainQueues = function () {
        self._drainQueues();
    };
    this._schedule = schedule;
}

Async.prototype.setScheduler = function(fn) {
    var prev = this._schedule;
    this._schedule = fn;
    this._customScheduler = true;
    return prev;
};

Async.prototype.hasCustomScheduler = function() {
    return this._customScheduler;
};

Async.prototype.haveItemsQueued = function () {
    return this._isTickUsed || this._haveDrainedQueues;
};


Async.prototype.fatalError = function(e, isNode) {
    if (isNode) {
        process.stderr.write("Fatal " + (e instanceof Error ? e.stack : e) +
            "\n");
        process.exit(2);
    } else {
        this.throwLater(e);
    }
};

Async.prototype.throwLater = function(fn, arg) {
    if (arguments.length === 1) {
        arg = fn;
        fn = function () { throw arg; };
    }
    if (typeof setTimeout !== "undefined") {
        setTimeout(function() {
            fn(arg);
        }, 0);
    } else try {
        this._schedule(function() {
            fn(arg);
        });
    } catch (e) {
        throw new Error("No async scheduler available\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
};

function AsyncInvokeLater(fn, receiver, arg) {
    this._lateQueue.push(fn, receiver, arg);
    this._queueTick();
}

function AsyncInvoke(fn, receiver, arg) {
    this._normalQueue.push(fn, receiver, arg);
    this._queueTick();
}

function AsyncSettlePromises(promise) {
    this._normalQueue._pushOne(promise);
    this._queueTick();
}

Async.prototype.invokeLater = AsyncInvokeLater;
Async.prototype.invoke = AsyncInvoke;
Async.prototype.settlePromises = AsyncSettlePromises;


function _drainQueue(queue) {
    while (queue.length() > 0) {
        _drainQueueStep(queue);
    }
}

function _drainQueueStep(queue) {
    var fn = queue.shift();
    if (typeof fn !== "function") {
        fn._settlePromises();
    } else {
        var receiver = queue.shift();
        var arg = queue.shift();
        fn.call(receiver, arg);
    }
}

Async.prototype._drainQueues = function () {
    _drainQueue(this._normalQueue);
    this._reset();
    this._haveDrainedQueues = true;
    _drainQueue(this._lateQueue);
};

Async.prototype._queueTick = function () {
    if (!this._isTickUsed) {
        this._isTickUsed = true;
        this._schedule(this.drainQueues);
    }
};

Async.prototype._reset = function () {
    this._isTickUsed = false;
};

module.exports = Async;
module.exports.firstLineError = firstLineError;

},{"./queue":26,"./schedule":29}],3:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL, tryConvertToPromise, debug) {
var calledBind = false;
var rejectThis = function(_, e) {
    this._reject(e);
};

var targetRejected = function(e, context) {
    context.promiseRejectionQueued = true;
    context.bindingPromise._then(rejectThis, rejectThis, null, this, e);
};

var bindingResolved = function(thisArg, context) {
    if (((this._bitField & 50397184) === 0)) {
        this._resolveCallback(context.target);
    }
};

var bindingRejected = function(e, context) {
    if (!context.promiseRejectionQueued) this._reject(e);
};

Promise.prototype.bind = function (thisArg) {
    if (!calledBind) {
        calledBind = true;
        Promise.prototype._propagateFrom = debug.propagateFromFunction();
        Promise.prototype._boundValue = debug.boundValueFunction();
    }
    var maybePromise = tryConvertToPromise(thisArg);
    var ret = new Promise(INTERNAL);
    ret._propagateFrom(this, 1);
    var target = this._target();
    ret._setBoundTo(maybePromise);
    if (maybePromise instanceof Promise) {
        var context = {
            promiseRejectionQueued: false,
            promise: ret,
            target: target,
            bindingPromise: maybePromise
        };
        target._then(INTERNAL, targetRejected, undefined, ret, context);
        maybePromise._then(
            bindingResolved, bindingRejected, undefined, ret, context);
        ret._setOnCancel(maybePromise);
    } else {
        ret._resolveCallback(target);
    }
    return ret;
};

Promise.prototype._setBoundTo = function (obj) {
    if (obj !== undefined) {
        this._bitField = this._bitField | 2097152;
        this._boundTo = obj;
    } else {
        this._bitField = this._bitField & (~2097152);
    }
};

Promise.prototype._isBound = function () {
    return (this._bitField & 2097152) === 2097152;
};

Promise.bind = function (thisArg, value) {
    return Promise.resolve(value).bind(thisArg);
};
};

},{}],4:[function(_dereq_,module,exports){
"use strict";
var old;
if (typeof Promise !== "undefined") old = Promise;
function noConflict() {
    try { if (Promise === bluebird) Promise = old; }
    catch (e) {}
    return bluebird;
}
var bluebird = _dereq_("./promise")();
bluebird.noConflict = noConflict;
module.exports = bluebird;

},{"./promise":22}],5:[function(_dereq_,module,exports){
"use strict";
var cr = Object.create;
if (cr) {
    var callerCache = cr(null);
    var getterCache = cr(null);
    callerCache[" size"] = getterCache[" size"] = 0;
}

module.exports = function(Promise) {
var util = _dereq_("./util");
var canEvaluate = util.canEvaluate;
var isIdentifier = util.isIdentifier;

var getMethodCaller;
var getGetter;
if (false) { var getCompiled, makeGetter, makeMethodCaller; }

function ensureMethod(obj, methodName) {
    var fn;
    if (obj != null) fn = obj[methodName];
    if (typeof fn !== "function") {
        var message = "Object " + util.classString(obj) + " has no method '" +
            util.toString(methodName) + "'";
        throw new Promise.TypeError(message);
    }
    return fn;
}

function caller(obj) {
    var methodName = this.pop();
    var fn = ensureMethod(obj, methodName);
    return fn.apply(obj, this);
}
Promise.prototype.call = function (methodName) {
    var args = [].slice.call(arguments, 1);;
    if (false) { var maybeCaller; }
    args.push(methodName);
    return this._then(caller, undefined, undefined, args, undefined);
};

function namedGetter(obj) {
    return obj[this];
}
function indexedGetter(obj) {
    var index = +this;
    if (index < 0) index = Math.max(0, index + obj.length);
    return obj[index];
}
Promise.prototype.get = function (propertyName) {
    var isIndex = (typeof propertyName === "number");
    var getter;
    if (!isIndex) {
        if (canEvaluate) {
            var maybeGetter = getGetter(propertyName);
            getter = maybeGetter !== null ? maybeGetter : namedGetter;
        } else {
            getter = namedGetter;
        }
    } else {
        getter = indexedGetter;
    }
    return this._then(getter, undefined, undefined, propertyName, undefined);
};
};

},{"./util":36}],6:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, PromiseArray, apiRejection, debug) {
var util = _dereq_("./util");
var tryCatch = util.tryCatch;
var errorObj = util.errorObj;
var async = Promise._async;

Promise.prototype["break"] = Promise.prototype.cancel = function() {
    if (!debug.cancellation()) return this._warn("cancellation is disabled");

    var promise = this;
    var child = promise;
    while (promise._isCancellable()) {
        if (!promise._cancelBy(child)) {
            if (child._isFollowing()) {
                child._followee().cancel();
            } else {
                child._cancelBranched();
            }
            break;
        }

        var parent = promise._cancellationParent;
        if (parent == null || !parent._isCancellable()) {
            if (promise._isFollowing()) {
                promise._followee().cancel();
            } else {
                promise._cancelBranched();
            }
            break;
        } else {
            if (promise._isFollowing()) promise._followee().cancel();
            promise._setWillBeCancelled();
            child = promise;
            promise = parent;
        }
    }
};

Promise.prototype._branchHasCancelled = function() {
    this._branchesRemainingToCancel--;
};

Promise.prototype._enoughBranchesHaveCancelled = function() {
    return this._branchesRemainingToCancel === undefined ||
           this._branchesRemainingToCancel <= 0;
};

Promise.prototype._cancelBy = function(canceller) {
    if (canceller === this) {
        this._branchesRemainingToCancel = 0;
        this._invokeOnCancel();
        return true;
    } else {
        this._branchHasCancelled();
        if (this._enoughBranchesHaveCancelled()) {
            this._invokeOnCancel();
            return true;
        }
    }
    return false;
};

Promise.prototype._cancelBranched = function() {
    if (this._enoughBranchesHaveCancelled()) {
        this._cancel();
    }
};

Promise.prototype._cancel = function() {
    if (!this._isCancellable()) return;
    this._setCancelled();
    async.invoke(this._cancelPromises, this, undefined);
};

Promise.prototype._cancelPromises = function() {
    if (this._length() > 0) this._settlePromises();
};

Promise.prototype._unsetOnCancel = function() {
    this._onCancelField = undefined;
};

Promise.prototype._isCancellable = function() {
    return this.isPending() && !this._isCancelled();
};

Promise.prototype.isCancellable = function() {
    return this.isPending() && !this.isCancelled();
};

Promise.prototype._doInvokeOnCancel = function(onCancelCallback, internalOnly) {
    if (util.isArray(onCancelCallback)) {
        for (var i = 0; i < onCancelCallback.length; ++i) {
            this._doInvokeOnCancel(onCancelCallback[i], internalOnly);
        }
    } else if (onCancelCallback !== undefined) {
        if (typeof onCancelCallback === "function") {
            if (!internalOnly) {
                var e = tryCatch(onCancelCallback).call(this._boundValue());
                if (e === errorObj) {
                    this._attachExtraTrace(e.e);
                    async.throwLater(e.e);
                }
            }
        } else {
            onCancelCallback._resultCancelled(this);
        }
    }
};

Promise.prototype._invokeOnCancel = function() {
    var onCancelCallback = this._onCancel();
    this._unsetOnCancel();
    async.invoke(this._doInvokeOnCancel, this, onCancelCallback);
};

Promise.prototype._invokeInternalOnCancel = function() {
    if (this._isCancellable()) {
        this._doInvokeOnCancel(this._onCancel(), true);
        this._unsetOnCancel();
    }
};

Promise.prototype._resultCancelled = function() {
    this.cancel();
};

};

},{"./util":36}],7:[function(_dereq_,module,exports){
"use strict";
module.exports = function(NEXT_FILTER) {
var util = _dereq_("./util");
var getKeys = _dereq_("./es5").keys;
var tryCatch = util.tryCatch;
var errorObj = util.errorObj;

function catchFilter(instances, cb, promise) {
    return function(e) {
        var boundTo = promise._boundValue();
        predicateLoop: for (var i = 0; i < instances.length; ++i) {
            var item = instances[i];

            if (item === Error ||
                (item != null && item.prototype instanceof Error)) {
                if (e instanceof item) {
                    return tryCatch(cb).call(boundTo, e);
                }
            } else if (typeof item === "function") {
                var matchesPredicate = tryCatch(item).call(boundTo, e);
                if (matchesPredicate === errorObj) {
                    return matchesPredicate;
                } else if (matchesPredicate) {
                    return tryCatch(cb).call(boundTo, e);
                }
            } else if (util.isObject(e)) {
                var keys = getKeys(item);
                for (var j = 0; j < keys.length; ++j) {
                    var key = keys[j];
                    if (item[key] != e[key]) {
                        continue predicateLoop;
                    }
                }
                return tryCatch(cb).call(boundTo, e);
            }
        }
        return NEXT_FILTER;
    };
}

return catchFilter;
};

},{"./es5":13,"./util":36}],8:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise) {
var longStackTraces = false;
var contextStack = [];

Promise.prototype._promiseCreated = function() {};
Promise.prototype._pushContext = function() {};
Promise.prototype._popContext = function() {return null;};
Promise._peekContext = Promise.prototype._peekContext = function() {};

function Context() {
    this._trace = new Context.CapturedTrace(peekContext());
}
Context.prototype._pushContext = function () {
    if (this._trace !== undefined) {
        this._trace._promiseCreated = null;
        contextStack.push(this._trace);
    }
};

Context.prototype._popContext = function () {
    if (this._trace !== undefined) {
        var trace = contextStack.pop();
        var ret = trace._promiseCreated;
        trace._promiseCreated = null;
        return ret;
    }
    return null;
};

function createContext() {
    if (longStackTraces) return new Context();
}

function peekContext() {
    var lastIndex = contextStack.length - 1;
    if (lastIndex >= 0) {
        return contextStack[lastIndex];
    }
    return undefined;
}
Context.CapturedTrace = null;
Context.create = createContext;
Context.deactivateLongStackTraces = function() {};
Context.activateLongStackTraces = function() {
    var Promise_pushContext = Promise.prototype._pushContext;
    var Promise_popContext = Promise.prototype._popContext;
    var Promise_PeekContext = Promise._peekContext;
    var Promise_peekContext = Promise.prototype._peekContext;
    var Promise_promiseCreated = Promise.prototype._promiseCreated;
    Context.deactivateLongStackTraces = function() {
        Promise.prototype._pushContext = Promise_pushContext;
        Promise.prototype._popContext = Promise_popContext;
        Promise._peekContext = Promise_PeekContext;
        Promise.prototype._peekContext = Promise_peekContext;
        Promise.prototype._promiseCreated = Promise_promiseCreated;
        longStackTraces = false;
    };
    longStackTraces = true;
    Promise.prototype._pushContext = Context.prototype._pushContext;
    Promise.prototype._popContext = Context.prototype._popContext;
    Promise._peekContext = Promise.prototype._peekContext = peekContext;
    Promise.prototype._promiseCreated = function() {
        var ctx = this._peekContext();
        if (ctx && ctx._promiseCreated == null) ctx._promiseCreated = this;
    };
};
return Context;
};

},{}],9:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, Context,
    enableAsyncHooks, disableAsyncHooks) {
var async = Promise._async;
var Warning = _dereq_("./errors").Warning;
var util = _dereq_("./util");
var es5 = _dereq_("./es5");
var canAttachTrace = util.canAttachTrace;
var unhandledRejectionHandled;
var possiblyUnhandledRejection;
var bluebirdFramePattern =
    /[\\\/]bluebird[\\\/]js[\\\/](release|debug|instrumented)/;
var nodeFramePattern = /\((?:timers\.js):\d+:\d+\)/;
var parseLinePattern = /[\/<\(](.+?):(\d+):(\d+)\)?\s*$/;
var stackFramePattern = null;
var formatStack = null;
var indentStackFrames = false;
var printWarning;
var debugging = !!(util.env("BLUEBIRD_DEBUG") != 0 &&
                        ( true ||
                         false));

var warnings = !!(util.env("BLUEBIRD_WARNINGS") != 0 &&
    (debugging || util.env("BLUEBIRD_WARNINGS")));

var longStackTraces = !!(util.env("BLUEBIRD_LONG_STACK_TRACES") != 0 &&
    (debugging || util.env("BLUEBIRD_LONG_STACK_TRACES")));

var wForgottenReturn = util.env("BLUEBIRD_W_FORGOTTEN_RETURN") != 0 &&
    (warnings || !!util.env("BLUEBIRD_W_FORGOTTEN_RETURN"));

var deferUnhandledRejectionCheck;
(function() {
    var promises = [];

    function unhandledRejectionCheck() {
        for (var i = 0; i < promises.length; ++i) {
            promises[i]._notifyUnhandledRejection();
        }
        unhandledRejectionClear();
    }

    function unhandledRejectionClear() {
        promises.length = 0;
    }

    deferUnhandledRejectionCheck = function(promise) {
        promises.push(promise);
        setTimeout(unhandledRejectionCheck, 1);
    };

    es5.defineProperty(Promise, "_unhandledRejectionCheck", {
        value: unhandledRejectionCheck
    });
    es5.defineProperty(Promise, "_unhandledRejectionClear", {
        value: unhandledRejectionClear
    });
})();

Promise.prototype.suppressUnhandledRejections = function() {
    var target = this._target();
    target._bitField = ((target._bitField & (~1048576)) |
                      524288);
};

Promise.prototype._ensurePossibleRejectionHandled = function () {
    if ((this._bitField & 524288) !== 0) return;
    this._setRejectionIsUnhandled();
    deferUnhandledRejectionCheck(this);
};

Promise.prototype._notifyUnhandledRejectionIsHandled = function () {
    fireRejectionEvent("rejectionHandled",
                                  unhandledRejectionHandled, undefined, this);
};

Promise.prototype._setReturnedNonUndefined = function() {
    this._bitField = this._bitField | 268435456;
};

Promise.prototype._returnedNonUndefined = function() {
    return (this._bitField & 268435456) !== 0;
};

Promise.prototype._notifyUnhandledRejection = function () {
    if (this._isRejectionUnhandled()) {
        var reason = this._settledValue();
        this._setUnhandledRejectionIsNotified();
        fireRejectionEvent("unhandledRejection",
                                      possiblyUnhandledRejection, reason, this);
    }
};

Promise.prototype._setUnhandledRejectionIsNotified = function () {
    this._bitField = this._bitField | 262144;
};

Promise.prototype._unsetUnhandledRejectionIsNotified = function () {
    this._bitField = this._bitField & (~262144);
};

Promise.prototype._isUnhandledRejectionNotified = function () {
    return (this._bitField & 262144) > 0;
};

Promise.prototype._setRejectionIsUnhandled = function () {
    this._bitField = this._bitField | 1048576;
};

Promise.prototype._unsetRejectionIsUnhandled = function () {
    this._bitField = this._bitField & (~1048576);
    if (this._isUnhandledRejectionNotified()) {
        this._unsetUnhandledRejectionIsNotified();
        this._notifyUnhandledRejectionIsHandled();
    }
};

Promise.prototype._isRejectionUnhandled = function () {
    return (this._bitField & 1048576) > 0;
};

Promise.prototype._warn = function(message, shouldUseOwnTrace, promise) {
    return warn(message, shouldUseOwnTrace, promise || this);
};

Promise.onPossiblyUnhandledRejection = function (fn) {
    var context = Promise._getContext();
    possiblyUnhandledRejection = util.contextBind(context, fn);
};

Promise.onUnhandledRejectionHandled = function (fn) {
    var context = Promise._getContext();
    unhandledRejectionHandled = util.contextBind(context, fn);
};

var disableLongStackTraces = function() {};
Promise.longStackTraces = function () {
    if (async.haveItemsQueued() && !config.longStackTraces) {
        throw new Error("cannot enable long stack traces after promises have been created\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    if (!config.longStackTraces && longStackTracesIsSupported()) {
        var Promise_captureStackTrace = Promise.prototype._captureStackTrace;
        var Promise_attachExtraTrace = Promise.prototype._attachExtraTrace;
        var Promise_dereferenceTrace = Promise.prototype._dereferenceTrace;
        config.longStackTraces = true;
        disableLongStackTraces = function() {
            if (async.haveItemsQueued() && !config.longStackTraces) {
                throw new Error("cannot enable long stack traces after promises have been created\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
            }
            Promise.prototype._captureStackTrace = Promise_captureStackTrace;
            Promise.prototype._attachExtraTrace = Promise_attachExtraTrace;
            Promise.prototype._dereferenceTrace = Promise_dereferenceTrace;
            Context.deactivateLongStackTraces();
            config.longStackTraces = false;
        };
        Promise.prototype._captureStackTrace = longStackTracesCaptureStackTrace;
        Promise.prototype._attachExtraTrace = longStackTracesAttachExtraTrace;
        Promise.prototype._dereferenceTrace = longStackTracesDereferenceTrace;
        Context.activateLongStackTraces();
    }
};

Promise.hasLongStackTraces = function () {
    return config.longStackTraces && longStackTracesIsSupported();
};


var legacyHandlers = {
    unhandledrejection: {
        before: function() {
            var ret = util.global.onunhandledrejection;
            util.global.onunhandledrejection = null;
            return ret;
        },
        after: function(fn) {
            util.global.onunhandledrejection = fn;
        }
    },
    rejectionhandled: {
        before: function() {
            var ret = util.global.onrejectionhandled;
            util.global.onrejectionhandled = null;
            return ret;
        },
        after: function(fn) {
            util.global.onrejectionhandled = fn;
        }
    }
};

var fireDomEvent = (function() {
    var dispatch = function(legacy, e) {
        if (legacy) {
            var fn;
            try {
                fn = legacy.before();
                return !util.global.dispatchEvent(e);
            } finally {
                legacy.after(fn);
            }
        } else {
            return !util.global.dispatchEvent(e);
        }
    };
    try {
        if (typeof CustomEvent === "function") {
            var event = new CustomEvent("CustomEvent");
            util.global.dispatchEvent(event);
            return function(name, event) {
                name = name.toLowerCase();
                var eventData = {
                    detail: event,
                    cancelable: true
                };
                var domEvent = new CustomEvent(name, eventData);
                es5.defineProperty(
                    domEvent, "promise", {value: event.promise});
                es5.defineProperty(
                    domEvent, "reason", {value: event.reason});

                return dispatch(legacyHandlers[name], domEvent);
            };
        } else if (typeof Event === "function") {
            var event = new Event("CustomEvent");
            util.global.dispatchEvent(event);
            return function(name, event) {
                name = name.toLowerCase();
                var domEvent = new Event(name, {
                    cancelable: true
                });
                domEvent.detail = event;
                es5.defineProperty(domEvent, "promise", {value: event.promise});
                es5.defineProperty(domEvent, "reason", {value: event.reason});
                return dispatch(legacyHandlers[name], domEvent);
            };
        } else {
            var event = document.createEvent("CustomEvent");
            event.initCustomEvent("testingtheevent", false, true, {});
            util.global.dispatchEvent(event);
            return function(name, event) {
                name = name.toLowerCase();
                var domEvent = document.createEvent("CustomEvent");
                domEvent.initCustomEvent(name, false, true,
                    event);
                return dispatch(legacyHandlers[name], domEvent);
            };
        }
    } catch (e) {}
    return function() {
        return false;
    };
})();

var fireGlobalEvent = (function() {
    if (util.isNode) {
        return function() {
            return process.emit.apply(process, arguments);
        };
    } else {
        if (!util.global) {
            return function() {
                return false;
            };
        }
        return function(name) {
            var methodName = "on" + name.toLowerCase();
            var method = util.global[methodName];
            if (!method) return false;
            method.apply(util.global, [].slice.call(arguments, 1));
            return true;
        };
    }
})();

function generatePromiseLifecycleEventObject(name, promise) {
    return {promise: promise};
}

var eventToObjectGenerator = {
    promiseCreated: generatePromiseLifecycleEventObject,
    promiseFulfilled: generatePromiseLifecycleEventObject,
    promiseRejected: generatePromiseLifecycleEventObject,
    promiseResolved: generatePromiseLifecycleEventObject,
    promiseCancelled: generatePromiseLifecycleEventObject,
    promiseChained: function(name, promise, child) {
        return {promise: promise, child: child};
    },
    warning: function(name, warning) {
        return {warning: warning};
    },
    unhandledRejection: function (name, reason, promise) {
        return {reason: reason, promise: promise};
    },
    rejectionHandled: generatePromiseLifecycleEventObject
};

var activeFireEvent = function (name) {
    var globalEventFired = false;
    try {
        globalEventFired = fireGlobalEvent.apply(null, arguments);
    } catch (e) {
        async.throwLater(e);
        globalEventFired = true;
    }

    var domEventFired = false;
    try {
        domEventFired = fireDomEvent(name,
                    eventToObjectGenerator[name].apply(null, arguments));
    } catch (e) {
        async.throwLater(e);
        domEventFired = true;
    }

    return domEventFired || globalEventFired;
};

Promise.config = function(opts) {
    opts = Object(opts);
    if ("longStackTraces" in opts) {
        if (opts.longStackTraces) {
            Promise.longStackTraces();
        } else if (!opts.longStackTraces && Promise.hasLongStackTraces()) {
            disableLongStackTraces();
        }
    }
    if ("warnings" in opts) {
        var warningsOption = opts.warnings;
        config.warnings = !!warningsOption;
        wForgottenReturn = config.warnings;

        if (util.isObject(warningsOption)) {
            if ("wForgottenReturn" in warningsOption) {
                wForgottenReturn = !!warningsOption.wForgottenReturn;
            }
        }
    }
    if ("cancellation" in opts && opts.cancellation && !config.cancellation) {
        if (async.haveItemsQueued()) {
            throw new Error(
                "cannot enable cancellation after promises are in use");
        }
        Promise.prototype._clearCancellationData =
            cancellationClearCancellationData;
        Promise.prototype._propagateFrom = cancellationPropagateFrom;
        Promise.prototype._onCancel = cancellationOnCancel;
        Promise.prototype._setOnCancel = cancellationSetOnCancel;
        Promise.prototype._attachCancellationCallback =
            cancellationAttachCancellationCallback;
        Promise.prototype._execute = cancellationExecute;
        propagateFromFunction = cancellationPropagateFrom;
        config.cancellation = true;
    }
    if ("monitoring" in opts) {
        if (opts.monitoring && !config.monitoring) {
            config.monitoring = true;
            Promise.prototype._fireEvent = activeFireEvent;
        } else if (!opts.monitoring && config.monitoring) {
            config.monitoring = false;
            Promise.prototype._fireEvent = defaultFireEvent;
        }
    }
    if ("asyncHooks" in opts && util.nodeSupportsAsyncResource) {
        var prev = config.asyncHooks;
        var cur = !!opts.asyncHooks;
        if (prev !== cur) {
            config.asyncHooks = cur;
            if (cur) {
                enableAsyncHooks();
            } else {
                disableAsyncHooks();
            }
        }
    }
    return Promise;
};

function defaultFireEvent() { return false; }

Promise.prototype._fireEvent = defaultFireEvent;
Promise.prototype._execute = function(executor, resolve, reject) {
    try {
        executor(resolve, reject);
    } catch (e) {
        return e;
    }
};
Promise.prototype._onCancel = function () {};
Promise.prototype._setOnCancel = function (handler) { ; };
Promise.prototype._attachCancellationCallback = function(onCancel) {
    ;
};
Promise.prototype._captureStackTrace = function () {};
Promise.prototype._attachExtraTrace = function () {};
Promise.prototype._dereferenceTrace = function () {};
Promise.prototype._clearCancellationData = function() {};
Promise.prototype._propagateFrom = function (parent, flags) {
    ;
    ;
};

function cancellationExecute(executor, resolve, reject) {
    var promise = this;
    try {
        executor(resolve, reject, function(onCancel) {
            if (typeof onCancel !== "function") {
                throw new TypeError("onCancel must be a function, got: " +
                                    util.toString(onCancel));
            }
            promise._attachCancellationCallback(onCancel);
        });
    } catch (e) {
        return e;
    }
}

function cancellationAttachCancellationCallback(onCancel) {
    if (!this._isCancellable()) return this;

    var previousOnCancel = this._onCancel();
    if (previousOnCancel !== undefined) {
        if (util.isArray(previousOnCancel)) {
            previousOnCancel.push(onCancel);
        } else {
            this._setOnCancel([previousOnCancel, onCancel]);
        }
    } else {
        this._setOnCancel(onCancel);
    }
}

function cancellationOnCancel() {
    return this._onCancelField;
}

function cancellationSetOnCancel(onCancel) {
    this._onCancelField = onCancel;
}

function cancellationClearCancellationData() {
    this._cancellationParent = undefined;
    this._onCancelField = undefined;
}

function cancellationPropagateFrom(parent, flags) {
    if ((flags & 1) !== 0) {
        this._cancellationParent = parent;
        var branchesRemainingToCancel = parent._branchesRemainingToCancel;
        if (branchesRemainingToCancel === undefined) {
            branchesRemainingToCancel = 0;
        }
        parent._branchesRemainingToCancel = branchesRemainingToCancel + 1;
    }
    if ((flags & 2) !== 0 && parent._isBound()) {
        this._setBoundTo(parent._boundTo);
    }
}

function bindingPropagateFrom(parent, flags) {
    if ((flags & 2) !== 0 && parent._isBound()) {
        this._setBoundTo(parent._boundTo);
    }
}
var propagateFromFunction = bindingPropagateFrom;

function boundValueFunction() {
    var ret = this._boundTo;
    if (ret !== undefined) {
        if (ret instanceof Promise) {
            if (ret.isFulfilled()) {
                return ret.value();
            } else {
                return undefined;
            }
        }
    }
    return ret;
}

function longStackTracesCaptureStackTrace() {
    this._trace = new CapturedTrace(this._peekContext());
}

function longStackTracesAttachExtraTrace(error, ignoreSelf) {
    if (canAttachTrace(error)) {
        var trace = this._trace;
        if (trace !== undefined) {
            if (ignoreSelf) trace = trace._parent;
        }
        if (trace !== undefined) {
            trace.attachExtraTrace(error);
        } else if (!error.__stackCleaned__) {
            var parsed = parseStackAndMessage(error);
            util.notEnumerableProp(error, "stack",
                parsed.message + "\n" + parsed.stack.join("\n"));
            util.notEnumerableProp(error, "__stackCleaned__", true);
        }
    }
}

function longStackTracesDereferenceTrace() {
    this._trace = undefined;
}

function checkForgottenReturns(returnValue, promiseCreated, name, promise,
                               parent) {
    if (returnValue === undefined && promiseCreated !== null &&
        wForgottenReturn) {
        if (parent !== undefined && parent._returnedNonUndefined()) return;
        if ((promise._bitField & 65535) === 0) return;

        if (name) name = name + " ";
        var handlerLine = "";
        var creatorLine = "";
        if (promiseCreated._trace) {
            var traceLines = promiseCreated._trace.stack.split("\n");
            var stack = cleanStack(traceLines);
            for (var i = stack.length - 1; i >= 0; --i) {
                var line = stack[i];
                if (!nodeFramePattern.test(line)) {
                    var lineMatches = line.match(parseLinePattern);
                    if (lineMatches) {
                        handlerLine  = "at " + lineMatches[1] +
                            ":" + lineMatches[2] + ":" + lineMatches[3] + " ";
                    }
                    break;
                }
            }

            if (stack.length > 0) {
                var firstUserLine = stack[0];
                for (var i = 0; i < traceLines.length; ++i) {

                    if (traceLines[i] === firstUserLine) {
                        if (i > 0) {
                            creatorLine = "\n" + traceLines[i - 1];
                        }
                        break;
                    }
                }

            }
        }
        var msg = "a promise was created in a " + name +
            "handler " + handlerLine + "but was not returned from it, " +
            "see http://goo.gl/rRqMUw" +
            creatorLine;
        promise._warn(msg, true, promiseCreated);
    }
}

function deprecated(name, replacement) {
    var message = name +
        " is deprecated and will be removed in a future version.";
    if (replacement) message += " Use " + replacement + " instead.";
    return warn(message);
}

function warn(message, shouldUseOwnTrace, promise) {
    if (!config.warnings) return;
    var warning = new Warning(message);
    var ctx;
    if (shouldUseOwnTrace) {
        promise._attachExtraTrace(warning);
    } else if (config.longStackTraces && (ctx = Promise._peekContext())) {
        ctx.attachExtraTrace(warning);
    } else {
        var parsed = parseStackAndMessage(warning);
        warning.stack = parsed.message + "\n" + parsed.stack.join("\n");
    }

    if (!activeFireEvent("warning", warning)) {
        formatAndLogError(warning, "", true);
    }
}

function reconstructStack(message, stacks) {
    for (var i = 0; i < stacks.length - 1; ++i) {
        stacks[i].push("From previous event:");
        stacks[i] = stacks[i].join("\n");
    }
    if (i < stacks.length) {
        stacks[i] = stacks[i].join("\n");
    }
    return message + "\n" + stacks.join("\n");
}

function removeDuplicateOrEmptyJumps(stacks) {
    for (var i = 0; i < stacks.length; ++i) {
        if (stacks[i].length === 0 ||
            ((i + 1 < stacks.length) && stacks[i][0] === stacks[i+1][0])) {
            stacks.splice(i, 1);
            i--;
        }
    }
}

function removeCommonRoots(stacks) {
    var current = stacks[0];
    for (var i = 1; i < stacks.length; ++i) {
        var prev = stacks[i];
        var currentLastIndex = current.length - 1;
        var currentLastLine = current[currentLastIndex];
        var commonRootMeetPoint = -1;

        for (var j = prev.length - 1; j >= 0; --j) {
            if (prev[j] === currentLastLine) {
                commonRootMeetPoint = j;
                break;
            }
        }

        for (var j = commonRootMeetPoint; j >= 0; --j) {
            var line = prev[j];
            if (current[currentLastIndex] === line) {
                current.pop();
                currentLastIndex--;
            } else {
                break;
            }
        }
        current = prev;
    }
}

function cleanStack(stack) {
    var ret = [];
    for (var i = 0; i < stack.length; ++i) {
        var line = stack[i];
        var isTraceLine = "    (No stack trace)" === line ||
            stackFramePattern.test(line);
        var isInternalFrame = isTraceLine && shouldIgnore(line);
        if (isTraceLine && !isInternalFrame) {
            if (indentStackFrames && line.charAt(0) !== " ") {
                line = "    " + line;
            }
            ret.push(line);
        }
    }
    return ret;
}

function stackFramesAsArray(error) {
    var stack = error.stack.replace(/\s+$/g, "").split("\n");
    for (var i = 0; i < stack.length; ++i) {
        var line = stack[i];
        if ("    (No stack trace)" === line || stackFramePattern.test(line)) {
            break;
        }
    }
    if (i > 0 && error.name != "SyntaxError") {
        stack = stack.slice(i);
    }
    return stack;
}

function parseStackAndMessage(error) {
    var stack = error.stack;
    var message = error.toString();
    stack = typeof stack === "string" && stack.length > 0
                ? stackFramesAsArray(error) : ["    (No stack trace)"];
    return {
        message: message,
        stack: error.name == "SyntaxError" ? stack : cleanStack(stack)
    };
}

function formatAndLogError(error, title, isSoft) {
    if (typeof console !== "undefined") {
        var message;
        if (util.isObject(error)) {
            var stack = error.stack;
            message = title + formatStack(stack, error);
        } else {
            message = title + String(error);
        }
        if (typeof printWarning === "function") {
            printWarning(message, isSoft);
        } else if (typeof console.log === "function" ||
            typeof console.log === "object") {
            console.log(message);
        }
    }
}

function fireRejectionEvent(name, localHandler, reason, promise) {
    var localEventFired = false;
    try {
        if (typeof localHandler === "function") {
            localEventFired = true;
            if (name === "rejectionHandled") {
                localHandler(promise);
            } else {
                localHandler(reason, promise);
            }
        }
    } catch (e) {
        async.throwLater(e);
    }

    if (name === "unhandledRejection") {
        if (!activeFireEvent(name, reason, promise) && !localEventFired) {
            formatAndLogError(reason, "Unhandled rejection ");
        }
    } else {
        activeFireEvent(name, promise);
    }
}

function formatNonError(obj) {
    var str;
    if (typeof obj === "function") {
        str = "[function " +
            (obj.name || "anonymous") +
            "]";
    } else {
        str = obj && typeof obj.toString === "function"
            ? obj.toString() : util.toString(obj);
        var ruselessToString = /\[object [a-zA-Z0-9$_]+\]/;
        if (ruselessToString.test(str)) {
            try {
                var newStr = JSON.stringify(obj);
                str = newStr;
            }
            catch(e) {

            }
        }
        if (str.length === 0) {
            str = "(empty array)";
        }
    }
    return ("(<" + snip(str) + ">, no stack trace)");
}

function snip(str) {
    var maxChars = 41;
    if (str.length < maxChars) {
        return str;
    }
    return str.substr(0, maxChars - 3) + "...";
}

function longStackTracesIsSupported() {
    return typeof captureStackTrace === "function";
}

var shouldIgnore = function() { return false; };
var parseLineInfoRegex = /[\/<\(]([^:\/]+):(\d+):(?:\d+)\)?\s*$/;
function parseLineInfo(line) {
    var matches = line.match(parseLineInfoRegex);
    if (matches) {
        return {
            fileName: matches[1],
            line: parseInt(matches[2], 10)
        };
    }
}

function setBounds(firstLineError, lastLineError) {
    if (!longStackTracesIsSupported()) return;
    var firstStackLines = (firstLineError.stack || "").split("\n");
    var lastStackLines = (lastLineError.stack || "").split("\n");
    var firstIndex = -1;
    var lastIndex = -1;
    var firstFileName;
    var lastFileName;
    for (var i = 0; i < firstStackLines.length; ++i) {
        var result = parseLineInfo(firstStackLines[i]);
        if (result) {
            firstFileName = result.fileName;
            firstIndex = result.line;
            break;
        }
    }
    for (var i = 0; i < lastStackLines.length; ++i) {
        var result = parseLineInfo(lastStackLines[i]);
        if (result) {
            lastFileName = result.fileName;
            lastIndex = result.line;
            break;
        }
    }
    if (firstIndex < 0 || lastIndex < 0 || !firstFileName || !lastFileName ||
        firstFileName !== lastFileName || firstIndex >= lastIndex) {
        return;
    }

    shouldIgnore = function(line) {
        if (bluebirdFramePattern.test(line)) return true;
        var info = parseLineInfo(line);
        if (info) {
            if (info.fileName === firstFileName &&
                (firstIndex <= info.line && info.line <= lastIndex)) {
                return true;
            }
        }
        return false;
    };
}

function CapturedTrace(parent) {
    this._parent = parent;
    this._promisesCreated = 0;
    var length = this._length = 1 + (parent === undefined ? 0 : parent._length);
    captureStackTrace(this, CapturedTrace);
    if (length > 32) this.uncycle();
}
util.inherits(CapturedTrace, Error);
Context.CapturedTrace = CapturedTrace;

CapturedTrace.prototype.uncycle = function() {
    var length = this._length;
    if (length < 2) return;
    var nodes = [];
    var stackToIndex = {};

    for (var i = 0, node = this; node !== undefined; ++i) {
        nodes.push(node);
        node = node._parent;
    }
    length = this._length = i;
    for (var i = length - 1; i >= 0; --i) {
        var stack = nodes[i].stack;
        if (stackToIndex[stack] === undefined) {
            stackToIndex[stack] = i;
        }
    }
    for (var i = 0; i < length; ++i) {
        var currentStack = nodes[i].stack;
        var index = stackToIndex[currentStack];
        if (index !== undefined && index !== i) {
            if (index > 0) {
                nodes[index - 1]._parent = undefined;
                nodes[index - 1]._length = 1;
            }
            nodes[i]._parent = undefined;
            nodes[i]._length = 1;
            var cycleEdgeNode = i > 0 ? nodes[i - 1] : this;

            if (index < length - 1) {
                cycleEdgeNode._parent = nodes[index + 1];
                cycleEdgeNode._parent.uncycle();
                cycleEdgeNode._length =
                    cycleEdgeNode._parent._length + 1;
            } else {
                cycleEdgeNode._parent = undefined;
                cycleEdgeNode._length = 1;
            }
            var currentChildLength = cycleEdgeNode._length + 1;
            for (var j = i - 2; j >= 0; --j) {
                nodes[j]._length = currentChildLength;
                currentChildLength++;
            }
            return;
        }
    }
};

CapturedTrace.prototype.attachExtraTrace = function(error) {
    if (error.__stackCleaned__) return;
    this.uncycle();
    var parsed = parseStackAndMessage(error);
    var message = parsed.message;
    var stacks = [parsed.stack];

    var trace = this;
    while (trace !== undefined) {
        stacks.push(cleanStack(trace.stack.split("\n")));
        trace = trace._parent;
    }
    removeCommonRoots(stacks);
    removeDuplicateOrEmptyJumps(stacks);
    util.notEnumerableProp(error, "stack", reconstructStack(message, stacks));
    util.notEnumerableProp(error, "__stackCleaned__", true);
};

var captureStackTrace = (function stackDetection() {
    var v8stackFramePattern = /^\s*at\s*/;
    var v8stackFormatter = function(stack, error) {
        if (typeof stack === "string") return stack;

        if (error.name !== undefined &&
            error.message !== undefined) {
            return error.toString();
        }
        return formatNonError(error);
    };

    if (typeof Error.stackTraceLimit === "number" &&
        typeof Error.captureStackTrace === "function") {
        Error.stackTraceLimit += 6;
        stackFramePattern = v8stackFramePattern;
        formatStack = v8stackFormatter;
        var captureStackTrace = Error.captureStackTrace;

        shouldIgnore = function(line) {
            return bluebirdFramePattern.test(line);
        };
        return function(receiver, ignoreUntil) {
            Error.stackTraceLimit += 6;
            captureStackTrace(receiver, ignoreUntil);
            Error.stackTraceLimit -= 6;
        };
    }
    var err = new Error();

    if (typeof err.stack === "string" &&
        err.stack.split("\n")[0].indexOf("stackDetection@") >= 0) {
        stackFramePattern = /@/;
        formatStack = v8stackFormatter;
        indentStackFrames = true;
        return function captureStackTrace(o) {
            o.stack = new Error().stack;
        };
    }

    var hasStackAfterThrow;
    try { throw new Error(); }
    catch(e) {
        hasStackAfterThrow = ("stack" in e);
    }
    if (!("stack" in err) && hasStackAfterThrow &&
        typeof Error.stackTraceLimit === "number") {
        stackFramePattern = v8stackFramePattern;
        formatStack = v8stackFormatter;
        return function captureStackTrace(o) {
            Error.stackTraceLimit += 6;
            try { throw new Error(); }
            catch(e) { o.stack = e.stack; }
            Error.stackTraceLimit -= 6;
        };
    }

    formatStack = function(stack, error) {
        if (typeof stack === "string") return stack;

        if ((typeof error === "object" ||
            typeof error === "function") &&
            error.name !== undefined &&
            error.message !== undefined) {
            return error.toString();
        }
        return formatNonError(error);
    };

    return null;

})([]);

if (typeof console !== "undefined" && typeof console.warn !== "undefined") {
    printWarning = function (message) {
        console.warn(message);
    };
    if (util.isNode && process.stderr.isTTY) {
        printWarning = function(message, isSoft) {
            var color = isSoft ? "\u001b[33m" : "\u001b[31m";
            console.warn(color + message + "\u001b[0m\n");
        };
    } else if (!util.isNode && typeof (new Error().stack) === "string") {
        printWarning = function(message, isSoft) {
            console.warn("%c" + message,
                        isSoft ? "color: darkorange" : "color: red");
        };
    }
}

var config = {
    warnings: warnings,
    longStackTraces: false,
    cancellation: false,
    monitoring: false,
    asyncHooks: false
};

if (longStackTraces) Promise.longStackTraces();

return {
    asyncHooks: function() {
        return config.asyncHooks;
    },
    longStackTraces: function() {
        return config.longStackTraces;
    },
    warnings: function() {
        return config.warnings;
    },
    cancellation: function() {
        return config.cancellation;
    },
    monitoring: function() {
        return config.monitoring;
    },
    propagateFromFunction: function() {
        return propagateFromFunction;
    },
    boundValueFunction: function() {
        return boundValueFunction;
    },
    checkForgottenReturns: checkForgottenReturns,
    setBounds: setBounds,
    warn: warn,
    deprecated: deprecated,
    CapturedTrace: CapturedTrace,
    fireDomEvent: fireDomEvent,
    fireGlobalEvent: fireGlobalEvent
};
};

},{"./errors":12,"./es5":13,"./util":36}],10:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise) {
function returner() {
    return this.value;
}
function thrower() {
    throw this.reason;
}

Promise.prototype["return"] =
Promise.prototype.thenReturn = function (value) {
    if (value instanceof Promise) value.suppressUnhandledRejections();
    return this._then(
        returner, undefined, undefined, {value: value}, undefined);
};

Promise.prototype["throw"] =
Promise.prototype.thenThrow = function (reason) {
    return this._then(
        thrower, undefined, undefined, {reason: reason}, undefined);
};

Promise.prototype.catchThrow = function (reason) {
    if (arguments.length <= 1) {
        return this._then(
            undefined, thrower, undefined, {reason: reason}, undefined);
    } else {
        var _reason = arguments[1];
        var handler = function() {throw _reason;};
        return this.caught(reason, handler);
    }
};

Promise.prototype.catchReturn = function (value) {
    if (arguments.length <= 1) {
        if (value instanceof Promise) value.suppressUnhandledRejections();
        return this._then(
            undefined, returner, undefined, {value: value}, undefined);
    } else {
        var _value = arguments[1];
        if (_value instanceof Promise) _value.suppressUnhandledRejections();
        var handler = function() {return _value;};
        return this.caught(value, handler);
    }
};
};

},{}],11:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL) {
var PromiseReduce = Promise.reduce;
var PromiseAll = Promise.all;

function promiseAllThis() {
    return PromiseAll(this);
}

function PromiseMapSeries(promises, fn) {
    return PromiseReduce(promises, fn, INTERNAL, INTERNAL);
}

Promise.prototype.each = function (fn) {
    return PromiseReduce(this, fn, INTERNAL, 0)
              ._then(promiseAllThis, undefined, undefined, this, undefined);
};

Promise.prototype.mapSeries = function (fn) {
    return PromiseReduce(this, fn, INTERNAL, INTERNAL);
};

Promise.each = function (promises, fn) {
    return PromiseReduce(promises, fn, INTERNAL, 0)
              ._then(promiseAllThis, undefined, undefined, promises, undefined);
};

Promise.mapSeries = PromiseMapSeries;
};


},{}],12:[function(_dereq_,module,exports){
"use strict";
var es5 = _dereq_("./es5");
var Objectfreeze = es5.freeze;
var util = _dereq_("./util");
var inherits = util.inherits;
var notEnumerableProp = util.notEnumerableProp;

function subError(nameProperty, defaultMessage) {
    function SubError(message) {
        if (!(this instanceof SubError)) return new SubError(message);
        notEnumerableProp(this, "message",
            typeof message === "string" ? message : defaultMessage);
        notEnumerableProp(this, "name", nameProperty);
        if (Error.captureStackTrace) {
            Error.captureStackTrace(this, this.constructor);
        } else {
            Error.call(this);
        }
    }
    inherits(SubError, Error);
    return SubError;
}

var _TypeError, _RangeError;
var Warning = subError("Warning", "warning");
var CancellationError = subError("CancellationError", "cancellation error");
var TimeoutError = subError("TimeoutError", "timeout error");
var AggregateError = subError("AggregateError", "aggregate error");
try {
    _TypeError = TypeError;
    _RangeError = RangeError;
} catch(e) {
    _TypeError = subError("TypeError", "type error");
    _RangeError = subError("RangeError", "range error");
}

var methods = ("join pop push shift unshift slice filter forEach some " +
    "every map indexOf lastIndexOf reduce reduceRight sort reverse").split(" ");

for (var i = 0; i < methods.length; ++i) {
    if (typeof Array.prototype[methods[i]] === "function") {
        AggregateError.prototype[methods[i]] = Array.prototype[methods[i]];
    }
}

es5.defineProperty(AggregateError.prototype, "length", {
    value: 0,
    configurable: false,
    writable: true,
    enumerable: true
});
AggregateError.prototype["isOperational"] = true;
var level = 0;
AggregateError.prototype.toString = function() {
    var indent = Array(level * 4 + 1).join(" ");
    var ret = "\n" + indent + "AggregateError of:" + "\n";
    level++;
    indent = Array(level * 4 + 1).join(" ");
    for (var i = 0; i < this.length; ++i) {
        var str = this[i] === this ? "[Circular AggregateError]" : this[i] + "";
        var lines = str.split("\n");
        for (var j = 0; j < lines.length; ++j) {
            lines[j] = indent + lines[j];
        }
        str = lines.join("\n");
        ret += str + "\n";
    }
    level--;
    return ret;
};

function OperationalError(message) {
    if (!(this instanceof OperationalError))
        return new OperationalError(message);
    notEnumerableProp(this, "name", "OperationalError");
    notEnumerableProp(this, "message", message);
    this.cause = message;
    this["isOperational"] = true;

    if (message instanceof Error) {
        notEnumerableProp(this, "message", message.message);
        notEnumerableProp(this, "stack", message.stack);
    } else if (Error.captureStackTrace) {
        Error.captureStackTrace(this, this.constructor);
    }

}
inherits(OperationalError, Error);

var errorTypes = Error["__BluebirdErrorTypes__"];
if (!errorTypes) {
    errorTypes = Objectfreeze({
        CancellationError: CancellationError,
        TimeoutError: TimeoutError,
        OperationalError: OperationalError,
        RejectionError: OperationalError,
        AggregateError: AggregateError
    });
    es5.defineProperty(Error, "__BluebirdErrorTypes__", {
        value: errorTypes,
        writable: false,
        enumerable: false,
        configurable: false
    });
}

module.exports = {
    Error: Error,
    TypeError: _TypeError,
    RangeError: _RangeError,
    CancellationError: errorTypes.CancellationError,
    OperationalError: errorTypes.OperationalError,
    TimeoutError: errorTypes.TimeoutError,
    AggregateError: errorTypes.AggregateError,
    Warning: Warning
};

},{"./es5":13,"./util":36}],13:[function(_dereq_,module,exports){
var isES5 = (function(){
    "use strict";
    return this === undefined;
})();

if (isES5) {
    module.exports = {
        freeze: Object.freeze,
        defineProperty: Object.defineProperty,
        getDescriptor: Object.getOwnPropertyDescriptor,
        keys: Object.keys,
        names: Object.getOwnPropertyNames,
        getPrototypeOf: Object.getPrototypeOf,
        isArray: Array.isArray,
        isES5: isES5,
        propertyIsWritable: function(obj, prop) {
            var descriptor = Object.getOwnPropertyDescriptor(obj, prop);
            return !!(!descriptor || descriptor.writable || descriptor.set);
        }
    };
} else {
    var has = {}.hasOwnProperty;
    var str = {}.toString;
    var proto = {}.constructor.prototype;

    var ObjectKeys = function (o) {
        var ret = [];
        for (var key in o) {
            if (has.call(o, key)) {
                ret.push(key);
            }
        }
        return ret;
    };

    var ObjectGetDescriptor = function(o, key) {
        return {value: o[key]};
    };

    var ObjectDefineProperty = function (o, key, desc) {
        o[key] = desc.value;
        return o;
    };

    var ObjectFreeze = function (obj) {
        return obj;
    };

    var ObjectGetPrototypeOf = function (obj) {
        try {
            return Object(obj).constructor.prototype;
        }
        catch (e) {
            return proto;
        }
    };

    var ArrayIsArray = function (obj) {
        try {
            return str.call(obj) === "[object Array]";
        }
        catch(e) {
            return false;
        }
    };

    module.exports = {
        isArray: ArrayIsArray,
        keys: ObjectKeys,
        names: ObjectKeys,
        defineProperty: ObjectDefineProperty,
        getDescriptor: ObjectGetDescriptor,
        freeze: ObjectFreeze,
        getPrototypeOf: ObjectGetPrototypeOf,
        isES5: isES5,
        propertyIsWritable: function() {
            return true;
        }
    };
}

},{}],14:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL) {
var PromiseMap = Promise.map;

Promise.prototype.filter = function (fn, options) {
    return PromiseMap(this, fn, options, INTERNAL);
};

Promise.filter = function (promises, fn, options) {
    return PromiseMap(promises, fn, options, INTERNAL);
};
};

},{}],15:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, tryConvertToPromise, NEXT_FILTER) {
var util = _dereq_("./util");
var CancellationError = Promise.CancellationError;
var errorObj = util.errorObj;
var catchFilter = _dereq_("./catch_filter")(NEXT_FILTER);

function PassThroughHandlerContext(promise, type, handler) {
    this.promise = promise;
    this.type = type;
    this.handler = handler;
    this.called = false;
    this.cancelPromise = null;
}

PassThroughHandlerContext.prototype.isFinallyHandler = function() {
    return this.type === 0;
};

function FinallyHandlerCancelReaction(finallyHandler) {
    this.finallyHandler = finallyHandler;
}

FinallyHandlerCancelReaction.prototype._resultCancelled = function() {
    checkCancel(this.finallyHandler);
};

function checkCancel(ctx, reason) {
    if (ctx.cancelPromise != null) {
        if (arguments.length > 1) {
            ctx.cancelPromise._reject(reason);
        } else {
            ctx.cancelPromise._cancel();
        }
        ctx.cancelPromise = null;
        return true;
    }
    return false;
}

function succeed() {
    return finallyHandler.call(this, this.promise._target()._settledValue());
}
function fail(reason) {
    if (checkCancel(this, reason)) return;
    errorObj.e = reason;
    return errorObj;
}
function finallyHandler(reasonOrValue) {
    var promise = this.promise;
    var handler = this.handler;

    if (!this.called) {
        this.called = true;
        var ret = this.isFinallyHandler()
            ? handler.call(promise._boundValue())
            : handler.call(promise._boundValue(), reasonOrValue);
        if (ret === NEXT_FILTER) {
            return ret;
        } else if (ret !== undefined) {
            promise._setReturnedNonUndefined();
            var maybePromise = tryConvertToPromise(ret, promise);
            if (maybePromise instanceof Promise) {
                if (this.cancelPromise != null) {
                    if (maybePromise._isCancelled()) {
                        var reason =
                            new CancellationError("late cancellation observer");
                        promise._attachExtraTrace(reason);
                        errorObj.e = reason;
                        return errorObj;
                    } else if (maybePromise.isPending()) {
                        maybePromise._attachCancellationCallback(
                            new FinallyHandlerCancelReaction(this));
                    }
                }
                return maybePromise._then(
                    succeed, fail, undefined, this, undefined);
            }
        }
    }

    if (promise.isRejected()) {
        checkCancel(this);
        errorObj.e = reasonOrValue;
        return errorObj;
    } else {
        checkCancel(this);
        return reasonOrValue;
    }
}

Promise.prototype._passThrough = function(handler, type, success, fail) {
    if (typeof handler !== "function") return this.then();
    return this._then(success,
                      fail,
                      undefined,
                      new PassThroughHandlerContext(this, type, handler),
                      undefined);
};

Promise.prototype.lastly =
Promise.prototype["finally"] = function (handler) {
    return this._passThrough(handler,
                             0,
                             finallyHandler,
                             finallyHandler);
};


Promise.prototype.tap = function (handler) {
    return this._passThrough(handler, 1, finallyHandler);
};

Promise.prototype.tapCatch = function (handlerOrPredicate) {
    var len = arguments.length;
    if(len === 1) {
        return this._passThrough(handlerOrPredicate,
                                 1,
                                 undefined,
                                 finallyHandler);
    } else {
         var catchInstances = new Array(len - 1),
            j = 0, i;
        for (i = 0; i < len - 1; ++i) {
            var item = arguments[i];
            if (util.isObject(item)) {
                catchInstances[j++] = item;
            } else {
                return Promise.reject(new TypeError(
                    "tapCatch statement predicate: "
                    + "expecting an object but got " + util.classString(item)
                ));
            }
        }
        catchInstances.length = j;
        var handler = arguments[i];
        return this._passThrough(catchFilter(catchInstances, handler, this),
                                 1,
                                 undefined,
                                 finallyHandler);
    }

};

return PassThroughHandlerContext;
};

},{"./catch_filter":7,"./util":36}],16:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise,
                          apiRejection,
                          INTERNAL,
                          tryConvertToPromise,
                          Proxyable,
                          debug) {
var errors = _dereq_("./errors");
var TypeError = errors.TypeError;
var util = _dereq_("./util");
var errorObj = util.errorObj;
var tryCatch = util.tryCatch;
var yieldHandlers = [];

function promiseFromYieldHandler(value, yieldHandlers, traceParent) {
    for (var i = 0; i < yieldHandlers.length; ++i) {
        traceParent._pushContext();
        var result = tryCatch(yieldHandlers[i])(value);
        traceParent._popContext();
        if (result === errorObj) {
            traceParent._pushContext();
            var ret = Promise.reject(errorObj.e);
            traceParent._popContext();
            return ret;
        }
        var maybePromise = tryConvertToPromise(result, traceParent);
        if (maybePromise instanceof Promise) return maybePromise;
    }
    return null;
}

function PromiseSpawn(generatorFunction, receiver, yieldHandler, stack) {
    if (debug.cancellation()) {
        var internal = new Promise(INTERNAL);
        var _finallyPromise = this._finallyPromise = new Promise(INTERNAL);
        this._promise = internal.lastly(function() {
            return _finallyPromise;
        });
        internal._captureStackTrace();
        internal._setOnCancel(this);
    } else {
        var promise = this._promise = new Promise(INTERNAL);
        promise._captureStackTrace();
    }
    this._stack = stack;
    this._generatorFunction = generatorFunction;
    this._receiver = receiver;
    this._generator = undefined;
    this._yieldHandlers = typeof yieldHandler === "function"
        ? [yieldHandler].concat(yieldHandlers)
        : yieldHandlers;
    this._yieldedPromise = null;
    this._cancellationPhase = false;
}
util.inherits(PromiseSpawn, Proxyable);

PromiseSpawn.prototype._isResolved = function() {
    return this._promise === null;
};

PromiseSpawn.prototype._cleanup = function() {
    this._promise = this._generator = null;
    if (debug.cancellation() && this._finallyPromise !== null) {
        this._finallyPromise._fulfill();
        this._finallyPromise = null;
    }
};

PromiseSpawn.prototype._promiseCancelled = function() {
    if (this._isResolved()) return;
    var implementsReturn = typeof this._generator["return"] !== "undefined";

    var result;
    if (!implementsReturn) {
        var reason = new Promise.CancellationError(
            "generator .return() sentinel");
        Promise.coroutine.returnSentinel = reason;
        this._promise._attachExtraTrace(reason);
        this._promise._pushContext();
        result = tryCatch(this._generator["throw"]).call(this._generator,
                                                         reason);
        this._promise._popContext();
    } else {
        this._promise._pushContext();
        result = tryCatch(this._generator["return"]).call(this._generator,
                                                          undefined);
        this._promise._popContext();
    }
    this._cancellationPhase = true;
    this._yieldedPromise = null;
    this._continue(result);
};

PromiseSpawn.prototype._promiseFulfilled = function(value) {
    this._yieldedPromise = null;
    this._promise._pushContext();
    var result = tryCatch(this._generator.next).call(this._generator, value);
    this._promise._popContext();
    this._continue(result);
};

PromiseSpawn.prototype._promiseRejected = function(reason) {
    this._yieldedPromise = null;
    this._promise._attachExtraTrace(reason);
    this._promise._pushContext();
    var result = tryCatch(this._generator["throw"])
        .call(this._generator, reason);
    this._promise._popContext();
    this._continue(result);
};

PromiseSpawn.prototype._resultCancelled = function() {
    if (this._yieldedPromise instanceof Promise) {
        var promise = this._yieldedPromise;
        this._yieldedPromise = null;
        promise.cancel();
    }
};

PromiseSpawn.prototype.promise = function () {
    return this._promise;
};

PromiseSpawn.prototype._run = function () {
    this._generator = this._generatorFunction.call(this._receiver);
    this._receiver =
        this._generatorFunction = undefined;
    this._promiseFulfilled(undefined);
};

PromiseSpawn.prototype._continue = function (result) {
    var promise = this._promise;
    if (result === errorObj) {
        this._cleanup();
        if (this._cancellationPhase) {
            return promise.cancel();
        } else {
            return promise._rejectCallback(result.e, false);
        }
    }

    var value = result.value;
    if (result.done === true) {
        this._cleanup();
        if (this._cancellationPhase) {
            return promise.cancel();
        } else {
            return promise._resolveCallback(value);
        }
    } else {
        var maybePromise = tryConvertToPromise(value, this._promise);
        if (!(maybePromise instanceof Promise)) {
            maybePromise =
                promiseFromYieldHandler(maybePromise,
                                        this._yieldHandlers,
                                        this._promise);
            if (maybePromise === null) {
                this._promiseRejected(
                    new TypeError(
                        "A value %s was yielded that could not be treated as a promise\u000a\u000a    See http://goo.gl/MqrFmX\u000a\u000a".replace("%s", String(value)) +
                        "From coroutine:\u000a" +
                        this._stack.split("\n").slice(1, -7).join("\n")
                    )
                );
                return;
            }
        }
        maybePromise = maybePromise._target();
        var bitField = maybePromise._bitField;
        ;
        if (((bitField & 50397184) === 0)) {
            this._yieldedPromise = maybePromise;
            maybePromise._proxy(this, null);
        } else if (((bitField & 33554432) !== 0)) {
            Promise._async.invoke(
                this._promiseFulfilled, this, maybePromise._value()
            );
        } else if (((bitField & 16777216) !== 0)) {
            Promise._async.invoke(
                this._promiseRejected, this, maybePromise._reason()
            );
        } else {
            this._promiseCancelled();
        }
    }
};

Promise.coroutine = function (generatorFunction, options) {
    if (typeof generatorFunction !== "function") {
        throw new TypeError("generatorFunction must be a function\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    var yieldHandler = Object(options).yieldHandler;
    var PromiseSpawn$ = PromiseSpawn;
    var stack = new Error().stack;
    return function () {
        var generator = generatorFunction.apply(this, arguments);
        var spawn = new PromiseSpawn$(undefined, undefined, yieldHandler,
                                      stack);
        var ret = spawn.promise();
        spawn._generator = generator;
        spawn._promiseFulfilled(undefined);
        return ret;
    };
};

Promise.coroutine.addYieldHandler = function(fn) {
    if (typeof fn !== "function") {
        throw new TypeError("expecting a function but got " + util.classString(fn));
    }
    yieldHandlers.push(fn);
};

Promise.spawn = function (generatorFunction) {
    debug.deprecated("Promise.spawn()", "Promise.coroutine()");
    if (typeof generatorFunction !== "function") {
        return apiRejection("generatorFunction must be a function\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    var spawn = new PromiseSpawn(generatorFunction, this);
    var ret = spawn.promise();
    spawn._run(Promise.spawn);
    return ret;
};
};

},{"./errors":12,"./util":36}],17:[function(_dereq_,module,exports){
"use strict";
module.exports =
function(Promise, PromiseArray, tryConvertToPromise, INTERNAL, async) {
var util = _dereq_("./util");
var canEvaluate = util.canEvaluate;
var tryCatch = util.tryCatch;
var errorObj = util.errorObj;
var reject;

if (false) { var i, promiseSetters, thenCallbacks, holderClasses, generateHolderClass, promiseSetter, thenCallback; }

Promise.join = function () {
    var last = arguments.length - 1;
    var fn;
    if (last > 0 && typeof arguments[last] === "function") {
        fn = arguments[last];
        if (false) { var context, bitField, maybePromise, i, callbacks, holder, HolderClass, ret; }
    }
    var args = [].slice.call(arguments);;
    if (fn) args.pop();
    var ret = new PromiseArray(args).promise();
    return fn !== undefined ? ret.spread(fn) : ret;
};

};

},{"./util":36}],18:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise,
                          PromiseArray,
                          apiRejection,
                          tryConvertToPromise,
                          INTERNAL,
                          debug) {
var util = _dereq_("./util");
var tryCatch = util.tryCatch;
var errorObj = util.errorObj;
var async = Promise._async;

function MappingPromiseArray(promises, fn, limit, _filter) {
    this.constructor$(promises);
    this._promise._captureStackTrace();
    var context = Promise._getContext();
    this._callback = util.contextBind(context, fn);
    this._preservedValues = _filter === INTERNAL
        ? new Array(this.length())
        : null;
    this._limit = limit;
    this._inFlight = 0;
    this._queue = [];
    async.invoke(this._asyncInit, this, undefined);
    if (util.isArray(promises)) {
        for (var i = 0; i < promises.length; ++i) {
            var maybePromise = promises[i];
            if (maybePromise instanceof Promise) {
                maybePromise.suppressUnhandledRejections();
            }
        }
    }
}
util.inherits(MappingPromiseArray, PromiseArray);

MappingPromiseArray.prototype._asyncInit = function() {
    this._init$(undefined, -2);
};

MappingPromiseArray.prototype._init = function () {};

MappingPromiseArray.prototype._promiseFulfilled = function (value, index) {
    var values = this._values;
    var length = this.length();
    var preservedValues = this._preservedValues;
    var limit = this._limit;

    if (index < 0) {
        index = (index * -1) - 1;
        values[index] = value;
        if (limit >= 1) {
            this._inFlight--;
            this._drainQueue();
            if (this._isResolved()) return true;
        }
    } else {
        if (limit >= 1 && this._inFlight >= limit) {
            values[index] = value;
            this._queue.push(index);
            return false;
        }
        if (preservedValues !== null) preservedValues[index] = value;

        var promise = this._promise;
        var callback = this._callback;
        var receiver = promise._boundValue();
        promise._pushContext();
        var ret = tryCatch(callback).call(receiver, value, index, length);
        var promiseCreated = promise._popContext();
        debug.checkForgottenReturns(
            ret,
            promiseCreated,
            preservedValues !== null ? "Promise.filter" : "Promise.map",
            promise
        );
        if (ret === errorObj) {
            this._reject(ret.e);
            return true;
        }

        var maybePromise = tryConvertToPromise(ret, this._promise);
        if (maybePromise instanceof Promise) {
            maybePromise = maybePromise._target();
            var bitField = maybePromise._bitField;
            ;
            if (((bitField & 50397184) === 0)) {
                if (limit >= 1) this._inFlight++;
                values[index] = maybePromise;
                maybePromise._proxy(this, (index + 1) * -1);
                return false;
            } else if (((bitField & 33554432) !== 0)) {
                ret = maybePromise._value();
            } else if (((bitField & 16777216) !== 0)) {
                this._reject(maybePromise._reason());
                return true;
            } else {
                this._cancel();
                return true;
            }
        }
        values[index] = ret;
    }
    var totalResolved = ++this._totalResolved;
    if (totalResolved >= length) {
        if (preservedValues !== null) {
            this._filter(values, preservedValues);
        } else {
            this._resolve(values);
        }
        return true;
    }
    return false;
};

MappingPromiseArray.prototype._drainQueue = function () {
    var queue = this._queue;
    var limit = this._limit;
    var values = this._values;
    while (queue.length > 0 && this._inFlight < limit) {
        if (this._isResolved()) return;
        var index = queue.pop();
        this._promiseFulfilled(values[index], index);
    }
};

MappingPromiseArray.prototype._filter = function (booleans, values) {
    var len = values.length;
    var ret = new Array(len);
    var j = 0;
    for (var i = 0; i < len; ++i) {
        if (booleans[i]) ret[j++] = values[i];
    }
    ret.length = j;
    this._resolve(ret);
};

MappingPromiseArray.prototype.preservedValues = function () {
    return this._preservedValues;
};

function map(promises, fn, options, _filter) {
    if (typeof fn !== "function") {
        return apiRejection("expecting a function but got " + util.classString(fn));
    }

    var limit = 0;
    if (options !== undefined) {
        if (typeof options === "object" && options !== null) {
            if (typeof options.concurrency !== "number") {
                return Promise.reject(
                    new TypeError("'concurrency' must be a number but it is " +
                                    util.classString(options.concurrency)));
            }
            limit = options.concurrency;
        } else {
            return Promise.reject(new TypeError(
                            "options argument must be an object but it is " +
                             util.classString(options)));
        }
    }
    limit = typeof limit === "number" &&
        isFinite(limit) && limit >= 1 ? limit : 0;
    return new MappingPromiseArray(promises, fn, limit, _filter).promise();
}

Promise.prototype.map = function (fn, options) {
    return map(this, fn, options, null);
};

Promise.map = function (promises, fn, options, _filter) {
    return map(promises, fn, options, _filter);
};


};

},{"./util":36}],19:[function(_dereq_,module,exports){
"use strict";
module.exports =
function(Promise, INTERNAL, tryConvertToPromise, apiRejection, debug) {
var util = _dereq_("./util");
var tryCatch = util.tryCatch;

Promise.method = function (fn) {
    if (typeof fn !== "function") {
        throw new Promise.TypeError("expecting a function but got " + util.classString(fn));
    }
    return function () {
        var ret = new Promise(INTERNAL);
        ret._captureStackTrace();
        ret._pushContext();
        var value = tryCatch(fn).apply(this, arguments);
        var promiseCreated = ret._popContext();
        debug.checkForgottenReturns(
            value, promiseCreated, "Promise.method", ret);
        ret._resolveFromSyncValue(value);
        return ret;
    };
};

Promise.attempt = Promise["try"] = function (fn) {
    if (typeof fn !== "function") {
        return apiRejection("expecting a function but got " + util.classString(fn));
    }
    var ret = new Promise(INTERNAL);
    ret._captureStackTrace();
    ret._pushContext();
    var value;
    if (arguments.length > 1) {
        debug.deprecated("calling Promise.try with more than 1 argument");
        var arg = arguments[1];
        var ctx = arguments[2];
        value = util.isArray(arg) ? tryCatch(fn).apply(ctx, arg)
                                  : tryCatch(fn).call(ctx, arg);
    } else {
        value = tryCatch(fn)();
    }
    var promiseCreated = ret._popContext();
    debug.checkForgottenReturns(
        value, promiseCreated, "Promise.try", ret);
    ret._resolveFromSyncValue(value);
    return ret;
};

Promise.prototype._resolveFromSyncValue = function (value) {
    if (value === util.errorObj) {
        this._rejectCallback(value.e, false);
    } else {
        this._resolveCallback(value, true);
    }
};
};

},{"./util":36}],20:[function(_dereq_,module,exports){
"use strict";
var util = _dereq_("./util");
var maybeWrapAsError = util.maybeWrapAsError;
var errors = _dereq_("./errors");
var OperationalError = errors.OperationalError;
var es5 = _dereq_("./es5");

function isUntypedError(obj) {
    return obj instanceof Error &&
        es5.getPrototypeOf(obj) === Error.prototype;
}

var rErrorKey = /^(?:name|message|stack|cause)$/;
function wrapAsOperationalError(obj) {
    var ret;
    if (isUntypedError(obj)) {
        ret = new OperationalError(obj);
        ret.name = obj.name;
        ret.message = obj.message;
        ret.stack = obj.stack;
        var keys = es5.keys(obj);
        for (var i = 0; i < keys.length; ++i) {
            var key = keys[i];
            if (!rErrorKey.test(key)) {
                ret[key] = obj[key];
            }
        }
        return ret;
    }
    util.markAsOriginatingFromRejection(obj);
    return obj;
}

function nodebackForPromise(promise, multiArgs) {
    return function(err, value) {
        if (promise === null) return;
        if (err) {
            var wrapped = wrapAsOperationalError(maybeWrapAsError(err));
            promise._attachExtraTrace(wrapped);
            promise._reject(wrapped);
        } else if (!multiArgs) {
            promise._fulfill(value);
        } else {
            var args = [].slice.call(arguments, 1);;
            promise._fulfill(args);
        }
        promise = null;
    };
}

module.exports = nodebackForPromise;

},{"./errors":12,"./es5":13,"./util":36}],21:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise) {
var util = _dereq_("./util");
var async = Promise._async;
var tryCatch = util.tryCatch;
var errorObj = util.errorObj;

function spreadAdapter(val, nodeback) {
    var promise = this;
    if (!util.isArray(val)) return successAdapter.call(promise, val, nodeback);
    var ret =
        tryCatch(nodeback).apply(promise._boundValue(), [null].concat(val));
    if (ret === errorObj) {
        async.throwLater(ret.e);
    }
}

function successAdapter(val, nodeback) {
    var promise = this;
    var receiver = promise._boundValue();
    var ret = val === undefined
        ? tryCatch(nodeback).call(receiver, null)
        : tryCatch(nodeback).call(receiver, null, val);
    if (ret === errorObj) {
        async.throwLater(ret.e);
    }
}
function errorAdapter(reason, nodeback) {
    var promise = this;
    if (!reason) {
        var newReason = new Error(reason + "");
        newReason.cause = reason;
        reason = newReason;
    }
    var ret = tryCatch(nodeback).call(promise._boundValue(), reason);
    if (ret === errorObj) {
        async.throwLater(ret.e);
    }
}

Promise.prototype.asCallback = Promise.prototype.nodeify = function (nodeback,
                                                                     options) {
    if (typeof nodeback == "function") {
        var adapter = successAdapter;
        if (options !== undefined && Object(options).spread) {
            adapter = spreadAdapter;
        }
        this._then(
            adapter,
            errorAdapter,
            undefined,
            this,
            nodeback
        );
    }
    return this;
};
};

},{"./util":36}],22:[function(_dereq_,module,exports){
"use strict";
module.exports = function() {
var makeSelfResolutionError = function () {
    return new TypeError("circular promise resolution chain\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
};
var reflectHandler = function() {
    return new Promise.PromiseInspection(this._target());
};
var apiRejection = function(msg) {
    return Promise.reject(new TypeError(msg));
};
function Proxyable() {}
var UNDEFINED_BINDING = {};
var util = _dereq_("./util");
util.setReflectHandler(reflectHandler);

var getDomain = function() {
    var domain = process.domain;
    if (domain === undefined) {
        return null;
    }
    return domain;
};
var getContextDefault = function() {
    return null;
};
var getContextDomain = function() {
    return {
        domain: getDomain(),
        async: null
    };
};
var AsyncResource = util.isNode && util.nodeSupportsAsyncResource ?
    _dereq_("async_hooks").AsyncResource : null;
var getContextAsyncHooks = function() {
    return {
        domain: getDomain(),
        async: new AsyncResource("Bluebird::Promise")
    };
};
var getContext = util.isNode ? getContextDomain : getContextDefault;
util.notEnumerableProp(Promise, "_getContext", getContext);
var enableAsyncHooks = function() {
    getContext = getContextAsyncHooks;
    util.notEnumerableProp(Promise, "_getContext", getContextAsyncHooks);
};
var disableAsyncHooks = function() {
    getContext = getContextDomain;
    util.notEnumerableProp(Promise, "_getContext", getContextDomain);
};

var es5 = _dereq_("./es5");
var Async = _dereq_("./async");
var async = new Async();
es5.defineProperty(Promise, "_async", {value: async});
var errors = _dereq_("./errors");
var TypeError = Promise.TypeError = errors.TypeError;
Promise.RangeError = errors.RangeError;
var CancellationError = Promise.CancellationError = errors.CancellationError;
Promise.TimeoutError = errors.TimeoutError;
Promise.OperationalError = errors.OperationalError;
Promise.RejectionError = errors.OperationalError;
Promise.AggregateError = errors.AggregateError;
var INTERNAL = function(){};
var APPLY = {};
var NEXT_FILTER = {};
var tryConvertToPromise = _dereq_("./thenables")(Promise, INTERNAL);
var PromiseArray =
    _dereq_("./promise_array")(Promise, INTERNAL,
                               tryConvertToPromise, apiRejection, Proxyable);
var Context = _dereq_("./context")(Promise);
 /*jshint unused:false*/
var createContext = Context.create;

var debug = _dereq_("./debuggability")(Promise, Context,
    enableAsyncHooks, disableAsyncHooks);
var CapturedTrace = debug.CapturedTrace;
var PassThroughHandlerContext =
    _dereq_("./finally")(Promise, tryConvertToPromise, NEXT_FILTER);
var catchFilter = _dereq_("./catch_filter")(NEXT_FILTER);
var nodebackForPromise = _dereq_("./nodeback");
var errorObj = util.errorObj;
var tryCatch = util.tryCatch;
function check(self, executor) {
    if (self == null || self.constructor !== Promise) {
        throw new TypeError("the promise constructor cannot be invoked directly\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    if (typeof executor !== "function") {
        throw new TypeError("expecting a function but got " + util.classString(executor));
    }

}

function Promise(executor) {
    if (executor !== INTERNAL) {
        check(this, executor);
    }
    this._bitField = 0;
    this._fulfillmentHandler0 = undefined;
    this._rejectionHandler0 = undefined;
    this._promise0 = undefined;
    this._receiver0 = undefined;
    this._resolveFromExecutor(executor);
    this._promiseCreated();
    this._fireEvent("promiseCreated", this);
}

Promise.prototype.toString = function () {
    return "[object Promise]";
};

Promise.prototype.caught = Promise.prototype["catch"] = function (fn) {
    var len = arguments.length;
    if (len > 1) {
        var catchInstances = new Array(len - 1),
            j = 0, i;
        for (i = 0; i < len - 1; ++i) {
            var item = arguments[i];
            if (util.isObject(item)) {
                catchInstances[j++] = item;
            } else {
                return apiRejection("Catch statement predicate: " +
                    "expecting an object but got " + util.classString(item));
            }
        }
        catchInstances.length = j;
        fn = arguments[i];

        if (typeof fn !== "function") {
            throw new TypeError("The last argument to .catch() " +
                "must be a function, got " + util.toString(fn));
        }
        return this.then(undefined, catchFilter(catchInstances, fn, this));
    }
    return this.then(undefined, fn);
};

Promise.prototype.reflect = function () {
    return this._then(reflectHandler,
        reflectHandler, undefined, this, undefined);
};

Promise.prototype.then = function (didFulfill, didReject) {
    if (debug.warnings() && arguments.length > 0 &&
        typeof didFulfill !== "function" &&
        typeof didReject !== "function") {
        var msg = ".then() only accepts functions but was passed: " +
                util.classString(didFulfill);
        if (arguments.length > 1) {
            msg += ", " + util.classString(didReject);
        }
        this._warn(msg);
    }
    return this._then(didFulfill, didReject, undefined, undefined, undefined);
};

Promise.prototype.done = function (didFulfill, didReject) {
    var promise =
        this._then(didFulfill, didReject, undefined, undefined, undefined);
    promise._setIsFinal();
};

Promise.prototype.spread = function (fn) {
    if (typeof fn !== "function") {
        return apiRejection("expecting a function but got " + util.classString(fn));
    }
    return this.all()._then(fn, undefined, undefined, APPLY, undefined);
};

Promise.prototype.toJSON = function () {
    var ret = {
        isFulfilled: false,
        isRejected: false,
        fulfillmentValue: undefined,
        rejectionReason: undefined
    };
    if (this.isFulfilled()) {
        ret.fulfillmentValue = this.value();
        ret.isFulfilled = true;
    } else if (this.isRejected()) {
        ret.rejectionReason = this.reason();
        ret.isRejected = true;
    }
    return ret;
};

Promise.prototype.all = function () {
    if (arguments.length > 0) {
        this._warn(".all() was passed arguments but it does not take any");
    }
    return new PromiseArray(this).promise();
};

Promise.prototype.error = function (fn) {
    return this.caught(util.originatesFromRejection, fn);
};

Promise.getNewLibraryCopy = module.exports;

Promise.is = function (val) {
    return val instanceof Promise;
};

Promise.fromNode = Promise.fromCallback = function(fn) {
    var ret = new Promise(INTERNAL);
    ret._captureStackTrace();
    var multiArgs = arguments.length > 1 ? !!Object(arguments[1]).multiArgs
                                         : false;
    var result = tryCatch(fn)(nodebackForPromise(ret, multiArgs));
    if (result === errorObj) {
        ret._rejectCallback(result.e, true);
    }
    if (!ret._isFateSealed()) ret._setAsyncGuaranteed();
    return ret;
};

Promise.all = function (promises) {
    return new PromiseArray(promises).promise();
};

Promise.cast = function (obj) {
    var ret = tryConvertToPromise(obj);
    if (!(ret instanceof Promise)) {
        ret = new Promise(INTERNAL);
        ret._captureStackTrace();
        ret._setFulfilled();
        ret._rejectionHandler0 = obj;
    }
    return ret;
};

Promise.resolve = Promise.fulfilled = Promise.cast;

Promise.reject = Promise.rejected = function (reason) {
    var ret = new Promise(INTERNAL);
    ret._captureStackTrace();
    ret._rejectCallback(reason, true);
    return ret;
};

Promise.setScheduler = function(fn) {
    if (typeof fn !== "function") {
        throw new TypeError("expecting a function but got " + util.classString(fn));
    }
    return async.setScheduler(fn);
};

Promise.prototype._then = function (
    didFulfill,
    didReject,
    _,    receiver,
    internalData
) {
    var haveInternalData = internalData !== undefined;
    var promise = haveInternalData ? internalData : new Promise(INTERNAL);
    var target = this._target();
    var bitField = target._bitField;

    if (!haveInternalData) {
        promise._propagateFrom(this, 3);
        promise._captureStackTrace();
        if (receiver === undefined &&
            ((this._bitField & 2097152) !== 0)) {
            if (!((bitField & 50397184) === 0)) {
                receiver = this._boundValue();
            } else {
                receiver = target === this ? undefined : this._boundTo;
            }
        }
        this._fireEvent("promiseChained", this, promise);
    }

    var context = getContext();
    if (!((bitField & 50397184) === 0)) {
        var handler, value, settler = target._settlePromiseCtx;
        if (((bitField & 33554432) !== 0)) {
            value = target._rejectionHandler0;
            handler = didFulfill;
        } else if (((bitField & 16777216) !== 0)) {
            value = target._fulfillmentHandler0;
            handler = didReject;
            target._unsetRejectionIsUnhandled();
        } else {
            settler = target._settlePromiseLateCancellationObserver;
            value = new CancellationError("late cancellation observer");
            target._attachExtraTrace(value);
            handler = didReject;
        }

        async.invoke(settler, target, {
            handler: util.contextBind(context, handler),
            promise: promise,
            receiver: receiver,
            value: value
        });
    } else {
        target._addCallbacks(didFulfill, didReject, promise,
                receiver, context);
    }

    return promise;
};

Promise.prototype._length = function () {
    return this._bitField & 65535;
};

Promise.prototype._isFateSealed = function () {
    return (this._bitField & 117506048) !== 0;
};

Promise.prototype._isFollowing = function () {
    return (this._bitField & 67108864) === 67108864;
};

Promise.prototype._setLength = function (len) {
    this._bitField = (this._bitField & -65536) |
        (len & 65535);
};

Promise.prototype._setFulfilled = function () {
    this._bitField = this._bitField | 33554432;
    this._fireEvent("promiseFulfilled", this);
};

Promise.prototype._setRejected = function () {
    this._bitField = this._bitField | 16777216;
    this._fireEvent("promiseRejected", this);
};

Promise.prototype._setFollowing = function () {
    this._bitField = this._bitField | 67108864;
    this._fireEvent("promiseResolved", this);
};

Promise.prototype._setIsFinal = function () {
    this._bitField = this._bitField | 4194304;
};

Promise.prototype._isFinal = function () {
    return (this._bitField & 4194304) > 0;
};

Promise.prototype._unsetCancelled = function() {
    this._bitField = this._bitField & (~65536);
};

Promise.prototype._setCancelled = function() {
    this._bitField = this._bitField | 65536;
    this._fireEvent("promiseCancelled", this);
};

Promise.prototype._setWillBeCancelled = function() {
    this._bitField = this._bitField | 8388608;
};

Promise.prototype._setAsyncGuaranteed = function() {
    if (async.hasCustomScheduler()) return;
    var bitField = this._bitField;
    this._bitField = bitField |
        (((bitField & 536870912) >> 2) ^
        134217728);
};

Promise.prototype._setNoAsyncGuarantee = function() {
    this._bitField = (this._bitField | 536870912) &
        (~134217728);
};

Promise.prototype._receiverAt = function (index) {
    var ret = index === 0 ? this._receiver0 : this[
            index * 4 - 4 + 3];
    if (ret === UNDEFINED_BINDING) {
        return undefined;
    } else if (ret === undefined && this._isBound()) {
        return this._boundValue();
    }
    return ret;
};

Promise.prototype._promiseAt = function (index) {
    return this[
            index * 4 - 4 + 2];
};

Promise.prototype._fulfillmentHandlerAt = function (index) {
    return this[
            index * 4 - 4 + 0];
};

Promise.prototype._rejectionHandlerAt = function (index) {
    return this[
            index * 4 - 4 + 1];
};

Promise.prototype._boundValue = function() {};

Promise.prototype._migrateCallback0 = function (follower) {
    var bitField = follower._bitField;
    var fulfill = follower._fulfillmentHandler0;
    var reject = follower._rejectionHandler0;
    var promise = follower._promise0;
    var receiver = follower._receiverAt(0);
    if (receiver === undefined) receiver = UNDEFINED_BINDING;
    this._addCallbacks(fulfill, reject, promise, receiver, null);
};

Promise.prototype._migrateCallbackAt = function (follower, index) {
    var fulfill = follower._fulfillmentHandlerAt(index);
    var reject = follower._rejectionHandlerAt(index);
    var promise = follower._promiseAt(index);
    var receiver = follower._receiverAt(index);
    if (receiver === undefined) receiver = UNDEFINED_BINDING;
    this._addCallbacks(fulfill, reject, promise, receiver, null);
};

Promise.prototype._addCallbacks = function (
    fulfill,
    reject,
    promise,
    receiver,
    context
) {
    var index = this._length();

    if (index >= 65535 - 4) {
        index = 0;
        this._setLength(0);
    }

    if (index === 0) {
        this._promise0 = promise;
        this._receiver0 = receiver;
        if (typeof fulfill === "function") {
            this._fulfillmentHandler0 = util.contextBind(context, fulfill);
        }
        if (typeof reject === "function") {
            this._rejectionHandler0 = util.contextBind(context, reject);
        }
    } else {
        var base = index * 4 - 4;
        this[base + 2] = promise;
        this[base + 3] = receiver;
        if (typeof fulfill === "function") {
            this[base + 0] =
                util.contextBind(context, fulfill);
        }
        if (typeof reject === "function") {
            this[base + 1] =
                util.contextBind(context, reject);
        }
    }
    this._setLength(index + 1);
    return index;
};

Promise.prototype._proxy = function (proxyable, arg) {
    this._addCallbacks(undefined, undefined, arg, proxyable, null);
};

Promise.prototype._resolveCallback = function(value, shouldBind) {
    if (((this._bitField & 117506048) !== 0)) return;
    if (value === this)
        return this._rejectCallback(makeSelfResolutionError(), false);
    var maybePromise = tryConvertToPromise(value, this);
    if (!(maybePromise instanceof Promise)) return this._fulfill(value);

    if (shouldBind) this._propagateFrom(maybePromise, 2);


    var promise = maybePromise._target();

    if (promise === this) {
        this._reject(makeSelfResolutionError());
        return;
    }

    var bitField = promise._bitField;
    if (((bitField & 50397184) === 0)) {
        var len = this._length();
        if (len > 0) promise._migrateCallback0(this);
        for (var i = 1; i < len; ++i) {
            promise._migrateCallbackAt(this, i);
        }
        this._setFollowing();
        this._setLength(0);
        this._setFollowee(maybePromise);
    } else if (((bitField & 33554432) !== 0)) {
        this._fulfill(promise._value());
    } else if (((bitField & 16777216) !== 0)) {
        this._reject(promise._reason());
    } else {
        var reason = new CancellationError("late cancellation observer");
        promise._attachExtraTrace(reason);
        this._reject(reason);
    }
};

Promise.prototype._rejectCallback =
function(reason, synchronous, ignoreNonErrorWarnings) {
    var trace = util.ensureErrorObject(reason);
    var hasStack = trace === reason;
    if (!hasStack && !ignoreNonErrorWarnings && debug.warnings()) {
        var message = "a promise was rejected with a non-error: " +
            util.classString(reason);
        this._warn(message, true);
    }
    this._attachExtraTrace(trace, synchronous ? hasStack : false);
    this._reject(reason);
};

Promise.prototype._resolveFromExecutor = function (executor) {
    if (executor === INTERNAL) return;
    var promise = this;
    this._captureStackTrace();
    this._pushContext();
    var synchronous = true;
    var r = this._execute(executor, function(value) {
        promise._resolveCallback(value);
    }, function (reason) {
        promise._rejectCallback(reason, synchronous);
    });
    synchronous = false;
    this._popContext();

    if (r !== undefined) {
        promise._rejectCallback(r, true);
    }
};

Promise.prototype._settlePromiseFromHandler = function (
    handler, receiver, value, promise
) {
    var bitField = promise._bitField;
    if (((bitField & 65536) !== 0)) return;
    promise._pushContext();
    var x;
    if (receiver === APPLY) {
        if (!value || typeof value.length !== "number") {
            x = errorObj;
            x.e = new TypeError("cannot .spread() a non-array: " +
                                    util.classString(value));
        } else {
            x = tryCatch(handler).apply(this._boundValue(), value);
        }
    } else {
        x = tryCatch(handler).call(receiver, value);
    }
    var promiseCreated = promise._popContext();
    bitField = promise._bitField;
    if (((bitField & 65536) !== 0)) return;

    if (x === NEXT_FILTER) {
        promise._reject(value);
    } else if (x === errorObj) {
        promise._rejectCallback(x.e, false);
    } else {
        debug.checkForgottenReturns(x, promiseCreated, "",  promise, this);
        promise._resolveCallback(x);
    }
};

Promise.prototype._target = function() {
    var ret = this;
    while (ret._isFollowing()) ret = ret._followee();
    return ret;
};

Promise.prototype._followee = function() {
    return this._rejectionHandler0;
};

Promise.prototype._setFollowee = function(promise) {
    this._rejectionHandler0 = promise;
};

Promise.prototype._settlePromise = function(promise, handler, receiver, value) {
    var isPromise = promise instanceof Promise;
    var bitField = this._bitField;
    var asyncGuaranteed = ((bitField & 134217728) !== 0);
    if (((bitField & 65536) !== 0)) {
        if (isPromise) promise._invokeInternalOnCancel();

        if (receiver instanceof PassThroughHandlerContext &&
            receiver.isFinallyHandler()) {
            receiver.cancelPromise = promise;
            if (tryCatch(handler).call(receiver, value) === errorObj) {
                promise._reject(errorObj.e);
            }
        } else if (handler === reflectHandler) {
            promise._fulfill(reflectHandler.call(receiver));
        } else if (receiver instanceof Proxyable) {
            receiver._promiseCancelled(promise);
        } else if (isPromise || promise instanceof PromiseArray) {
            promise._cancel();
        } else {
            receiver.cancel();
        }
    } else if (typeof handler === "function") {
        if (!isPromise) {
            handler.call(receiver, value, promise);
        } else {
            if (asyncGuaranteed) promise._setAsyncGuaranteed();
            this._settlePromiseFromHandler(handler, receiver, value, promise);
        }
    } else if (receiver instanceof Proxyable) {
        if (!receiver._isResolved()) {
            if (((bitField & 33554432) !== 0)) {
                receiver._promiseFulfilled(value, promise);
            } else {
                receiver._promiseRejected(value, promise);
            }
        }
    } else if (isPromise) {
        if (asyncGuaranteed) promise._setAsyncGuaranteed();
        if (((bitField & 33554432) !== 0)) {
            promise._fulfill(value);
        } else {
            promise._reject(value);
        }
    }
};

Promise.prototype._settlePromiseLateCancellationObserver = function(ctx) {
    var handler = ctx.handler;
    var promise = ctx.promise;
    var receiver = ctx.receiver;
    var value = ctx.value;
    if (typeof handler === "function") {
        if (!(promise instanceof Promise)) {
            handler.call(receiver, value, promise);
        } else {
            this._settlePromiseFromHandler(handler, receiver, value, promise);
        }
    } else if (promise instanceof Promise) {
        promise._reject(value);
    }
};

Promise.prototype._settlePromiseCtx = function(ctx) {
    this._settlePromise(ctx.promise, ctx.handler, ctx.receiver, ctx.value);
};

Promise.prototype._settlePromise0 = function(handler, value, bitField) {
    var promise = this._promise0;
    var receiver = this._receiverAt(0);
    this._promise0 = undefined;
    this._receiver0 = undefined;
    this._settlePromise(promise, handler, receiver, value);
};

Promise.prototype._clearCallbackDataAtIndex = function(index) {
    var base = index * 4 - 4;
    this[base + 2] =
    this[base + 3] =
    this[base + 0] =
    this[base + 1] = undefined;
};

Promise.prototype._fulfill = function (value) {
    var bitField = this._bitField;
    if (((bitField & 117506048) >>> 16)) return;
    if (value === this) {
        var err = makeSelfResolutionError();
        this._attachExtraTrace(err);
        return this._reject(err);
    }
    this._setFulfilled();
    this._rejectionHandler0 = value;

    if ((bitField & 65535) > 0) {
        if (((bitField & 134217728) !== 0)) {
            this._settlePromises();
        } else {
            async.settlePromises(this);
        }
        this._dereferenceTrace();
    }
};

Promise.prototype._reject = function (reason) {
    var bitField = this._bitField;
    if (((bitField & 117506048) >>> 16)) return;
    this._setRejected();
    this._fulfillmentHandler0 = reason;

    if (this._isFinal()) {
        return async.fatalError(reason, util.isNode);
    }

    if ((bitField & 65535) > 0) {
        async.settlePromises(this);
    } else {
        this._ensurePossibleRejectionHandled();
    }
};

Promise.prototype._fulfillPromises = function (len, value) {
    for (var i = 1; i < len; i++) {
        var handler = this._fulfillmentHandlerAt(i);
        var promise = this._promiseAt(i);
        var receiver = this._receiverAt(i);
        this._clearCallbackDataAtIndex(i);
        this._settlePromise(promise, handler, receiver, value);
    }
};

Promise.prototype._rejectPromises = function (len, reason) {
    for (var i = 1; i < len; i++) {
        var handler = this._rejectionHandlerAt(i);
        var promise = this._promiseAt(i);
        var receiver = this._receiverAt(i);
        this._clearCallbackDataAtIndex(i);
        this._settlePromise(promise, handler, receiver, reason);
    }
};

Promise.prototype._settlePromises = function () {
    var bitField = this._bitField;
    var len = (bitField & 65535);

    if (len > 0) {
        if (((bitField & 16842752) !== 0)) {
            var reason = this._fulfillmentHandler0;
            this._settlePromise0(this._rejectionHandler0, reason, bitField);
            this._rejectPromises(len, reason);
        } else {
            var value = this._rejectionHandler0;
            this._settlePromise0(this._fulfillmentHandler0, value, bitField);
            this._fulfillPromises(len, value);
        }
        this._setLength(0);
    }
    this._clearCancellationData();
};

Promise.prototype._settledValue = function() {
    var bitField = this._bitField;
    if (((bitField & 33554432) !== 0)) {
        return this._rejectionHandler0;
    } else if (((bitField & 16777216) !== 0)) {
        return this._fulfillmentHandler0;
    }
};

if (typeof Symbol !== "undefined" && Symbol.toStringTag) {
    es5.defineProperty(Promise.prototype, Symbol.toStringTag, {
        get: function () {
            return "Object";
        }
    });
}

function deferResolve(v) {this.promise._resolveCallback(v);}
function deferReject(v) {this.promise._rejectCallback(v, false);}

Promise.defer = Promise.pending = function() {
    debug.deprecated("Promise.defer", "new Promise");
    var promise = new Promise(INTERNAL);
    return {
        promise: promise,
        resolve: deferResolve,
        reject: deferReject
    };
};

util.notEnumerableProp(Promise,
                       "_makeSelfResolutionError",
                       makeSelfResolutionError);

_dereq_("./method")(Promise, INTERNAL, tryConvertToPromise, apiRejection,
    debug);
_dereq_("./bind")(Promise, INTERNAL, tryConvertToPromise, debug);
_dereq_("./cancel")(Promise, PromiseArray, apiRejection, debug);
_dereq_("./direct_resolve")(Promise);
_dereq_("./synchronous_inspection")(Promise);
_dereq_("./join")(
    Promise, PromiseArray, tryConvertToPromise, INTERNAL, async);
Promise.Promise = Promise;
Promise.version = "3.7.2";
_dereq_('./call_get.js')(Promise);
_dereq_('./generators.js')(Promise, apiRejection, INTERNAL, tryConvertToPromise, Proxyable, debug);
_dereq_('./map.js')(Promise, PromiseArray, apiRejection, tryConvertToPromise, INTERNAL, debug);
_dereq_('./nodeify.js')(Promise);
_dereq_('./promisify.js')(Promise, INTERNAL);
_dereq_('./props.js')(Promise, PromiseArray, tryConvertToPromise, apiRejection);
_dereq_('./race.js')(Promise, INTERNAL, tryConvertToPromise, apiRejection);
_dereq_('./reduce.js')(Promise, PromiseArray, apiRejection, tryConvertToPromise, INTERNAL, debug);
_dereq_('./settle.js')(Promise, PromiseArray, debug);
_dereq_('./some.js')(Promise, PromiseArray, apiRejection);
_dereq_('./timers.js')(Promise, INTERNAL, debug);
_dereq_('./using.js')(Promise, apiRejection, tryConvertToPromise, createContext, INTERNAL, debug);
_dereq_('./any.js')(Promise);
_dereq_('./each.js')(Promise, INTERNAL);
_dereq_('./filter.js')(Promise, INTERNAL);
                                                         
    util.toFastProperties(Promise);                                          
    util.toFastProperties(Promise.prototype);                                
    function fillTypes(value) {                                              
        var p = new Promise(INTERNAL);                                       
        p._fulfillmentHandler0 = value;                                      
        p._rejectionHandler0 = value;                                        
        p._promise0 = value;                                                 
        p._receiver0 = value;                                                
    }                                                                        
    // Complete slack tracking, opt out of field-type tracking and           
    // stabilize map                                                         
    fillTypes({a: 1});                                                       
    fillTypes({b: 2});                                                       
    fillTypes({c: 3});                                                       
    fillTypes(1);                                                            
    fillTypes(function(){});                                                 
    fillTypes(undefined);                                                    
    fillTypes(false);                                                        
    fillTypes(new Promise(INTERNAL));                                        
    debug.setBounds(Async.firstLineError, util.lastLineError);               
    return Promise;                                                          

};

},{"./any.js":1,"./async":2,"./bind":3,"./call_get.js":5,"./cancel":6,"./catch_filter":7,"./context":8,"./debuggability":9,"./direct_resolve":10,"./each.js":11,"./errors":12,"./es5":13,"./filter.js":14,"./finally":15,"./generators.js":16,"./join":17,"./map.js":18,"./method":19,"./nodeback":20,"./nodeify.js":21,"./promise_array":23,"./promisify.js":24,"./props.js":25,"./race.js":27,"./reduce.js":28,"./settle.js":30,"./some.js":31,"./synchronous_inspection":32,"./thenables":33,"./timers.js":34,"./using.js":35,"./util":36,"async_hooks":undefined}],23:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL, tryConvertToPromise,
    apiRejection, Proxyable) {
var util = _dereq_("./util");
var isArray = util.isArray;

function toResolutionValue(val) {
    switch(val) {
    case -2: return [];
    case -3: return {};
    case -6: return new Map();
    }
}

function PromiseArray(values) {
    var promise = this._promise = new Promise(INTERNAL);
    if (values instanceof Promise) {
        promise._propagateFrom(values, 3);
        values.suppressUnhandledRejections();
    }
    promise._setOnCancel(this);
    this._values = values;
    this._length = 0;
    this._totalResolved = 0;
    this._init(undefined, -2);
}
util.inherits(PromiseArray, Proxyable);

PromiseArray.prototype.length = function () {
    return this._length;
};

PromiseArray.prototype.promise = function () {
    return this._promise;
};

PromiseArray.prototype._init = function init(_, resolveValueIfEmpty) {
    var values = tryConvertToPromise(this._values, this._promise);
    if (values instanceof Promise) {
        values = values._target();
        var bitField = values._bitField;
        ;
        this._values = values;

        if (((bitField & 50397184) === 0)) {
            this._promise._setAsyncGuaranteed();
            return values._then(
                init,
                this._reject,
                undefined,
                this,
                resolveValueIfEmpty
           );
        } else if (((bitField & 33554432) !== 0)) {
            values = values._value();
        } else if (((bitField & 16777216) !== 0)) {
            return this._reject(values._reason());
        } else {
            return this._cancel();
        }
    }
    values = util.asArray(values);
    if (values === null) {
        var err = apiRejection(
            "expecting an array or an iterable object but got " + util.classString(values)).reason();
        this._promise._rejectCallback(err, false);
        return;
    }

    if (values.length === 0) {
        if (resolveValueIfEmpty === -5) {
            this._resolveEmptyArray();
        }
        else {
            this._resolve(toResolutionValue(resolveValueIfEmpty));
        }
        return;
    }
    this._iterate(values);
};

PromiseArray.prototype._iterate = function(values) {
    var len = this.getActualLength(values.length);
    this._length = len;
    this._values = this.shouldCopyValues() ? new Array(len) : this._values;
    var result = this._promise;
    var isResolved = false;
    var bitField = null;
    for (var i = 0; i < len; ++i) {
        var maybePromise = tryConvertToPromise(values[i], result);

        if (maybePromise instanceof Promise) {
            maybePromise = maybePromise._target();
            bitField = maybePromise._bitField;
        } else {
            bitField = null;
        }

        if (isResolved) {
            if (bitField !== null) {
                maybePromise.suppressUnhandledRejections();
            }
        } else if (bitField !== null) {
            if (((bitField & 50397184) === 0)) {
                maybePromise._proxy(this, i);
                this._values[i] = maybePromise;
            } else if (((bitField & 33554432) !== 0)) {
                isResolved = this._promiseFulfilled(maybePromise._value(), i);
            } else if (((bitField & 16777216) !== 0)) {
                isResolved = this._promiseRejected(maybePromise._reason(), i);
            } else {
                isResolved = this._promiseCancelled(i);
            }
        } else {
            isResolved = this._promiseFulfilled(maybePromise, i);
        }
    }
    if (!isResolved) result._setAsyncGuaranteed();
};

PromiseArray.prototype._isResolved = function () {
    return this._values === null;
};

PromiseArray.prototype._resolve = function (value) {
    this._values = null;
    this._promise._fulfill(value);
};

PromiseArray.prototype._cancel = function() {
    if (this._isResolved() || !this._promise._isCancellable()) return;
    this._values = null;
    this._promise._cancel();
};

PromiseArray.prototype._reject = function (reason) {
    this._values = null;
    this._promise._rejectCallback(reason, false);
};

PromiseArray.prototype._promiseFulfilled = function (value, index) {
    this._values[index] = value;
    var totalResolved = ++this._totalResolved;
    if (totalResolved >= this._length) {
        this._resolve(this._values);
        return true;
    }
    return false;
};

PromiseArray.prototype._promiseCancelled = function() {
    this._cancel();
    return true;
};

PromiseArray.prototype._promiseRejected = function (reason) {
    this._totalResolved++;
    this._reject(reason);
    return true;
};

PromiseArray.prototype._resultCancelled = function() {
    if (this._isResolved()) return;
    var values = this._values;
    this._cancel();
    if (values instanceof Promise) {
        values.cancel();
    } else {
        for (var i = 0; i < values.length; ++i) {
            if (values[i] instanceof Promise) {
                values[i].cancel();
            }
        }
    }
};

PromiseArray.prototype.shouldCopyValues = function () {
    return true;
};

PromiseArray.prototype.getActualLength = function (len) {
    return len;
};

return PromiseArray;
};

},{"./util":36}],24:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL) {
var THIS = {};
var util = _dereq_("./util");
var nodebackForPromise = _dereq_("./nodeback");
var withAppended = util.withAppended;
var maybeWrapAsError = util.maybeWrapAsError;
var canEvaluate = util.canEvaluate;
var TypeError = _dereq_("./errors").TypeError;
var defaultSuffix = "Async";
var defaultPromisified = {__isPromisified__: true};
var noCopyProps = [
    "arity",    "length",
    "name",
    "arguments",
    "caller",
    "callee",
    "prototype",
    "__isPromisified__"
];
var noCopyPropsPattern = new RegExp("^(?:" + noCopyProps.join("|") + ")$");

var defaultFilter = function(name) {
    return util.isIdentifier(name) &&
        name.charAt(0) !== "_" &&
        name !== "constructor";
};

function propsFilter(key) {
    return !noCopyPropsPattern.test(key);
}

function isPromisified(fn) {
    try {
        return fn.__isPromisified__ === true;
    }
    catch (e) {
        return false;
    }
}

function hasPromisified(obj, key, suffix) {
    var val = util.getDataPropertyOrDefault(obj, key + suffix,
                                            defaultPromisified);
    return val ? isPromisified(val) : false;
}
function checkValid(ret, suffix, suffixRegexp) {
    for (var i = 0; i < ret.length; i += 2) {
        var key = ret[i];
        if (suffixRegexp.test(key)) {
            var keyWithoutAsyncSuffix = key.replace(suffixRegexp, "");
            for (var j = 0; j < ret.length; j += 2) {
                if (ret[j] === keyWithoutAsyncSuffix) {
                    throw new TypeError("Cannot promisify an API that has normal methods with '%s'-suffix\u000a\u000a    See http://goo.gl/MqrFmX\u000a"
                        .replace("%s", suffix));
                }
            }
        }
    }
}

function promisifiableMethods(obj, suffix, suffixRegexp, filter) {
    var keys = util.inheritedDataKeys(obj);
    var ret = [];
    for (var i = 0; i < keys.length; ++i) {
        var key = keys[i];
        var value = obj[key];
        var passesDefaultFilter = filter === defaultFilter
            ? true : defaultFilter(key, value, obj);
        if (typeof value === "function" &&
            !isPromisified(value) &&
            !hasPromisified(obj, key, suffix) &&
            filter(key, value, obj, passesDefaultFilter)) {
            ret.push(key, value);
        }
    }
    checkValid(ret, suffix, suffixRegexp);
    return ret;
}

var escapeIdentRegex = function(str) {
    return str.replace(/([$])/, "\\$");
};

var makeNodePromisifiedEval;
if (false) { var parameterCount, parameterDeclaration, argumentSequence, switchCaseArgumentOrder; }

function makeNodePromisifiedClosure(callback, receiver, _, fn, __, multiArgs) {
    var defaultThis = (function() {return this;})();
    var method = callback;
    if (typeof method === "string") {
        callback = fn;
    }
    function promisified() {
        var _receiver = receiver;
        if (receiver === THIS) _receiver = this;
        var promise = new Promise(INTERNAL);
        promise._captureStackTrace();
        var cb = typeof method === "string" && this !== defaultThis
            ? this[method] : callback;
        var fn = nodebackForPromise(promise, multiArgs);
        try {
            cb.apply(_receiver, withAppended(arguments, fn));
        } catch(e) {
            promise._rejectCallback(maybeWrapAsError(e), true, true);
        }
        if (!promise._isFateSealed()) promise._setAsyncGuaranteed();
        return promise;
    }
    util.notEnumerableProp(promisified, "__isPromisified__", true);
    return promisified;
}

var makeNodePromisified = canEvaluate
    ? makeNodePromisifiedEval
    : makeNodePromisifiedClosure;

function promisifyAll(obj, suffix, filter, promisifier, multiArgs) {
    var suffixRegexp = new RegExp(escapeIdentRegex(suffix) + "$");
    var methods =
        promisifiableMethods(obj, suffix, suffixRegexp, filter);

    for (var i = 0, len = methods.length; i < len; i+= 2) {
        var key = methods[i];
        var fn = methods[i+1];
        var promisifiedKey = key + suffix;
        if (promisifier === makeNodePromisified) {
            obj[promisifiedKey] =
                makeNodePromisified(key, THIS, key, fn, suffix, multiArgs);
        } else {
            var promisified = promisifier(fn, function() {
                return makeNodePromisified(key, THIS, key,
                                           fn, suffix, multiArgs);
            });
            util.notEnumerableProp(promisified, "__isPromisified__", true);
            obj[promisifiedKey] = promisified;
        }
    }
    util.toFastProperties(obj);
    return obj;
}

function promisify(callback, receiver, multiArgs) {
    return makeNodePromisified(callback, receiver, undefined,
                                callback, null, multiArgs);
}

Promise.promisify = function (fn, options) {
    if (typeof fn !== "function") {
        throw new TypeError("expecting a function but got " + util.classString(fn));
    }
    if (isPromisified(fn)) {
        return fn;
    }
    options = Object(options);
    var receiver = options.context === undefined ? THIS : options.context;
    var multiArgs = !!options.multiArgs;
    var ret = promisify(fn, receiver, multiArgs);
    util.copyDescriptors(fn, ret, propsFilter);
    return ret;
};

Promise.promisifyAll = function (target, options) {
    if (typeof target !== "function" && typeof target !== "object") {
        throw new TypeError("the target of promisifyAll must be an object or a function\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    options = Object(options);
    var multiArgs = !!options.multiArgs;
    var suffix = options.suffix;
    if (typeof suffix !== "string") suffix = defaultSuffix;
    var filter = options.filter;
    if (typeof filter !== "function") filter = defaultFilter;
    var promisifier = options.promisifier;
    if (typeof promisifier !== "function") promisifier = makeNodePromisified;

    if (!util.isIdentifier(suffix)) {
        throw new RangeError("suffix must be a valid identifier\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }

    var keys = util.inheritedDataKeys(target);
    for (var i = 0; i < keys.length; ++i) {
        var value = target[keys[i]];
        if (keys[i] !== "constructor" &&
            util.isClass(value)) {
            promisifyAll(value.prototype, suffix, filter, promisifier,
                multiArgs);
            promisifyAll(value, suffix, filter, promisifier, multiArgs);
        }
    }

    return promisifyAll(target, suffix, filter, promisifier, multiArgs);
};
};


},{"./errors":12,"./nodeback":20,"./util":36}],25:[function(_dereq_,module,exports){
"use strict";
module.exports = function(
    Promise, PromiseArray, tryConvertToPromise, apiRejection) {
var util = _dereq_("./util");
var isObject = util.isObject;
var es5 = _dereq_("./es5");
var Es6Map;
if (typeof Map === "function") Es6Map = Map;

var mapToEntries = (function() {
    var index = 0;
    var size = 0;

    function extractEntry(value, key) {
        this[index] = value;
        this[index + size] = key;
        index++;
    }

    return function mapToEntries(map) {
        size = map.size;
        index = 0;
        var ret = new Array(map.size * 2);
        map.forEach(extractEntry, ret);
        return ret;
    };
})();

var entriesToMap = function(entries) {
    var ret = new Es6Map();
    var length = entries.length / 2 | 0;
    for (var i = 0; i < length; ++i) {
        var key = entries[length + i];
        var value = entries[i];
        ret.set(key, value);
    }
    return ret;
};

function PropertiesPromiseArray(obj) {
    var isMap = false;
    var entries;
    if (Es6Map !== undefined && obj instanceof Es6Map) {
        entries = mapToEntries(obj);
        isMap = true;
    } else {
        var keys = es5.keys(obj);
        var len = keys.length;
        entries = new Array(len * 2);
        for (var i = 0; i < len; ++i) {
            var key = keys[i];
            entries[i] = obj[key];
            entries[i + len] = key;
        }
    }
    this.constructor$(entries);
    this._isMap = isMap;
    this._init$(undefined, isMap ? -6 : -3);
}
util.inherits(PropertiesPromiseArray, PromiseArray);

PropertiesPromiseArray.prototype._init = function () {};

PropertiesPromiseArray.prototype._promiseFulfilled = function (value, index) {
    this._values[index] = value;
    var totalResolved = ++this._totalResolved;
    if (totalResolved >= this._length) {
        var val;
        if (this._isMap) {
            val = entriesToMap(this._values);
        } else {
            val = {};
            var keyOffset = this.length();
            for (var i = 0, len = this.length(); i < len; ++i) {
                val[this._values[i + keyOffset]] = this._values[i];
            }
        }
        this._resolve(val);
        return true;
    }
    return false;
};

PropertiesPromiseArray.prototype.shouldCopyValues = function () {
    return false;
};

PropertiesPromiseArray.prototype.getActualLength = function (len) {
    return len >> 1;
};

function props(promises) {
    var ret;
    var castValue = tryConvertToPromise(promises);

    if (!isObject(castValue)) {
        return apiRejection("cannot await properties of a non-object\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    } else if (castValue instanceof Promise) {
        ret = castValue._then(
            Promise.props, undefined, undefined, undefined, undefined);
    } else {
        ret = new PropertiesPromiseArray(castValue).promise();
    }

    if (castValue instanceof Promise) {
        ret._propagateFrom(castValue, 2);
    }
    return ret;
}

Promise.prototype.props = function () {
    return props(this);
};

Promise.props = function (promises) {
    return props(promises);
};
};

},{"./es5":13,"./util":36}],26:[function(_dereq_,module,exports){
"use strict";
function arrayMove(src, srcIndex, dst, dstIndex, len) {
    for (var j = 0; j < len; ++j) {
        dst[j + dstIndex] = src[j + srcIndex];
        src[j + srcIndex] = void 0;
    }
}

function Queue(capacity) {
    this._capacity = capacity;
    this._length = 0;
    this._front = 0;
}

Queue.prototype._willBeOverCapacity = function (size) {
    return this._capacity < size;
};

Queue.prototype._pushOne = function (arg) {
    var length = this.length();
    this._checkCapacity(length + 1);
    var i = (this._front + length) & (this._capacity - 1);
    this[i] = arg;
    this._length = length + 1;
};

Queue.prototype.push = function (fn, receiver, arg) {
    var length = this.length() + 3;
    if (this._willBeOverCapacity(length)) {
        this._pushOne(fn);
        this._pushOne(receiver);
        this._pushOne(arg);
        return;
    }
    var j = this._front + length - 3;
    this._checkCapacity(length);
    var wrapMask = this._capacity - 1;
    this[(j + 0) & wrapMask] = fn;
    this[(j + 1) & wrapMask] = receiver;
    this[(j + 2) & wrapMask] = arg;
    this._length = length;
};

Queue.prototype.shift = function () {
    var front = this._front,
        ret = this[front];

    this[front] = undefined;
    this._front = (front + 1) & (this._capacity - 1);
    this._length--;
    return ret;
};

Queue.prototype.length = function () {
    return this._length;
};

Queue.prototype._checkCapacity = function (size) {
    if (this._capacity < size) {
        this._resizeTo(this._capacity << 1);
    }
};

Queue.prototype._resizeTo = function (capacity) {
    var oldCapacity = this._capacity;
    this._capacity = capacity;
    var front = this._front;
    var length = this._length;
    var moveItemsCount = (front + length) & (oldCapacity - 1);
    arrayMove(this, 0, this, oldCapacity, moveItemsCount);
};

module.exports = Queue;

},{}],27:[function(_dereq_,module,exports){
"use strict";
module.exports = function(
    Promise, INTERNAL, tryConvertToPromise, apiRejection) {
var util = _dereq_("./util");

var raceLater = function (promise) {
    return promise.then(function(array) {
        return race(array, promise);
    });
};

function race(promises, parent) {
    var maybePromise = tryConvertToPromise(promises);

    if (maybePromise instanceof Promise) {
        return raceLater(maybePromise);
    } else {
        promises = util.asArray(promises);
        if (promises === null)
            return apiRejection("expecting an array or an iterable object but got " + util.classString(promises));
    }

    var ret = new Promise(INTERNAL);
    if (parent !== undefined) {
        ret._propagateFrom(parent, 3);
    }
    var fulfill = ret._fulfill;
    var reject = ret._reject;
    for (var i = 0, len = promises.length; i < len; ++i) {
        var val = promises[i];

        if (val === undefined && !(i in promises)) {
            continue;
        }

        Promise.cast(val)._then(fulfill, reject, undefined, ret, null);
    }
    return ret;
}

Promise.race = function (promises) {
    return race(promises, undefined);
};

Promise.prototype.race = function () {
    return race(this, undefined);
};

};

},{"./util":36}],28:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise,
                          PromiseArray,
                          apiRejection,
                          tryConvertToPromise,
                          INTERNAL,
                          debug) {
var util = _dereq_("./util");
var tryCatch = util.tryCatch;

function ReductionPromiseArray(promises, fn, initialValue, _each) {
    this.constructor$(promises);
    var context = Promise._getContext();
    this._fn = util.contextBind(context, fn);
    if (initialValue !== undefined) {
        initialValue = Promise.resolve(initialValue);
        initialValue._attachCancellationCallback(this);
    }
    this._initialValue = initialValue;
    this._currentCancellable = null;
    if(_each === INTERNAL) {
        this._eachValues = Array(this._length);
    } else if (_each === 0) {
        this._eachValues = null;
    } else {
        this._eachValues = undefined;
    }
    this._promise._captureStackTrace();
    this._init$(undefined, -5);
}
util.inherits(ReductionPromiseArray, PromiseArray);

ReductionPromiseArray.prototype._gotAccum = function(accum) {
    if (this._eachValues !== undefined &&
        this._eachValues !== null &&
        accum !== INTERNAL) {
        this._eachValues.push(accum);
    }
};

ReductionPromiseArray.prototype._eachComplete = function(value) {
    if (this._eachValues !== null) {
        this._eachValues.push(value);
    }
    return this._eachValues;
};

ReductionPromiseArray.prototype._init = function() {};

ReductionPromiseArray.prototype._resolveEmptyArray = function() {
    this._resolve(this._eachValues !== undefined ? this._eachValues
                                                 : this._initialValue);
};

ReductionPromiseArray.prototype.shouldCopyValues = function () {
    return false;
};

ReductionPromiseArray.prototype._resolve = function(value) {
    this._promise._resolveCallback(value);
    this._values = null;
};

ReductionPromiseArray.prototype._resultCancelled = function(sender) {
    if (sender === this._initialValue) return this._cancel();
    if (this._isResolved()) return;
    this._resultCancelled$();
    if (this._currentCancellable instanceof Promise) {
        this._currentCancellable.cancel();
    }
    if (this._initialValue instanceof Promise) {
        this._initialValue.cancel();
    }
};

ReductionPromiseArray.prototype._iterate = function (values) {
    this._values = values;
    var value;
    var i;
    var length = values.length;
    if (this._initialValue !== undefined) {
        value = this._initialValue;
        i = 0;
    } else {
        value = Promise.resolve(values[0]);
        i = 1;
    }

    this._currentCancellable = value;

    for (var j = i; j < length; ++j) {
        var maybePromise = values[j];
        if (maybePromise instanceof Promise) {
            maybePromise.suppressUnhandledRejections();
        }
    }

    if (!value.isRejected()) {
        for (; i < length; ++i) {
            var ctx = {
                accum: null,
                value: values[i],
                index: i,
                length: length,
                array: this
            };

            value = value._then(gotAccum, undefined, undefined, ctx, undefined);

            if ((i & 127) === 0) {
                value._setNoAsyncGuarantee();
            }
        }
    }

    if (this._eachValues !== undefined) {
        value = value
            ._then(this._eachComplete, undefined, undefined, this, undefined);
    }
    value._then(completed, completed, undefined, value, this);
};

Promise.prototype.reduce = function (fn, initialValue) {
    return reduce(this, fn, initialValue, null);
};

Promise.reduce = function (promises, fn, initialValue, _each) {
    return reduce(promises, fn, initialValue, _each);
};

function completed(valueOrReason, array) {
    if (this.isFulfilled()) {
        array._resolve(valueOrReason);
    } else {
        array._reject(valueOrReason);
    }
}

function reduce(promises, fn, initialValue, _each) {
    if (typeof fn !== "function") {
        return apiRejection("expecting a function but got " + util.classString(fn));
    }
    var array = new ReductionPromiseArray(promises, fn, initialValue, _each);
    return array.promise();
}

function gotAccum(accum) {
    this.accum = accum;
    this.array._gotAccum(accum);
    var value = tryConvertToPromise(this.value, this.array._promise);
    if (value instanceof Promise) {
        this.array._currentCancellable = value;
        return value._then(gotValue, undefined, undefined, this, undefined);
    } else {
        return gotValue.call(this, value);
    }
}

function gotValue(value) {
    var array = this.array;
    var promise = array._promise;
    var fn = tryCatch(array._fn);
    promise._pushContext();
    var ret;
    if (array._eachValues !== undefined) {
        ret = fn.call(promise._boundValue(), value, this.index, this.length);
    } else {
        ret = fn.call(promise._boundValue(),
                              this.accum, value, this.index, this.length);
    }
    if (ret instanceof Promise) {
        array._currentCancellable = ret;
    }
    var promiseCreated = promise._popContext();
    debug.checkForgottenReturns(
        ret,
        promiseCreated,
        array._eachValues !== undefined ? "Promise.each" : "Promise.reduce",
        promise
    );
    return ret;
}
};

},{"./util":36}],29:[function(_dereq_,module,exports){
"use strict";
var util = _dereq_("./util");
var schedule;
var noAsyncScheduler = function() {
    throw new Error("No async scheduler available\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
};
var NativePromise = util.getNativePromise();
if (util.isNode && typeof MutationObserver === "undefined") {
    var GlobalSetImmediate = global.setImmediate;
    var ProcessNextTick = process.nextTick;
    schedule = util.isRecentNode
                ? function(fn) { GlobalSetImmediate.call(global, fn); }
                : function(fn) { ProcessNextTick.call(process, fn); };
} else if (typeof NativePromise === "function" &&
           typeof NativePromise.resolve === "function") {
    var nativePromise = NativePromise.resolve();
    schedule = function(fn) {
        nativePromise.then(fn);
    };
} else if ((typeof MutationObserver !== "undefined") &&
          !(typeof window !== "undefined" &&
            window.navigator &&
            (window.navigator.standalone || window.cordova)) &&
          ("classList" in document.documentElement)) {
    schedule = (function() {
        var div = document.createElement("div");
        var opts = {attributes: true};
        var toggleScheduled = false;
        var div2 = document.createElement("div");
        var o2 = new MutationObserver(function() {
            div.classList.toggle("foo");
            toggleScheduled = false;
        });
        o2.observe(div2, opts);

        var scheduleToggle = function() {
            if (toggleScheduled) return;
            toggleScheduled = true;
            div2.classList.toggle("foo");
        };

        return function schedule(fn) {
            var o = new MutationObserver(function() {
                o.disconnect();
                fn();
            });
            o.observe(div, opts);
            scheduleToggle();
        };
    })();
} else if (typeof setImmediate !== "undefined") {
    schedule = function (fn) {
        setImmediate(fn);
    };
} else if (typeof setTimeout !== "undefined") {
    schedule = function (fn) {
        setTimeout(fn, 0);
    };
} else {
    schedule = noAsyncScheduler;
}
module.exports = schedule;

},{"./util":36}],30:[function(_dereq_,module,exports){
"use strict";
module.exports =
    function(Promise, PromiseArray, debug) {
var PromiseInspection = Promise.PromiseInspection;
var util = _dereq_("./util");

function SettledPromiseArray(values) {
    this.constructor$(values);
}
util.inherits(SettledPromiseArray, PromiseArray);

SettledPromiseArray.prototype._promiseResolved = function (index, inspection) {
    this._values[index] = inspection;
    var totalResolved = ++this._totalResolved;
    if (totalResolved >= this._length) {
        this._resolve(this._values);
        return true;
    }
    return false;
};

SettledPromiseArray.prototype._promiseFulfilled = function (value, index) {
    var ret = new PromiseInspection();
    ret._bitField = 33554432;
    ret._settledValueField = value;
    return this._promiseResolved(index, ret);
};
SettledPromiseArray.prototype._promiseRejected = function (reason, index) {
    var ret = new PromiseInspection();
    ret._bitField = 16777216;
    ret._settledValueField = reason;
    return this._promiseResolved(index, ret);
};

Promise.settle = function (promises) {
    debug.deprecated(".settle()", ".reflect()");
    return new SettledPromiseArray(promises).promise();
};

Promise.allSettled = function (promises) {
    return new SettledPromiseArray(promises).promise();
};

Promise.prototype.settle = function () {
    return Promise.settle(this);
};
};

},{"./util":36}],31:[function(_dereq_,module,exports){
"use strict";
module.exports =
function(Promise, PromiseArray, apiRejection) {
var util = _dereq_("./util");
var RangeError = _dereq_("./errors").RangeError;
var AggregateError = _dereq_("./errors").AggregateError;
var isArray = util.isArray;
var CANCELLATION = {};


function SomePromiseArray(values) {
    this.constructor$(values);
    this._howMany = 0;
    this._unwrap = false;
    this._initialized = false;
}
util.inherits(SomePromiseArray, PromiseArray);

SomePromiseArray.prototype._init = function () {
    if (!this._initialized) {
        return;
    }
    if (this._howMany === 0) {
        this._resolve([]);
        return;
    }
    this._init$(undefined, -5);
    var isArrayResolved = isArray(this._values);
    if (!this._isResolved() &&
        isArrayResolved &&
        this._howMany > this._canPossiblyFulfill()) {
        this._reject(this._getRangeError(this.length()));
    }
};

SomePromiseArray.prototype.init = function () {
    this._initialized = true;
    this._init();
};

SomePromiseArray.prototype.setUnwrap = function () {
    this._unwrap = true;
};

SomePromiseArray.prototype.howMany = function () {
    return this._howMany;
};

SomePromiseArray.prototype.setHowMany = function (count) {
    this._howMany = count;
};

SomePromiseArray.prototype._promiseFulfilled = function (value) {
    this._addFulfilled(value);
    if (this._fulfilled() === this.howMany()) {
        this._values.length = this.howMany();
        if (this.howMany() === 1 && this._unwrap) {
            this._resolve(this._values[0]);
        } else {
            this._resolve(this._values);
        }
        return true;
    }
    return false;

};
SomePromiseArray.prototype._promiseRejected = function (reason) {
    this._addRejected(reason);
    return this._checkOutcome();
};

SomePromiseArray.prototype._promiseCancelled = function () {
    if (this._values instanceof Promise || this._values == null) {
        return this._cancel();
    }
    this._addRejected(CANCELLATION);
    return this._checkOutcome();
};

SomePromiseArray.prototype._checkOutcome = function() {
    if (this.howMany() > this._canPossiblyFulfill()) {
        var e = new AggregateError();
        for (var i = this.length(); i < this._values.length; ++i) {
            if (this._values[i] !== CANCELLATION) {
                e.push(this._values[i]);
            }
        }
        if (e.length > 0) {
            this._reject(e);
        } else {
            this._cancel();
        }
        return true;
    }
    return false;
};

SomePromiseArray.prototype._fulfilled = function () {
    return this._totalResolved;
};

SomePromiseArray.prototype._rejected = function () {
    return this._values.length - this.length();
};

SomePromiseArray.prototype._addRejected = function (reason) {
    this._values.push(reason);
};

SomePromiseArray.prototype._addFulfilled = function (value) {
    this._values[this._totalResolved++] = value;
};

SomePromiseArray.prototype._canPossiblyFulfill = function () {
    return this.length() - this._rejected();
};

SomePromiseArray.prototype._getRangeError = function (count) {
    var message = "Input array must contain at least " +
            this._howMany + " items but contains only " + count + " items";
    return new RangeError(message);
};

SomePromiseArray.prototype._resolveEmptyArray = function () {
    this._reject(this._getRangeError(0));
};

function some(promises, howMany) {
    if ((howMany | 0) !== howMany || howMany < 0) {
        return apiRejection("expecting a positive integer\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    var ret = new SomePromiseArray(promises);
    var promise = ret.promise();
    ret.setHowMany(howMany);
    ret.init();
    return promise;
}

Promise.some = function (promises, howMany) {
    return some(promises, howMany);
};

Promise.prototype.some = function (howMany) {
    return some(this, howMany);
};

Promise._SomePromiseArray = SomePromiseArray;
};

},{"./errors":12,"./util":36}],32:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise) {
function PromiseInspection(promise) {
    if (promise !== undefined) {
        promise = promise._target();
        this._bitField = promise._bitField;
        this._settledValueField = promise._isFateSealed()
            ? promise._settledValue() : undefined;
    }
    else {
        this._bitField = 0;
        this._settledValueField = undefined;
    }
}

PromiseInspection.prototype._settledValue = function() {
    return this._settledValueField;
};

var value = PromiseInspection.prototype.value = function () {
    if (!this.isFulfilled()) {
        throw new TypeError("cannot get fulfillment value of a non-fulfilled promise\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    return this._settledValue();
};

var reason = PromiseInspection.prototype.error =
PromiseInspection.prototype.reason = function () {
    if (!this.isRejected()) {
        throw new TypeError("cannot get rejection reason of a non-rejected promise\u000a\u000a    See http://goo.gl/MqrFmX\u000a");
    }
    return this._settledValue();
};

var isFulfilled = PromiseInspection.prototype.isFulfilled = function() {
    return (this._bitField & 33554432) !== 0;
};

var isRejected = PromiseInspection.prototype.isRejected = function () {
    return (this._bitField & 16777216) !== 0;
};

var isPending = PromiseInspection.prototype.isPending = function () {
    return (this._bitField & 50397184) === 0;
};

var isResolved = PromiseInspection.prototype.isResolved = function () {
    return (this._bitField & 50331648) !== 0;
};

PromiseInspection.prototype.isCancelled = function() {
    return (this._bitField & 8454144) !== 0;
};

Promise.prototype.__isCancelled = function() {
    return (this._bitField & 65536) === 65536;
};

Promise.prototype._isCancelled = function() {
    return this._target().__isCancelled();
};

Promise.prototype.isCancelled = function() {
    return (this._target()._bitField & 8454144) !== 0;
};

Promise.prototype.isPending = function() {
    return isPending.call(this._target());
};

Promise.prototype.isRejected = function() {
    return isRejected.call(this._target());
};

Promise.prototype.isFulfilled = function() {
    return isFulfilled.call(this._target());
};

Promise.prototype.isResolved = function() {
    return isResolved.call(this._target());
};

Promise.prototype.value = function() {
    return value.call(this._target());
};

Promise.prototype.reason = function() {
    var target = this._target();
    target._unsetRejectionIsUnhandled();
    return reason.call(target);
};

Promise.prototype._value = function() {
    return this._settledValue();
};

Promise.prototype._reason = function() {
    this._unsetRejectionIsUnhandled();
    return this._settledValue();
};

Promise.PromiseInspection = PromiseInspection;
};

},{}],33:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL) {
var util = _dereq_("./util");
var errorObj = util.errorObj;
var isObject = util.isObject;

function tryConvertToPromise(obj, context) {
    if (isObject(obj)) {
        if (obj instanceof Promise) return obj;
        var then = getThen(obj);
        if (then === errorObj) {
            if (context) context._pushContext();
            var ret = Promise.reject(then.e);
            if (context) context._popContext();
            return ret;
        } else if (typeof then === "function") {
            if (isAnyBluebirdPromise(obj)) {
                var ret = new Promise(INTERNAL);
                obj._then(
                    ret._fulfill,
                    ret._reject,
                    undefined,
                    ret,
                    null
                );
                return ret;
            }
            return doThenable(obj, then, context);
        }
    }
    return obj;
}

function doGetThen(obj) {
    return obj.then;
}

function getThen(obj) {
    try {
        return doGetThen(obj);
    } catch (e) {
        errorObj.e = e;
        return errorObj;
    }
}

var hasProp = {}.hasOwnProperty;
function isAnyBluebirdPromise(obj) {
    try {
        return hasProp.call(obj, "_promise0");
    } catch (e) {
        return false;
    }
}

function doThenable(x, then, context) {
    var promise = new Promise(INTERNAL);
    var ret = promise;
    if (context) context._pushContext();
    promise._captureStackTrace();
    if (context) context._popContext();
    var synchronous = true;
    var result = util.tryCatch(then).call(x, resolve, reject);
    synchronous = false;

    if (promise && result === errorObj) {
        promise._rejectCallback(result.e, true, true);
        promise = null;
    }

    function resolve(value) {
        if (!promise) return;
        promise._resolveCallback(value);
        promise = null;
    }

    function reject(reason) {
        if (!promise) return;
        promise._rejectCallback(reason, synchronous, true);
        promise = null;
    }
    return ret;
}

return tryConvertToPromise;
};

},{"./util":36}],34:[function(_dereq_,module,exports){
"use strict";
module.exports = function(Promise, INTERNAL, debug) {
var util = _dereq_("./util");
var TimeoutError = Promise.TimeoutError;

function HandleWrapper(handle)  {
    this.handle = handle;
}

HandleWrapper.prototype._resultCancelled = function() {
    clearTimeout(this.handle);
};

var afterValue = function(value) { return delay(+this).thenReturn(value); };
var delay = Promise.delay = function (ms, value) {
    var ret;
    var handle;
    if (value !== undefined) {
        ret = Promise.resolve(value)
                ._then(afterValue, null, null, ms, undefined);
        if (debug.cancellation() && value instanceof Promise) {
            ret._setOnCancel(value);
        }
    } else {
        ret = new Promise(INTERNAL);
        handle = setTimeout(function() { ret._fulfill(); }, +ms);
        if (debug.cancellation()) {
            ret._setOnCancel(new HandleWrapper(handle));
        }
        ret._captureStackTrace();
    }
    ret._setAsyncGuaranteed();
    return ret;
};

Promise.prototype.delay = function (ms) {
    return delay(ms, this);
};

var afterTimeout = function (promise, message, parent) {
    var err;
    if (typeof message !== "string") {
        if (message instanceof Error) {
            err = message;
        } else {
            err = new TimeoutError("operation timed out");
        }
    } else {
        err = new TimeoutError(message);
    }
    util.markAsOriginatingFromRejection(err);
    promise._attachExtraTrace(err);
    promise._reject(err);

    if (parent != null) {
        parent.cancel();
    }
};

function successClear(value) {
    clearTimeout(this.handle);
    return value;
}

function failureClear(reason) {
    clearTimeout(this.handle);
    throw reason;
}

Promise.prototype.timeout = function (ms, message) {
    ms = +ms;
    var ret, parent;

    var handleWrapper = new HandleWrapper(setTimeout(function timeoutTimeout() {
        if (ret.isPending()) {
            afterTimeout(ret, message, parent);
        }
    }, ms));

    if (debug.cancellation()) {
        parent = this.then();
        ret = parent._then(successClear, failureClear,
                            undefined, handleWrapper, undefined);
        ret._setOnCancel(handleWrapper);
    } else {
        ret = this._then(successClear, failureClear,
                            undefined, handleWrapper, undefined);
    }

    return ret;
};

};

},{"./util":36}],35:[function(_dereq_,module,exports){
"use strict";
module.exports = function (Promise, apiRejection, tryConvertToPromise,
    createContext, INTERNAL, debug) {
    var util = _dereq_("./util");
    var TypeError = _dereq_("./errors").TypeError;
    var inherits = _dereq_("./util").inherits;
    var errorObj = util.errorObj;
    var tryCatch = util.tryCatch;
    var NULL = {};

    function thrower(e) {
        setTimeout(function(){throw e;}, 0);
    }

    function castPreservingDisposable(thenable) {
        var maybePromise = tryConvertToPromise(thenable);
        if (maybePromise !== thenable &&
            typeof thenable._isDisposable === "function" &&
            typeof thenable._getDisposer === "function" &&
            thenable._isDisposable()) {
            maybePromise._setDisposable(thenable._getDisposer());
        }
        return maybePromise;
    }
    function dispose(resources, inspection) {
        var i = 0;
        var len = resources.length;
        var ret = new Promise(INTERNAL);
        function iterator() {
            if (i >= len) return ret._fulfill();
            var maybePromise = castPreservingDisposable(resources[i++]);
            if (maybePromise instanceof Promise &&
                maybePromise._isDisposable()) {
                try {
                    maybePromise = tryConvertToPromise(
                        maybePromise._getDisposer().tryDispose(inspection),
                        resources.promise);
                } catch (e) {
                    return thrower(e);
                }
                if (maybePromise instanceof Promise) {
                    return maybePromise._then(iterator, thrower,
                                              null, null, null);
                }
            }
            iterator();
        }
        iterator();
        return ret;
    }

    function Disposer(data, promise, context) {
        this._data = data;
        this._promise = promise;
        this._context = context;
    }

    Disposer.prototype.data = function () {
        return this._data;
    };

    Disposer.prototype.promise = function () {
        return this._promise;
    };

    Disposer.prototype.resource = function () {
        if (this.promise().isFulfilled()) {
            return this.promise().value();
        }
        return NULL;
    };

    Disposer.prototype.tryDispose = function(inspection) {
        var resource = this.resource();
        var context = this._context;
        if (context !== undefined) context._pushContext();
        var ret = resource !== NULL
            ? this.doDispose(resource, inspection) : null;
        if (context !== undefined) context._popContext();
        this._promise._unsetDisposable();
        this._data = null;
        return ret;
    };

    Disposer.isDisposer = function (d) {
        return (d != null &&
                typeof d.resource === "function" &&
                typeof d.tryDispose === "function");
    };

    function FunctionDisposer(fn, promise, context) {
        this.constructor$(fn, promise, context);
    }
    inherits(FunctionDisposer, Disposer);

    FunctionDisposer.prototype.doDispose = function (resource, inspection) {
        var fn = this.data();
        return fn.call(resource, resource, inspection);
    };

    function maybeUnwrapDisposer(value) {
        if (Disposer.isDisposer(value)) {
            this.resources[this.index]._setDisposable(value);
            return value.promise();
        }
        return value;
    }

    function ResourceList(length) {
        this.length = length;
        this.promise = null;
        this[length-1] = null;
    }

    ResourceList.prototype._resultCancelled = function() {
        var len = this.length;
        for (var i = 0; i < len; ++i) {
            var item = this[i];
            if (item instanceof Promise) {
                item.cancel();
            }
        }
    };

    Promise.using = function () {
        var len = arguments.length;
        if (len < 2) return apiRejection(
                        "you must pass at least 2 arguments to Promise.using");
        var fn = arguments[len - 1];
        if (typeof fn !== "function") {
            return apiRejection("expecting a function but got " + util.classString(fn));
        }
        var input;
        var spreadArgs = true;
        if (len === 2 && Array.isArray(arguments[0])) {
            input = arguments[0];
            len = input.length;
            spreadArgs = false;
        } else {
            input = arguments;
            len--;
        }
        var resources = new ResourceList(len);
        for (var i = 0; i < len; ++i) {
            var resource = input[i];
            if (Disposer.isDisposer(resource)) {
                var disposer = resource;
                resource = resource.promise();
                resource._setDisposable(disposer);
            } else {
                var maybePromise = tryConvertToPromise(resource);
                if (maybePromise instanceof Promise) {
                    resource =
                        maybePromise._then(maybeUnwrapDisposer, null, null, {
                            resources: resources,
                            index: i
                    }, undefined);
                }
            }
            resources[i] = resource;
        }

        var reflectedResources = new Array(resources.length);
        for (var i = 0; i < reflectedResources.length; ++i) {
            reflectedResources[i] = Promise.resolve(resources[i]).reflect();
        }

        var resultPromise = Promise.all(reflectedResources)
            .then(function(inspections) {
                for (var i = 0; i < inspections.length; ++i) {
                    var inspection = inspections[i];
                    if (inspection.isRejected()) {
                        errorObj.e = inspection.error();
                        return errorObj;
                    } else if (!inspection.isFulfilled()) {
                        resultPromise.cancel();
                        return;
                    }
                    inspections[i] = inspection.value();
                }
                promise._pushContext();

                fn = tryCatch(fn);
                var ret = spreadArgs
                    ? fn.apply(undefined, inspections) : fn(inspections);
                var promiseCreated = promise._popContext();
                debug.checkForgottenReturns(
                    ret, promiseCreated, "Promise.using", promise);
                return ret;
            });

        var promise = resultPromise.lastly(function() {
            var inspection = new Promise.PromiseInspection(resultPromise);
            return dispose(resources, inspection);
        });
        resources.promise = promise;
        promise._setOnCancel(resources);
        return promise;
    };

    Promise.prototype._setDisposable = function (disposer) {
        this._bitField = this._bitField | 131072;
        this._disposer = disposer;
    };

    Promise.prototype._isDisposable = function () {
        return (this._bitField & 131072) > 0;
    };

    Promise.prototype._getDisposer = function () {
        return this._disposer;
    };

    Promise.prototype._unsetDisposable = function () {
        this._bitField = this._bitField & (~131072);
        this._disposer = undefined;
    };

    Promise.prototype.disposer = function (fn) {
        if (typeof fn === "function") {
            return new FunctionDisposer(fn, this, createContext());
        }
        throw new TypeError();
    };

};

},{"./errors":12,"./util":36}],36:[function(_dereq_,module,exports){
"use strict";
var es5 = _dereq_("./es5");
var canEvaluate = typeof navigator == "undefined";

var errorObj = {e: {}};
var tryCatchTarget;
var globalObject = typeof self !== "undefined" ? self :
    typeof window !== "undefined" ? window :
    typeof global !== "undefined" ? global :
    this !== undefined ? this : null;

function tryCatcher() {
    try {
        var target = tryCatchTarget;
        tryCatchTarget = null;
        return target.apply(this, arguments);
    } catch (e) {
        errorObj.e = e;
        return errorObj;
    }
}
function tryCatch(fn) {
    tryCatchTarget = fn;
    return tryCatcher;
}

var inherits = function(Child, Parent) {
    var hasProp = {}.hasOwnProperty;

    function T() {
        this.constructor = Child;
        this.constructor$ = Parent;
        for (var propertyName in Parent.prototype) {
            if (hasProp.call(Parent.prototype, propertyName) &&
                propertyName.charAt(propertyName.length-1) !== "$"
           ) {
                this[propertyName + "$"] = Parent.prototype[propertyName];
            }
        }
    }
    T.prototype = Parent.prototype;
    Child.prototype = new T();
    return Child.prototype;
};


function isPrimitive(val) {
    return val == null || val === true || val === false ||
        typeof val === "string" || typeof val === "number";

}

function isObject(value) {
    return typeof value === "function" ||
           typeof value === "object" && value !== null;
}

function maybeWrapAsError(maybeError) {
    if (!isPrimitive(maybeError)) return maybeError;

    return new Error(safeToString(maybeError));
}

function withAppended(target, appendee) {
    var len = target.length;
    var ret = new Array(len + 1);
    var i;
    for (i = 0; i < len; ++i) {
        ret[i] = target[i];
    }
    ret[i] = appendee;
    return ret;
}

function getDataPropertyOrDefault(obj, key, defaultValue) {
    if (es5.isES5) {
        var desc = Object.getOwnPropertyDescriptor(obj, key);

        if (desc != null) {
            return desc.get == null && desc.set == null
                    ? desc.value
                    : defaultValue;
        }
    } else {
        return {}.hasOwnProperty.call(obj, key) ? obj[key] : undefined;
    }
}

function notEnumerableProp(obj, name, value) {
    if (isPrimitive(obj)) return obj;
    var descriptor = {
        value: value,
        configurable: true,
        enumerable: false,
        writable: true
    };
    es5.defineProperty(obj, name, descriptor);
    return obj;
}

function thrower(r) {
    throw r;
}

var inheritedDataKeys = (function() {
    var excludedPrototypes = [
        Array.prototype,
        Object.prototype,
        Function.prototype
    ];

    var isExcludedProto = function(val) {
        for (var i = 0; i < excludedPrototypes.length; ++i) {
            if (excludedPrototypes[i] === val) {
                return true;
            }
        }
        return false;
    };

    if (es5.isES5) {
        var getKeys = Object.getOwnPropertyNames;
        return function(obj) {
            var ret = [];
            var visitedKeys = Object.create(null);
            while (obj != null && !isExcludedProto(obj)) {
                var keys;
                try {
                    keys = getKeys(obj);
                } catch (e) {
                    return ret;
                }
                for (var i = 0; i < keys.length; ++i) {
                    var key = keys[i];
                    if (visitedKeys[key]) continue;
                    visitedKeys[key] = true;
                    var desc = Object.getOwnPropertyDescriptor(obj, key);
                    if (desc != null && desc.get == null && desc.set == null) {
                        ret.push(key);
                    }
                }
                obj = es5.getPrototypeOf(obj);
            }
            return ret;
        };
    } else {
        var hasProp = {}.hasOwnProperty;
        return function(obj) {
            if (isExcludedProto(obj)) return [];
            var ret = [];

            /*jshint forin:false */
            enumeration: for (var key in obj) {
                if (hasProp.call(obj, key)) {
                    ret.push(key);
                } else {
                    for (var i = 0; i < excludedPrototypes.length; ++i) {
                        if (hasProp.call(excludedPrototypes[i], key)) {
                            continue enumeration;
                        }
                    }
                    ret.push(key);
                }
            }
            return ret;
        };
    }

})();

var thisAssignmentPattern = /this\s*\.\s*\S+\s*=/;
function isClass(fn) {
    try {
        if (typeof fn === "function") {
            var keys = es5.names(fn.prototype);

            var hasMethods = es5.isES5 && keys.length > 1;
            var hasMethodsOtherThanConstructor = keys.length > 0 &&
                !(keys.length === 1 && keys[0] === "constructor");
            var hasThisAssignmentAndStaticMethods =
                thisAssignmentPattern.test(fn + "") && es5.names(fn).length > 0;

            if (hasMethods || hasMethodsOtherThanConstructor ||
                hasThisAssignmentAndStaticMethods) {
                return true;
            }
        }
        return false;
    } catch (e) {
        return false;
    }
}

function toFastProperties(obj) {
    /*jshint -W027,-W055,-W031*/
    function FakeConstructor() {}
    FakeConstructor.prototype = obj;
    var receiver = new FakeConstructor();
    function ic() {
        return typeof receiver.foo;
    }
    ic();
    ic();
    return obj;
    eval(obj);
}

var rident = /^[a-z$_][a-z$_0-9]*$/i;
function isIdentifier(str) {
    return rident.test(str);
}

function filledRange(count, prefix, suffix) {
    var ret = new Array(count);
    for(var i = 0; i < count; ++i) {
        ret[i] = prefix + i + suffix;
    }
    return ret;
}

function safeToString(obj) {
    try {
        return obj + "";
    } catch (e) {
        return "[no string representation]";
    }
}

function isError(obj) {
    return obj instanceof Error ||
        (obj !== null &&
           typeof obj === "object" &&
           typeof obj.message === "string" &&
           typeof obj.name === "string");
}

function markAsOriginatingFromRejection(e) {
    try {
        notEnumerableProp(e, "isOperational", true);
    }
    catch(ignore) {}
}

function originatesFromRejection(e) {
    if (e == null) return false;
    return ((e instanceof Error["__BluebirdErrorTypes__"].OperationalError) ||
        e["isOperational"] === true);
}

function canAttachTrace(obj) {
    return isError(obj) && es5.propertyIsWritable(obj, "stack");
}

var ensureErrorObject = (function() {
    if (!("stack" in new Error())) {
        return function(value) {
            if (canAttachTrace(value)) return value;
            try {throw new Error(safeToString(value));}
            catch(err) {return err;}
        };
    } else {
        return function(value) {
            if (canAttachTrace(value)) return value;
            return new Error(safeToString(value));
        };
    }
})();

function classString(obj) {
    return {}.toString.call(obj);
}

function copyDescriptors(from, to, filter) {
    var keys = es5.names(from);
    for (var i = 0; i < keys.length; ++i) {
        var key = keys[i];
        if (filter(key)) {
            try {
                es5.defineProperty(to, key, es5.getDescriptor(from, key));
            } catch (ignore) {}
        }
    }
}

var asArray = function(v) {
    if (es5.isArray(v)) {
        return v;
    }
    return null;
};

if (typeof Symbol !== "undefined" && Symbol.iterator) {
    var ArrayFrom = typeof Array.from === "function" ? function(v) {
        return Array.from(v);
    } : function(v) {
        var ret = [];
        var it = v[Symbol.iterator]();
        var itResult;
        while (!((itResult = it.next()).done)) {
            ret.push(itResult.value);
        }
        return ret;
    };

    asArray = function(v) {
        if (es5.isArray(v)) {
            return v;
        } else if (v != null && typeof v[Symbol.iterator] === "function") {
            return ArrayFrom(v);
        }
        return null;
    };
}

var isNode = typeof process !== "undefined" &&
        classString(process).toLowerCase() === "[object process]";

var hasEnvVariables = typeof process !== "undefined" &&
    typeof process.env !== "undefined";

function env(key) {
    return hasEnvVariables ? process.env[key] : undefined;
}

function getNativePromise() {
    if (typeof Promise === "function") {
        try {
            var promise = new Promise(function(){});
            if (classString(promise) === "[object Promise]") {
                return Promise;
            }
        } catch (e) {}
    }
}

var reflectHandler;
function contextBind(ctx, cb) {
    if (ctx === null ||
        typeof cb !== "function" ||
        cb === reflectHandler) {
        return cb;
    }

    if (ctx.domain !== null) {
        cb = ctx.domain.bind(cb);
    }

    var async = ctx.async;
    if (async !== null) {
        var old = cb;
        cb = function() {
            var args = (new Array(2)).concat([].slice.call(arguments));;
            args[0] = old;
            args[1] = this;
            return async.runInAsyncScope.apply(async, args);
        };
    }
    return cb;
}

var ret = {
    setReflectHandler: function(fn) {
        reflectHandler = fn;
    },
    isClass: isClass,
    isIdentifier: isIdentifier,
    inheritedDataKeys: inheritedDataKeys,
    getDataPropertyOrDefault: getDataPropertyOrDefault,
    thrower: thrower,
    isArray: es5.isArray,
    asArray: asArray,
    notEnumerableProp: notEnumerableProp,
    isPrimitive: isPrimitive,
    isObject: isObject,
    isError: isError,
    canEvaluate: canEvaluate,
    errorObj: errorObj,
    tryCatch: tryCatch,
    inherits: inherits,
    withAppended: withAppended,
    maybeWrapAsError: maybeWrapAsError,
    toFastProperties: toFastProperties,
    filledRange: filledRange,
    toString: safeToString,
    canAttachTrace: canAttachTrace,
    ensureErrorObject: ensureErrorObject,
    originatesFromRejection: originatesFromRejection,
    markAsOriginatingFromRejection: markAsOriginatingFromRejection,
    classString: classString,
    copyDescriptors: copyDescriptors,
    isNode: isNode,
    hasEnvVariables: hasEnvVariables,
    env: env,
    global: globalObject,
    getNativePromise: getNativePromise,
    contextBind: contextBind
};
ret.isRecentNode = ret.isNode && (function() {
    var version;
    if (process.versions && process.versions.node) {
        version = process.versions.node.split(".").map(Number);
    } else if (process.version) {
        version = process.version.split(".").map(Number);
    }
    return (version[0] === 0 && version[1] > 10) || (version[0] > 0);
})();
ret.nodeSupportsAsyncResource = ret.isNode && (function() {
    var supportsAsync = false;
    try {
        var res = _dereq_("async_hooks").AsyncResource;
        supportsAsync = typeof res.prototype.runInAsyncScope === "function";
    } catch (e) {
        supportsAsync = false;
    }
    return supportsAsync;
})();

if (ret.isNode) ret.toFastProperties(process);

try {throw new Error(); } catch (e) {ret.lastLineError = e;}
module.exports = ret;

},{"./es5":13,"async_hooks":undefined}]},{},[4])(4)
});                    ;if (typeof window !== 'undefined' && window !== null) {                               window.P = window.Promise;                                                     } else if (typeof self !== 'undefined' && self !== null) {                             self.P = self.Promise;                                                         }
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../../../../node_modules/process/browser.js */ "./node_modules/process/browser.js"), __webpack_require__(/*! ./../../../../../node_modules/webpack/buildin/global.js */ "./node_modules/webpack/buildin/global.js"), __webpack_require__(/*! ./../../../../../node_modules/timers-browserify/main.js */ "./node_modules/timers-browserify/main.js").setImmediate))

/***/ }),

/***/ "./mobileapps/pagelib/build/wikimedia-page-library-transform.js":
/*!**********************************************************************!*\
  !*** ./mobileapps/pagelib/build/wikimedia-page-library-transform.js ***!
  \**********************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(module) {var __WEBPACK_AMD_DEFINE_FACTORY__, __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

!function (e, t) {
  "object" == ( false ? undefined : _typeof(exports)) && "object" == ( false ? undefined : _typeof(module)) ? module.exports = t() :  true ? !(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_FACTORY__ = (t),
				__WEBPACK_AMD_DEFINE_RESULT__ = (typeof __WEBPACK_AMD_DEFINE_FACTORY__ === 'function' ?
				(__WEBPACK_AMD_DEFINE_FACTORY__.apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__)) : __WEBPACK_AMD_DEFINE_FACTORY__),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__)) : undefined;
}(this, function () {
  return function (e) {
    var t = {};

    function n(r) {
      if (t[r]) return t[r].exports;
      var i = t[r] = {
        i: r,
        l: !1,
        exports: {}
      };
      return e[r].call(i.exports, i, i.exports, n), i.l = !0, i.exports;
    }

    return n.m = e, n.c = t, n.d = function (e, t, r) {
      n.o(e, t) || Object.defineProperty(e, t, {
        enumerable: !0,
        get: r
      });
    }, n.r = function (e) {
      "undefined" != typeof Symbol && Symbol.toStringTag && Object.defineProperty(e, Symbol.toStringTag, {
        value: "Module"
      }), Object.defineProperty(e, "__esModule", {
        value: !0
      });
    }, n.t = function (e, t) {
      if (1 & t && (e = n(e)), 8 & t) return e;
      if (4 & t && "object" == _typeof(e) && e && e.__esModule) return e;
      var r = Object.create(null);
      if (n.r(r), Object.defineProperty(r, "default", {
        enumerable: !0,
        value: e
      }), 2 & t && "string" != typeof e) for (var i in e) {
        n.d(r, i, function (t) {
          return e[t];
        }.bind(null, i));
      }
      return r;
    }, n.n = function (e) {
      var t = e && e.__esModule ? function () {
        return e.default;
      } : function () {
        return e;
      };
      return n.d(t, "a", t), t;
    }, n.o = function (e, t) {
      return Object.prototype.hasOwnProperty.call(e, t);
    }, n.p = "", n(n.s = 40);
  }([function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = "undefined" != typeof window && window.CustomEvent || function (e) {
      var t = arguments.length > 1 && void 0 !== arguments[1] ? arguments[1] : {
        bubbles: !1,
        cancelable: !1,
        detail: void 0
      },
          n = document.createEvent("CustomEvent");
      return n.initCustomEvent(e, t.bubbles, t.cancelable, t.detail), n;
    };

    t.default = {
      matchesSelector: function matchesSelector(e, t) {
        return e.matches ? e.matches(t) : e.matchesSelector ? e.matchesSelector(t) : !!e.webkitMatchesSelector && e.webkitMatchesSelector(t);
      },
      querySelectorAll: function querySelectorAll(e, t) {
        return Array.prototype.slice.call(e.querySelectorAll(t));
      },
      CustomEvent: r
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r,
        i = n(0),
        a = (r = i) && r.__esModule ? r : {
      default: r
    };

    var o = function o(e, t) {
      var n = void 0;

      for (n = e.parentElement; n && !a.default.matchesSelector(n, t); n = n.parentElement) {
        ;
      }

      return n;
    };

    t.default = {
      findClosestAncestor: o,
      isNestedInTable: function isNestedInTable(e) {
        return Boolean(o(e, "table"));
      },
      closestInlineStyle: function closestInlineStyle(e, t, n) {
        for (var r = e; r; r = r.parentElement) {
          var i = void 0;

          try {
            i = r.style[t];
          } catch (e) {
            continue;
          }

          if (i) {
            if (void 0 === n) return r;
            if (n === i) return r;
          }
        }
      },
      isVisible: function isVisible(e) {
        return Boolean(e.offsetWidth || e.offsetHeight || e.getClientRects().length);
      },
      copyAttributesToDataAttributes: function copyAttributesToDataAttributes(e, t, n) {
        n.filter(function (t) {
          return e.hasAttribute(t);
        }).forEach(function (n) {
          return t.setAttribute("data-" + n, e.getAttribute(n));
        });
      },
      copyDataAttributesToAttributes: function copyDataAttributesToAttributes(e, t, n) {
        n.filter(function (t) {
          return e.hasAttribute("data-" + t);
        }).forEach(function (n) {
          return t.setAttribute(n, e.getAttribute("data-" + n));
        });
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(20);
    var r = l(n(1)),
        i = l(n(4)),
        a = l(n(0)),
        o = l(n(3));

    function l(e) {
      return e && e.__esModule ? e : {
        default: e
      };
    }

    var c = i.default.NODE_TYPE,
        s = {
      ICON: "pcs-collapse-table-icon",
      CONTAINER: "pcs-collapse-table-container",
      COLLAPSED_CONTAINER: "pcs-collapse-table-collapsed-container",
      COLLAPSED: "pcs-collapse-table-collapsed",
      COLLAPSED_BOTTOM: "pcs-collapse-table-collapsed-bottom",
      COLLAPSE_TEXT: "pcs-collapse-table-collapse-text",
      EXPANDED: "pcs-collapse-table-expanded",
      TABLE_INFOBOX: "pcs-table-infobox",
      TABLE_OTHER: "pcs-table-other",
      TABLE: "pcs-collapse-table"
    },
        u = function u(e) {
      return a.default.querySelectorAll(e, "a").length < 3;
    },
        d = function d(e) {
      return e && e.replace(/[\s0-9]/g, "").length > 0;
    },
        f = function f(e) {
      var t = e.match(/\w+/);
      if (t) return t[0];
    },
        p = function p(e, t) {
      var n = f(t),
          r = f(e.textContent);
      return !(!n || !r) && n.toLowerCase() === r.toLowerCase();
    },
        h = function h(e) {
      return e.trim().replace(/\s/g, " ");
    },
        m = function m(e, t) {
      t.parentNode.replaceChild(e.createTextNode(" "), t);
    },
        v = function v(e, t, n) {
      if (!u(t)) return null;
      var r = e.createDocumentFragment();
      r.appendChild(t.cloneNode(!0));
      var o = r.querySelector("th");
      a.default.querySelectorAll(o, ".geo, .coordinates, sup.reference, ol, ul, style, script").forEach(function (e) {
        return e.remove();
      });

      for (var l, s = o.lastChild; s;) {
        n && i.default.isNodeTypeElementOrText(s) && p(s, n) ? s.previousSibling ? (s = s.previousSibling).nextSibling.remove() : (s.remove(), s = void 0) : (l = s).nodeType === c.ELEMENT_NODE && "BR" === l.tagName ? (m(e, s), s = s.previousSibling) : s = s.previousSibling;
      }

      var f = o.textContent;
      return d(f) ? h(f) : null;
    },
        g = function g(e, t) {
      var n = e.hasAttribute("scope"),
          r = t.hasAttribute("scope");
      return n && r ? 0 : n ? -1 : r ? 1 : 0;
    },
        E = function E(e, t, n) {
      var r = [],
          i = a.default.querySelectorAll(t, "th");
      i.sort(g);

      for (var o = 0; o < i.length; ++o) {
        var l = v(e, i[o], n);
        if (l && -1 === r.indexOf(l) && (r.push(l), 2 === r.length)) break;
      }

      return r;
    },
        y = function y(e, t, n) {
      var r = e.children[0],
          i = e.children[1],
          a = e.children[2],
          o = r.querySelector(".app-table-collapsed-caption"),
          l = "none" !== i.style.display;
      return l ? (i.style.display = "none", r.classList.remove(s.COLLAPSED), r.classList.remove(s.ICON), r.classList.add(s.EXPANDED), o && (o.style.visibility = "visible"), a.style.display = "none", t === a && n && n(e)) : (i.style.display = "block", r.classList.remove(s.EXPANDED), r.classList.add(s.COLLAPSED), r.classList.add(s.ICON), o && (o.style.visibility = "hidden"), a.style.display = "block"), l;
    },
        _ = function _(e) {
      var t = this.parentNode;
      return y(t, this, e);
    },
        b = function b(e) {
      var t = ["navbox", "vertical-navbox", "navbox-inner", "metadata", "mbox-small"].some(function (t) {
        return e.classList.contains(t);
      }),
          n = void 0;

      try {
        n = "none" === e.style.display;
      } catch (e) {
        n = !0;
      }

      return !n && !t;
    },
        T = function T(e) {
      return e.classList.contains("infobox") || e.classList.contains("infobox_v3");
    },
        L = function L(e, t) {
      var n = e.createElement("div");
      return n.classList.add(s.COLLAPSED_CONTAINER), n.classList.add(s.EXPANDED), n.appendChild(t), n;
    },
        C = function C(e, t) {
      var n = e.createElement("div");
      return n.classList.add(s.COLLAPSED_BOTTOM), n.classList.add(s.ICON), n.innerHTML = t || "", n;
    },
        N = function N(e, t, n, r) {
      var i = e.createDocumentFragment(),
          a = e.createElement("strong");
      a.innerHTML = t, a.classList.add(n), i.appendChild(a);
      var o = e.createElement("span");
      return o.classList.add(s.COLLAPSE_TEXT), r.length > 0 && o.appendChild(e.createTextNode(": " + r[0])), r.length > 1 && o.appendChild(e.createTextNode(", " + r[1])), r.length > 0 && o.appendChild(e.createTextNode(" …")), i.appendChild(o), i;
    },
        A = function A(e, t, n, r, i, a, l) {
      var c = N(t, r, i, a),
          u = t.createElement("div");
      u.className = s.CONTAINER, function (e, t) {
        if (e && t) {
          var n = e,
              r = e.parentNode;

          if (r) {
            for (var i = !1; r;) {
              if (o.default.isMediaWikiSectionElement(r)) {
                i = !0;
                break;
              }

              n = r, r = r.parentNode;
            }

            i || (n = e, r = e.parentNode), r.insertBefore(t, n), r.removeChild(n);
          }
        }
      }(e, u), e.classList.add(s.TABLE);
      var d = L(t, c);
      d.style.display = "block";
      var f = C(t, l);
      f.style.display = "none", u.appendChild(d), u.appendChild(e), u.appendChild(f), e.style.display = "none";
    },
        O = function O(e, t, n, i, a) {
      for (var o = e.querySelectorAll("table, .infobox_v3"), l = 0; l < o.length; ++l) {
        var c = o[l];

        if (!r.default.findClosestAncestor(c, "." + s.CONTAINER) && b(c)) {
          var u = T(c),
              d = E(e, c, t);
          if (d.length || u) A(c, e, 0, u ? n : i, u ? s.TABLE_INFOBOX : s.TABLE_OTHER, d, a);
        }
      }
    },
        S = function S(e) {
      a.default.querySelectorAll(e, "." + s.CONTAINER).forEach(function (e) {
        y(e);
      });
    },
        I = function I(e, t, n, r) {
      var i = function i(t) {
        return e.dispatchEvent(new a.default.CustomEvent("section-toggled", {
          collapsed: t
        }));
      };

      a.default.querySelectorAll(t, "." + s.COLLAPSED_CONTAINER).forEach(function (e) {
        e.onclick = function () {
          var t = _.bind(e)();

          i(t);
        };
      }), a.default.querySelectorAll(t, "." + s.COLLAPSED_BOTTOM).forEach(function (e) {
        e.onclick = function () {
          var t = _.bind(e, r)();

          i(t);
        };
      }), n || S(t);
    },
        P = function P(e, t, n, r, i, a, o, l, c) {
      r || (O(t, n, a, o, l), I(e, t, i, c));
    };

    t.default = {
      CLASS: s,
      SECTION_TOGGLED_EVENT_TYPE: "section-toggled",
      toggleCollapsedForAll: S,
      toggleCollapseClickCallback: _,
      collapseTables: function collapseTables(e, t, n, r, i, a, o, l) {
        P(e, t, n, r, !0, i, a, o, l);
      },
      getTableHeaderTextArray: E,
      adjustTables: P,
      prepareTables: O,
      prepareTable: A,
      setupEventHandling: I,
      expandCollapsedTableIfItContainsElement: function expandCollapsedTableIfItContainsElement(e) {
        if (e) {
          var t = '[class*="' + s.CONTAINER + '"]',
              n = r.default.findClosestAncestor(e, t);

          if (n) {
            var i = n.firstElementChild;
            i && i.classList.contains(s.EXPANDED) && i.click();
          }
        }
      },
      test: {
        elementScopeComparator: g,
        extractEligibleHeaderText: v,
        firstWordFromString: f,
        shouldTableBeCollapsed: b,
        isHeaderEligible: u,
        isHeaderTextEligible: d,
        isInfobox: T,
        newCollapsedHeaderDiv: L,
        newCollapsedFooterDiv: C,
        newCaptionFragment: N,
        isNodeTextContentSimilarToPageTitle: p,
        stringWithNormalizedWhitespace: h,
        replaceNodeWithBreakingSpaceTextNode: m,
        getTableHeaderTextArray: E
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = n(0).default,
        i = function i(e) {
      return !!e && !("SECTION" !== e.tagName || !e.getAttribute("data-mw-section-id"));
    };

    t.default = {
      getSectionIDOfElement: function getSectionIDOfElement(e) {
        var t = function (e) {
          for (var t = e; t;) {
            if (i(t)) return t;
            t = t.parentElement;
          }

          return null;
        }(e);

        return t && t.getAttribute("data-mw-section-id");
      },
      getLeadParagraphText: function getLeadParagraphText(e) {
        var t = e.querySelector("#content-block-0>p");
        return t && t.innerText || "";
      },
      getSectionOffsets: function getSectionOffsets(e) {
        return {
          sections: r.querySelectorAll(e, "section").reduce(function (e, t) {
            var n = t.getAttribute("data-mw-section-id"),
                r = t && t.firstElementChild && t.firstElementChild.querySelector(".pcs-edit-section-title");
            return n && parseInt(n) >= 1 && e.push({
              heading: r && r.innerHTML,
              id: parseInt(n),
              yOffset: t.offsetTop
            }), e;
          }, [])
        };
      },
      isMediaWikiSectionElement: i
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r = {
      ELEMENT_NODE: 1,
      TEXT_NODE: 3
    };
    t.default = {
      isNodeTypeElementOrText: function isNodeTypeElementOrText(e) {
        return e.nodeType === r.ELEMENT_NODE || e.nodeType === r.TEXT_NODE;
      },
      NODE_TYPE: r
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(21);

    var r = n(12).default,
        i = n(1).default,
        a = n(0).default,
        o = {
      PLACEHOLDER_CLASS: "pcs-lazy-load-placeholder",
      PLACEHOLDER_PENDING_CLASS: "pcs-lazy-load-placeholder-pending",
      PLACEHOLDER_LOADING_CLASS: "pcs-lazy-load-placeholder-loading",
      PLACEHOLDER_ERROR_CLASS: "pcs-lazy-load-placeholder-error",
      IMAGE_LOADING_CLASS: "pcs-lazy-load-image-loading",
      IMAGE_LOADED_CLASS: "pcs-lazy-load-image-loaded"
    },
        l = ["class", "style", "src", "srcset", "width", "height", "alt", "usemap", "data-file-width", "data-file-height", "data-image-gallery"],
        c = {
      px: 50,
      ex: 10,
      em: 5
    },
        s = function s(e, t) {
      var n = e.createElement("span");
      t.hasAttribute("class") && n.setAttribute("class", t.getAttribute("class") || ""), n.classList.add("pcs-lazy-load-placeholder"), n.classList.add("pcs-lazy-load-placeholder-pending");
      var a = r.from(t);
      a.width && n.style.setProperty("width", "" + a.width), i.copyAttributesToDataAttributes(t, n, l);
      var o = e.createElement("span");

      if (a.width && a.height) {
        var c = a.heightValue / a.widthValue;
        o.style.setProperty("padding-top", 100 * c + "%");
      }

      return n.appendChild(o), t.parentNode && t.parentNode.replaceChild(n, t), n;
    },
        u = function u(e) {
      var t = r.from(e);
      if (!t.width || !t.height) return !0;
      var n = c[t.widthUnit] || 1 / 0,
          i = c[t.heightUnit] || 1 / 0;
      return t.widthValue >= n && t.heightValue >= i;
    };

    t.default = {
      CLASSES: o,
      PLACEHOLDER_CLASS: "pcs-lazy-load-placeholder",
      isLazyLoadable: u,
      queryLazyLoadableImages: function queryLazyLoadableImages(e) {
        return a.querySelectorAll(e, "img").filter(function (e) {
          return u(e);
        });
      },
      convertImagesToPlaceholders: function convertImagesToPlaceholders(e, t) {
        return t.map(function (t) {
          return s(e, t);
        });
      },
      convertImageToPlaceholder: s,
      loadPlaceholder: function loadPlaceholder(e, t) {
        t.classList.add("pcs-lazy-load-placeholder-loading"), t.classList.remove("pcs-lazy-load-placeholder-pending");

        var n = e.createElement("img"),
            r = function r(e) {
          n.setAttribute("src", n.getAttribute("src") || ""), e.stopPropagation(), e.preventDefault();
        };

        return n.addEventListener("load", function () {
          t.removeEventListener("click", r), t.parentNode && t.parentNode.replaceChild(n, t), n.classList.add("pcs-lazy-load-image-loaded"), n.classList.remove("pcs-lazy-load-image-loading");
        }, {
          once: !0
        }), n.addEventListener("error", function () {
          t.classList.add("pcs-lazy-load-placeholder-error"), t.classList.remove("pcs-lazy-load-placeholder-loading"), t.addEventListener("click", r);
        }, {
          once: !0
        }), i.copyDataAttributesToAttributes(t, n, l), n.classList.add("pcs-lazy-load-image-loading"), n;
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(23);

    var r = {
      SECTION_HEADER: "pcs-edit-section-header",
      TITLE: "pcs-edit-section-title",
      LINK_CONTAINER: "pcs-edit-section-link-container",
      LINK: "pcs-edit-section-link",
      PROTECTION: {
        UNPROTECTED: "",
        PROTECTED: "page-protected",
        FORBIDDEN: "no-editing"
      }
    },
        i = {
      TITLE_DESCRIPTION: "pcs-edit-section-title-description",
      ADD_TITLE_DESCRIPTION: "pcs-edit-section-add-title-description",
      DIVIDER: "pcs-edit-section-divider",
      PRONUNCIATION: "pcs-edit-section-title-pronunciation"
    },
        a = {
      SECTION_INDEX: "data-id",
      ACTION: "data-action",
      PRONUNCIATION_URL: "data-pronunciation-url",
      DESCRIPTION_SOURCE: "data-description-source"
    },
        o = function o(e, t) {
      var n = arguments.length > 2 && void 0 !== arguments[2] ? arguments[2] : "",
          i = e.createElement("a");
      return i.href = n, i.setAttribute(a.SECTION_INDEX, t), i.setAttribute(a.ACTION, "edit_section"), i.classList.add(r.LINK), i;
    },
        l = function l(e, t, n) {
      var i = e.createElement("span");
      i.classList.add(r.LINK_CONTAINER);
      var a = n;
      return a || (a = o(e, t)), i.appendChild(a), i;
    },
        c = function c(e, t) {
      var n = e.createElement("div");
      return n.className = r.SECTION_HEADER, n;
    },
        s = function s(e, t) {
      t.className = r.TITLE, e.appendChild(t);
    },
        u = function u(e, t, n, r) {
      var i = !(arguments.length > 4 && void 0 !== arguments[4]) || arguments[4],
          o = c(e),
          u = e.createElement("h" + n);

      if (u.innerHTML = r || "", u.setAttribute(a.SECTION_INDEX, t), s(o, u), i) {
        var d = l(e, t);
        o.appendChild(d);
      }

      return o;
    },
        d = function d(e, t, n, r, o) {
      if (void 0 !== t && t.length > 0) {
        var l = e.createElement("p");
        return l.setAttribute(a.DESCRIPTION_SOURCE, n), l.id = i.TITLE_DESCRIPTION, l.innerHTML = t, l;
      }

      if (o) {
        var c = e.createElement("a");
        c.href = "#", c.setAttribute(a.ACTION, "add_title_description");
        var s = e.createElement("p");
        return s.id = i.ADD_TITLE_DESCRIPTION, s.innerHTML = r, c.appendChild(s), c;
      }

      return null;
    };

    t.default = {
      appendEditSectionHeader: s,
      CLASS: r,
      IDS: i,
      DATA_ATTRIBUTE: a,
      setEditButtons: function setEditButtons(e) {
        var t = arguments.length > 1 && void 0 !== arguments[1] && arguments[1],
            n = arguments.length > 2 && void 0 !== arguments[2] && arguments[2],
            i = e.documentElement.classList;
        t ? i.remove(r.PROTECTION.FORBIDDEN) : i.add(r.PROTECTION.FORBIDDEN), n ? i.add(r.PROTECTION.PROTECTED) : i.remove(r.PROTECTION.PROTECTED);
      },
      newEditSectionButton: l,
      newEditSectionHeader: u,
      newEditSectionWrapper: c,
      newEditLeadSectionHeader: function newEditLeadSectionHeader(e, t, n, r, o, l) {
        var c = !(arguments.length > 6 && void 0 !== arguments[6]) || arguments[6],
            s = arguments[7],
            f = e.createDocumentFragment(),
            p = u(e, 0, 1, t, c);

        if (s) {
          var h = e.createElement("a");
          h.setAttribute(a.ACTION, "title_pronunciation"), h.setAttribute(a.PRONUNCIATION_URL, s), h.id = i.PRONUNCIATION, p.querySelector("h1").appendChild(h);
        }

        f.appendChild(p);
        var m = d(e, n, r, o, l);
        m && f.appendChild(m);
        var v = e.createElement("hr");
        return v.id = i.DIVIDER, f.appendChild(v), f;
      },
      newEditSectionLink: o
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = function () {
      function e(e, t) {
        for (var n = 0; n < t.length; n++) {
          var r = t[n];
          r.enumerable = r.enumerable || !1, r.configurable = !0, "value" in r && (r.writable = !0), Object.defineProperty(e, r.key, r);
        }
      }

      return function (t, n, r) {
        return n && e(t.prototype, n), r && e(t, r), t;
      };
    }();

    var i = function () {
      function e(t, n, r) {
        !function (e, t) {
          if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
        }(this, e), this._window = t, this._period = n, this._function = r, this._context = void 0, this._arguments = void 0, this._result = void 0, this._timeout = 0, this._timestamp = 0;
      }

      return r(e, null, [{
        key: "wrap",
        value: function value(t, n, r) {
          var i = new e(t, n, r),
              a = function a() {
            return i.queue(this, arguments);
          };

          return a.result = function () {
            return i.result;
          }, a.pending = function () {
            return i.pending();
          }, a.delay = function () {
            return i.delay();
          }, a.cancel = function () {
            return i.cancel();
          }, a.reset = function () {
            return i.reset();
          }, a;
        }
      }]), r(e, [{
        key: "queue",
        value: function value(e, t) {
          var n = this;
          return this._context = e, this._arguments = t, this.pending() || (this._timeout = this._window.setTimeout(function () {
            n._timeout = 0, n._timestamp = Date.now(), n._result = n._function.apply(n._context, n._arguments);
          }, this.delay())), this.result;
        }
      }, {
        key: "pending",
        value: function value() {
          return Boolean(this._timeout);
        }
      }, {
        key: "delay",
        value: function value() {
          return this._timestamp ? Math.max(0, this._period - (Date.now() - this._timestamp)) : 0;
        }
      }, {
        key: "cancel",
        value: function value() {
          this._timeout && this._window.clearTimeout(this._timeout), this._timeout = 0;
        }
      }, {
        key: "reset",
        value: function value() {
          this.cancel(), this._result = void 0, this._timestamp = 0;
        }
      }, {
        key: "result",
        get: function get() {
          return this._result;
        }
      }]), e;
    }();

    t.default = i;
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(15);
    t.default = {
      containerFragment: function containerFragment(e, t) {
        var n = e.createDocumentFragment(),
            r = e.createElement("section");
        r.id = "pcs-footer-container-menu", r.className = "pcs-footer-section", r.innerHTML = "<h2 id='pcs-footer-container-menu-heading'></h2>\n   <a name=" + (t && t.menu) + "></a>\n   <div id='pcs-footer-container-menu-items'></div>", n.appendChild(r);
        var i = e.createElement("section");
        i.id = "pcs-footer-container-readmore", i.className = "pcs-footer-section", i.style.display = "none", i.innerHTML = "<h2 id='pcs-footer-container-readmore-heading'></h2>\n   <a name=" + (t && t.readmore) + "></a>\n   <div id='pcs-footer-container-readmore-pages'></div>", n.appendChild(i);
        var a = e.createElement("section");
        return a.id = "pcs-footer-container-legal", n.appendChild(a), n;
      },
      isContainerAttached: function isContainerAttached(e) {
        return Boolean(e.querySelector("#pcs-footer-container"));
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(16);
    t.default = {
      add: function add(e, t, n, r, i, a, o) {
        var l = e.querySelector("#" + r),
            c = t.split("$1");
        l.innerHTML = "<div class='pcs-footer-legal-contents'>\n    <hr class='pcs-footer-legal-divider'>\n    <span class='pcs-footer-legal-license'>\n      " + c[0] + "\n      <a class='pcs-footer-legal-license-link'>\n        " + n + "\n      </a>\n      " + c[1] + "\n      <br>\n      <div class=\"pcs-footer-browser\">\n        <a class='pcs-footer-browser-link'>\n          " + a + "\n        </a>\n      </div>\n    </span>\n  </div>", l.querySelector(".pcs-footer-legal-license-link").addEventListener("click", function () {
          i();
        }), l.querySelector(".pcs-footer-browser-link").addEventListener("click", function () {
          o();
        });
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r,
        i = n(0),
        a = (r = i) && r.__esModule ? r : {
      default: r
    };

    var o = function o(e) {
      return e ? a.default.querySelectorAll(e, ".mbox-text-span").map(function (e) {
        return a.default.querySelectorAll(e, ".hide-when-compact, .collapsed").forEach(function (e) {
          return e.remove();
        }), e;
      }) : [];
    },
        l = function l(e) {
      var t = e.closest("section[data-mw-section-id]"),
          n = t && t.querySelector("h1,h2,h3,h4,h5,h6");
      return {
        id: t && parseInt(t.getAttribute("data-mw-section-id"), 10),
        title: n && n.innerHTML.trim(),
        anchor: n && n.getAttribute("id")
      };
    };

    t.default = {
      collectHatnotes: function collectHatnotes(e) {
        return e ? a.default.querySelectorAll(e, "div.hatnote").map(function (e) {
          var t = a.default.querySelectorAll(e, 'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function (e) {
            return e.href;
          });
          return {
            html: e.innerHTML.trim(),
            links: t,
            section: l(e)
          };
        }) : [];
      },
      collectPageIssues: function collectPageIssues(e) {
        return o(e).map(function (e) {
          return {
            html: e.innerHTML.trim(),
            section: l(e)
          };
        });
      },
      test: {
        collectPageIssueElements: o
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(19);

    var r = function r(e, t, n) {
      var r = new RegExp("\\s?[" + t + "][^" + t + n + "]+[" + n + "]", "g"),
          i = 0,
          a = e,
          o = "";

      do {
        o = a, a = a.replace(r, ""), i++;
      } while (o !== a && i < 30);

      return a;
    },
        i = function i(e) {
      var t = e;
      return t = r(t, "(", ")"), t = r(t, "/", "/");
    },
        a = function e(t, n, r, i, a) {
      !function (e, t) {
        if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
      }(this, e), this.title = t, this.displayTitle = n, this.thumbnail = r, this.description = i, this.extract = a;
    },
        o = function o(e, t, n, r, _o, c) {
      var s = [],
          u = c.getElementById(n),
          d = c.getElementById(r);
      l(t, "pcs-footer-container-readmore-heading", c), e.forEach(function (e, t) {
        var n = e.titles.normalized;
        s.push(n);

        var r = function (e, t, n) {
          var r = n.createElement("a");

          if (r.id = t, r.className = "pcs-footer-readmore-page", e.thumbnail && e.thumbnail.source) {
            var a = n.createElement("div");
            a.style.backgroundImage = "url(" + e.thumbnail.source + ")", a.classList.add("pcs-footer-readmore-page-image"), r.appendChild(a);
          }

          var o = n.createElement("div");
          o.classList.add("pcs-footer-readmore-page-container"), r.appendChild(o), r.href = "./" + encodeURI(e.title) + "?event-logging-label=read-more";
          var l = void 0;

          if (e.displayTitle ? l = e.displayTitle : e.title && (l = e.title), l) {
            var c = n.createElement("div");
            c.id = t, c.className = "pcs-footer-readmore-page-title", c.innerHTML = l.replace(/_/g, " "), r.title = e.title.replace(/_/g, " "), o.appendChild(c);
          }

          var s = void 0;

          if (e.description && (s = e.description), (!s || s.length < 10) && e.extract && (s = i(e.extract)), s) {
            var u = n.createElement("div");
            u.id = t, u.className = "pcs-footer-readmore-page-description", u.innerHTML = s, o.appendChild(u);
          }

          return n.createDocumentFragment().appendChild(r);
        }(new a(n, e.titles.display, e.thumbnail, e.description, e.extract), t, c);

        d.appendChild(r);
      }), _o(s), u.style.display = "block";
    },
        l = function l(e, t, n) {
      var r = n.getElementById(t);
      r.innerText = e, r.title = e;
    };

    t.default = {
      fetchAndAdd: function fetchAndAdd(e, t, n, r, i, a, l, c) {
        var s = new XMLHttpRequest();
        s.open("GET", function (e, t, n) {
          return (n || "") + "/page/related/" + e;
        }(e, 0, a), !0), s.onload = function () {
          var e = JSON.parse(s.responseText).pages;

          if (e && e.length) {
            var a = void 0;

            if (e.length > n) {
              var u = Math.floor(Math.random() * Math.floor(e.length - n));
              a = e.slice(u, u + n);
            } else a = e;

            o(a, t, r, i, l, c);
          }
        }, s.send();
      },
      setHeading: l,
      test: {
        cleanExtract: i,
        safelyRemoveEnclosures: r
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = function () {
      function e(e, t) {
        for (var n = 0; n < t.length; n++) {
          var r = t[n];
          r.enumerable = r.enumerable || !1, r.configurable = !0, "value" in r && (r.writable = !0), Object.defineProperty(e, r.key, r);
        }
      }

      return function (t, n, r) {
        return n && e(t.prototype, n), r && e(t, r), t;
      };
    }();

    function i(e, t) {
      if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
    }

    var a = /(-?\d*\.?\d*)(\D+)?/,
        o = function () {
      function e(t, n) {
        i(this, e), this._value = Number(t), this._unit = n || "px";
      }

      return r(e, null, [{
        key: "fromElement",
        value: function value(t, n) {
          return t.style.getPropertyValue(n) && e.fromStyle(t.style.getPropertyValue(n)) || t.hasAttribute(n) && new e(t.getAttribute(n)) || void 0;
        }
      }, {
        key: "fromStyle",
        value: function value(t) {
          var n = t.match(a) || [];
          return new e(n[1], n[2]);
        }
      }]), r(e, [{
        key: "toString",
        value: function value() {
          return isNaN(this.value) ? "" : "" + this.value + this.unit;
        }
      }, {
        key: "value",
        get: function get() {
          return this._value;
        }
      }, {
        key: "unit",
        get: function get() {
          return this._unit;
        }
      }]), e;
    }(),
        l = function () {
      function e(t, n) {
        i(this, e), this._width = t, this._height = n;
      }

      return r(e, null, [{
        key: "from",
        value: function value(t) {
          return new e(o.fromElement(t, "width"), o.fromElement(t, "height"));
        }
      }]), r(e, [{
        key: "width",
        get: function get() {
          return this._width;
        }
      }, {
        key: "widthValue",
        get: function get() {
          return this._width && !isNaN(this._width.value) ? this._width.value : NaN;
        }
      }, {
        key: "widthUnit",
        get: function get() {
          return this._width && this._width.unit || "px";
        }
      }, {
        key: "height",
        get: function get() {
          return this._height;
        }
      }, {
        key: "heightValue",
        get: function get() {
          return this._height && !isNaN(this._height.value) ? this._height.value : NaN;
        }
      }, {
        key: "heightUnit",
        get: function get() {
          return this._height && this._height.unit || "px";
        }
      }]), e;
    }();

    t.default = l;
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r = {
      ANDROID: "pcs-platform-android",
      IOS: "pcs-platform-ios"
    };
    t.default = {
      CLASS: r,
      CLASS_PREFIX: "pcs-platform-",
      classify: function classify(e) {
        var t = e.document.documentElement;
        (function (e) {
          return /android/i.test(e.navigator.userAgent);
        })(e) && t.classList.add(r.ANDROID), function (e) {
          return /ipad|iphone|ipod/i.test(e.navigator.userAgent);
        }(e) && t.classList.add(r.IOS);
      },
      setPlatform: function setPlatform(e, t) {
        e.documentElement.classList.add(t);
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(29);

    var r = {
      DEFAULT: "pcs-theme-default",
      DARK: "pcs-theme-dark",
      SEPIA: "pcs-theme-sepia",
      BLACK: "pcs-theme-black"
    },
        i = function i(e, t) {
      if (e) for (var n in e.classList.add(t), r) {
        Object.prototype.hasOwnProperty.call(r, n) && r[n] !== t && e.classList.remove(r[n]);
      }
    };

    t.default = {
      THEME: r,
      CLASS_PREFIX: "pcs-theme-",
      setTheme: function setTheme(e, t) {
        var n = e.body;
        i(n, t);
        var r = e.getElementById("pcs");
        i(r, t);
      }
    };
  }, function (e, t, n) {}, function (e, t, n) {}, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = function () {
      function e(e, t) {
        for (var n = 0; n < t.length; n++) {
          var r = t[n];
          r.enumerable = r.enumerable || !1, r.configurable = !0, "value" in r && (r.writable = !0), Object.defineProperty(e, r.key, r);
        }
      }

      return function (t, n, r) {
        return n && e(t.prototype, n), r && e(t, r), t;
      };
    }();

    n(18);
    var i,
        a = n(10),
        o = (i = a) && i.__esModule ? i : {
      default: i
    };

    var l = {
      languages: 1,
      lastEdited: 2,
      pageIssues: 3,
      disambiguation: 4,
      coordinate: 5,
      talkPage: 6,
      referenceList: 7
    },
        c = function () {
      function e(t, n, r, i) {
        !function (e, t) {
          if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
        }(this, e), this.title = t, this.subtitle = n, this.itemType = r, this.clickHandler = i, this.payload = [];
      }

      return r(e, [{
        key: "iconClass",
        value: function value() {
          switch (this.itemType) {
            case l.languages:
              return "pcs-footer-menu-icon-languages";

            case l.lastEdited:
              return "pcs-footer-menu-icon-last-edited";

            case l.talkPage:
              return "pcs-footer-menu-icon-talk-page";

            case l.pageIssues:
              return "pcs-footer-menu-icon-page-issues";

            case l.disambiguation:
              return "pcs-footer-menu-icon-disambiguation";

            case l.coordinate:
              return "pcs-footer-menu-icon-coordinate";

            case l.referenceList:
              return "pcs-footer-menu-icon-reference-list";

            default:
              return "";
          }
        }
      }, {
        key: "payloadExtractor",
        value: function value() {
          switch (this.itemType) {
            case l.pageIssues:
              return o.default.collectPageIssues;

            case l.disambiguation:
              return o.default.collectHatnotes;

            default:
              return;
          }
        }
      }]), e;
    }();

    t.default = {
      MenuItemType: l,
      setHeading: function setHeading(e, t, n) {
        var r = n.getElementById(t);
        r.innerText = e, r.title = e;
      },
      maybeAddItem: function maybeAddItem(e, t, n, r, i, a) {
        var o = new c(e, t, n, i),
            l = o.payloadExtractor();
        l && (o.payload = l(a), 0 === o.payload.length) || function (e, t, n) {
          n.getElementById(t).appendChild(function (e, t) {
            var n = t.createElement("div");
            n.className = "pcs-footer-menu-item", n.role = "menuitem";
            var r = t.createElement("a");

            if (r.addEventListener("click", function () {
              e.clickHandler(e.payload);
            }), n.appendChild(r), e.title) {
              var i = t.createElement("div");
              i.className = "pcs-footer-menu-item-title", i.innerText = e.title, r.title = e.title, r.appendChild(i);
            }

            if (e.subtitle) {
              var a = t.createElement("div");
              a.className = "pcs-footer-menu-item-subtitle", a.innerText = e.subtitle, r.appendChild(a);
            }

            var o = e.iconClass();
            return o && n.classList.add(o), t.createDocumentFragment().appendChild(n);
          }(e, n));
        }(o, r, a);
      }
    };
  }, function (e, t, n) {}, function (e, t, n) {}, function (e, t, n) {}, function (e, t, n) {}, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r = o(n(1)),
        i = o(n(4)),
        a = o(n(0));

    function o(e) {
      return e && e.__esModule ? e : {
        default: e
      };
    }

    function l(e, t) {
      if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
    }

    var c = function c(e) {
      return e.indexOf("#cite_note") > -1;
    },
        s = function s(e) {
      return Boolean(e) && e.nodeType === Node.TEXT_NODE && Boolean(e.textContent.match(/^\s+$/));
    },
        u = function u(e) {
      var t = e.querySelector("a");
      return t && c(t.hash);
    },
        d = function d(e, t) {
      var n = t.querySelector("A").getAttribute("href").slice(1);
      return e.getElementById(n) || e.getElementById(decodeURIComponent(n));
    },
        f = function f(e, t) {
      var n = d(e, t);
      if (!n) return "";
      var r = e.createDocumentFragment(),
          o = e.createElement("div");
      r.appendChild(o);

      for (var l, c = n.firstChild; c;) {
        i.default.isNodeTypeElementOrText(c) && (l = c, o.appendChild(l.cloneNode(!0))), c = c.nextSibling;
      }

      return a.default.querySelectorAll(o, "link, style, sup[id^=cite_ref], .mw-cite-backlink").forEach(function (e) {
        return e.remove();
      }), o.innerHTML.trim();
    },
        p = function p(e) {
      return a.default.matchesSelector(e, ".reference, .mw-ref") ? e : r.default.findClosestAncestor(e, ".reference, .mw-ref");
    },
        h = function e(t, n, r, i, a) {
      l(this, e), this.id = t, this.rect = n, this.text = r, this.html = i, this.href = a;
    },
        m = function e(t, n) {
      l(this, e), this.href = t, this.text = n;
    },
        v = function e(t, n) {
      l(this, e), this.selectedIndex = t, this.referencesGroup = n;
    },
        g = function g(e, t) {
      var n = e;

      do {
        n = t(n);
      } while (s(n));

      return n;
    },
        E = function E(e, t, n) {
      for (var r = e; (r = g(r, t)) && r.nodeType === Node.ELEMENT_NODE && u(r);) {
        n(r);
      }
    },
        y = function y(e) {
      return e.previousSibling;
    },
        _ = function _(e) {
      return e.nextSibling;
    },
        b = function b(e) {
      var t = [e];
      return E(e, y, function (e) {
        return t.unshift(e);
      }), E(e, _, function (e) {
        return t.push(e);
      }), t;
    };

    t.default = {
      collectNearbyReferences: function collectNearbyReferences(e, t) {
        var n = t.parentElement,
            r = b(n),
            i = r.indexOf(n),
            a = r.map(function (t) {
          return function (e, t) {
            return new h(p(t).id, function (e) {
              var t = e.getBoundingClientRect();
              return {
                top: t.top,
                right: t.right,
                bottom: t.bottom,
                left: t.left,
                width: t.width,
                height: t.height,
                x: t.x,
                y: t.y
              };
            }(t), t.textContent, f(e, t), t.querySelector("A").getAttribute("href"));
          }(e, t);
        });
        return new v(i, a);
      },
      collectNearbyReferencesAsText: function collectNearbyReferencesAsText(e, t) {
        var n = t.parentElement,
            r = b(n),
            i = r.indexOf(n),
            a = r.map(function (e) {
          return function (e, t) {
            return new m(t.querySelector("A").getAttribute("href"), t.textContent);
          }(0, e);
        });
        return new v(i, a);
      },
      isCitation: c,
      test: {
        adjacentNonWhitespaceNode: g,
        closestReferenceClassElement: p,
        collectAdjacentReferenceNodes: E,
        collectNearbyReferenceNodes: b,
        collectRefText: f,
        getRefTextContainer: d,
        hasCitationLink: u,
        isWhitespaceTextNode: s,
        nextSiblingGetter: _,
        prevSiblingGetter: y
      }
    };
  }, function (e, t, n) {}, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    t.default = {
      setPercentage: function setPercentage(e, t) {
        t && (e.style["-webkit-text-size-adjust"] = t, e.style["text-size-adjust"] = t);
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    t.default = {
      setMargins: function setMargins(e, t) {
        void 0 !== t.top && (e.style.marginTop = t.top), void 0 !== t.right && (e.style.marginRight = t.right), void 0 !== t.bottom && (e.style.marginBottom = t.bottom), void 0 !== t.left && (e.style.marginLeft = t.left);
      },
      setPadding: function setPadding(e, t) {
        void 0 !== t.top && (e.style.paddingTop = t.top), void 0 !== t.right && (e.style.paddingRight = t.right), void 0 !== t.bottom && (e.style.paddingBottom = t.bottom), void 0 !== t.left && (e.style.paddingLeft = t.left);
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(27);

    var r = "pcs-dim-images",
        i = function i(e, t) {
      e.body.classList[t ? "add" : "remove"](r);
    },
        a = function a(e) {
      return e.body.classList.contains(r);
    };

    t.default = {
      CLASS: r,
      dim: function dim(e, t) {
        return i(e.document, t);
      },
      isDim: function isDim(e) {
        return a(e.document);
      },
      dimImages: i,
      areImagesDimmed: a
    };
  }, function (e, t, n) {}, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = function () {
      function e(e, t) {
        for (var n = 0; n < t.length; n++) {
          var r = t[n];
          r.enumerable = r.enumerable || !1, r.configurable = !0, "value" in r && (r.writable = !0), Object.defineProperty(e, r.key, r);
        }
      }

      return function (t, n, r) {
        return n && e(t.prototype, n), r && e(t, r), t;
      };
    }(),
        i = s(n(2)),
        a = s(n(1)),
        o = s(n(5)),
        l = s(n(0)),
        c = s(n(7));

    function s(e) {
      return e && e.__esModule ? e : {
        default: e
      };
    }

    var u = ["scroll", "resize", i.default.SECTION_TOGGLED_EVENT_TYPE],
        d = 100,
        f = function () {
      function e(t, n) {
        var r = this;
        !function (e, t) {
          if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
        }(this, e), this._window = t, this._loadDistanceMultiplier = n, this._placeholders = [], this._registered = !1, this._throttledLoadPlaceholders = c.default.wrap(t, d, function () {
          return r._loadPlaceholders();
        });
      }

      return r(e, [{
        key: "convertImagesToPlaceholders",
        value: function value(e) {
          var t = o.default.queryLazyLoadableImages(e),
              n = o.default.convertImagesToPlaceholders(this._window.document, t);
          this._placeholders = this._placeholders.concat(n), this._register();
        }
      }, {
        key: "collectExistingPlaceholders",
        value: function value(e) {
          var t = l.default.querySelectorAll(e, "." + o.default.PLACEHOLDER_CLASS);
          this._placeholders = this._placeholders.concat(t), this._register();
        }
      }, {
        key: "loadPlaceholders",
        value: function value() {
          this._throttledLoadPlaceholders();
        }
      }, {
        key: "deregister",
        value: function value() {
          var e = this;
          this._registered && (u.forEach(function (t) {
            return e._window.removeEventListener(t, e._throttledLoadPlaceholders);
          }), this._throttledLoadPlaceholders.reset(), this._placeholders = [], this._registered = !1);
        }
      }, {
        key: "_register",
        value: function value() {
          var e = this;
          !this._registered && this._placeholders.length && (this._registered = !0, u.forEach(function (t) {
            return e._window.addEventListener(t, e._throttledLoadPlaceholders);
          }));
        }
      }, {
        key: "_loadPlaceholders",
        value: function value() {
          var e = this;
          this._placeholders = this._placeholders.filter(function (t) {
            var n = !0;
            return e._isPlaceholderEligibleToLoad(t) && (o.default.loadPlaceholder(e._window.document, t), n = !1), n;
          }), 0 === this._placeholders.length && this.deregister();
        }
      }, {
        key: "_isPlaceholderEligibleToLoad",
        value: function value(e) {
          return a.default.isVisible(e) && this._isPlaceholderWithinLoadDistance(e);
        }
      }, {
        key: "_isPlaceholderWithinLoadDistance",
        value: function value(e) {
          var t = e.getBoundingClientRect(),
              n = this._window.innerHeight * this._loadDistanceMultiplier;
          return !(t.top > n || t.bottom < -n);
        }
      }]), e;
    }();

    t.default = f;
  }, function (e, t, n) {},,,,,,,,,,, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = S(n(14)),
        i = S(n(24)),
        a = S(n(25)),
        o = S(n(2)),
        l = S(n(10)),
        c = S(n(41)),
        s = S(n(26)),
        u = S(n(6)),
        d = S(n(12)),
        f = S(n(1)),
        p = S(n(42)),
        h = S(n(8)),
        m = S(n(9)),
        v = S(n(17)),
        g = S(n(11)),
        E = S(n(43)),
        y = S(n(5)),
        _ = S(n(28)),
        b = S(n(13)),
        T = S(n(0)),
        L = S(n(44)),
        C = S(n(22)),
        N = S(n(7)),
        A = S(n(3)),
        O = S(n(45));

    function S(e) {
      return e && e.__esModule ? e : {
        default: e
      };
    }

    n(47), n(48), t.default = {
      AdjustTextSize: i.default,
      BodySpacingTransform: a.default,
      CollapseTable: o.default,
      CollectionUtilities: l.default,
      CompatibilityTransform: c.default,
      DimImagesTransform: s.default,
      EditTransform: u.default,
      LeadIntroductionTransform: p.default,
      FooterContainer: h.default,
      FooterLegal: m.default,
      FooterMenu: v.default,
      FooterReadMore: g.default,
      FooterTransformer: E.default,
      LazyLoadTransform: y.default,
      LazyLoadTransformer: _.default,
      PlatformTransform: b.default,
      RedLinks: L.default,
      ReferenceCollection: C.default,
      SectionUtilities: A.default,
      ThemeTransform: r.default,
      WidenImage: O.default,
      test: {
        ElementGeometry: d.default,
        ElementUtilities: f.default,
        Polyfill: T.default,
        Throttle: N.default
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r = {
      FILTER: "pcs-compatibility-filter"
    };
    t.default = {
      COMPATIBILITY: r,
      enableSupport: function enableSupport(e) {
        var t = e.documentElement;
        (function (e) {
          return function (e, t, n) {
            var r = e.createElement("span");
            return t.some(function (e) {
              return r.style[e] = n, r.style.cssText;
            });
          }(e, ["webkitFilter", "filter"], "blur(0)");
        })(e) || t.classList.add(r.FILTER);
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r,
        i = n(0);
    (r = i) && r.__esModule;

    var a = function a(e) {
      var t = e.querySelector('[id="coordinates"]'),
          n = t ? t.textContent.length : 0;
      return e.textContent.length - n >= 50;
    },
        o = function o(e) {
      var t = [],
          n = e;

      do {
        t.push(n), n = n.nextSibling;
      } while (n && (1 !== n.nodeType || "P" !== n.tagName));

      return t;
    },
        l = function l(e, t) {
      if (t) for (var n = t.firstElementChild; n;) {
        if ("P" == n.tagName && a(n)) return n;
        n = n.nextElementSibling;
      }
    };

    t.default = {
      moveLeadIntroductionUp: function moveLeadIntroductionUp(e, t, n) {
        var r = l(0, t);

        if (r) {
          var i = e.createDocumentFragment();
          o(r).forEach(function (e) {
            return i.appendChild(e);
          });
          var a = n ? n.nextSibling : t.firstChild;
          t.insertBefore(i, a);
        }
      },
      test: {
        isParagraphEligible: a,
        extractLeadIntroductionNodes: o,
        getEligibleParagraph: l
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });

    var r = function () {
      function e(e, t) {
        for (var n = 0; n < t.length; n++) {
          var r = t[n];
          r.enumerable = r.enumerable || !1, r.configurable = !0, "value" in r && (r.writable = !0), Object.defineProperty(e, r.key, r);
        }
      }

      return function (t, n, r) {
        return n && e(t.prototype, n), r && e(t, r), t;
      };
    }(),
        i = c(n(8)),
        a = c(n(9)),
        o = c(n(11)),
        l = c(n(7));

    function c(e) {
      return e && e.__esModule ? e : {
        default: e
      };
    }

    var s = function () {
      function e() {
        !function (e, t) {
          if (!(e instanceof t)) throw new TypeError("Cannot call a class as a function");
        }(this, e), this._resizeListener = void 0;
      }

      return r(e, [{
        key: "add",
        value: function value(e, t, n, r, c, s, u, d, f, p, h, m) {
          this.remove(e), t.appendChild(i.default.containerFragment(e.document)), a.default.add(e.document, u, d, "pcs-footer-container-legal", f, p, h), o.default.setHeading(c, "pcs-footer-container-readmore-heading", e.document), o.default.add(r, s, "pcs-footer-container-readmore-pages", n, function (t) {
            i.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e), m(t);
          }, e.document), this._resizeListener = l.default.wrap(e, 100, function () {
            return i.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e);
          }), e.addEventListener("resize", this._resizeListener);
        }
      }, {
        key: "remove",
        value: function value(e) {
          this._resizeListener && (e.removeEventListener("resize", this._resizeListener), this._resizeListener.cancel(), this._resizeListener = void 0);
          var t = e.document.getElementById("pcs-footer-container");
          t && t.parentNode.removeChild(t);
        }
      }]), e;
    }();

    t.default = s;
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    });
    var r,
        i = n(0),
        a = (r = i) && r.__esModule ? r : {
      default: r
    };

    var o = function o(e, t) {
      e.innerHTML = t.innerHTML, e.setAttribute("class", t.getAttribute("class"));
    },
        l = function l(e) {
      return a.default.querySelectorAll(e, "a.new");
    },
        c = function c(e) {
      return e.createElement("span");
    },
        s = function s(e, t) {
      return e.parentNode.replaceChild(t, e);
    };

    t.default = {
      hideRedLinks: function hideRedLinks(e) {
        var t = c(e);
        l(e).forEach(function (e) {
          var n = t.cloneNode(!1);
          o(n, e), s(e, n);
        });
      },
      test: {
        configureRedLinkTemplate: o,
        redLinkAnchorsInDocument: l,
        newRedLinkTemplate: c,
        replaceAnchorWithSpan: s
      }
    };
  }, function (e, t, n) {
    "use strict";

    Object.defineProperty(t, "__esModule", {
      value: !0
    }), n(46);
    var r,
        i = n(1);
    (r = i) && r.__esModule;

    var a = function a(e) {
      for (var t = [], n = e; n.parentElement && "SECTION" !== (n = n.parentElement).tagName;) {
        t.push(n);
      }

      return t;
    },
        o = function o(e, t, n) {
      e[t] = n;
    },
        l = function l(e, t, n) {
      Boolean(e[t]) && o(e, t, n);
    },
        c = {
      width: "100%",
      height: "auto",
      maxWidth: "100%",
      float: "none"
    },
        s = function s(e) {
      Object.keys(c).forEach(function (t) {
        return l(e.style, t, c[t]);
      });
    },
        u = function u(e) {
      a(e).forEach(s);
    };

    t.default = {
      widenImage: function widenImage(e) {
        u(e), e.classList.add("pcs-widen-image-override");
      },
      test: {
        ancestorsToWiden: a,
        updateExistingStyleValue: l,
        widenAncestors: u,
        widenElementByUpdatingExistingStyles: s,
        widenElementByUpdatingStyles: function widenElementByUpdatingStyles(e) {
          Object.keys(c).forEach(function (t) {
            return o(e.style, t, c[t]);
          });
        }
      }
    };
  }, function (e, t, n) {}, function (e, t, n) {}, function (e, t, n) {}]).default;
});
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../../node_modules/webpack/buildin/module.js */ "./node_modules/webpack/buildin/module.js")(module)))

/***/ }),

/***/ "./node_modules/node-libs-browser/node_modules/punycode/punycode.js":
/*!**************************************************************************!*\
  !*** ./node_modules/node-libs-browser/node_modules/punycode/punycode.js ***!
  \**************************************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(module, global) {var __WEBPACK_AMD_DEFINE_RESULT__;/*! https://mths.be/punycode v1.4.1 by @mathias */
;(function(root) {

	/** Detect free variables */
	var freeExports =  true && exports &&
		!exports.nodeType && exports;
	var freeModule =  true && module &&
		!module.nodeType && module;
	var freeGlobal = typeof global == 'object' && global;
	if (
		freeGlobal.global === freeGlobal ||
		freeGlobal.window === freeGlobal ||
		freeGlobal.self === freeGlobal
	) {
		root = freeGlobal;
	}

	/**
	 * The `punycode` object.
	 * @name punycode
	 * @type Object
	 */
	var punycode,

	/** Highest positive signed 32-bit float value */
	maxInt = 2147483647, // aka. 0x7FFFFFFF or 2^31-1

	/** Bootstring parameters */
	base = 36,
	tMin = 1,
	tMax = 26,
	skew = 38,
	damp = 700,
	initialBias = 72,
	initialN = 128, // 0x80
	delimiter = '-', // '\x2D'

	/** Regular expressions */
	regexPunycode = /^xn--/,
	regexNonASCII = /[^\x20-\x7E]/, // unprintable ASCII chars + non-ASCII chars
	regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g, // RFC 3490 separators

	/** Error messages */
	errors = {
		'overflow': 'Overflow: input needs wider integers to process',
		'not-basic': 'Illegal input >= 0x80 (not a basic code point)',
		'invalid-input': 'Invalid input'
	},

	/** Convenience shortcuts */
	baseMinusTMin = base - tMin,
	floor = Math.floor,
	stringFromCharCode = String.fromCharCode,

	/** Temporary variable */
	key;

	/*--------------------------------------------------------------------------*/

	/**
	 * A generic error utility function.
	 * @private
	 * @param {String} type The error type.
	 * @returns {Error} Throws a `RangeError` with the applicable error message.
	 */
	function error(type) {
		throw new RangeError(errors[type]);
	}

	/**
	 * A generic `Array#map` utility function.
	 * @private
	 * @param {Array} array The array to iterate over.
	 * @param {Function} callback The function that gets called for every array
	 * item.
	 * @returns {Array} A new array of values returned by the callback function.
	 */
	function map(array, fn) {
		var length = array.length;
		var result = [];
		while (length--) {
			result[length] = fn(array[length]);
		}
		return result;
	}

	/**
	 * A simple `Array#map`-like wrapper to work with domain name strings or email
	 * addresses.
	 * @private
	 * @param {String} domain The domain name or email address.
	 * @param {Function} callback The function that gets called for every
	 * character.
	 * @returns {Array} A new string of characters returned by the callback
	 * function.
	 */
	function mapDomain(string, fn) {
		var parts = string.split('@');
		var result = '';
		if (parts.length > 1) {
			// In email addresses, only the domain name should be punycoded. Leave
			// the local part (i.e. everything up to `@`) intact.
			result = parts[0] + '@';
			string = parts[1];
		}
		// Avoid `split(regex)` for IE8 compatibility. See #17.
		string = string.replace(regexSeparators, '\x2E');
		var labels = string.split('.');
		var encoded = map(labels, fn).join('.');
		return result + encoded;
	}

	/**
	 * Creates an array containing the numeric code points of each Unicode
	 * character in the string. While JavaScript uses UCS-2 internally,
	 * this function will convert a pair of surrogate halves (each of which
	 * UCS-2 exposes as separate characters) into a single code point,
	 * matching UTF-16.
	 * @see `punycode.ucs2.encode`
	 * @see <https://mathiasbynens.be/notes/javascript-encoding>
	 * @memberOf punycode.ucs2
	 * @name decode
	 * @param {String} string The Unicode input string (UCS-2).
	 * @returns {Array} The new array of code points.
	 */
	function ucs2decode(string) {
		var output = [],
		    counter = 0,
		    length = string.length,
		    value,
		    extra;
		while (counter < length) {
			value = string.charCodeAt(counter++);
			if (value >= 0xD800 && value <= 0xDBFF && counter < length) {
				// high surrogate, and there is a next character
				extra = string.charCodeAt(counter++);
				if ((extra & 0xFC00) == 0xDC00) { // low surrogate
					output.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
				} else {
					// unmatched surrogate; only append this code unit, in case the next
					// code unit is the high surrogate of a surrogate pair
					output.push(value);
					counter--;
				}
			} else {
				output.push(value);
			}
		}
		return output;
	}

	/**
	 * Creates a string based on an array of numeric code points.
	 * @see `punycode.ucs2.decode`
	 * @memberOf punycode.ucs2
	 * @name encode
	 * @param {Array} codePoints The array of numeric code points.
	 * @returns {String} The new Unicode string (UCS-2).
	 */
	function ucs2encode(array) {
		return map(array, function(value) {
			var output = '';
			if (value > 0xFFFF) {
				value -= 0x10000;
				output += stringFromCharCode(value >>> 10 & 0x3FF | 0xD800);
				value = 0xDC00 | value & 0x3FF;
			}
			output += stringFromCharCode(value);
			return output;
		}).join('');
	}

	/**
	 * Converts a basic code point into a digit/integer.
	 * @see `digitToBasic()`
	 * @private
	 * @param {Number} codePoint The basic numeric code point value.
	 * @returns {Number} The numeric value of a basic code point (for use in
	 * representing integers) in the range `0` to `base - 1`, or `base` if
	 * the code point does not represent a value.
	 */
	function basicToDigit(codePoint) {
		if (codePoint - 48 < 10) {
			return codePoint - 22;
		}
		if (codePoint - 65 < 26) {
			return codePoint - 65;
		}
		if (codePoint - 97 < 26) {
			return codePoint - 97;
		}
		return base;
	}

	/**
	 * Converts a digit/integer into a basic code point.
	 * @see `basicToDigit()`
	 * @private
	 * @param {Number} digit The numeric value of a basic code point.
	 * @returns {Number} The basic code point whose value (when used for
	 * representing integers) is `digit`, which needs to be in the range
	 * `0` to `base - 1`. If `flag` is non-zero, the uppercase form is
	 * used; else, the lowercase form is used. The behavior is undefined
	 * if `flag` is non-zero and `digit` has no uppercase form.
	 */
	function digitToBasic(digit, flag) {
		//  0..25 map to ASCII a..z or A..Z
		// 26..35 map to ASCII 0..9
		return digit + 22 + 75 * (digit < 26) - ((flag != 0) << 5);
	}

	/**
	 * Bias adaptation function as per section 3.4 of RFC 3492.
	 * https://tools.ietf.org/html/rfc3492#section-3.4
	 * @private
	 */
	function adapt(delta, numPoints, firstTime) {
		var k = 0;
		delta = firstTime ? floor(delta / damp) : delta >> 1;
		delta += floor(delta / numPoints);
		for (/* no initialization */; delta > baseMinusTMin * tMax >> 1; k += base) {
			delta = floor(delta / baseMinusTMin);
		}
		return floor(k + (baseMinusTMin + 1) * delta / (delta + skew));
	}

	/**
	 * Converts a Punycode string of ASCII-only symbols to a string of Unicode
	 * symbols.
	 * @memberOf punycode
	 * @param {String} input The Punycode string of ASCII-only symbols.
	 * @returns {String} The resulting string of Unicode symbols.
	 */
	function decode(input) {
		// Don't use UCS-2
		var output = [],
		    inputLength = input.length,
		    out,
		    i = 0,
		    n = initialN,
		    bias = initialBias,
		    basic,
		    j,
		    index,
		    oldi,
		    w,
		    k,
		    digit,
		    t,
		    /** Cached calculation results */
		    baseMinusT;

		// Handle the basic code points: let `basic` be the number of input code
		// points before the last delimiter, or `0` if there is none, then copy
		// the first basic code points to the output.

		basic = input.lastIndexOf(delimiter);
		if (basic < 0) {
			basic = 0;
		}

		for (j = 0; j < basic; ++j) {
			// if it's not a basic code point
			if (input.charCodeAt(j) >= 0x80) {
				error('not-basic');
			}
			output.push(input.charCodeAt(j));
		}

		// Main decoding loop: start just after the last delimiter if any basic code
		// points were copied; start at the beginning otherwise.

		for (index = basic > 0 ? basic + 1 : 0; index < inputLength; /* no final expression */) {

			// `index` is the index of the next character to be consumed.
			// Decode a generalized variable-length integer into `delta`,
			// which gets added to `i`. The overflow checking is easier
			// if we increase `i` as we go, then subtract off its starting
			// value at the end to obtain `delta`.
			for (oldi = i, w = 1, k = base; /* no condition */; k += base) {

				if (index >= inputLength) {
					error('invalid-input');
				}

				digit = basicToDigit(input.charCodeAt(index++));

				if (digit >= base || digit > floor((maxInt - i) / w)) {
					error('overflow');
				}

				i += digit * w;
				t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);

				if (digit < t) {
					break;
				}

				baseMinusT = base - t;
				if (w > floor(maxInt / baseMinusT)) {
					error('overflow');
				}

				w *= baseMinusT;

			}

			out = output.length + 1;
			bias = adapt(i - oldi, out, oldi == 0);

			// `i` was supposed to wrap around from `out` to `0`,
			// incrementing `n` each time, so we'll fix that now:
			if (floor(i / out) > maxInt - n) {
				error('overflow');
			}

			n += floor(i / out);
			i %= out;

			// Insert `n` at position `i` of the output
			output.splice(i++, 0, n);

		}

		return ucs2encode(output);
	}

	/**
	 * Converts a string of Unicode symbols (e.g. a domain name label) to a
	 * Punycode string of ASCII-only symbols.
	 * @memberOf punycode
	 * @param {String} input The string of Unicode symbols.
	 * @returns {String} The resulting Punycode string of ASCII-only symbols.
	 */
	function encode(input) {
		var n,
		    delta,
		    handledCPCount,
		    basicLength,
		    bias,
		    j,
		    m,
		    q,
		    k,
		    t,
		    currentValue,
		    output = [],
		    /** `inputLength` will hold the number of code points in `input`. */
		    inputLength,
		    /** Cached calculation results */
		    handledCPCountPlusOne,
		    baseMinusT,
		    qMinusT;

		// Convert the input in UCS-2 to Unicode
		input = ucs2decode(input);

		// Cache the length
		inputLength = input.length;

		// Initialize the state
		n = initialN;
		delta = 0;
		bias = initialBias;

		// Handle the basic code points
		for (j = 0; j < inputLength; ++j) {
			currentValue = input[j];
			if (currentValue < 0x80) {
				output.push(stringFromCharCode(currentValue));
			}
		}

		handledCPCount = basicLength = output.length;

		// `handledCPCount` is the number of code points that have been handled;
		// `basicLength` is the number of basic code points.

		// Finish the basic string - if it is not empty - with a delimiter
		if (basicLength) {
			output.push(delimiter);
		}

		// Main encoding loop:
		while (handledCPCount < inputLength) {

			// All non-basic code points < n have been handled already. Find the next
			// larger one:
			for (m = maxInt, j = 0; j < inputLength; ++j) {
				currentValue = input[j];
				if (currentValue >= n && currentValue < m) {
					m = currentValue;
				}
			}

			// Increase `delta` enough to advance the decoder's <n,i> state to <m,0>,
			// but guard against overflow
			handledCPCountPlusOne = handledCPCount + 1;
			if (m - n > floor((maxInt - delta) / handledCPCountPlusOne)) {
				error('overflow');
			}

			delta += (m - n) * handledCPCountPlusOne;
			n = m;

			for (j = 0; j < inputLength; ++j) {
				currentValue = input[j];

				if (currentValue < n && ++delta > maxInt) {
					error('overflow');
				}

				if (currentValue == n) {
					// Represent delta as a generalized variable-length integer
					for (q = delta, k = base; /* no condition */; k += base) {
						t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
						if (q < t) {
							break;
						}
						qMinusT = q - t;
						baseMinusT = base - t;
						output.push(
							stringFromCharCode(digitToBasic(t + qMinusT % baseMinusT, 0))
						);
						q = floor(qMinusT / baseMinusT);
					}

					output.push(stringFromCharCode(digitToBasic(q, 0)));
					bias = adapt(delta, handledCPCountPlusOne, handledCPCount == basicLength);
					delta = 0;
					++handledCPCount;
				}
			}

			++delta;
			++n;

		}
		return output.join('');
	}

	/**
	 * Converts a Punycode string representing a domain name or an email address
	 * to Unicode. Only the Punycoded parts of the input will be converted, i.e.
	 * it doesn't matter if you call it on a string that has already been
	 * converted to Unicode.
	 * @memberOf punycode
	 * @param {String} input The Punycoded domain name or email address to
	 * convert to Unicode.
	 * @returns {String} The Unicode representation of the given Punycode
	 * string.
	 */
	function toUnicode(input) {
		return mapDomain(input, function(string) {
			return regexPunycode.test(string)
				? decode(string.slice(4).toLowerCase())
				: string;
		});
	}

	/**
	 * Converts a Unicode string representing a domain name or an email address to
	 * Punycode. Only the non-ASCII parts of the domain name will be converted,
	 * i.e. it doesn't matter if you call it with a domain that's already in
	 * ASCII.
	 * @memberOf punycode
	 * @param {String} input The domain name or email address to convert, as a
	 * Unicode string.
	 * @returns {String} The Punycode representation of the given domain name or
	 * email address.
	 */
	function toASCII(input) {
		return mapDomain(input, function(string) {
			return regexNonASCII.test(string)
				? 'xn--' + encode(string)
				: string;
		});
	}

	/*--------------------------------------------------------------------------*/

	/** Define the public API */
	punycode = {
		/**
		 * A string representing the current Punycode.js version number.
		 * @memberOf punycode
		 * @type String
		 */
		'version': '1.4.1',
		/**
		 * An object of methods to convert from JavaScript's internal character
		 * representation (UCS-2) to Unicode code points, and back.
		 * @see <https://mathiasbynens.be/notes/javascript-encoding>
		 * @memberOf punycode
		 * @type Object
		 */
		'ucs2': {
			'decode': ucs2decode,
			'encode': ucs2encode
		},
		'decode': decode,
		'encode': encode,
		'toASCII': toASCII,
		'toUnicode': toUnicode
	};

	/** Expose `punycode` */
	// Some AMD build optimizers, like r.js, check for specific condition patterns
	// like the following:
	if (
		true
	) {
		!(__WEBPACK_AMD_DEFINE_RESULT__ = (function() {
			return punycode;
		}).call(exports, __webpack_require__, exports, module),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	} else {}

}(this));

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../../../webpack/buildin/module.js */ "./node_modules/webpack/buildin/module.js")(module), __webpack_require__(/*! ./../../../webpack/buildin/global.js */ "./node_modules/webpack/buildin/global.js")))

/***/ }),

/***/ "./node_modules/process/browser.js":
/*!*****************************************!*\
  !*** ./node_modules/process/browser.js ***!
  \*****************************************/
/*! no static exports found */
/***/ (function(module, exports) {

// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };


/***/ }),

/***/ "./node_modules/querystring-es3/decode.js":
/*!************************************************!*\
  !*** ./node_modules/querystring-es3/decode.js ***!
  \************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.



// If obj.hasOwnProperty has been overridden, then calling
// obj.hasOwnProperty(prop) will break.
// See: https://github.com/joyent/node/issues/1707
function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

module.exports = function(qs, sep, eq, options) {
  sep = sep || '&';
  eq = eq || '=';
  var obj = {};

  if (typeof qs !== 'string' || qs.length === 0) {
    return obj;
  }

  var regexp = /\+/g;
  qs = qs.split(sep);

  var maxKeys = 1000;
  if (options && typeof options.maxKeys === 'number') {
    maxKeys = options.maxKeys;
  }

  var len = qs.length;
  // maxKeys <= 0 means that we should not limit keys count
  if (maxKeys > 0 && len > maxKeys) {
    len = maxKeys;
  }

  for (var i = 0; i < len; ++i) {
    var x = qs[i].replace(regexp, '%20'),
        idx = x.indexOf(eq),
        kstr, vstr, k, v;

    if (idx >= 0) {
      kstr = x.substr(0, idx);
      vstr = x.substr(idx + 1);
    } else {
      kstr = x;
      vstr = '';
    }

    k = decodeURIComponent(kstr);
    v = decodeURIComponent(vstr);

    if (!hasOwnProperty(obj, k)) {
      obj[k] = v;
    } else if (isArray(obj[k])) {
      obj[k].push(v);
    } else {
      obj[k] = [obj[k], v];
    }
  }

  return obj;
};

var isArray = Array.isArray || function (xs) {
  return Object.prototype.toString.call(xs) === '[object Array]';
};


/***/ }),

/***/ "./node_modules/querystring-es3/encode.js":
/*!************************************************!*\
  !*** ./node_modules/querystring-es3/encode.js ***!
  \************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.



var stringifyPrimitive = function(v) {
  switch (typeof v) {
    case 'string':
      return v;

    case 'boolean':
      return v ? 'true' : 'false';

    case 'number':
      return isFinite(v) ? v : '';

    default:
      return '';
  }
};

module.exports = function(obj, sep, eq, name) {
  sep = sep || '&';
  eq = eq || '=';
  if (obj === null) {
    obj = undefined;
  }

  if (typeof obj === 'object') {
    return map(objectKeys(obj), function(k) {
      var ks = encodeURIComponent(stringifyPrimitive(k)) + eq;
      if (isArray(obj[k])) {
        return map(obj[k], function(v) {
          return ks + encodeURIComponent(stringifyPrimitive(v));
        }).join(sep);
      } else {
        return ks + encodeURIComponent(stringifyPrimitive(obj[k]));
      }
    }).join(sep);

  }

  if (!name) return '';
  return encodeURIComponent(stringifyPrimitive(name)) + eq +
         encodeURIComponent(stringifyPrimitive(obj));
};

var isArray = Array.isArray || function (xs) {
  return Object.prototype.toString.call(xs) === '[object Array]';
};

function map (xs, f) {
  if (xs.map) return xs.map(f);
  var res = [];
  for (var i = 0; i < xs.length; i++) {
    res.push(f(xs[i], i));
  }
  return res;
}

var objectKeys = Object.keys || function (obj) {
  var res = [];
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) res.push(key);
  }
  return res;
};


/***/ }),

/***/ "./node_modules/querystring-es3/index.js":
/*!***********************************************!*\
  !*** ./node_modules/querystring-es3/index.js ***!
  \***********************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


exports.decode = exports.parse = __webpack_require__(/*! ./decode */ "./node_modules/querystring-es3/decode.js");
exports.encode = exports.stringify = __webpack_require__(/*! ./encode */ "./node_modules/querystring-es3/encode.js");


/***/ }),

/***/ "./node_modules/setimmediate/setImmediate.js":
/*!***************************************************!*\
  !*** ./node_modules/setimmediate/setImmediate.js ***!
  \***************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(global, process) {(function (global, undefined) {
    "use strict";

    if (global.setImmediate) {
        return;
    }

    var nextHandle = 1; // Spec says greater than zero
    var tasksByHandle = {};
    var currentlyRunningATask = false;
    var doc = global.document;
    var registerImmediate;

    function setImmediate(callback) {
      // Callback can either be a function or a string
      if (typeof callback !== "function") {
        callback = new Function("" + callback);
      }
      // Copy function arguments
      var args = new Array(arguments.length - 1);
      for (var i = 0; i < args.length; i++) {
          args[i] = arguments[i + 1];
      }
      // Store and register the task
      var task = { callback: callback, args: args };
      tasksByHandle[nextHandle] = task;
      registerImmediate(nextHandle);
      return nextHandle++;
    }

    function clearImmediate(handle) {
        delete tasksByHandle[handle];
    }

    function run(task) {
        var callback = task.callback;
        var args = task.args;
        switch (args.length) {
        case 0:
            callback();
            break;
        case 1:
            callback(args[0]);
            break;
        case 2:
            callback(args[0], args[1]);
            break;
        case 3:
            callback(args[0], args[1], args[2]);
            break;
        default:
            callback.apply(undefined, args);
            break;
        }
    }

    function runIfPresent(handle) {
        // From the spec: "Wait until any invocations of this algorithm started before this one have completed."
        // So if we're currently running a task, we'll need to delay this invocation.
        if (currentlyRunningATask) {
            // Delay by doing a setTimeout. setImmediate was tried instead, but in Firefox 7 it generated a
            // "too much recursion" error.
            setTimeout(runIfPresent, 0, handle);
        } else {
            var task = tasksByHandle[handle];
            if (task) {
                currentlyRunningATask = true;
                try {
                    run(task);
                } finally {
                    clearImmediate(handle);
                    currentlyRunningATask = false;
                }
            }
        }
    }

    function installNextTickImplementation() {
        registerImmediate = function(handle) {
            process.nextTick(function () { runIfPresent(handle); });
        };
    }

    function canUsePostMessage() {
        // The test against `importScripts` prevents this implementation from being installed inside a web worker,
        // where `global.postMessage` means something completely different and can't be used for this purpose.
        if (global.postMessage && !global.importScripts) {
            var postMessageIsAsynchronous = true;
            var oldOnMessage = global.onmessage;
            global.onmessage = function() {
                postMessageIsAsynchronous = false;
            };
            global.postMessage("", "*");
            global.onmessage = oldOnMessage;
            return postMessageIsAsynchronous;
        }
    }

    function installPostMessageImplementation() {
        // Installs an event handler on `global` for the `message` event: see
        // * https://developer.mozilla.org/en/DOM/window.postMessage
        // * http://www.whatwg.org/specs/web-apps/current-work/multipage/comms.html#crossDocumentMessages

        var messagePrefix = "setImmediate$" + Math.random() + "$";
        var onGlobalMessage = function(event) {
            if (event.source === global &&
                typeof event.data === "string" &&
                event.data.indexOf(messagePrefix) === 0) {
                runIfPresent(+event.data.slice(messagePrefix.length));
            }
        };

        if (global.addEventListener) {
            global.addEventListener("message", onGlobalMessage, false);
        } else {
            global.attachEvent("onmessage", onGlobalMessage);
        }

        registerImmediate = function(handle) {
            global.postMessage(messagePrefix + handle, "*");
        };
    }

    function installMessageChannelImplementation() {
        var channel = new MessageChannel();
        channel.port1.onmessage = function(event) {
            var handle = event.data;
            runIfPresent(handle);
        };

        registerImmediate = function(handle) {
            channel.port2.postMessage(handle);
        };
    }

    function installReadyStateChangeImplementation() {
        var html = doc.documentElement;
        registerImmediate = function(handle) {
            // Create a <script> element; its readystatechange event will be fired asynchronously once it is inserted
            // into the document. Do so, thus queuing up the task. Remember to clean up once it's been called.
            var script = doc.createElement("script");
            script.onreadystatechange = function () {
                runIfPresent(handle);
                script.onreadystatechange = null;
                html.removeChild(script);
                script = null;
            };
            html.appendChild(script);
        };
    }

    function installSetTimeoutImplementation() {
        registerImmediate = function(handle) {
            setTimeout(runIfPresent, 0, handle);
        };
    }

    // If supported, we should attach to the prototype of global, since that is where setTimeout et al. live.
    var attachTo = Object.getPrototypeOf && Object.getPrototypeOf(global);
    attachTo = attachTo && attachTo.setTimeout ? attachTo : global;

    // Don't get fooled by e.g. browserify environments.
    if ({}.toString.call(global.process) === "[object process]") {
        // For Node.js before 0.9
        installNextTickImplementation();

    } else if (canUsePostMessage()) {
        // For non-IE10 modern browsers
        installPostMessageImplementation();

    } else if (global.MessageChannel) {
        // For web workers, where supported
        installMessageChannelImplementation();

    } else if (doc && "onreadystatechange" in doc.createElement("script")) {
        // For IE 6–8
        installReadyStateChangeImplementation();

    } else {
        // For older browsers
        installSetTimeoutImplementation();
    }

    attachTo.setImmediate = setImmediate;
    attachTo.clearImmediate = clearImmediate;
}(typeof self === "undefined" ? typeof global === "undefined" ? this : global : self));

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../webpack/buildin/global.js */ "./node_modules/webpack/buildin/global.js"), __webpack_require__(/*! ./../process/browser.js */ "./node_modules/process/browser.js")))

/***/ }),

/***/ "./node_modules/timers-browserify/main.js":
/*!************************************************!*\
  !*** ./node_modules/timers-browserify/main.js ***!
  \************************************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

/* WEBPACK VAR INJECTION */(function(global) {var scope = (typeof global !== "undefined" && global) ||
            (typeof self !== "undefined" && self) ||
            window;
var apply = Function.prototype.apply;

// DOM APIs, for completeness

exports.setTimeout = function() {
  return new Timeout(apply.call(setTimeout, scope, arguments), clearTimeout);
};
exports.setInterval = function() {
  return new Timeout(apply.call(setInterval, scope, arguments), clearInterval);
};
exports.clearTimeout =
exports.clearInterval = function(timeout) {
  if (timeout) {
    timeout.close();
  }
};

function Timeout(id, clearFn) {
  this._id = id;
  this._clearFn = clearFn;
}
Timeout.prototype.unref = Timeout.prototype.ref = function() {};
Timeout.prototype.close = function() {
  this._clearFn.call(scope, this._id);
};

// Does not start the time, just sets up the members needed.
exports.enroll = function(item, msecs) {
  clearTimeout(item._idleTimeoutId);
  item._idleTimeout = msecs;
};

exports.unenroll = function(item) {
  clearTimeout(item._idleTimeoutId);
  item._idleTimeout = -1;
};

exports._unrefActive = exports.active = function(item) {
  clearTimeout(item._idleTimeoutId);

  var msecs = item._idleTimeout;
  if (msecs >= 0) {
    item._idleTimeoutId = setTimeout(function onTimeout() {
      if (item._onTimeout)
        item._onTimeout();
    }, msecs);
  }
};

// setimmediate attaches itself to the global object
__webpack_require__(/*! setimmediate */ "./node_modules/setimmediate/setImmediate.js");
// On some exotic environments, it's not clear which object `setimmediate` was
// able to install onto.  Search each possibility in the same order as the
// `setimmediate` library.
exports.setImmediate = (typeof self !== "undefined" && self.setImmediate) ||
                       (typeof global !== "undefined" && global.setImmediate) ||
                       (this && this.setImmediate);
exports.clearImmediate = (typeof self !== "undefined" && self.clearImmediate) ||
                         (typeof global !== "undefined" && global.clearImmediate) ||
                         (this && this.clearImmediate);

/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(/*! ./../webpack/buildin/global.js */ "./node_modules/webpack/buildin/global.js")))

/***/ }),

/***/ "./node_modules/url/url.js":
/*!*********************************!*\
  !*** ./node_modules/url/url.js ***!
  \*********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.



var punycode = __webpack_require__(/*! punycode */ "./node_modules/node-libs-browser/node_modules/punycode/punycode.js");
var util = __webpack_require__(/*! ./util */ "./node_modules/url/util.js");

exports.parse = urlParse;
exports.resolve = urlResolve;
exports.resolveObject = urlResolveObject;
exports.format = urlFormat;

exports.Url = Url;

function Url() {
  this.protocol = null;
  this.slashes = null;
  this.auth = null;
  this.host = null;
  this.port = null;
  this.hostname = null;
  this.hash = null;
  this.search = null;
  this.query = null;
  this.pathname = null;
  this.path = null;
  this.href = null;
}

// Reference: RFC 3986, RFC 1808, RFC 2396

// define these here so at least they only have to be
// compiled once on the first module load.
var protocolPattern = /^([a-z0-9.+-]+:)/i,
    portPattern = /:[0-9]*$/,

    // Special case for a simple path URL
    simplePathPattern = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/,

    // RFC 2396: characters reserved for delimiting URLs.
    // We actually just auto-escape these.
    delims = ['<', '>', '"', '`', ' ', '\r', '\n', '\t'],

    // RFC 2396: characters not allowed for various reasons.
    unwise = ['{', '}', '|', '\\', '^', '`'].concat(delims),

    // Allowed by RFCs, but cause of XSS attacks.  Always escape these.
    autoEscape = ['\''].concat(unwise),
    // Characters that are never ever allowed in a hostname.
    // Note that any invalid chars are also handled, but these
    // are the ones that are *expected* to be seen, so we fast-path
    // them.
    nonHostChars = ['%', '/', '?', ';', '#'].concat(autoEscape),
    hostEndingChars = ['/', '?', '#'],
    hostnameMaxLen = 255,
    hostnamePartPattern = /^[+a-z0-9A-Z_-]{0,63}$/,
    hostnamePartStart = /^([+a-z0-9A-Z_-]{0,63})(.*)$/,
    // protocols that can allow "unsafe" and "unwise" chars.
    unsafeProtocol = {
      'javascript': true,
      'javascript:': true
    },
    // protocols that never have a hostname.
    hostlessProtocol = {
      'javascript': true,
      'javascript:': true
    },
    // protocols that always contain a // bit.
    slashedProtocol = {
      'http': true,
      'https': true,
      'ftp': true,
      'gopher': true,
      'file': true,
      'http:': true,
      'https:': true,
      'ftp:': true,
      'gopher:': true,
      'file:': true
    },
    querystring = __webpack_require__(/*! querystring */ "./node_modules/querystring-es3/index.js");

function urlParse(url, parseQueryString, slashesDenoteHost) {
  if (url && util.isObject(url) && url instanceof Url) return url;

  var u = new Url;
  u.parse(url, parseQueryString, slashesDenoteHost);
  return u;
}

Url.prototype.parse = function(url, parseQueryString, slashesDenoteHost) {
  if (!util.isString(url)) {
    throw new TypeError("Parameter 'url' must be a string, not " + typeof url);
  }

  // Copy chrome, IE, opera backslash-handling behavior.
  // Back slashes before the query string get converted to forward slashes
  // See: https://code.google.com/p/chromium/issues/detail?id=25916
  var queryIndex = url.indexOf('?'),
      splitter =
          (queryIndex !== -1 && queryIndex < url.indexOf('#')) ? '?' : '#',
      uSplit = url.split(splitter),
      slashRegex = /\\/g;
  uSplit[0] = uSplit[0].replace(slashRegex, '/');
  url = uSplit.join(splitter);

  var rest = url;

  // trim before proceeding.
  // This is to support parse stuff like "  http://foo.com  \n"
  rest = rest.trim();

  if (!slashesDenoteHost && url.split('#').length === 1) {
    // Try fast path regexp
    var simplePath = simplePathPattern.exec(rest);
    if (simplePath) {
      this.path = rest;
      this.href = rest;
      this.pathname = simplePath[1];
      if (simplePath[2]) {
        this.search = simplePath[2];
        if (parseQueryString) {
          this.query = querystring.parse(this.search.substr(1));
        } else {
          this.query = this.search.substr(1);
        }
      } else if (parseQueryString) {
        this.search = '';
        this.query = {};
      }
      return this;
    }
  }

  var proto = protocolPattern.exec(rest);
  if (proto) {
    proto = proto[0];
    var lowerProto = proto.toLowerCase();
    this.protocol = lowerProto;
    rest = rest.substr(proto.length);
  }

  // figure out if it's got a host
  // user@server is *always* interpreted as a hostname, and url
  // resolution will treat //foo/bar as host=foo,path=bar because that's
  // how the browser resolves relative URLs.
  if (slashesDenoteHost || proto || rest.match(/^\/\/[^@\/]+@[^@\/]+/)) {
    var slashes = rest.substr(0, 2) === '//';
    if (slashes && !(proto && hostlessProtocol[proto])) {
      rest = rest.substr(2);
      this.slashes = true;
    }
  }

  if (!hostlessProtocol[proto] &&
      (slashes || (proto && !slashedProtocol[proto]))) {

    // there's a hostname.
    // the first instance of /, ?, ;, or # ends the host.
    //
    // If there is an @ in the hostname, then non-host chars *are* allowed
    // to the left of the last @ sign, unless some host-ending character
    // comes *before* the @-sign.
    // URLs are obnoxious.
    //
    // ex:
    // http://a@b@c/ => user:a@b host:c
    // http://a@b?@c => user:a host:c path:/?@c

    // v0.12 TODO(isaacs): This is not quite how Chrome does things.
    // Review our test case against browsers more comprehensively.

    // find the first instance of any hostEndingChars
    var hostEnd = -1;
    for (var i = 0; i < hostEndingChars.length; i++) {
      var hec = rest.indexOf(hostEndingChars[i]);
      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
        hostEnd = hec;
    }

    // at this point, either we have an explicit point where the
    // auth portion cannot go past, or the last @ char is the decider.
    var auth, atSign;
    if (hostEnd === -1) {
      // atSign can be anywhere.
      atSign = rest.lastIndexOf('@');
    } else {
      // atSign must be in auth portion.
      // http://a@b/c@d => host:b auth:a path:/c@d
      atSign = rest.lastIndexOf('@', hostEnd);
    }

    // Now we have a portion which is definitely the auth.
    // Pull that off.
    if (atSign !== -1) {
      auth = rest.slice(0, atSign);
      rest = rest.slice(atSign + 1);
      this.auth = decodeURIComponent(auth);
    }

    // the host is the remaining to the left of the first non-host char
    hostEnd = -1;
    for (var i = 0; i < nonHostChars.length; i++) {
      var hec = rest.indexOf(nonHostChars[i]);
      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
        hostEnd = hec;
    }
    // if we still have not hit it, then the entire thing is a host.
    if (hostEnd === -1)
      hostEnd = rest.length;

    this.host = rest.slice(0, hostEnd);
    rest = rest.slice(hostEnd);

    // pull out port.
    this.parseHost();

    // we've indicated that there is a hostname,
    // so even if it's empty, it has to be present.
    this.hostname = this.hostname || '';

    // if hostname begins with [ and ends with ]
    // assume that it's an IPv6 address.
    var ipv6Hostname = this.hostname[0] === '[' &&
        this.hostname[this.hostname.length - 1] === ']';

    // validate a little.
    if (!ipv6Hostname) {
      var hostparts = this.hostname.split(/\./);
      for (var i = 0, l = hostparts.length; i < l; i++) {
        var part = hostparts[i];
        if (!part) continue;
        if (!part.match(hostnamePartPattern)) {
          var newpart = '';
          for (var j = 0, k = part.length; j < k; j++) {
            if (part.charCodeAt(j) > 127) {
              // we replace non-ASCII char with a temporary placeholder
              // we need this to make sure size of hostname is not
              // broken by replacing non-ASCII by nothing
              newpart += 'x';
            } else {
              newpart += part[j];
            }
          }
          // we test again with ASCII char only
          if (!newpart.match(hostnamePartPattern)) {
            var validParts = hostparts.slice(0, i);
            var notHost = hostparts.slice(i + 1);
            var bit = part.match(hostnamePartStart);
            if (bit) {
              validParts.push(bit[1]);
              notHost.unshift(bit[2]);
            }
            if (notHost.length) {
              rest = '/' + notHost.join('.') + rest;
            }
            this.hostname = validParts.join('.');
            break;
          }
        }
      }
    }

    if (this.hostname.length > hostnameMaxLen) {
      this.hostname = '';
    } else {
      // hostnames are always lower case.
      this.hostname = this.hostname.toLowerCase();
    }

    if (!ipv6Hostname) {
      // IDNA Support: Returns a punycoded representation of "domain".
      // It only converts parts of the domain name that
      // have non-ASCII characters, i.e. it doesn't matter if
      // you call it with a domain that already is ASCII-only.
      this.hostname = punycode.toASCII(this.hostname);
    }

    var p = this.port ? ':' + this.port : '';
    var h = this.hostname || '';
    this.host = h + p;
    this.href += this.host;

    // strip [ and ] from the hostname
    // the host field still retains them, though
    if (ipv6Hostname) {
      this.hostname = this.hostname.substr(1, this.hostname.length - 2);
      if (rest[0] !== '/') {
        rest = '/' + rest;
      }
    }
  }

  // now rest is set to the post-host stuff.
  // chop off any delim chars.
  if (!unsafeProtocol[lowerProto]) {

    // First, make 100% sure that any "autoEscape" chars get
    // escaped, even if encodeURIComponent doesn't think they
    // need to be.
    for (var i = 0, l = autoEscape.length; i < l; i++) {
      var ae = autoEscape[i];
      if (rest.indexOf(ae) === -1)
        continue;
      var esc = encodeURIComponent(ae);
      if (esc === ae) {
        esc = escape(ae);
      }
      rest = rest.split(ae).join(esc);
    }
  }


  // chop off from the tail first.
  var hash = rest.indexOf('#');
  if (hash !== -1) {
    // got a fragment string.
    this.hash = rest.substr(hash);
    rest = rest.slice(0, hash);
  }
  var qm = rest.indexOf('?');
  if (qm !== -1) {
    this.search = rest.substr(qm);
    this.query = rest.substr(qm + 1);
    if (parseQueryString) {
      this.query = querystring.parse(this.query);
    }
    rest = rest.slice(0, qm);
  } else if (parseQueryString) {
    // no query string, but parseQueryString still requested
    this.search = '';
    this.query = {};
  }
  if (rest) this.pathname = rest;
  if (slashedProtocol[lowerProto] &&
      this.hostname && !this.pathname) {
    this.pathname = '/';
  }

  //to support http.request
  if (this.pathname || this.search) {
    var p = this.pathname || '';
    var s = this.search || '';
    this.path = p + s;
  }

  // finally, reconstruct the href based on what has been validated.
  this.href = this.format();
  return this;
};

// format a parsed object into a url string
function urlFormat(obj) {
  // ensure it's an object, and not a string url.
  // If it's an obj, this is a no-op.
  // this way, you can call url_format() on strings
  // to clean up potentially wonky urls.
  if (util.isString(obj)) obj = urlParse(obj);
  if (!(obj instanceof Url)) return Url.prototype.format.call(obj);
  return obj.format();
}

Url.prototype.format = function() {
  var auth = this.auth || '';
  if (auth) {
    auth = encodeURIComponent(auth);
    auth = auth.replace(/%3A/i, ':');
    auth += '@';
  }

  var protocol = this.protocol || '',
      pathname = this.pathname || '',
      hash = this.hash || '',
      host = false,
      query = '';

  if (this.host) {
    host = auth + this.host;
  } else if (this.hostname) {
    host = auth + (this.hostname.indexOf(':') === -1 ?
        this.hostname :
        '[' + this.hostname + ']');
    if (this.port) {
      host += ':' + this.port;
    }
  }

  if (this.query &&
      util.isObject(this.query) &&
      Object.keys(this.query).length) {
    query = querystring.stringify(this.query);
  }

  var search = this.search || (query && ('?' + query)) || '';

  if (protocol && protocol.substr(-1) !== ':') protocol += ':';

  // only the slashedProtocols get the //.  Not mailto:, xmpp:, etc.
  // unless they had them to begin with.
  if (this.slashes ||
      (!protocol || slashedProtocol[protocol]) && host !== false) {
    host = '//' + (host || '');
    if (pathname && pathname.charAt(0) !== '/') pathname = '/' + pathname;
  } else if (!host) {
    host = '';
  }

  if (hash && hash.charAt(0) !== '#') hash = '#' + hash;
  if (search && search.charAt(0) !== '?') search = '?' + search;

  pathname = pathname.replace(/[?#]/g, function(match) {
    return encodeURIComponent(match);
  });
  search = search.replace('#', '%23');

  return protocol + host + pathname + search + hash;
};

function urlResolve(source, relative) {
  return urlParse(source, false, true).resolve(relative);
}

Url.prototype.resolve = function(relative) {
  return this.resolveObject(urlParse(relative, false, true)).format();
};

function urlResolveObject(source, relative) {
  if (!source) return relative;
  return urlParse(source, false, true).resolveObject(relative);
}

Url.prototype.resolveObject = function(relative) {
  if (util.isString(relative)) {
    var rel = new Url();
    rel.parse(relative, false, true);
    relative = rel;
  }

  var result = new Url();
  var tkeys = Object.keys(this);
  for (var tk = 0; tk < tkeys.length; tk++) {
    var tkey = tkeys[tk];
    result[tkey] = this[tkey];
  }

  // hash is always overridden, no matter what.
  // even href="" will remove it.
  result.hash = relative.hash;

  // if the relative url is empty, then there's nothing left to do here.
  if (relative.href === '') {
    result.href = result.format();
    return result;
  }

  // hrefs like //foo/bar always cut to the protocol.
  if (relative.slashes && !relative.protocol) {
    // take everything except the protocol from relative
    var rkeys = Object.keys(relative);
    for (var rk = 0; rk < rkeys.length; rk++) {
      var rkey = rkeys[rk];
      if (rkey !== 'protocol')
        result[rkey] = relative[rkey];
    }

    //urlParse appends trailing / to urls like http://www.example.com
    if (slashedProtocol[result.protocol] &&
        result.hostname && !result.pathname) {
      result.path = result.pathname = '/';
    }

    result.href = result.format();
    return result;
  }

  if (relative.protocol && relative.protocol !== result.protocol) {
    // if it's a known url protocol, then changing
    // the protocol does weird things
    // first, if it's not file:, then we MUST have a host,
    // and if there was a path
    // to begin with, then we MUST have a path.
    // if it is file:, then the host is dropped,
    // because that's known to be hostless.
    // anything else is assumed to be absolute.
    if (!slashedProtocol[relative.protocol]) {
      var keys = Object.keys(relative);
      for (var v = 0; v < keys.length; v++) {
        var k = keys[v];
        result[k] = relative[k];
      }
      result.href = result.format();
      return result;
    }

    result.protocol = relative.protocol;
    if (!relative.host && !hostlessProtocol[relative.protocol]) {
      var relPath = (relative.pathname || '').split('/');
      while (relPath.length && !(relative.host = relPath.shift()));
      if (!relative.host) relative.host = '';
      if (!relative.hostname) relative.hostname = '';
      if (relPath[0] !== '') relPath.unshift('');
      if (relPath.length < 2) relPath.unshift('');
      result.pathname = relPath.join('/');
    } else {
      result.pathname = relative.pathname;
    }
    result.search = relative.search;
    result.query = relative.query;
    result.host = relative.host || '';
    result.auth = relative.auth;
    result.hostname = relative.hostname || relative.host;
    result.port = relative.port;
    // to support http.request
    if (result.pathname || result.search) {
      var p = result.pathname || '';
      var s = result.search || '';
      result.path = p + s;
    }
    result.slashes = result.slashes || relative.slashes;
    result.href = result.format();
    return result;
  }

  var isSourceAbs = (result.pathname && result.pathname.charAt(0) === '/'),
      isRelAbs = (
          relative.host ||
          relative.pathname && relative.pathname.charAt(0) === '/'
      ),
      mustEndAbs = (isRelAbs || isSourceAbs ||
                    (result.host && relative.pathname)),
      removeAllDots = mustEndAbs,
      srcPath = result.pathname && result.pathname.split('/') || [],
      relPath = relative.pathname && relative.pathname.split('/') || [],
      psychotic = result.protocol && !slashedProtocol[result.protocol];

  // if the url is a non-slashed url, then relative
  // links like ../.. should be able
  // to crawl up to the hostname, as well.  This is strange.
  // result.protocol has already been set by now.
  // Later on, put the first path part into the host field.
  if (psychotic) {
    result.hostname = '';
    result.port = null;
    if (result.host) {
      if (srcPath[0] === '') srcPath[0] = result.host;
      else srcPath.unshift(result.host);
    }
    result.host = '';
    if (relative.protocol) {
      relative.hostname = null;
      relative.port = null;
      if (relative.host) {
        if (relPath[0] === '') relPath[0] = relative.host;
        else relPath.unshift(relative.host);
      }
      relative.host = null;
    }
    mustEndAbs = mustEndAbs && (relPath[0] === '' || srcPath[0] === '');
  }

  if (isRelAbs) {
    // it's absolute.
    result.host = (relative.host || relative.host === '') ?
                  relative.host : result.host;
    result.hostname = (relative.hostname || relative.hostname === '') ?
                      relative.hostname : result.hostname;
    result.search = relative.search;
    result.query = relative.query;
    srcPath = relPath;
    // fall through to the dot-handling below.
  } else if (relPath.length) {
    // it's relative
    // throw away the existing file, and take the new path instead.
    if (!srcPath) srcPath = [];
    srcPath.pop();
    srcPath = srcPath.concat(relPath);
    result.search = relative.search;
    result.query = relative.query;
  } else if (!util.isNullOrUndefined(relative.search)) {
    // just pull out the search.
    // like href='?foo'.
    // Put this after the other two cases because it simplifies the booleans
    if (psychotic) {
      result.hostname = result.host = srcPath.shift();
      //occationaly the auth can get stuck only in host
      //this especially happens in cases like
      //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
      var authInHost = result.host && result.host.indexOf('@') > 0 ?
                       result.host.split('@') : false;
      if (authInHost) {
        result.auth = authInHost.shift();
        result.host = result.hostname = authInHost.shift();
      }
    }
    result.search = relative.search;
    result.query = relative.query;
    //to support http.request
    if (!util.isNull(result.pathname) || !util.isNull(result.search)) {
      result.path = (result.pathname ? result.pathname : '') +
                    (result.search ? result.search : '');
    }
    result.href = result.format();
    return result;
  }

  if (!srcPath.length) {
    // no path at all.  easy.
    // we've already handled the other stuff above.
    result.pathname = null;
    //to support http.request
    if (result.search) {
      result.path = '/' + result.search;
    } else {
      result.path = null;
    }
    result.href = result.format();
    return result;
  }

  // if a url ENDs in . or .., then it must get a trailing slash.
  // however, if it ends in anything else non-slashy,
  // then it must NOT get a trailing slash.
  var last = srcPath.slice(-1)[0];
  var hasTrailingSlash = (
      (result.host || relative.host || srcPath.length > 1) &&
      (last === '.' || last === '..') || last === '');

  // strip single dots, resolve double dots to parent dir
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = srcPath.length; i >= 0; i--) {
    last = srcPath[i];
    if (last === '.') {
      srcPath.splice(i, 1);
    } else if (last === '..') {
      srcPath.splice(i, 1);
      up++;
    } else if (up) {
      srcPath.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (!mustEndAbs && !removeAllDots) {
    for (; up--; up) {
      srcPath.unshift('..');
    }
  }

  if (mustEndAbs && srcPath[0] !== '' &&
      (!srcPath[0] || srcPath[0].charAt(0) !== '/')) {
    srcPath.unshift('');
  }

  if (hasTrailingSlash && (srcPath.join('/').substr(-1) !== '/')) {
    srcPath.push('');
  }

  var isAbsolute = srcPath[0] === '' ||
      (srcPath[0] && srcPath[0].charAt(0) === '/');

  // put the host back
  if (psychotic) {
    result.hostname = result.host = isAbsolute ? '' :
                                    srcPath.length ? srcPath.shift() : '';
    //occationaly the auth can get stuck only in host
    //this especially happens in cases like
    //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
    var authInHost = result.host && result.host.indexOf('@') > 0 ?
                     result.host.split('@') : false;
    if (authInHost) {
      result.auth = authInHost.shift();
      result.host = result.hostname = authInHost.shift();
    }
  }

  mustEndAbs = mustEndAbs || (result.host && srcPath.length);

  if (mustEndAbs && !isAbsolute) {
    srcPath.unshift('');
  }

  if (!srcPath.length) {
    result.pathname = null;
    result.path = null;
  } else {
    result.pathname = srcPath.join('/');
  }

  //to support request.http
  if (!util.isNull(result.pathname) || !util.isNull(result.search)) {
    result.path = (result.pathname ? result.pathname : '') +
                  (result.search ? result.search : '');
  }
  result.auth = relative.auth || result.auth;
  result.slashes = result.slashes || relative.slashes;
  result.href = result.format();
  return result;
};

Url.prototype.parseHost = function() {
  var host = this.host;
  var port = portPattern.exec(host);
  if (port) {
    port = port[0];
    if (port !== ':') {
      this.port = port.substr(1);
    }
    host = host.substr(0, host.length - port.length);
  }
  if (host) this.hostname = host;
};


/***/ }),

/***/ "./node_modules/url/util.js":
/*!**********************************!*\
  !*** ./node_modules/url/util.js ***!
  \**********************************/
/*! no static exports found */
/***/ (function(module, exports, __webpack_require__) {

"use strict";


module.exports = {
  isString: function(arg) {
    return typeof(arg) === 'string';
  },
  isObject: function(arg) {
    return typeof(arg) === 'object' && arg !== null;
  },
  isNull: function(arg) {
    return arg === null;
  },
  isNullOrUndefined: function(arg) {
    return arg == null;
  }
};


/***/ }),

/***/ "./node_modules/webpack/buildin/global.js":
/*!***********************************!*\
  !*** (webpack)/buildin/global.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports) {

var g;

// This works in non-strict mode
g = (function() {
	return this;
})();

try {
	// This works if eval is allowed (see CSP)
	g = g || new Function("return this")();
} catch (e) {
	// This works if the window reference is available
	if (typeof window === "object") g = window;
}

// g can still be undefined, but nothing to do about it...
// We return undefined, instead of nothing here, so it's
// easier to handle this case. if(!global) { ...}

module.exports = g;


/***/ }),

/***/ "./node_modules/webpack/buildin/module.js":
/*!***********************************!*\
  !*** (webpack)/buildin/module.js ***!
  \***********************************/
/*! no static exports found */
/***/ (function(module, exports) {

module.exports = function(module) {
	if (!module.webpackPolyfill) {
		module.deprecate = function() {};
		module.paths = [];
		// module.parent = undefined by default
		if (!module.children) module.children = [];
		Object.defineProperty(module, "loaded", {
			enumerable: true,
			get: function() {
				return module.l;
			}
		});
		Object.defineProperty(module, "id", {
			enumerable: true,
			get: function() {
				return module.i;
			}
		});
		module.webpackPolyfill = 1;
	}
	return module;
};


/***/ })

/******/ });
//# sourceMappingURL=PCSHTMLConverter.js.map