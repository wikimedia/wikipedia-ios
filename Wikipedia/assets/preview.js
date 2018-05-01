(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){

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
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["pagelib"] = factory();
	else
		root["pagelib"] = factory();
})(typeof self !== 'undefined' ? self : this, function() {
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
/******/ 			Object.defineProperty(exports, name, {
/******/ 				configurable: false,
/******/ 				enumerable: true,
/******/ 				get: getter
/******/ 			});
/******/ 		}
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
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = 10);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var matchesSelector=function matchesSelector(el,selector){if(el.matches){return el.matches(selector);}if(el.matchesSelector){return el.matchesSelector(selector);}if(el.webkitMatchesSelector){return el.webkitMatchesSelector(selector);}return false;};var querySelectorAll=function querySelectorAll(element,selector){return Array.prototype.slice.call(element.querySelectorAll(selector));};var CustomEvent=typeof window!=='undefined'&&window.CustomEvent||function(type){var parameters=arguments.length>1&&arguments[1]!==undefined?arguments[1]:{bubbles:false,cancelable:false,detail:undefined};var event=document.createEvent('CustomEvent');event.initCustomEvent(type,parameters.bubbles,parameters.cancelable,parameters.detail);return event;};exports.default={matchesSelector:matchesSelector,querySelectorAll:querySelectorAll,CustomEvent:CustomEvent};

/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var findClosestAncestor=function findClosestAncestor(el,selector){var parentElement=void 0;for(parentElement=el.parentElement;parentElement&&!_Polyfill2.default.matchesSelector(parentElement,selector);parentElement=parentElement.parentElement){}return parentElement;};var closestInlineStyle=function closestInlineStyle(element,property){for(var el=element;el;el=el.parentElement){if(el.style[property]){return el;}}return undefined;};var isNestedInTable=function isNestedInTable(el){return Boolean(findClosestAncestor(el,'table'));};var isVisible=function isVisible(element){return Boolean(element.offsetWidth||element.offsetHeight||element.getClientRects().length);};var copyAttributesToDataAttributes=function copyAttributesToDataAttributes(source,destination,attributes){attributes.filter(function(attribute){return source.hasAttribute(attribute);}).forEach(function(attribute){return destination.setAttribute('data-'+attribute,source.getAttribute(attribute));});};var copyDataAttributesToAttributes=function copyDataAttributesToAttributes(source,destination,attributes){attributes.filter(function(attribute){return source.hasAttribute('data-'+attribute);}).forEach(function(attribute){return destination.setAttribute(attribute,source.getAttribute('data-'+attribute));});};exports.default={findClosestAncestor:findClosestAncestor,isNestedInTable:isNestedInTable,closestInlineStyle:closestInlineStyle,isVisible:isVisible,copyAttributesToDataAttributes:copyAttributesToDataAttributes,copyDataAttributesToAttributes:copyDataAttributesToAttributes};

/***/ }),
/* 2 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _createClass=function(){function defineProperties(target,props){for(var i=0;i<props.length;i++){var descriptor=props[i];descriptor.enumerable=descriptor.enumerable||false;descriptor.configurable=true;if("value"in descriptor)descriptor.writable=true;Object.defineProperty(target,descriptor.key,descriptor);}}return function(Constructor,protoProps,staticProps){if(protoProps)defineProperties(Constructor.prototype,protoProps);if(staticProps)defineProperties(Constructor,staticProps);return Constructor;};}();function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var Throttle=function(){_createClass(Throttle,null,[{key:"wrap",value:function wrap(window,period,funktion){var throttle=new Throttle(window,period,funktion);var throttled=function Throttled(){return throttle.queue(this,arguments);};throttled.result=function(){return throttle.result;};throttled.pending=function(){return throttle.pending();};throttled.delay=function(){return throttle.delay();};throttled.cancel=function(){return throttle.cancel();};throttled.reset=function(){return throttle.reset();};return throttled;}}]);function Throttle(window,period,funktion){_classCallCheck(this,Throttle);this._window=window;this._period=period;this._function=funktion;this._context=undefined;this._arguments=undefined;this._result=undefined;this._timeout=0;this._timestamp=0;}_createClass(Throttle,[{key:"queue",value:function queue(context,args){var _this=this;this._context=context;this._arguments=args;if(!this.pending()){this._timeout=this._window.setTimeout(function(){_this._timeout=0;_this._timestamp=Date.now();_this._result=_this._function.apply(_this._context,_this._arguments);},this.delay());}return this.result;}},{key:"pending",value:function pending(){return Boolean(this._timeout);}},{key:"delay",value:function delay(){if(!this._timestamp){return 0;}return Math.max(0,this._period-(Date.now()-this._timestamp));}},{key:"cancel",value:function cancel(){if(this._timeout){this._window.clearTimeout(this._timeout);}this._timeout=0;}},{key:"reset",value:function reset(){this.cancel();this._result=undefined;this._timestamp=0;}},{key:"result",get:function get(){return this._result;}}]);return Throttle;}();exports.default=Throttle;

/***/ }),
/* 3 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(13);var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var SECTION_TOGGLED_EVENT_TYPE='section-toggled';var ELEMENT_NODE=1;var TEXT_NODE=3;var BREAKING_SPACE=' ';var isHeaderEligible=function isHeaderEligible(header){return header.childNodes&&_Polyfill2.default.querySelectorAll(header,'a').length<3;};var isHeaderTextEligible=function isHeaderTextEligible(headerText){return headerText&&headerText.replace(/[\s0-9]/g,'').length>0;};var firstWordFromString=function firstWordFromString(string){var matches=string.match(/\w+/);if(!matches){return undefined;}return matches[0];};var isNodeTextContentSimilarToPageTitle=function isNodeTextContentSimilarToPageTitle(node,pageTitle){var firstPageTitleWord=firstWordFromString(pageTitle);var firstNodeTextContentWord=firstWordFromString(node.textContent);if(!firstPageTitleWord||!firstNodeTextContentWord){return false;}return firstPageTitleWord.toLowerCase()===firstNodeTextContentWord.toLowerCase();};var nodeTypeIsElementOrText=function nodeTypeIsElementOrText(node){return node.nodeType===ELEMENT_NODE||node.nodeType===TEXT_NODE;};var stringWithNormalizedWhitespace=function stringWithNormalizedWhitespace(string){return string.trim().replace(/\s/g,BREAKING_SPACE);};var isNodeBreakElement=function isNodeBreakElement(node){return node.nodeType===ELEMENT_NODE&&node.tagName==='BR';};var replaceNodeWithBreakingSpaceTextNode=function replaceNodeWithBreakingSpaceTextNode(document,node){return node.parentNode.replaceChild(document.createTextNode(BREAKING_SPACE),node);};var extractEligibleHeaderText=function extractEligibleHeaderText(document,header,pageTitle){if(!isHeaderEligible(header)){return null;}var fragment=document.createDocumentFragment();fragment.appendChild(header.cloneNode(true));var fragmentHeader=fragment.querySelector('th');_Polyfill2.default.querySelectorAll(fragmentHeader,'.geo, .coordinates, sup.reference, ol, ul').forEach(function(el){return el.remove();});var childNodesArray=Array.prototype.slice.call(fragmentHeader.childNodes);if(pageTitle){childNodesArray.filter(nodeTypeIsElementOrText).filter(function(node){return isNodeTextContentSimilarToPageTitle(node,pageTitle);}).forEach(function(node){return node.remove();});}childNodesArray.filter(isNodeBreakElement).forEach(function(node){return replaceNodeWithBreakingSpaceTextNode(document,node);});var headerText=fragmentHeader.textContent;if(isHeaderTextEligible(headerText)){return stringWithNormalizedWhitespace(headerText);}return null;};var elementScopeComparator=function elementScopeComparator(a,b){var aHasScope=a.hasAttribute('scope');var bHasScope=b.hasAttribute('scope');if(aHasScope&&bHasScope){return 0;}if(aHasScope){return-1;}if(bHasScope){return 1;}return 0;};var getTableHeaderTextArray=function getTableHeaderTextArray(document,element,pageTitle){var headerTextArray=[];var headers=_Polyfill2.default.querySelectorAll(element,'th');headers.sort(elementScopeComparator);for(var i=0;i<headers.length;++i){var headerText=extractEligibleHeaderText(document,headers[i],pageTitle);if(headerText&&headerTextArray.indexOf(headerText)===-1){headerTextArray.push(headerText);if(headerTextArray.length===2){break;}}}return headerTextArray;};var toggleCollapsedForContainer=function toggleCollapsedForContainer(container,trigger,footerDivClickCallback){var header=container.children[0];var table=container.children[1];var footer=container.children[2];var caption=header.querySelector('.app_table_collapsed_caption');var collapsed=table.style.display!=='none';if(collapsed){table.style.display='none';header.classList.remove('pagelib_collapse_table_collapsed');header.classList.remove('pagelib_collapse_table_icon');header.classList.add('pagelib_collapse_table_expanded');if(caption){caption.style.visibility='visible';}footer.style.display='none';if(trigger===footer&&footerDivClickCallback){footerDivClickCallback(container);}}else{table.style.display='block';header.classList.remove('pagelib_collapse_table_expanded');header.classList.add('pagelib_collapse_table_collapsed');header.classList.add('pagelib_collapse_table_icon');if(caption){caption.style.visibility='hidden';}footer.style.display='block';}return collapsed;};var toggleCollapseClickCallback=function toggleCollapseClickCallback(footerDivClickCallback){var container=this.parentNode;return toggleCollapsedForContainer(container,this,footerDivClickCallback);};var shouldTableBeCollapsed=function shouldTableBeCollapsed(table){var classBlacklist=['navbox','vertical-navbox','navbox-inner','metadata','mbox-small'];var blacklistIntersects=classBlacklist.some(function(clazz){return table.classList.contains(clazz);});return table.style.display!=='none'&&!blacklistIntersects;};var isInfobox=function isInfobox(element){return element.classList.contains('infobox');};var newCollapsedHeaderDiv=function newCollapsedHeaderDiv(document,content){var div=document.createElement('div');div.classList.add('pagelib_collapse_table_collapsed_container');div.classList.add('pagelib_collapse_table_expanded');div.appendChild(content);return div;};var newCollapsedFooterDiv=function newCollapsedFooterDiv(document,content){var div=document.createElement('div');div.classList.add('pagelib_collapse_table_collapsed_bottom');div.classList.add('pagelib_collapse_table_icon');div.innerHTML=content||'';return div;};var newCaptionFragment=function newCaptionFragment(document,title,headerText){var fragment=document.createDocumentFragment();var strong=document.createElement('strong');strong.innerHTML=title;fragment.appendChild(strong);var span=document.createElement('span');span.classList.add('pagelib_collapse_table_collapse_text');if(headerText.length>0){span.appendChild(document.createTextNode(': '+headerText[0]));}if(headerText.length>1){span.appendChild(document.createTextNode(', '+headerText[1]));}if(headerText.length>0){span.appendChild(document.createTextNode(' …'));}fragment.appendChild(span);return fragment;};var adjustTables=function adjustTables(window,document,pageTitle,isMainPage,isInitiallyCollapsed,infoboxTitle,otherTitle,footerTitle,footerDivClickCallback){if(isMainPage){return;}var tables=document.querySelectorAll('table');var _loop=function _loop(i){var table=tables[i];if(_ElementUtilities2.default.findClosestAncestor(table,'.pagelib_collapse_table_container')||!shouldTableBeCollapsed(table)){return'continue';}var headerTextArray=getTableHeaderTextArray(document,table,pageTitle);if(!headerTextArray.length&&!isInfobox(table)){return'continue';}var captionFragment=newCaptionFragment(document,isInfobox(table)?infoboxTitle:otherTitle,headerTextArray);var containerDiv=document.createElement('div');containerDiv.className='pagelib_collapse_table_container';table.parentNode.insertBefore(containerDiv,table);table.parentNode.removeChild(table);table.style.marginTop='0px';table.style.marginBottom='0px';var collapsedHeaderDiv=newCollapsedHeaderDiv(document,captionFragment);collapsedHeaderDiv.style.display='block';var collapsedFooterDiv=newCollapsedFooterDiv(document,footerTitle);collapsedFooterDiv.style.display='none';containerDiv.appendChild(collapsedHeaderDiv);containerDiv.appendChild(table);containerDiv.appendChild(collapsedFooterDiv);table.style.display='none';var dispatchSectionToggledEvent=function dispatchSectionToggledEvent(collapsed){return window.dispatchEvent(new _Polyfill2.default.CustomEvent(SECTION_TOGGLED_EVENT_TYPE,{collapsed:collapsed}));};collapsedHeaderDiv.onclick=function(){var collapsed=toggleCollapseClickCallback.bind(collapsedHeaderDiv)();dispatchSectionToggledEvent(collapsed);};collapsedFooterDiv.onclick=function(){var collapsed=toggleCollapseClickCallback.bind(collapsedFooterDiv,footerDivClickCallback)();dispatchSectionToggledEvent(collapsed);};if(!isInitiallyCollapsed){toggleCollapsedForContainer(containerDiv);}};for(var i=0;i<tables.length;++i){var _ret=_loop(i);if(_ret==='continue')continue;}};var collapseTables=function collapseTables(window,document,pageTitle,isMainPage,infoboxTitle,otherTitle,footerTitle,footerDivClickCallback){adjustTables(window,document,pageTitle,isMainPage,true,infoboxTitle,otherTitle,footerTitle,footerDivClickCallback);};var expandCollapsedTableIfItContainsElement=function expandCollapsedTableIfItContainsElement(element){if(element){var containerSelector='[class*="pagelib_collapse_table_container"]';var container=_ElementUtilities2.default.findClosestAncestor(element,containerSelector);if(container){var collapsedDiv=container.firstElementChild;if(collapsedDiv&&collapsedDiv.classList.contains('pagelib_collapse_table_expanded')){collapsedDiv.click();}}}};exports.default={SECTION_TOGGLED_EVENT_TYPE:SECTION_TOGGLED_EVENT_TYPE,toggleCollapseClickCallback:toggleCollapseClickCallback,collapseTables:collapseTables,adjustTables:adjustTables,expandCollapsedTableIfItContainsElement:expandCollapsedTableIfItContainsElement,test:{elementScopeComparator:elementScopeComparator,extractEligibleHeaderText:extractEligibleHeaderText,firstWordFromString:firstWordFromString,getTableHeaderTextArray:getTableHeaderTextArray,shouldTableBeCollapsed:shouldTableBeCollapsed,isHeaderEligible:isHeaderEligible,isHeaderTextEligible:isHeaderTextEligible,isInfobox:isInfobox,newCollapsedHeaderDiv:newCollapsedHeaderDiv,newCollapsedFooterDiv:newCollapsedFooterDiv,newCaptionFragment:newCaptionFragment,isNodeTextContentSimilarToPageTitle:isNodeTextContentSimilarToPageTitle,stringWithNormalizedWhitespace:stringWithNormalizedWhitespace,replaceNodeWithBreakingSpaceTextNode:replaceNodeWithBreakingSpaceTextNode}};

/***/ }),
/* 4 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var collectPageIssues=function collectPageIssues(document,element){if(!element){return[];}var tables=_Polyfill2.default.querySelectorAll(element,'table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)');var fragment=document.createDocumentFragment();var cloneTableIntoFragment=function cloneTableIntoFragment(table){return fragment.appendChild(table.cloneNode(true));};tables.forEach(cloneTableIntoFragment);_Polyfill2.default.querySelectorAll(fragment,'.hide-when-compact, .collapsed').forEach(function(el){return el.remove();});return _Polyfill2.default.querySelectorAll(fragment,'td[class*=mbox-text] > *[class*=mbox-text]');};var collectPageIssuesHTML=function collectPageIssuesHTML(document,element){return collectPageIssues(document,element).map(function(el){return el.innerHTML;});};var collectPageIssuesText=function collectPageIssuesText(document,element){return collectPageIssues(document,element).map(function(el){return el.textContent.trim();});};var collectDisambiguationTitles=function collectDisambiguationTitles(element){if(!element){return[];}return _Polyfill2.default.querySelectorAll(element,'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function(el){return el.href;});};var collectDisambiguationHTML=function collectDisambiguationHTML(element){if(!element){return[];}return _Polyfill2.default.querySelectorAll(element,'div.hatnote').map(function(el){return el.innerHTML;});};exports.default={collectDisambiguationTitles:collectDisambiguationTitles,collectDisambiguationHTML:collectDisambiguationHTML,collectPageIssuesHTML:collectPageIssuesHTML,collectPageIssuesText:collectPageIssuesText,test:{collectPageIssues:collectPageIssues}};

/***/ }),
/* 5 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _createClass=function(){function defineProperties(target,props){for(var i=0;i<props.length;i++){var descriptor=props[i];descriptor.enumerable=descriptor.enumerable||false;descriptor.configurable=true;if("value"in descriptor)descriptor.writable=true;Object.defineProperty(target,descriptor.key,descriptor);}}return function(Constructor,protoProps,staticProps){if(protoProps)defineProperties(Constructor.prototype,protoProps);if(staticProps)defineProperties(Constructor,staticProps);return Constructor;};}();function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var DimensionUnit=function(){_createClass(DimensionUnit,null,[{key:'fromElement',value:function fromElement(element,property){return element.style.getPropertyValue(property)&&DimensionUnit.fromStyle(element.style.getPropertyValue(property))||element.hasAttribute(property)&&new DimensionUnit(element.getAttribute(property))||undefined;}},{key:'fromStyle',value:function fromStyle(property){var matches=property.match(/(-?\d*\.?\d*)(\D+)?/)||[];return new DimensionUnit(matches[1],matches[2]);}}]);function DimensionUnit(value,unit){_classCallCheck(this,DimensionUnit);this._value=Number(value);this._unit=unit||'px';}_createClass(DimensionUnit,[{key:'toString',value:function toString(){return isNaN(this.value)?'':''+this.value+this.unit;}},{key:'value',get:function get(){return this._value;}},{key:'unit',get:function get(){return this._unit;}}]);return DimensionUnit;}();var ElementGeometry=function(){_createClass(ElementGeometry,null,[{key:'from',value:function from(element){return new ElementGeometry(DimensionUnit.fromElement(element,'width'),DimensionUnit.fromElement(element,'height'));}}]);function ElementGeometry(width,height){_classCallCheck(this,ElementGeometry);this._width=width;this._height=height;}_createClass(ElementGeometry,[{key:'width',get:function get(){return this._width;}},{key:'widthValue',get:function get(){return this._width&&!isNaN(this._width.value)?this._width.value:NaN;}},{key:'widthUnit',get:function get(){return this._width&&this._width.unit||'px';}},{key:'height',get:function get(){return this._height;}},{key:'heightValue',get:function get(){return this._height&&!isNaN(this._height.value)?this._height.value:NaN;}},{key:'heightUnit',get:function get(){return this._height&&this._height.unit||'px';}}]);return ElementGeometry;}();exports.default=ElementGeometry;

/***/ }),
/* 6 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(20);var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var updateBottomPaddingToAllowReadMoreToScrollToTop=function updateBottomPaddingToAllowReadMoreToScrollToTop(window){var div=window.document.getElementById('pagelib_footer_container_ensure_can_scroll_to_top');var currentPadding=parseInt(div.style.paddingBottom,10)||0;var height=div.clientHeight-currentPadding;var newPadding=Math.max(0,window.innerHeight-height);div.style.paddingBottom=newPadding+'px';};var updateLeftAndRightMargin=function updateLeftAndRightMargin(margin,document){var selectors=['#pagelib_footer_container_menu_heading','#pagelib_footer_container_readmore','#pagelib_footer_container_legal'];var elements=_Polyfill2.default.querySelectorAll(document,selectors.join());elements.forEach(function(element){element.style.marginLeft=margin+'px';element.style.marginRight=margin+'px';});var rightOrLeft=document.querySelector('html').dir==='rtl'?'right':'left';_Polyfill2.default.querySelectorAll(document,'.pagelib_footer_menu_item').forEach(function(element){element.style.backgroundPosition=rightOrLeft+' '+margin+'px center';element.style.paddingLeft=margin+'px';element.style.paddingRight=margin+'px';});};var containerFragment=function containerFragment(document){var containerDiv=document.createElement('div');var containerFragment=document.createDocumentFragment();containerFragment.appendChild(containerDiv);containerDiv.innerHTML='<div id=\'pagelib_footer_container\' class=\'pagelib_footer_container\'>\n    <div id=\'pagelib_footer_container_section_0\'>\n      <div id=\'pagelib_footer_container_menu\'>\n        <div id=\'pagelib_footer_container_menu_heading\' class=\'pagelib_footer_container_heading\'>\n        </div>\n        <div id=\'pagelib_footer_container_menu_items\'>\n        </div>\n      </div>\n    </div>\n    <div id=\'pagelib_footer_container_ensure_can_scroll_to_top\'>\n      <div id=\'pagelib_footer_container_section_1\'>\n        <div id=\'pagelib_footer_container_readmore\'>\n          <div\n            id=\'pagelib_footer_container_readmore_heading\' class=\'pagelib_footer_container_heading\'>\n          </div>\n          <div id=\'pagelib_footer_container_readmore_pages\'>\n          </div>\n        </div>\n      </div>\n      <div id=\'pagelib_footer_container_legal\'></div>\n    </div>\n  </div>';return containerFragment;};var isContainerAttached=function isContainerAttached(document){return Boolean(document.querySelector('#pagelib_footer_container'));};exports.default={containerFragment:containerFragment,isContainerAttached:isContainerAttached,updateBottomPaddingToAllowReadMoreToScrollToTop:updateBottomPaddingToAllowReadMoreToScrollToTop,updateLeftAndRightMargin:updateLeftAndRightMargin};

/***/ }),
/* 7 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(21);var add=function add(content,licenseString,licenseSubstitutionString,containerID,licenseLinkClickHandler,viewInBrowserString,browserLinkClickHandler){var container=content.querySelector('#'+containerID);var licenseStringHalves=licenseString.split('$1');container.innerHTML='<div class=\'pagelib_footer_legal_contents\'>\n    <hr class=\'pagelib_footer_legal_divider\'>\n    <span class=\'pagelib_footer_legal_license\'>\n      '+licenseStringHalves[0]+'\n      <a class=\'pagelib_footer_legal_license_link\'>\n        '+licenseSubstitutionString+'\n      </a>\n      '+licenseStringHalves[1]+'\n      <br>\n      <div class="pagelib_footer_browser">\n        <a class=\'pagelib_footer_browser_link\'>\n          '+viewInBrowserString+'\n        </a>\n      </div>\n    </span>\n  </div>';container.querySelector('.pagelib_footer_legal_license_link').addEventListener('click',function(){licenseLinkClickHandler();});container.querySelector('.pagelib_footer_browser_link').addEventListener('click',function(){browserLinkClickHandler();});};exports.default={add:add};

/***/ }),
/* 8 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(24);function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var SAVE_BUTTON_ID_PREFIX='pagelib_footer_read_more_save_';var safelyRemoveEnclosures=function safelyRemoveEnclosures(string,opener,closer){var enclosureRegex=new RegExp('\\s?['+opener+'][^'+opener+closer+']+['+closer+']','g');var counter=0;var safeMaxTries=30;var stringToClean=string;var previousString='';do{previousString=stringToClean;stringToClean=stringToClean.replace(enclosureRegex,'');counter++;}while(previousString!==stringToClean&&counter<safeMaxTries);return stringToClean;};var cleanExtract=function cleanExtract(string){var stringToClean=string;stringToClean=safelyRemoveEnclosures(stringToClean,'(',')');stringToClean=safelyRemoveEnclosures(stringToClean,'/','/');return stringToClean;};var ReadMorePage=function ReadMorePage(title,thumbnail,description,extract){_classCallCheck(this,ReadMorePage);this.title=title;this.thumbnail=thumbnail;this.description=description;this.extract=extract;};var documentFragmentForReadMorePage=function documentFragmentForReadMorePage(readMorePage,index,saveButtonClickHandler,document){var outerAnchorContainer=document.createElement('a');outerAnchorContainer.id=index;outerAnchorContainer.className='pagelib_footer_readmore_page';var hasImage=readMorePage.thumbnail&&readMorePage.thumbnail.source;if(hasImage){var image=document.createElement('div');image.style.backgroundImage='url('+readMorePage.thumbnail.source+')';image.classList.add('pagelib_footer_readmore_page_image');outerAnchorContainer.appendChild(image);}var innerDivContainer=document.createElement('div');innerDivContainer.classList.add('pagelib_footer_readmore_page_container');outerAnchorContainer.appendChild(innerDivContainer);outerAnchorContainer.href='/wiki/'+encodeURI(readMorePage.title);if(readMorePage.title){var title=document.createElement('div');title.id=index;title.className='pagelib_footer_readmore_page_title';var displayTitle=readMorePage.title.replace(/_/g,' ');title.innerHTML=displayTitle;outerAnchorContainer.title=displayTitle;innerDivContainer.appendChild(title);}var description=void 0;if(readMorePage.description){description=readMorePage.description;}if((!description||description.length<10)&&readMorePage.extract){description=cleanExtract(readMorePage.extract);}if(description){var descriptionEl=document.createElement('div');descriptionEl.id=index;descriptionEl.className='pagelib_footer_readmore_page_description';descriptionEl.innerHTML=description;innerDivContainer.appendChild(descriptionEl);}var saveButton=document.createElement('div');saveButton.id=''+SAVE_BUTTON_ID_PREFIX+encodeURI(readMorePage.title);saveButton.className='pagelib_footer_readmore_page_save';saveButton.addEventListener('click',function(event){event.stopPropagation();event.preventDefault();saveButtonClickHandler(readMorePage.title);});innerDivContainer.appendChild(saveButton);return document.createDocumentFragment().appendChild(outerAnchorContainer);};var showReadMorePages=function showReadMorePages(pages,containerID,saveButtonClickHandler,titlesShownHandler,document){var shownTitles=[];var container=document.getElementById(containerID);pages.forEach(function(page,index){var title=page.title.replace(/ /g,'_');shownTitles.push(title);var pageModel=new ReadMorePage(title,page.thumbnail,page.description,page.extract);var pageFragment=documentFragmentForReadMorePage(pageModel,index,saveButtonClickHandler,document);container.appendChild(pageFragment);});titlesShownHandler(shownTitles);};var queryParameters=function queryParameters(title,count){return{action:'query',format:'json',formatversion:2,prop:'extracts|pageimages|description',generator:'search',gsrlimit:count,gsrprop:'redirecttitle',gsrsearch:'morelike:'+title,gsrwhat:'text',exchars:256,exintro:'',exlimit:count,explaintext:'',pilicense:'any',pilimit:count,piprop:'thumbnail',pithumbsize:120};};var stringFromQueryParameters=function stringFromQueryParameters(parameters){return Object.keys(parameters).map(function(key){return encodeURIComponent(key)+'='+encodeURIComponent(parameters[key]);}).join('&');};var readMoreQueryURL=function readMoreQueryURL(title,count,baseURL){return(baseURL||'')+'/w/api.php?'+stringFromQueryParameters(queryParameters(title,count));};var fetchErrorHandler=function fetchErrorHandler(statusText){console.log('statusText = '+statusText);};var fetchReadMore=function fetchReadMore(title,count,containerID,baseURL,showReadMorePagesHandler,saveButtonClickHandler,titlesShownHandler,document){var xhr=new XMLHttpRequest();xhr.open('GET',readMoreQueryURL(title,count,baseURL),true);xhr.onload=function(){if(xhr.readyState===XMLHttpRequest.DONE){if(xhr.status===200){showReadMorePagesHandler(JSON.parse(xhr.responseText).query.pages,containerID,saveButtonClickHandler,titlesShownHandler,document);}else{fetchErrorHandler(xhr.statusText);}}};xhr.onerror=function(){return fetchErrorHandler(xhr.statusText);};try{xhr.send();}catch(error){fetchErrorHandler(error.toString());}};var updateSaveButtonBookmarkIcon=function updateSaveButtonBookmarkIcon(button,isSaved){var unfilledClass='pagelib_footer_readmore_bookmark_unfilled';var filledClass='pagelib_footer_readmore_bookmark_filled';button.classList.remove(filledClass,unfilledClass);button.classList.add(isSaved?filledClass:unfilledClass);};var updateSaveButtonForTitle=function updateSaveButtonForTitle(title,text,isSaved,document){var saveButton=document.getElementById(''+SAVE_BUTTON_ID_PREFIX+encodeURI(title));if(!saveButton){return;}saveButton.innerText=text;saveButton.title=text;updateSaveButtonBookmarkIcon(saveButton,isSaved);};var add=function add(title,count,containerID,baseURL,saveButtonClickHandler,titlesShownHandler,document){fetchReadMore(title,count,containerID,baseURL,showReadMorePages,saveButtonClickHandler,titlesShownHandler,document);};var setHeading=function setHeading(headingString,headingID,document){var headingElement=document.getElementById(headingID);headingElement.innerText=headingString;headingElement.title=headingString;};exports.default={add:add,setHeading:setHeading,updateSaveButtonForTitle:updateSaveButtonForTitle,test:{cleanExtract:cleanExtract,safelyRemoveEnclosures:safelyRemoveEnclosures}};

/***/ }),
/* 9 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(26);var _ElementGeometry=__webpack_require__(5);var _ElementGeometry2=_interopRequireDefault(_ElementGeometry);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var PLACEHOLDER_CLASS='pagelib_lazy_load_placeholder';var PLACEHOLDER_PENDING_CLASS='pagelib_lazy_load_placeholder_pending';var PLACEHOLDER_LOADING_CLASS='pagelib_lazy_load_placeholder_loading';var PLACEHOLDER_ERROR_CLASS='pagelib_lazy_load_placeholder_error';var IMAGE_LOADING_CLASS='pagelib_lazy_load_image_loading';var IMAGE_LOADED_CLASS='pagelib_lazy_load_image_loaded';var COPY_ATTRIBUTES=['class','style','src','srcset','width','height','alt','usemap','data-file-width','data-file-height','data-image-gallery'];var UNIT_TO_MINIMUM_LAZY_LOAD_SIZE={px:50,ex:10,em:5};var convertImageToPlaceholder=function convertImageToPlaceholder(document,image){var placeholder=document.createElement('span');if(image.hasAttribute('class')){placeholder.setAttribute('class',image.getAttribute('class'));}placeholder.classList.add(PLACEHOLDER_CLASS);placeholder.classList.add(PLACEHOLDER_PENDING_CLASS);var geometry=_ElementGeometry2.default.from(image);if(geometry.width){placeholder.style.setProperty('width',''+geometry.width);}_ElementUtilities2.default.copyAttributesToDataAttributes(image,placeholder,COPY_ATTRIBUTES);var spacing=document.createElement('span');if(geometry.width&&geometry.height){var ratio=geometry.heightValue/geometry.widthValue;spacing.style.setProperty('padding-top',ratio*100+'%');}placeholder.appendChild(spacing);image.parentNode.replaceChild(placeholder,image);return placeholder;};var isLazyLoadable=function isLazyLoadable(image){var geometry=_ElementGeometry2.default.from(image);if(!geometry.width||!geometry.height){return true;}return geometry.widthValue>=UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.widthUnit]&&geometry.heightValue>=UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.heightUnit];};var queryLazyLoadableImages=function queryLazyLoadableImages(element){return _Polyfill2.default.querySelectorAll(element,'img').filter(function(image){return isLazyLoadable(image);});};var convertImagesToPlaceholders=function convertImagesToPlaceholders(document,images){return images.map(function(image){return convertImageToPlaceholder(document,image);});};var loadPlaceholder=function loadPlaceholder(document,placeholder){placeholder.classList.add(PLACEHOLDER_LOADING_CLASS);placeholder.classList.remove(PLACEHOLDER_PENDING_CLASS);var image=document.createElement('img');var retryListener=function retryListener(event){image.setAttribute('src',image.getAttribute('src'));event.stopPropagation();event.preventDefault();};image.addEventListener('load',function(){placeholder.removeEventListener('click',retryListener);placeholder.parentNode.replaceChild(image,placeholder);image.classList.add(IMAGE_LOADED_CLASS);image.classList.remove(IMAGE_LOADING_CLASS);},{once:true});image.addEventListener('error',function(){placeholder.classList.add(PLACEHOLDER_ERROR_CLASS);placeholder.classList.remove(PLACEHOLDER_LOADING_CLASS);placeholder.addEventListener('click',retryListener);},{once:true});_ElementUtilities2.default.copyDataAttributesToAttributes(placeholder,image,COPY_ATTRIBUTES);image.classList.add(IMAGE_LOADING_CLASS);return image;};exports.default={queryLazyLoadableImages:queryLazyLoadableImages,convertImagesToPlaceholders:convertImagesToPlaceholders,loadPlaceholder:loadPlaceholder};

/***/ }),
/* 10 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _ThemeTransform=__webpack_require__(11);var _ThemeTransform2=_interopRequireDefault(_ThemeTransform);var _CollapseTable=__webpack_require__(3);var _CollapseTable2=_interopRequireDefault(_CollapseTable);var _CollectionUtilities=__webpack_require__(4);var _CollectionUtilities2=_interopRequireDefault(_CollectionUtilities);var _CompatibilityTransform=__webpack_require__(14);var _CompatibilityTransform2=_interopRequireDefault(_CompatibilityTransform);var _DimImagesTransform=__webpack_require__(15);var _DimImagesTransform2=_interopRequireDefault(_DimImagesTransform);var _EditTransform=__webpack_require__(17);var _EditTransform2=_interopRequireDefault(_EditTransform);var _ElementGeometry=__webpack_require__(5);var _ElementGeometry2=_interopRequireDefault(_ElementGeometry);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);var _LeadIntroductionTransform=__webpack_require__(19);var _LeadIntroductionTransform2=_interopRequireDefault(_LeadIntroductionTransform);var _FooterContainer=__webpack_require__(6);var _FooterContainer2=_interopRequireDefault(_FooterContainer);var _FooterLegal=__webpack_require__(7);var _FooterLegal2=_interopRequireDefault(_FooterLegal);var _FooterMenu=__webpack_require__(22);var _FooterMenu2=_interopRequireDefault(_FooterMenu);var _FooterReadMore=__webpack_require__(8);var _FooterReadMore2=_interopRequireDefault(_FooterReadMore);var _FooterTransformer=__webpack_require__(25);var _FooterTransformer2=_interopRequireDefault(_FooterTransformer);var _LazyLoadTransform=__webpack_require__(9);var _LazyLoadTransform2=_interopRequireDefault(_LazyLoadTransform);var _LazyLoadTransformer=__webpack_require__(27);var _LazyLoadTransformer2=_interopRequireDefault(_LazyLoadTransformer);var _PlatformTransform=__webpack_require__(28);var _PlatformTransform2=_interopRequireDefault(_PlatformTransform);var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);var _RedLinks=__webpack_require__(29);var _RedLinks2=_interopRequireDefault(_RedLinks);var _Throttle=__webpack_require__(2);var _Throttle2=_interopRequireDefault(_Throttle);var _WidenImage=__webpack_require__(30);var _WidenImage2=_interopRequireDefault(_WidenImage);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}exports.default={CollapseTable:_CollapseTable2.default,CollectionUtilities:_CollectionUtilities2.default,CompatibilityTransform:_CompatibilityTransform2.default,DimImagesTransform:_DimImagesTransform2.default,EditTransform:_EditTransform2.default,LeadIntroductionTransform:_LeadIntroductionTransform2.default,FooterContainer:_FooterContainer2.default,FooterLegal:_FooterLegal2.default,FooterMenu:_FooterMenu2.default,FooterReadMore:_FooterReadMore2.default,FooterTransformer:_FooterTransformer2.default,LazyLoadTransform:_LazyLoadTransform2.default,LazyLoadTransformer:_LazyLoadTransformer2.default,PlatformTransform:_PlatformTransform2.default,RedLinks:_RedLinks2.default,ThemeTransform:_ThemeTransform2.default,WidenImage:_WidenImage2.default,test:{ElementGeometry:_ElementGeometry2.default,ElementUtilities:_ElementUtilities2.default,Polyfill:_Polyfill2.default,Throttle:_Throttle2.default}};

/***/ }),
/* 11 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(12);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var CONSTRAINT={IMAGE_PRESUMES_WHITE_BACKGROUND:'pagelib_theme_image_presumes_white_background',DIV_DO_NOT_APPLY_BASELINE:'pagelib_theme_div_do_not_apply_baseline'};var THEME={DEFAULT:'pagelib_theme_default',DARK:'pagelib_theme_dark',SEPIA:'pagelib_theme_sepia',BLACK:'pagelib_theme_black'};var setTheme=function setTheme(document,theme){var html=document.querySelector('html');html.classList.add(theme);for(var key in THEME){if(Object.prototype.hasOwnProperty.call(THEME,key)&&THEME[key]!==theme){html.classList.remove(THEME[key]);}}};var footballTemplateImageFilenameRegex=new RegExp('Kit_(body|socks|shorts|right_arm|left_arm)(.*).png$');var imagePresumesWhiteBackground=function imagePresumesWhiteBackground(image){if(footballTemplateImageFilenameRegex.test(image.src)){return false;}if(image.classList.contains('mwe-math-fallback-image-inline')){return false;}return!_ElementUtilities2.default.closestInlineStyle(image,'background');};var classifyElements=function classifyElements(element){_Polyfill2.default.querySelectorAll(element,'img').filter(imagePresumesWhiteBackground).forEach(function(image){image.classList.add(CONSTRAINT.IMAGE_PRESUMES_WHITE_BACKGROUND);});var selector=['div.color_swatch div','div[style*="position: absolute"]','div.barbox table div[style*="background:"]','div.chart div[style*="background-color"]','div.chart ul li span[style*="background-color"]','span.legend-color','div.mw-highlight span','code.mw-highlight span'].join();_Polyfill2.default.querySelectorAll(element,selector).forEach(function(element){return element.classList.add(CONSTRAINT.DIV_DO_NOT_APPLY_BASELINE);});};exports.default={CONSTRAINT:CONSTRAINT,THEME:THEME,setTheme:setTheme,classifyElements:classifyElements};

/***/ }),
/* 12 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 13 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 14 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var COMPATIBILITY={FILTER:'pagelib_compatibility_filter'};var isStyleSupported=function isStyleSupported(document,properties,value){var element=document.createElement('span');return properties.some(function(property){element.style[property]=value;return element.style.cssText;});};var isFilterSupported=function isFilterSupported(document){return isStyleSupported(document,['webkitFilter','filter'],'blur(0)');};var enableSupport=function enableSupport(document){var html=document.querySelector('html');if(!isFilterSupported(document)){html.classList.add(COMPATIBILITY.FILTER);}};exports.default={COMPATIBILITY:COMPATIBILITY,enableSupport:enableSupport};

/***/ }),
/* 15 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(16);var CLASS='pagelib_dim_images';var dim=function dim(window,enable){window.document.querySelector('html').classList[enable?'add':'remove'](CLASS);};var isDim=function isDim(window){return window.document.querySelector('html').classList.contains(CLASS);};exports.default={CLASS:CLASS,isDim:isDim,dim:dim};

/***/ }),
/* 16 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 17 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(18);var CLASS={SECTION_HEADER:'pagelib_edit_section_header',TITLE:'pagelib_edit_section_title',LINK_CONTAINER:'pagelib_edit_section_link_container',LINK:'pagelib_edit_section_link',PROTECTION:{UNPROTECTED:'',PROTECTED:'page-protected',FORBIDDEN:'no-editing'}};var DATA_ATTRIBUTE={SECTION_INDEX:'data-id',ACTION:'data-action'};var ACTION_EDIT_SECTION='edit_section';var newEditSectionLink=function newEditSectionLink(document,index){var link=document.createElement('a');link.href='';link.setAttribute(DATA_ATTRIBUTE.SECTION_INDEX,index);link.setAttribute(DATA_ATTRIBUTE.ACTION,ACTION_EDIT_SECTION);link.classList.add(CLASS.LINK);return link;};var newEditSectionButton=function newEditSectionButton(document,index){var container=document.createElement('span');container.classList.add(CLASS.LINK_CONTAINER);var link=newEditSectionLink(document,index);container.appendChild(link);return container;};var newEditSectionHeader=function newEditSectionHeader(document,index,level,titleHTML){var element=document.createElement('div');element.className=CLASS.SECTION_HEADER;var title=document.createElement('h'+level);title.innerHTML=titleHTML||'';title.className=CLASS.TITLE;title.setAttribute(DATA_ATTRIBUTE.SECTION_INDEX,index);element.appendChild(title);var button=newEditSectionButton(document,index);element.appendChild(button);return element;};exports.default={CLASS:CLASS,newEditSectionButton:newEditSectionButton,newEditSectionHeader:newEditSectionHeader};

/***/ }),
/* 18 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 19 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var ELEMENT_NODE=1;var isParagraphEligible=function isParagraphEligible(paragraphElement){var coordElement=paragraphElement.querySelector('[id="coordinates"]');var coordTextLength=!coordElement?0:coordElement.textContent.length;var minEligibleTextLength=50;var hasEnoughEligibleText=paragraphElement.textContent.length-coordTextLength>=minEligibleTextLength;return hasEnoughEligibleText;};var extractLeadIntroductionNodes=function extractLeadIntroductionNodes(eligibleParagraph){var introNodes=[];var node=eligibleParagraph;do{introNodes.push(node);node=node.nextSibling;}while(node&&!(node.nodeType===ELEMENT_NODE&&node.tagName==='P'));return introNodes;};var getEligibleParagraph=function getEligibleParagraph(document,containerID){return _Polyfill2.default.querySelectorAll(document,'#'+containerID+' > p').find(isParagraphEligible);};var moveLeadIntroductionUp=function moveLeadIntroductionUp(document,containerID,afterElement){var eligibleParagraph=getEligibleParagraph(document,containerID);if(!eligibleParagraph){return;}var fragment=document.createDocumentFragment();extractLeadIntroductionNodes(eligibleParagraph).forEach(function(element){return fragment.appendChild(element);});var container=document.getElementById(containerID);var insertBeforeThisElement=!afterElement?container.firstChild:afterElement.nextSibling;container.insertBefore(fragment,insertBeforeThisElement);};exports.default={moveLeadIntroductionUp:moveLeadIntroductionUp,test:{isParagraphEligible:isParagraphEligible,extractLeadIntroductionNodes:extractLeadIntroductionNodes,getEligibleParagraph:getEligibleParagraph}};

/***/ }),
/* 20 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 21 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 22 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _createClass=function(){function defineProperties(target,props){for(var i=0;i<props.length;i++){var descriptor=props[i];descriptor.enumerable=descriptor.enumerable||false;descriptor.configurable=true;if("value"in descriptor)descriptor.writable=true;Object.defineProperty(target,descriptor.key,descriptor);}}return function(Constructor,protoProps,staticProps){if(protoProps)defineProperties(Constructor.prototype,protoProps);if(staticProps)defineProperties(Constructor,staticProps);return Constructor;};}();__webpack_require__(23);var _CollectionUtilities=__webpack_require__(4);var _CollectionUtilities2=_interopRequireDefault(_CollectionUtilities);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var MenuItemType={languages:1,lastEdited:2,pageIssues:3,disambiguation:4,coordinate:5,talkPage:6};var MenuItem=function(){function MenuItem(title,subtitle,itemType,clickHandler){_classCallCheck(this,MenuItem);this.title=title;this.subtitle=subtitle;this.itemType=itemType;this.clickHandler=clickHandler;this.payload=[];}_createClass(MenuItem,[{key:'iconClass',value:function iconClass(){switch(this.itemType){case MenuItemType.languages:return'pagelib_footer_menu_icon_languages';case MenuItemType.lastEdited:return'pagelib_footer_menu_icon_last_edited';case MenuItemType.talkPage:return'pagelib_footer_menu_icon_talk_page';case MenuItemType.pageIssues:return'pagelib_footer_menu_icon_page_issues';case MenuItemType.disambiguation:return'pagelib_footer_menu_icon_disambiguation';case MenuItemType.coordinate:return'pagelib_footer_menu_icon_coordinate';default:return'';}}},{key:'payloadExtractor',value:function payloadExtractor(){switch(this.itemType){case MenuItemType.pageIssues:return _CollectionUtilities2.default.collectPageIssuesText;case MenuItemType.disambiguation:return function(_,element){return _CollectionUtilities2.default.collectDisambiguationTitles(element);};default:return undefined;}}}]);return MenuItem;}();var documentFragmentForMenuItem=function documentFragmentForMenuItem(menuItem,document){var item=document.createElement('div');item.className='pagelib_footer_menu_item';var containerAnchor=document.createElement('a');containerAnchor.addEventListener('click',function(){menuItem.clickHandler(menuItem.payload);});item.appendChild(containerAnchor);if(menuItem.title){var title=document.createElement('div');title.className='pagelib_footer_menu_item_title';title.innerText=menuItem.title;containerAnchor.title=menuItem.title;containerAnchor.appendChild(title);}if(menuItem.subtitle){var subtitle=document.createElement('div');subtitle.className='pagelib_footer_menu_item_subtitle';subtitle.innerText=menuItem.subtitle;containerAnchor.appendChild(subtitle);}var iconClass=menuItem.iconClass();if(iconClass){item.classList.add(iconClass);}return document.createDocumentFragment().appendChild(item);};var addItem=function addItem(menuItem,containerID,document){document.getElementById(containerID).appendChild(documentFragmentForMenuItem(menuItem,document));};var maybeAddItem=function maybeAddItem(title,subtitle,itemType,containerID,clickHandler,document){var item=new MenuItem(title,subtitle,itemType,clickHandler);var extractor=item.payloadExtractor();if(extractor){item.payload=extractor(document,document.querySelector('div#content_block_0'));if(item.payload.length===0){return;}}addItem(item,containerID,document);};var setHeading=function setHeading(headingString,headingID,document){var headingElement=document.getElementById(headingID);headingElement.innerText=headingString;headingElement.title=headingString;};exports.default={MenuItemType:MenuItemType,setHeading:setHeading,maybeAddItem:maybeAddItem};

/***/ }),
/* 23 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 24 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 25 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _createClass=function(){function defineProperties(target,props){for(var i=0;i<props.length;i++){var descriptor=props[i];descriptor.enumerable=descriptor.enumerable||false;descriptor.configurable=true;if("value"in descriptor)descriptor.writable=true;Object.defineProperty(target,descriptor.key,descriptor);}}return function(Constructor,protoProps,staticProps){if(protoProps)defineProperties(Constructor.prototype,protoProps);if(staticProps)defineProperties(Constructor,staticProps);return Constructor;};}();var _FooterContainer=__webpack_require__(6);var _FooterContainer2=_interopRequireDefault(_FooterContainer);var _FooterLegal=__webpack_require__(7);var _FooterLegal2=_interopRequireDefault(_FooterLegal);var _FooterReadMore=__webpack_require__(8);var _FooterReadMore2=_interopRequireDefault(_FooterReadMore);var _Throttle=__webpack_require__(2);var _Throttle2=_interopRequireDefault(_Throttle);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var RESIZE_EVENT_TYPE='resize';var RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS=100;var ID_CONTAINER='pagelib_footer_container';var ID_LEGAL_CONTAINER='pagelib_footer_container_legal';var ID_READ_MORE_CONTAINER='pagelib_footer_container_readmore_pages';var ID_READ_MORE_HEADER='pagelib_footer_container_readmore_heading';var _class=function(){function _class(){_classCallCheck(this,_class);this._resizeListener=undefined;}_createClass(_class,[{key:'add',value:function add(window,container,baseURL,title,readMoreHeader,readMoreLimit,license,licenseSubstitutionString,licenseLinkClickHandler,viewInBrowserString,browserLinkClickHandler,titlesShownHandler,saveButtonClickHandler){this.remove(window);container.appendChild(_FooterContainer2.default.containerFragment(window.document));_FooterLegal2.default.add(window.document,license,licenseSubstitutionString,ID_LEGAL_CONTAINER,licenseLinkClickHandler,viewInBrowserString,browserLinkClickHandler);_FooterReadMore2.default.setHeading(readMoreHeader,ID_READ_MORE_HEADER,window.document);_FooterReadMore2.default.add(title,readMoreLimit,ID_READ_MORE_CONTAINER,baseURL,saveButtonClickHandler,function(titles){_FooterContainer2.default.updateBottomPaddingToAllowReadMoreToScrollToTop(window);titlesShownHandler(titles);},window.document);this._resizeListener=_Throttle2.default.wrap(window,RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS,function(){return _FooterContainer2.default.updateBottomPaddingToAllowReadMoreToScrollToTop(window);});window.addEventListener(RESIZE_EVENT_TYPE,this._resizeListener);}},{key:'remove',value:function remove(window){if(this._resizeListener){window.removeEventListener(RESIZE_EVENT_TYPE,this._resizeListener);this._resizeListener.cancel();this._resizeListener=undefined;}var footer=window.document.getElementById(ID_CONTAINER);if(footer){footer.parentNode.removeChild(footer);}}}]);return _class;}();exports.default=_class;

/***/ }),
/* 26 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ }),
/* 27 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _createClass=function(){function defineProperties(target,props){for(var i=0;i<props.length;i++){var descriptor=props[i];descriptor.enumerable=descriptor.enumerable||false;descriptor.configurable=true;if("value"in descriptor)descriptor.writable=true;Object.defineProperty(target,descriptor.key,descriptor);}}return function(Constructor,protoProps,staticProps){if(protoProps)defineProperties(Constructor.prototype,protoProps);if(staticProps)defineProperties(Constructor,staticProps);return Constructor;};}();var _CollapseTable=__webpack_require__(3);var _CollapseTable2=_interopRequireDefault(_CollapseTable);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);var _LazyLoadTransform=__webpack_require__(9);var _LazyLoadTransform2=_interopRequireDefault(_LazyLoadTransform);var _Throttle=__webpack_require__(2);var _Throttle2=_interopRequireDefault(_Throttle);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}function _classCallCheck(instance,Constructor){if(!(instance instanceof Constructor)){throw new TypeError("Cannot call a class as a function");}}var EVENT_TYPES=['scroll','resize',_CollapseTable2.default.SECTION_TOGGLED_EVENT_TYPE];var THROTTLE_PERIOD_MILLISECONDS=100;var _class=function(){function _class(window,loadDistanceMultiplier){var _this=this;_classCallCheck(this,_class);this._window=window;this._loadDistanceMultiplier=loadDistanceMultiplier;this._placeholders=[];this._registered=false;this._throttledLoadPlaceholders=_Throttle2.default.wrap(window,THROTTLE_PERIOD_MILLISECONDS,function(){return _this._loadPlaceholders();});}_createClass(_class,[{key:'convertImagesToPlaceholders',value:function convertImagesToPlaceholders(element){var images=_LazyLoadTransform2.default.queryLazyLoadableImages(element);var placeholders=_LazyLoadTransform2.default.convertImagesToPlaceholders(this._window.document,images);this._placeholders=this._placeholders.concat(placeholders);this._register();}},{key:'loadPlaceholders',value:function loadPlaceholders(){this._throttledLoadPlaceholders();}},{key:'deregister',value:function deregister(){var _this2=this;if(!this._registered){return;}EVENT_TYPES.forEach(function(eventType){return _this2._window.removeEventListener(eventType,_this2._throttledLoadPlaceholders);});this._throttledLoadPlaceholders.reset();this._placeholders=[];this._registered=false;}},{key:'_register',value:function _register(){var _this3=this;if(this._registered||!this._placeholders.length){return;}this._registered=true;EVENT_TYPES.forEach(function(eventType){return _this3._window.addEventListener(eventType,_this3._throttledLoadPlaceholders);});}},{key:'_loadPlaceholders',value:function _loadPlaceholders(){var _this4=this;this._placeholders=this._placeholders.filter(function(placeholder){var pending=true;if(_this4._isPlaceholderEligibleToLoad(placeholder)){_LazyLoadTransform2.default.loadPlaceholder(_this4._window.document,placeholder);pending=false;}return pending;});if(this._placeholders.length===0){this.deregister();}}},{key:'_isPlaceholderEligibleToLoad',value:function _isPlaceholderEligibleToLoad(placeholder){return _ElementUtilities2.default.isVisible(placeholder)&&this._isPlaceholderWithinLoadDistance(placeholder);}},{key:'_isPlaceholderWithinLoadDistance',value:function _isPlaceholderWithinLoadDistance(placeholder){var bounds=placeholder.getBoundingClientRect();var range=this._window.innerHeight*this._loadDistanceMultiplier;return!(bounds.top>range||bounds.bottom<-range);}}]);return _class;}();exports.default=_class;

/***/ }),
/* 28 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var CLASS={ANDROID:'pagelib_platform_android',IOS:'pagelib_platform_ios'};var isAndroid=function isAndroid(window){return /android/i.test(window.navigator.userAgent);};var isIOs=function isIOs(window){return /ipad|iphone|ipod/i.test(window.navigator.userAgent);};var classify=function classify(window){var html=window.document.querySelector('html');if(isAndroid(window)){html.classList.add(CLASS.ANDROID);}if(isIOs(window)){html.classList.add(CLASS.IOS);}};exports.default={CLASS:CLASS,classify:classify};

/***/ }),
/* 29 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});var _Polyfill=__webpack_require__(0);var _Polyfill2=_interopRequireDefault(_Polyfill);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var configureRedLinkTemplate=function configureRedLinkTemplate(span,anchor){span.innerHTML=anchor.innerHTML;span.setAttribute('class',anchor.getAttribute('class'));};var redLinkAnchorsInDocument=function redLinkAnchorsInDocument(content){return _Polyfill2.default.querySelectorAll(content,'a.new');};var newRedLinkTemplate=function newRedLinkTemplate(document){return document.createElement('span');};var replaceAnchorWithSpan=function replaceAnchorWithSpan(anchor,span){return anchor.parentNode.replaceChild(span,anchor);};var hideRedLinks=function hideRedLinks(document){var spanTemplate=newRedLinkTemplate(document);redLinkAnchorsInDocument(document).forEach(function(redLink){var span=spanTemplate.cloneNode(false);configureRedLinkTemplate(span,redLink);replaceAnchorWithSpan(redLink,span);});};exports.default={hideRedLinks:hideRedLinks,test:{configureRedLinkTemplate:configureRedLinkTemplate,redLinkAnchorsInDocument:redLinkAnchorsInDocument,newRedLinkTemplate:newRedLinkTemplate,replaceAnchorWithSpan:replaceAnchorWithSpan}};

/***/ }),
/* 30 */
/***/ (function(module, exports, __webpack_require__) {

"use strict";
Object.defineProperty(exports,"__esModule",{value:true});__webpack_require__(31);var _ElementUtilities=__webpack_require__(1);var _ElementUtilities2=_interopRequireDefault(_ElementUtilities);function _interopRequireDefault(obj){return obj&&obj.__esModule?obj:{default:obj};}var ancestorsToWiden=function ancestorsToWiden(element){var widenThese=[];var el=element;while(el.parentElement){el=el.parentElement;if(el.classList.contains('content_block')){break;}widenThese.push(el);}return widenThese;};var updateStyleValue=function updateStyleValue(style,key,value){style[key]=value;};var updateExistingStyleValue=function updateExistingStyleValue(style,key,value){var valueExists=Boolean(style[key]);if(valueExists){updateStyleValue(style,key,value);}};var styleWideningKeysAndValues={width:'100%',height:'auto',maxWidth:'100%',float:'none'};var widenElementByUpdatingExistingStyles=function widenElementByUpdatingExistingStyles(element){Object.keys(styleWideningKeysAndValues).forEach(function(key){return updateExistingStyleValue(element.style,key,styleWideningKeysAndValues[key]);});};var widenElementByUpdatingStyles=function widenElementByUpdatingStyles(element){Object.keys(styleWideningKeysAndValues).forEach(function(key){return updateStyleValue(element.style,key,styleWideningKeysAndValues[key]);});};var widenAncestors=function widenAncestors(element){ancestorsToWiden(element).forEach(widenElementByUpdatingExistingStyles);var parentAnchor=_ElementUtilities2.default.findClosestAncestor(element,'a.image');if(parentAnchor){widenElementByUpdatingStyles(parentAnchor);}};var shouldWidenImage=function shouldWidenImage(image){if(_ElementUtilities2.default.findClosestAncestor(image,"[class*='noresize']")){return false;}if(_ElementUtilities2.default.findClosestAncestor(image,"div[class*='tsingle']")){return false;}if(image.hasAttribute('usemap')){return false;}if(_ElementUtilities2.default.isNestedInTable(image)){return false;}return true;};var widenImage=function widenImage(image){widenAncestors(image);image.classList.add('pagelib_widen_image_override');};var maybeWidenImage=function maybeWidenImage(image){if(shouldWidenImage(image)){widenImage(image);return true;}return false;};exports.default={maybeWidenImage:maybeWidenImage,test:{ancestorsToWiden:ancestorsToWiden,shouldWidenImage:shouldWidenImage,updateExistingStyleValue:updateExistingStyleValue,widenAncestors:widenAncestors,widenElementByUpdatingExistingStyles:widenElementByUpdatingExistingStyles,widenElementByUpdatingStyles:widenElementByUpdatingStyles}};

/***/ }),
/* 31 */
/***/ (function(module, exports) {

// removed by extract-text-webpack-plugin

/***/ })
/******/ ])["default"];
});

},{}],3:[function(require,module,exports){
const wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.utilities = require('./js/utilities')
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform

window.wmf = wmf
},{"./js/utilities":1,"wikimedia-page-library":2}]},{},[3,1]);
