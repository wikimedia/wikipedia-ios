(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
!function(e,t){"object"==typeof exports&&"object"==typeof module?module.exports=t():"function"==typeof define&&define.amd?define([],t):"object"==typeof exports?exports.pagelib=t():e.pagelib=t()}(this,function(){return function(e){var t={};function n(i){if(t[i])return t[i].exports;var r=t[i]={i:i,l:!1,exports:{}};return e[i].call(r.exports,r,r.exports,n),r.l=!0,r.exports}return n.m=e,n.c=t,n.d=function(e,t,i){n.o(e,t)||Object.defineProperty(e,t,{enumerable:!0,get:i})},n.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},n.t=function(e,t){if(1&t&&(e=n(e)),8&t)return e;if(4&t&&"object"==typeof e&&e&&e.__esModule)return e;var i=Object.create(null);if(n.r(i),Object.defineProperty(i,"default",{enumerable:!0,value:e}),2&t&&"string"!=typeof e)for(var r in e)n.d(i,r,function(t){return e[t]}.bind(null,r));return i},n.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return n.d(t,"a",t),t},n.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},n.p="",n(n.s=11)}([function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i="undefined"!=typeof window&&window.CustomEvent||function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{bubbles:!1,cancelable:!1,detail:void 0},n=document.createEvent("CustomEvent");return n.initCustomEvent(e,t.bubbles,t.cancelable,t.detail),n};t.default={matchesSelector:function(e,t){return e.matches?e.matches(t):e.matchesSelector?e.matchesSelector(t):!!e.webkitMatchesSelector&&e.webkitMatchesSelector(t)},querySelectorAll:function(e,t){return Array.prototype.slice.call(e.querySelectorAll(t))},CustomEvent:i}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,r=n(0),a=(i=r)&&i.__esModule?i:{default:i};var o=function(e,t){var n=void 0;for(n=e.parentElement;n&&!a.default.matchesSelector(n,t);n=n.parentElement);return n};t.default={findClosestAncestor:o,isNestedInTable:function(e){return Boolean(o(e,"table"))},closestInlineStyle:function(e,t,n){for(var i=e;i;i=i.parentElement){var r=i.style[t];if(r){if(void 0===n)return i;if(n===r)return i}}},isVisible:function(e){return Boolean(e.offsetWidth||e.offsetHeight||e.getClientRects().length)},copyAttributesToDataAttributes:function(e,t,n){n.filter(function(t){return e.hasAttribute(t)}).forEach(function(n){return t.setAttribute("data-"+n,e.getAttribute(n))})},copyDataAttributesToAttributes:function(e,t,n){n.filter(function(t){return e.hasAttribute("data-"+t)}).forEach(function(n){return t.setAttribute(n,e.getAttribute("data-"+n))})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();var r=function(){function e(t,n,i){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._window=t,this._period=n,this._function=i,this._context=void 0,this._arguments=void 0,this._result=void 0,this._timeout=0,this._timestamp=0}return i(e,null,[{key:"wrap",value:function(t,n,i){var r=new e(t,n,i),a=function(){return r.queue(this,arguments)};return a.result=function(){return r.result},a.pending=function(){return r.pending()},a.delay=function(){return r.delay()},a.cancel=function(){return r.cancel()},a.reset=function(){return r.reset()},a}}]),i(e,[{key:"queue",value:function(e,t){var n=this;return this._context=e,this._arguments=t,this.pending()||(this._timeout=this._window.setTimeout(function(){n._timeout=0,n._timestamp=Date.now(),n._result=n._function.apply(n._context,n._arguments)},this.delay())),this.result}},{key:"pending",value:function(){return Boolean(this._timeout)}},{key:"delay",value:function(){return this._timestamp?Math.max(0,this._period-(Date.now()-this._timestamp)):0}},{key:"cancel",value:function(){this._timeout&&this._window.clearTimeout(this._timeout),this._timeout=0}},{key:"reset",value:function(){this.cancel(),this._result=void 0,this._timestamp=0}},{key:"result",get:function(){return this._result}}]),e}();t.default=r},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(15);var i=o(n(1)),r=o(n(4)),a=o(n(0));function o(e){return e&&e.__esModule?e:{default:e}}var l=r.default.NODE_TYPE,u="pagelib_collapse_table_icon",c="pagelib_collapse_table_container",s="pagelib_collapse_table_collapsed_container",d="pagelib_collapse_table_collapsed",f="pagelib_collapse_table_collapsed_bottom",p="pagelib_collapse_table_collapse_text",_="pagelib_collapse_table_expanded",h=function(e){return e.childNodes&&a.default.querySelectorAll(e,"a").length<3},g=function(e){return e&&e.replace(/[\s0-9]/g,"").length>0},m=function(e){var t=e.match(/\w+/);if(t)return t[0]},v=function(e,t){var n=m(t),i=m(e.textContent);return!(!n||!i)&&n.toLowerCase()===i.toLowerCase()},b=function(e){return e.trim().replace(/\s/g," ")},y=function(e){return e.nodeType===l.ELEMENT_NODE&&"BR"===e.tagName},E=function(e,t){t.parentNode.replaceChild(e.createTextNode(" "),t)},T=function(e,t,n){if(!h(t))return null;var i=e.createDocumentFragment();i.appendChild(t.cloneNode(!0));var o=i.querySelector("th");a.default.querySelectorAll(o,".geo, .coordinates, sup.reference, ol, ul").forEach(function(e){return e.remove()});var l=Array.prototype.slice.call(o.childNodes);n&&l.filter(r.default.isNodeTypeElementOrText).filter(function(e){return v(e,n)}).forEach(function(e){return e.remove()}),l.filter(y).forEach(function(t){return E(e,t)});var u=o.textContent;return g(u)?b(u):null},L=function(e,t){var n=e.hasAttribute("scope"),i=t.hasAttribute("scope");return n&&i?0:n?-1:i?1:0},C=function(e,t,n){var i=[],r=a.default.querySelectorAll(t,"th");r.sort(L);for(var o=0;o<r.length;++o){var l=T(e,r[o],n);if(l&&-1===i.indexOf(l)&&(i.push(l),2===i.length))break}return i},w=function(e,t,n){var i=e.children[0],r=e.children[1],a=e.children[2],o=i.querySelector(".app_table_collapsed_caption"),l="none"!==r.style.display;return l?(r.style.display="none",i.classList.remove(d),i.classList.remove(u),i.classList.add(_),o&&(o.style.visibility="visible"),a.style.display="none",t===a&&n&&n(e)):(r.style.display="block",i.classList.remove(_),i.classList.add(d),i.classList.add(u),o&&(o.style.visibility="hidden"),a.style.display="block"),l},x=function(e){var t=this.parentNode;return w(t,this,e)},S=function(e){var t=["navbox","vertical-navbox","navbox-inner","metadata","mbox-small"].some(function(t){return e.classList.contains(t)});return"none"!==e.style.display&&!t},A=function(e){return e.classList.contains("infobox")||e.classList.contains("infobox_v3")},N=function(e,t){var n=e.createElement("div");return n.classList.add(s),n.classList.add(_),n.appendChild(t),n},k=function(e,t){var n=e.createElement("div");return n.classList.add(f),n.classList.add(u),n.innerHTML=t||"",n},P=function(e,t,n){var i=e.createDocumentFragment(),r=e.createElement("strong");r.innerHTML=t,i.appendChild(r);var a=e.createElement("span");return a.classList.add(p),n.length>0&&a.appendChild(e.createTextNode(": "+n[0])),n.length>1&&a.appendChild(e.createTextNode(", "+n[1])),n.length>0&&a.appendChild(e.createTextNode(" …")),i.appendChild(a),i},O=function(e,t,n,r,a){for(var o=e.querySelectorAll("table, .infobox_v3"),l=0;l<o.length;++l){var u=o[l];if(!i.default.findClosestAncestor(u,"."+c)&&S(u)){var s=C(e,u,t);if(s.length||A(u)){var d=P(e,A(u)?n:r,s),f=e.createElement("div");f.className=c,u.parentNode.insertBefore(f,u),u.parentNode.removeChild(u),u.style.marginTop="0px",u.style.marginBottom="0px";var p=N(e,d);p.style.display="block";var _=k(e,a);_.style.display="none",f.appendChild(p),f.appendChild(u),f.appendChild(_),u.style.display="none"}}}},M=function(e,t,n,i){var r=function(t){return e.dispatchEvent(new a.default.CustomEvent("section-toggled",{collapsed:t}))};(a.default.querySelectorAll(t,"."+s).forEach(function(e){e.onclick=function(){var t=x.bind(e)();r(t)}}),a.default.querySelectorAll(t,"."+f).forEach(function(e){e.onclick=function(){var t=x.bind(e,i)();r(t)}}),n)||a.default.querySelectorAll(t,"."+c).forEach(function(e){w(e)})},I=function(e,t,n,i,r,a,o,l,u){i||(O(t,n,a,o,l),M(e,t,r,u))};t.default={SECTION_TOGGLED_EVENT_TYPE:"section-toggled",toggleCollapseClickCallback:x,collapseTables:function(e,t,n,i,r,a,o,l){I(e,t,n,i,!0,r,a,o,l)},adjustTables:I,prepareTables:O,setupEventHandling:M,expandCollapsedTableIfItContainsElement:function(e){if(e){var t='[class*="'+c+'"]',n=i.default.findClosestAncestor(e,t);if(n){var r=n.firstElementChild;r&&r.classList.contains(_)&&r.click()}}},test:{elementScopeComparator:L,extractEligibleHeaderText:T,firstWordFromString:m,getTableHeaderTextArray:C,shouldTableBeCollapsed:S,isHeaderEligible:h,isHeaderTextEligible:g,isInfobox:A,newCollapsedHeaderDiv:N,newCollapsedFooterDiv:k,newCaptionFragment:P,isNodeTextContentSimilarToPageTitle:v,stringWithNormalizedWhitespace:b,replaceNodeWithBreakingSpaceTextNode:E}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i={ELEMENT_NODE:1,TEXT_NODE:3};t.default={isNodeTypeElementOrText:function(e){return e.nodeType===i.ELEMENT_NODE||e.nodeType===i.TEXT_NODE},NODE_TYPE:i}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,r=n(0),a=(i=r)&&i.__esModule?i:{default:i};var o=function(e,t){if(!t)return[];var n=a.default.querySelectorAll(t,"table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)"),i=e.createDocumentFragment();return n.forEach(function(e){return i.appendChild(e.cloneNode(!0))}),a.default.querySelectorAll(i,".hide-when-compact, .collapsed").forEach(function(e){return e.remove()}),a.default.querySelectorAll(i,"td[class*=mbox-text] > *[class*=mbox-text]")};t.default={collectDisambiguationTitles:function(e){return e?a.default.querySelectorAll(e,'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function(e){return e.href}):[]},collectDisambiguationHTML:function(e){return e?a.default.querySelectorAll(e,"div.hatnote").map(function(e){return e.innerHTML}):[]},collectPageIssuesHTML:function(e,t){return o(e,t).map(function(e){return e.innerHTML})},collectPageIssuesText:function(e,t){return o(e,t).map(function(e){return e.textContent.trim()})},test:{collectPageIssues:o}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();function r(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}var a=function(){function e(t,n){r(this,e),this._value=Number(t),this._unit=n||"px"}return i(e,null,[{key:"fromElement",value:function(t,n){return t.style.getPropertyValue(n)&&e.fromStyle(t.style.getPropertyValue(n))||t.hasAttribute(n)&&new e(t.getAttribute(n))||void 0}},{key:"fromStyle",value:function(t){var n=t.match(/(-?\d*\.?\d*)(\D+)?/)||[];return new e(n[1],n[2])}}]),i(e,[{key:"toString",value:function(){return isNaN(this.value)?"":""+this.value+this.unit}},{key:"value",get:function(){return this._value}},{key:"unit",get:function(){return this._unit}}]),e}(),o=function(){function e(t,n){r(this,e),this._width=t,this._height=n}return i(e,null,[{key:"from",value:function(t){return new e(a.fromElement(t,"width"),a.fromElement(t,"height"))}}]),i(e,[{key:"width",get:function(){return this._width}},{key:"widthValue",get:function(){return this._width&&!isNaN(this._width.value)?this._width.value:NaN}},{key:"widthUnit",get:function(){return this._width&&this._width.unit||"px"}},{key:"height",get:function(){return this._height}},{key:"heightValue",get:function(){return this._height&&!isNaN(this._height.value)?this._height.value:NaN}},{key:"heightUnit",get:function(){return this._height&&this._height.unit||"px"}}]),e}();t.default=o},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(22);var i,r=n(0),a=(i=r)&&i.__esModule?i:{default:i};t.default={containerFragment:function(e){var t=e.createElement("div"),n=e.createDocumentFragment();return n.appendChild(t),t.innerHTML="<div id='pagelib_footer_container' class='pagelib_footer_container'>\n    <div id='pagelib_footer_container_section_0'>\n      <div id='pagelib_footer_container_menu'>\n        <div id='pagelib_footer_container_menu_heading' class='pagelib_footer_container_heading'>\n        </div>\n        <div id='pagelib_footer_container_menu_items'>\n        </div>\n      </div>\n    </div>\n    <div id='pagelib_footer_container_ensure_can_scroll_to_top'>\n      <div id='pagelib_footer_container_section_1'>\n        <div id='pagelib_footer_container_readmore'>\n          <div\n            id='pagelib_footer_container_readmore_heading' class='pagelib_footer_container_heading'>\n          </div>\n          <div id='pagelib_footer_container_readmore_pages'>\n          </div>\n        </div>\n      </div>\n      <div id='pagelib_footer_container_legal'></div>\n    </div>\n  </div>",n},isContainerAttached:function(e){return Boolean(e.querySelector("#pagelib_footer_container"))},updateBottomPaddingToAllowReadMoreToScrollToTop:function(e){var t=e.document.getElementById("pagelib_footer_container_ensure_can_scroll_to_top"),n=parseInt(t.style.paddingBottom,10)||0,i=t.clientHeight-n,r=Math.max(0,e.innerHeight-i);t.style.paddingBottom=r+"px"},updateLeftAndRightMargin:function(e,t){a.default.querySelectorAll(t,["#pagelib_footer_container_menu_heading","#pagelib_footer_container_readmore","#pagelib_footer_container_legal"].join()).forEach(function(t){t.style.marginLeft=e+"px",t.style.marginRight=e+"px"});var n="rtl"===t.querySelector("html").dir?"right":"left";a.default.querySelectorAll(t,".pagelib_footer_menu_item").forEach(function(t){t.style.backgroundPosition=n+" "+e+"px center",t.style.paddingLeft=e+"px",t.style.paddingRight=e+"px"})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(23);t.default={add:function(e,t,n,i,r,a,o){var l=e.querySelector("#"+i),u=t.split("$1");l.innerHTML="<div class='pagelib_footer_legal_contents'>\n    <hr class='pagelib_footer_legal_divider'>\n    <span class='pagelib_footer_legal_license'>\n      "+u[0]+"\n      <a class='pagelib_footer_legal_license_link'>\n        "+n+"\n      </a>\n      "+u[1]+"\n      <br>\n      <div class=\"pagelib_footer_browser\">\n        <a class='pagelib_footer_browser_link'>\n          "+a+"\n        </a>\n      </div>\n    </span>\n  </div>",l.querySelector(".pagelib_footer_legal_license_link").addEventListener("click",function(){r()}),l.querySelector(".pagelib_footer_browser_link").addEventListener("click",function(){o()})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(26);var i=function(e,t,n){var i=new RegExp("\\s?["+t+"][^"+t+n+"]+["+n+"]","g"),r=0,a=e,o="";do{o=a,a=a.replace(i,""),r++}while(o!==a&&r<30);return a},r=function(e){var t=e;return t=i(t,"(",")"),t=i(t,"/","/")},a=function e(t,n,i,r,a){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this.title=t,this.displayTitle=n,this.thumbnail=i,this.description=r,this.extract=a},o=function(e,t,n,i,o){var l=[],u=o.getElementById(t);e.forEach(function(e,t){var i=e.title.replace(/ /g,"_");l.push(i);var c=function(e,t,n,i){var a=i.createElement("a");if(a.id=t,a.className="pagelib_footer_readmore_page",e.thumbnail&&e.thumbnail.source){var o=i.createElement("div");o.style.backgroundImage="url("+e.thumbnail.source+")",o.classList.add("pagelib_footer_readmore_page_image"),a.appendChild(o)}var l=i.createElement("div");l.classList.add("pagelib_footer_readmore_page_container"),a.appendChild(l),a.href="/wiki/"+encodeURI(e.title)+"?event_logging_label=read_more";var u=void 0;if(e.displayTitle?u=e.displayTitle:e.title&&(u=e.title),u){var c=i.createElement("div");c.id=t,c.className="pagelib_footer_readmore_page_title",c.innerHTML=u.replace(/_/g," "),a.title=e.title.replace(/_/g," "),l.appendChild(c)}var s=void 0;if(e.description&&(s=e.description),(!s||s.length<10)&&e.extract&&(s=r(e.extract)),s){var d=i.createElement("div");d.id=t,d.className="pagelib_footer_readmore_page_description",d.innerHTML=s,l.appendChild(d)}var f=i.createElement("div");return f.id="pagelib_footer_read_more_save_"+encodeURI(e.title),f.className="pagelib_footer_readmore_page_save",f.addEventListener("click",function(t){t.stopPropagation(),t.preventDefault(),n(e.title)}),l.appendChild(f),i.createDocumentFragment().appendChild(a)}(new a(i,e.pageprops.displaytitle,e.thumbnail,e.description,e.extract),t,n,o);u.appendChild(c)}),i(l)},l=function(e,t,n){return(n||"")+"/w/api.php?"+(i=function(e,t){return{action:"query",format:"json",formatversion:2,prop:"extracts|pageimages|description|pageprops",generator:"search",gsrlimit:t,gsrprop:"redirecttitle",gsrsearch:"morelike:"+e,gsrwhat:"text",exchars:256,exintro:"",exlimit:t,explaintext:"",pilicense:"any",pilimit:t,piprop:"thumbnail",pithumbsize:120}}(e,t),Object.keys(i).map(function(e){return encodeURIComponent(e)+"="+encodeURIComponent(i[e])}).join("&"));var i},u=function(e){console.log("statusText = "+e)};t.default={add:function(e,t,n,i,r,a,c){!function(e,t,n,i,r,a,o,c){var s=new XMLHttpRequest;s.open("GET",l(e,t,i),!0),s.onload=function(){s.readyState===XMLHttpRequest.DONE&&(200===s.status?r(JSON.parse(s.responseText).query.pages,n,a,o,c):u(s.statusText))},s.onerror=function(){return u(s.statusText)};try{s.send()}catch(e){u(e.toString())}}(e,t,n,i,o,r,a,c)},setHeading:function(e,t,n){var i=n.getElementById(t);i.innerText=e,i.title=e},updateSaveButtonForTitle:function(e,t,n,i){var r=i.getElementById("pagelib_footer_read_more_save_"+encodeURI(e));r&&(r.innerText=t,r.title=t,function(e,t){var n="pagelib_footer_readmore_bookmark_unfilled",i="pagelib_footer_readmore_bookmark_filled";e.classList.remove(i,n),e.classList.add(t?i:n)}(r,n))},test:{cleanExtract:r,safelyRemoveEnclosures:i}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(28);var i=n(6).default,r=n(1).default,a=n(0).default,o=["class","style","src","srcset","width","height","alt","usemap","data-file-width","data-file-height","data-image-gallery"],l={px:50,ex:10,em:5};t.default={PLACEHOLDER_CLASS:"pagelib_lazy_load_placeholder",queryLazyLoadableImages:function(e){return a.querySelectorAll(e,"img").filter(function(e){return function(e){var t=i.from(e);if(!t.width||!t.height)return!0;var n=l[t.widthUnit]||1/0,r=l[t.heightUnit]||1/0;return t.widthValue>=n&&t.heightValue>=r}(e)})},convertImagesToPlaceholders:function(e,t){return t.map(function(t){return function(e,t){var n=e.createElement("span");t.hasAttribute("class")&&n.setAttribute("class",t.getAttribute("class")||""),n.classList.add("pagelib_lazy_load_placeholder"),n.classList.add("pagelib_lazy_load_placeholder_pending");var a=i.from(t);a.width&&n.style.setProperty("width",""+a.width),r.copyAttributesToDataAttributes(t,n,o);var l=e.createElement("span");if(a.width&&a.height){var u=a.heightValue/a.widthValue;l.style.setProperty("padding-top",100*u+"%")}return n.appendChild(l),t.parentNode&&t.parentNode.replaceChild(n,t),n}(e,t)})},loadPlaceholder:function(e,t){t.classList.add("pagelib_lazy_load_placeholder_loading"),t.classList.remove("pagelib_lazy_load_placeholder_pending");var n=e.createElement("img"),i=function(e){n.setAttribute("src",n.getAttribute("src")||""),e.stopPropagation(),e.preventDefault()};return n.addEventListener("load",function(){t.removeEventListener("click",i),t.parentNode&&t.parentNode.replaceChild(n,t),n.classList.add("pagelib_lazy_load_image_loaded"),n.classList.remove("pagelib_lazy_load_image_loading")},{once:!0}),n.addEventListener("error",function(){t.classList.add("pagelib_lazy_load_placeholder_error"),t.classList.remove("pagelib_lazy_load_placeholder_loading"),t.addEventListener("click",i)},{once:!0}),r.copyDataAttributesToAttributes(t,n,o),n.classList.add("pagelib_lazy_load_image_loading"),n}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=x(n(12)),r=x(n(14)),a=x(n(3)),o=x(n(5)),l=x(n(16)),u=x(n(17)),c=x(n(19)),s=x(n(6)),d=x(n(1)),f=x(n(21)),p=x(n(7)),_=x(n(8)),h=x(n(24)),g=x(n(9)),m=x(n(27)),v=x(n(10)),b=x(n(29)),y=x(n(30)),E=x(n(0)),T=x(n(31)),L=x(n(32)),C=x(n(2)),w=x(n(33));function x(e){return e&&e.__esModule?e:{default:e}}n(35),t.default={BodySpacingTransform:r.default,CollapseTable:a.default,CollectionUtilities:o.default,CompatibilityTransform:l.default,DimImagesTransform:u.default,EditTransform:c.default,LeadIntroductionTransform:f.default,FooterContainer:p.default,FooterLegal:_.default,FooterMenu:h.default,FooterReadMore:g.default,FooterTransformer:m.default,LazyLoadTransform:v.default,LazyLoadTransformer:b.default,PlatformTransform:y.default,RedLinks:T.default,ReferenceCollection:L.default,ThemeTransform:i.default,WidenImage:w.default,test:{ElementGeometry:s.default,ElementUtilities:d.default,Polyfill:E.default,Throttle:C.default}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(13);var i=a(n(1)),r=a(n(0));function a(e){return e&&e.__esModule?e:{default:e}}var o={IMAGE_PRESUMES_WHITE_BACKGROUND:"pagelib_theme_image_presumes_white_background",DIV_DO_NOT_APPLY_BASELINE:"pagelib_theme_div_do_not_apply_baseline"},l={DEFAULT:"pagelib_theme_default",DARK:"pagelib_theme_dark",SEPIA:"pagelib_theme_sepia",BLACK:"pagelib_theme_black"},u=new RegExp("Kit_(body|socks|shorts|right_arm|left_arm)(.*).png$"),c=function(e){return!u.test(e.src)&&(!e.classList.contains("mwe-math-fallback-image-inline")&&!i.default.closestInlineStyle(e,"background"))};t.default={CONSTRAINT:o,THEME:l,setTheme:function(e,t){var n=e.querySelector("html");for(var i in n.classList.add(t),l)Object.prototype.hasOwnProperty.call(l,i)&&l[i]!==t&&n.classList.remove(l[i])},classifyElements:function(e){r.default.querySelectorAll(e,"img").filter(c).forEach(function(e){e.classList.add(o.IMAGE_PRESUMES_WHITE_BACKGROUND)});var t=["div.color_swatch div",'div[style*="position: absolute"]','div.barbox table div[style*="background:"]','div.chart div[style*="background-color"]','div.chart ul li span[style*="background-color"]',"span.legend-color","div.mw-highlight span","code.mw-highlight span",".BrickChartTemplate div",".PieChartTemplate div",".BarChartTemplate div",".StackedBarTemplate td",".chess-board div"].join();r.default.querySelectorAll(e,t).forEach(function(e){return e.classList.add(o.DIV_DO_NOT_APPLY_BASELINE)})}}},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});t.default={setMargins:function(e,t,n){void 0!==t.top&&(e.style.marginTop=t.top),void 0!==t.right&&(e.style.marginRight=t.right),void 0!==t.bottom&&(e.style.marginBottom=t.bottom),void 0!==t.left&&(e.style.marginLeft=t.left),n&&n()},setPadding:function(e,t,n){void 0!==t.top&&(e.style.paddingTop=t.top),void 0!==t.right&&(e.style.paddingRight=t.right),void 0!==t.bottom&&(e.style.paddingBottom=t.bottom),void 0!==t.left&&(e.style.paddingLeft=t.left),n&&n()}}},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i={FILTER:"pagelib_compatibility_filter"};t.default={COMPATIBILITY:i,enableSupport:function(e){var t=e.querySelector("html");(function(e){return function(e,t,n){var i=e.createElement("span");return t.some(function(e){return i.style[e]=n,i.style.cssText})}(e,["webkitFilter","filter"],"blur(0)")})(e)||t.classList.add(i.FILTER)}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(18);var i="pagelib_dim_images";t.default={CLASS:i,isDim:function(e){return e.document.querySelector("html").classList.contains(i)},dim:function(e,t){e.document.querySelector("html").classList[t?"add":"remove"](i)}}},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(20);var i={SECTION_HEADER:"pagelib_edit_section_header",TITLE:"pagelib_edit_section_title",LINK_CONTAINER:"pagelib_edit_section_link_container",LINK:"pagelib_edit_section_link",PROTECTION:{UNPROTECTED:"",PROTECTED:"page-protected",FORBIDDEN:"no-editing"}},r="pagelib_edit_section_title_description",a="pagelib_edit_section_add_title_description",o="pagelib_edit_section_divider",l="pagelib_edit_section_title_pronunciation",u="data-id",c="data-action",s=function(e,t){var n=e.createElement("span");n.classList.add(i.LINK_CONTAINER);var r=function(e,t){var n=e.createElement("a");return n.href="",n.setAttribute(u,t),n.setAttribute(c,"edit_section"),n.classList.add(i.LINK),n}(e,t);return n.appendChild(r),n},d=function(e,t,n,r){var a=!(arguments.length>4&&void 0!==arguments[4])||arguments[4],o=e.createElement("div");o.className=i.SECTION_HEADER;var l=e.createElement("h"+n);if(l.innerHTML=r||"",l.className=i.TITLE,l.setAttribute(u,t),o.appendChild(l),a){var c=s(e,t);o.appendChild(c)}return o};t.default={CLASS:i,newEditSectionButton:s,newEditSectionHeader:d,newEditLeadSectionHeader:function(e,t,n,i,u){var s=!(arguments.length>5&&void 0!==arguments[5])||arguments[5],f=arguments.length>6&&void 0!==arguments[6]&&arguments[6],p=e.createDocumentFragment(),_=d(e,0,1,t,s);if(f){var h=e.createElement("a");h.setAttribute(c,"title_pronunciation"),h.id=l,_.querySelector("h1").appendChild(h)}p.appendChild(_);var g=function(e,t,n,i){if(void 0!==t&&t.length>0){var o=e.createElement("p");return o.id=r,o.innerHTML=t,o}if(i){var l=e.createElement("a");l.href="#",l.setAttribute(c,"add_title_description");var u=e.createElement("p");return u.id=a,u.innerHTML=n,l.appendChild(u),l}return null}(e,n,i,u);g&&p.appendChild(g);var m=e.createElement("hr");return m.id=o,p.appendChild(m),p}}},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,r=n(0),a=(i=r)&&i.__esModule?i:{default:i};var o=function(e){var t=e.querySelector('[id="coordinates"]'),n=t?t.textContent.length:0;return e.textContent.length-n>=50},l=function(e){var t=[],n=e;do{t.push(n),n=n.nextSibling}while(n&&(1!==n.nodeType||"P"!==n.tagName));return t},u=function(e,t){return a.default.querySelectorAll(e,"#"+t+" > p").find(o)};t.default={moveLeadIntroductionUp:function(e,t,n){var i=u(e,t);if(i){var r=e.createDocumentFragment();l(i).forEach(function(e){return r.appendChild(e)});var a=e.getElementById(t),o=n?n.nextSibling:a.firstChild;a.insertBefore(r,o)}},test:{isParagraphEligible:o,extractLeadIntroductionNodes:l,getEligibleParagraph:u}}},function(e,t,n){},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();n(25);var r,a=n(5),o=(r=a)&&r.__esModule?r:{default:r};var l={languages:1,lastEdited:2,pageIssues:3,disambiguation:4,coordinate:5,talkPage:6},u=function(){function e(t,n,i,r){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this.title=t,this.subtitle=n,this.itemType=i,this.clickHandler=r,this.payload=[]}return i(e,[{key:"iconClass",value:function(){switch(this.itemType){case l.languages:return"pagelib_footer_menu_icon_languages";case l.lastEdited:return"pagelib_footer_menu_icon_last_edited";case l.talkPage:return"pagelib_footer_menu_icon_talk_page";case l.pageIssues:return"pagelib_footer_menu_icon_page_issues";case l.disambiguation:return"pagelib_footer_menu_icon_disambiguation";case l.coordinate:return"pagelib_footer_menu_icon_coordinate";default:return""}}},{key:"payloadExtractor",value:function(){switch(this.itemType){case l.pageIssues:return o.default.collectPageIssuesText;case l.disambiguation:return function(e,t){return o.default.collectDisambiguationTitles(t)};default:return}}}]),e}();t.default={MenuItemType:l,setHeading:function(e,t,n){var i=n.getElementById(t);i.innerText=e,i.title=e},maybeAddItem:function(e,t,n,i,r,a){var o=new u(e,t,n,r),l=o.payloadExtractor();l&&(o.payload=l(a,a.querySelector("div#content_block_0")),0===o.payload.length)||function(e,t,n){n.getElementById(t).appendChild(function(e,t){var n=t.createElement("div");n.className="pagelib_footer_menu_item";var i=t.createElement("a");if(i.addEventListener("click",function(){e.clickHandler(e.payload)}),n.appendChild(i),e.title){var r=t.createElement("div");r.className="pagelib_footer_menu_item_title",r.innerText=e.title,i.title=e.title,i.appendChild(r)}if(e.subtitle){var a=t.createElement("div");a.className="pagelib_footer_menu_item_subtitle",a.innerText=e.subtitle,i.appendChild(a)}var o=e.iconClass();return o&&n.classList.add(o),t.createDocumentFragment().appendChild(n)}(e,n))}(o,i,a)}}},function(e,t,n){},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}(),r=u(n(7)),a=u(n(8)),o=u(n(9)),l=u(n(2));function u(e){return e&&e.__esModule?e:{default:e}}var c=function(){function e(){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._resizeListener=void 0}return i(e,[{key:"add",value:function(e,t,n,i,u,c,s,d,f,p,_,h,g){this.remove(e),t.appendChild(r.default.containerFragment(e.document)),a.default.add(e.document,s,d,"pagelib_footer_container_legal",f,p,_),o.default.setHeading(u,"pagelib_footer_container_readmore_heading",e.document),o.default.add(i,c,"pagelib_footer_container_readmore_pages",n,g,function(t){r.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e),h(t)},e.document),this._resizeListener=l.default.wrap(e,100,function(){return r.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e)}),e.addEventListener("resize",this._resizeListener)}},{key:"remove",value:function(e){this._resizeListener&&(e.removeEventListener("resize",this._resizeListener),this._resizeListener.cancel(),this._resizeListener=void 0);var t=e.document.getElementById("pagelib_footer_container");t&&t.parentNode.removeChild(t)}}]),e}();t.default=c},function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}(),r=u(n(3)),a=u(n(1)),o=u(n(10)),l=u(n(2));function u(e){return e&&e.__esModule?e:{default:e}}var c=["scroll","resize",r.default.SECTION_TOGGLED_EVENT_TYPE],s=100,d=function(){function e(t,n){var i=this;!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._window=t,this._loadDistanceMultiplier=n,this._placeholders=[],this._registered=!1,this._throttledLoadPlaceholders=l.default.wrap(t,s,function(){return i._loadPlaceholders()})}return i(e,[{key:"convertImagesToPlaceholders",value:function(e){var t=o.default.queryLazyLoadableImages(e),n=o.default.convertImagesToPlaceholders(this._window.document,t);this._placeholders=this._placeholders.concat(n),this._register()}},{key:"collectExistingPlaceholders",value:function(e){var t=Array.from(e.querySelectorAll("."+o.default.PLACEHOLDER_CLASS));this._placeholders=this._placeholders.concat(t),this._register()}},{key:"loadPlaceholders",value:function(){this._throttledLoadPlaceholders()}},{key:"deregister",value:function(){var e=this;this._registered&&(c.forEach(function(t){return e._window.removeEventListener(t,e._throttledLoadPlaceholders)}),this._throttledLoadPlaceholders.reset(),this._placeholders=[],this._registered=!1)}},{key:"_register",value:function(){var e=this;!this._registered&&this._placeholders.length&&(this._registered=!0,c.forEach(function(t){return e._window.addEventListener(t,e._throttledLoadPlaceholders)}))}},{key:"_loadPlaceholders",value:function(){var e=this;this._placeholders=this._placeholders.filter(function(t){var n=!0;return e._isPlaceholderEligibleToLoad(t)&&(o.default.loadPlaceholder(e._window.document,t),n=!1),n}),0===this._placeholders.length&&this.deregister()}},{key:"_isPlaceholderEligibleToLoad",value:function(e){return a.default.isVisible(e)&&this._isPlaceholderWithinLoadDistance(e)}},{key:"_isPlaceholderWithinLoadDistance",value:function(e){var t=e.getBoundingClientRect(),n=this._window.innerHeight*this._loadDistanceMultiplier;return!(t.top>n||t.bottom<-n)}}]),e}();t.default=d},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i={ANDROID:"pagelib_platform_android",IOS:"pagelib_platform_ios"};t.default={CLASS:i,classify:function(e){var t=e.document.querySelector("html");(function(e){return/android/i.test(e.navigator.userAgent)})(e)&&t.classList.add(i.ANDROID),function(e){return/ipad|iphone|ipod/i.test(e.navigator.userAgent)}(e)&&t.classList.add(i.IOS)}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,r=n(0),a=(i=r)&&i.__esModule?i:{default:i};var o=function(e,t){e.innerHTML=t.innerHTML,e.setAttribute("class",t.getAttribute("class"))},l=function(e){return a.default.querySelectorAll(e,"a.new")},u=function(e){return e.createElement("span")},c=function(e,t){return e.parentNode.replaceChild(t,e)};t.default={hideRedLinks:function(e){var t=u(e);l(e).forEach(function(e){var n=t.cloneNode(!1);o(n,e),c(e,n)})},test:{configureRedLinkTemplate:o,redLinkAnchorsInDocument:l,newRedLinkTemplate:u,replaceAnchorWithSpan:c}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=o(n(1)),r=o(n(4)),a=o(n(0));function o(e){return e&&e.__esModule?e:{default:e}}function l(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}var u=function(e){return e.indexOf("#cite_note")>-1},c=function(e){return Boolean(e)&&e.nodeType===Node.TEXT_NODE&&Boolean(e.textContent.match(/^\s+$/))},s=function(e){var t=e.querySelector("a");return t&&u(t.hash)},d=function(e,t){var n=t.querySelector("A").getAttribute("href").slice(1);return e.getElementById(n)||e.getElementById(decodeURIComponent(n))},f=function(e,t){var n=d(e,t);if(!n)return"";var i=e.createDocumentFragment(),o=e.createElement("div");i.appendChild(o);Array.prototype.slice.call(n.childNodes).filter(r.default.isNodeTypeElementOrText).forEach(function(e){return o.appendChild(e.cloneNode(!0))});return a.default.querySelectorAll(o,"link, style, sup[id^=cite_ref], .mw-cite-backlink").forEach(function(e){return e.remove()}),o.innerHTML.trim()},p=function(e){return a.default.matchesSelector(e,".reference, .mw-ref")?e:i.default.findClosestAncestor(e,".reference, .mw-ref")},_=function e(t,n,i,r){l(this,e),this.id=t,this.rect=n,this.text=i,this.html=r},h=function e(t,n){l(this,e),this.selectedIndex=t,this.referencesGroup=n},g=function(e,t){var n=e;do{n=t(n)}while(c(n));return n},m=function(e,t,n){for(var i=e;(i=g(i,t))&&i.nodeType===Node.ELEMENT_NODE&&s(i);)n(i)},v=function(e){return e.previousSibling},b=function(e){return e.nextSibling},y=function(e){var t=[e];return m(e,v,function(e){return t.unshift(e)}),m(e,b,function(e){return t.push(e)}),t};t.default={collectNearbyReferences:function(e,t){var n=t.parentElement,i=y(n),r=i.indexOf(n),a=i.map(function(t){return function(e,t){return new _(p(t).id,t.getBoundingClientRect(),t.textContent,f(e,t))}(e,t)});return new h(r,a)},isCitation:u,test:{adjacentNonWhitespaceNode:g,closestReferenceClassElement:p,collectAdjacentReferenceNodes:m,collectNearbyReferenceNodes:y,collectRefText:f,getRefTextContainer:d,hasCitationLink:s,isWhitespaceTextNode:c,nextSiblingGetter:b,prevSiblingGetter:v}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(34);var i,r=n(1),a=(i=r)&&i.__esModule?i:{default:i};var o=function(e){for(var t=[],n=e;n.parentElement&&!(n=n.parentElement).classList.contains("content_block");)t.push(n);return t},l=function(e,t,n){e[t]=n},u=function(e,t,n){Boolean(e[t])&&l(e,t,n)},c={width:"100%",height:"auto",maxWidth:"100%",float:"none"},s=function(e){Object.keys(c).forEach(function(t){return u(e.style,t,c[t])})},d=function(e){Object.keys(c).forEach(function(t){return l(e.style,t,c[t])})},f=function(e){o(e).forEach(s);var t=a.default.findClosestAncestor(e,"a.image");t&&d(t)},p=function(e){return!a.default.findClosestAncestor(e,"[class*='noresize']")&&(!a.default.findClosestAncestor(e,"div[class*='tsingle']")&&(!e.hasAttribute("usemap")&&(!a.default.isNestedInTable(e)&&!a.default.closestInlineStyle(e,"position","absolute"))))};t.default={maybeWidenImage:function(e){return!!p(e)&&(function(e){f(e),e.classList.add("pagelib_widen_image_override")}(e),!0)},test:{ancestorsToWiden:o,shouldWidenImage:p,updateExistingStyleValue:u,widenAncestors:f,widenElementByUpdatingExistingStyles:s,widenElementByUpdatingStyles:d}}},function(e,t,n){},function(e,t,n){}]).default});

},{}],2:[function(require,module,exports){
const wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.elementLocation = require('./js/elementLocation')
wmf.utilities = require('./js/utilities')
wmf.findInPage = require('./js/findInPage')
wmf.footerReadMore = require('wikimedia-page-library').FooterReadMore
wmf.footerMenu = require('wikimedia-page-library').FooterMenu
wmf.footerContainer = require('wikimedia-page-library').FooterContainer
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.sections = require('./js/sections')
wmf.footers = require('./js/footers')
wmf.windowResizeScroll = require('./js/windowResizeScroll')
wmf.editTextSelection = require('./js/editTextSelection')

window.wmf = wmf
},{"./js/editTextSelection":4,"./js/elementLocation":5,"./js/findInPage":6,"./js/footers":7,"./js/sections":8,"./js/utilities":9,"./js/windowResizeScroll":10,"wikimedia-page-library":1}],3:[function(require,module,exports){
const referenceCollection = require('wikimedia-page-library').ReferenceCollection
const utilities = require('./utilities')
const tableCollapser = require('wikimedia-page-library').CollapseTable

/**
 * Type of items users can click which we may need to handle.
 * @type {!Object}
 */
const ItemType = {
  unknown: 0,
  link: 1,
  image: 2,
  imagePlaceholder: 3,
  reference: 4
}

/**
 * Model of clicked item.
 * Reminder: separate `target` and `href` properties
 * needed to handle non-anchor targets such as images.
 */
class ClickedItem {
  constructor(target, href) {
    this.target = target
    this.href = href
  }
  /**
   * Determines type of item based on its properties.
   * @return {!ItemType} Type of the item
   */
  type() {
    if (referenceCollection.isCitation(this.href)) {
      return ItemType.reference
    } else if (this.target.tagName === 'IMG' && this.target.getAttribute( 'data-image-gallery' ) === 'true') {
      return ItemType.image
    } else if (this.target.tagName === 'SPAN' && this.target.parentElement.getAttribute( 'data-data-image-gallery' ) === 'true') {
      return ItemType.imagePlaceholder
    } else if (this.href) {
      return ItemType.link
    }
    return ItemType.unknown
  }
}

/**
 * Send messages to native land for respective click types.
 * @param  {!ClickedItem} item the item which was clicked on
 * @return {Boolean} `true` if a message was sent, otherwise `false`
 */
const sendMessageForClickedItem = item => {
  switch(item.type()) {
  case ItemType.link:
    sendMessageForLinkWithHref(item.href)
    break
  case ItemType.image:
    sendMessageForImageWithTarget(item.target)
    break
  case ItemType.imagePlaceholder:
    sendMessageForImagePlaceholderWithTarget(item.target)
    break
  case ItemType.reference:
    sendMessageForReferenceWithTarget(item.target)
    break
  default:
    return false
  }
  return true
}

/**
 * Sends message for a link click.
 * @param  {!String} href url
 * @return {void}
 */
const sendMessageForLinkWithHref = href => {
  if(href[0] === '#'){
    tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))
  }
  window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
}

/**
 * Sends message for an image click.
 * @param  {!Element} target an image element
 * @return {void}
 */
const sendMessageForImageWithTarget = target => {
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': target.getAttribute('src'),
    'width': target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
    'height': target.naturalHeight,
    'data-file-width': target.getAttribute('data-file-width'),
    'data-file-height': target.getAttribute('data-file-height')
  })
}

/**
 * Sends message for a lazy load image placeholder click.
 * @param  {!Element} innerPlaceholderSpan
 * @return {void}
 */
const sendMessageForImagePlaceholderWithTarget = innerPlaceholderSpan => {
  const outerSpan = innerPlaceholderSpan.parentElement
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': outerSpan.getAttribute('data-src'),
    'width': outerSpan.getAttribute('data-width'),
    'height': outerSpan.getAttribute('data-height'),
    'data-file-width': outerSpan.getAttribute('data-data-file-width'),
    'data-file-height': outerSpan.getAttribute('data-data-file-height')
  })
}

/**
 * Use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in
 * native land to convert to CGRect.
 * @param  {!ReferenceItem} referenceItem
 * @return {void}
 */
const reformatReferenceItemRectToBridgeToCGRect = referenceItem => {
  referenceItem.rect = {
    X: referenceItem.rect.left,
    Y: referenceItem.rect.top,
    Width: referenceItem.rect.width,
    Height: referenceItem.rect.height
  }
}

/**
 * Sends message for a reference click.
 * @param  {!Element} target an anchor element
 * @return {void}
 */
const sendMessageForReferenceWithTarget = target => {
  const nearbyReferences = referenceCollection.collectNearbyReferences( document, target )
  nearbyReferences.referencesGroup.forEach(reformatReferenceItemRectToBridgeToCGRect)
  window.webkit.messageHandlers.referenceClicked.postMessage(nearbyReferences)
}

/**
 * Handler for the click event.
 * @param  {ClickEvent} event the event being handled
 * @return {void}
 */
const handleClickEvent = event => {
  const target = event.target
  if(!target) {
    return
  }
  // Find anchor for non-anchor targets - like images.
  const anchorForTarget = utilities.findClosest(target, 'A') || target
  if(!anchorForTarget) {
    return
  }

  // Handle edit links.
  if (anchorForTarget.getAttribute( 'data-action' ) === 'edit_section'){
    window.webkit.messageHandlers.editClicked.postMessage({
      'sectionId': anchorForTarget.getAttribute( 'data-id' )
    })
    return
  }

  // Handle add title description link.
  if (anchorForTarget.getAttribute( 'data-action' ) === 'add_title_description'){
    window.webkit.messageHandlers.addTitleDescriptionClicked.postMessage('add_title_description')
    return
  }

  const href = anchorForTarget.getAttribute( 'href' )
  if(!href) {
    return
  }
  sendMessageForClickedItem(new ClickedItem(target, href))
}

/**
 * Associate our custom click handler logic with the document `click` event.
 */
document.addEventListener('click', event => {
  event.preventDefault()
  handleClickEvent(event)
}, false)
},{"./utilities":9,"wikimedia-page-library":1}],4:[function(require,module,exports){
const utilities = require('./utilities')

class SelectedTextEditInfo {
  constructor(selectedAndAdjacentText, isSelectedTextInTitleDescription, sectionID) {
    this.selectedAndAdjacentText = selectedAndAdjacentText
    this.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
    this.sectionID = sectionID
  }
}

const isSelectedTextInTitleDescription = selection => utilities.findClosest(selection.anchorNode, 'p#pagelib_edit_section_title_description') != null
const isSelectedTextInArticleTitle = selection => utilities.findClosest(selection.anchorNode, 'h1.pagelib_edit_section_title') != null

const getSelectedTextSectionID = selection => {
  const sectionIDString = utilities.findClosest(selection.anchorNode, 'div[id^="section_heading_and_content_block_"]').id.slice('section_heading_and_content_block_'.length)
  if (sectionIDString == null) {
    return null
  }
  return parseInt(sectionIDString)
}

const getSelectedTextEditInfo = () => {
  const selection = window.getSelection()

  const isTitleDescriptionSelection = isSelectedTextInTitleDescription(selection)
  let sectionID = 0
  if (!isTitleDescriptionSelection) {
    sectionID = getSelectedTextSectionID(selection)
  }

  let selectedAndAdjacentText = isSelectedTextInArticleTitle(selection) ? new SelectedAndAdjacentText('', '', '') : getSelectedAndAdjacentText().reducedToSpaceSeparatedWordsOnly()

  selection.removeAllRanges()
  selection.empty()

  return new SelectedTextEditInfo(
    selectedAndAdjacentText,
    isTitleDescriptionSelection,
    sectionID
  )
}

const stringWithoutParenthesisForString = s => s.replace(/\([^\(\)]*\)/g, ' ')
const stringWithoutReferenceForString = s => s.replace(/\[[^\[\]]*\]/g, ' ')

// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `codemirror-editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
  // Reduces to space separated words only and only keeps a couple adjacent before and after words.
  reducedToSpaceSeparatedWordsOnly() {
    const separator = ' '
    const wordsOnlyForString = s => stringWithoutParenthesisForString(stringWithoutReferenceForString(s)).replace(/[\W]+/g, separator).trim().split(separator)

    return new SelectedAndAdjacentText(
      wordsOnlyForString(this.selectedText).join(separator),
      wordsOnlyForString(this.textBeforeSelectedText).join(separator),
      wordsOnlyForString(this.textAfterSelectedText).join(separator)
    )
  }
}

const getSelectedAndAdjacentText = () => {
  const selection = window.getSelection()
  const range = selection.getRangeAt(0)
  const selectedText = range.toString()
  selection.modify('extend', 'backward', 'sentenceboundary')
  const textBeforeSelectedText = window.getSelection().getRangeAt(0).toString().slice(0, -selectedText.length)
  selection.modify('extend', 'forward', 'sentenceboundary')
  const textAfterSelectedText = window.getSelection().getRangeAt(0).toString()
  window.getSelection().removeAllRanges()
  window.getSelection().addRange(range)
  return new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo
},{"./utilities":9}],5:[function(require,module,exports){
//  Used by methods in "UIWebView+ElementLocation.h" category.

const stringEndsWith = (str, suffix) => str.indexOf(suffix, str.length - suffix.length) !== -1

exports.getImageWithSrc = src => document.querySelector(`img[src$="${src}"]`)

exports.getElementRect = element => {
  const rect = element.getBoundingClientRect()
  // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

exports.getIndexOfFirstOnScreenElement = (elementPrefix, elementCount, insetTop) => {
  for (let i = 0; i < elementCount; ++i) {
    const div = document.getElementById(elementPrefix + i)
    if (div === null) {
      continue
    }
    const rect = this.getElementRect(div)
    if (rect.Y > (insetTop + 1) || (rect.Y + rect.Height) > (insetTop + 1)) {
      return i
    }
  }
  return -1
}

exports.getElementFromPoint = (x, y) => document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)

exports.isElementTopOnscreen = element => element.getBoundingClientRect().top < 0

},{}],6:[function(require,module,exports){
// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

let PreviousFocusMatchSpanId = null

const deFocusPreviouslyFocusedSpan = () => {
  if (PreviousFocusMatchSpanId) {
    document.getElementById(PreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    PreviousFocusMatchSpanId = null
  }
}

const removeSearchTermHighlight = highlightElement => {
  highlightElement.parentNode.insertBefore(highlightElement.removeChild(highlightElement.firstChild), highlightElement)
  highlightElement.parentNode.removeChild(highlightElement)
}

const removeSearchTermHighlights = () => {
  // const startTime = new Date()
  deFocusPreviouslyFocusedSpan()
  walkBackwards(document.body, NodeFilter.SHOW_ELEMENT, searchTermHighlightFilter, removeSearchTermHighlight)
  document.normalize()
  // printTimeElapsedDebugMessage('CLEAR', startTime)
}

const addSearchTermHighlight = (idx, textNode, searchTerm) => {
  const value = textNode.nodeValue
  const span = document.createElement('span')
  let newTextNode = document.createTextNode(value.substr(idx, searchTerm.length))
  span.appendChild(newTextNode)
  span.setAttribute('class', 'findInPageMatch')
  span.setAttribute('id', `find|${ Math.random().toString(36).substring(2, 9) }`)
  newTextNode = document.createTextNode(value.substr(idx + searchTerm.length))
  textNode.deleteData(idx, value.length - idx)
  const nextNode = textNode.nextSibling
  textNode.parentNode.insertBefore(span, nextNode)
  textNode.parentNode.insertBefore(newTextNode, nextNode)
  return newTextNode
}

const addSearchTermHighlights = (textNode, searchTerm) => {
  let idx = -1, currentTextNode = textNode
  while ((idx = searchTermIndex(currentTextNode, searchTerm)) > -1) {
    currentTextNode = addSearchTermHighlight(idx, currentTextNode, searchTerm)
  }
}

const searchTermIndex = (textNode, searchTerm) => textNode.nodeValue.toLowerCase().indexOf(searchTerm)
const isHidden = element => element.offsetParent === null

const searchTermHighlightFilter = node => {
  if (node.tagName !== 'SPAN') {
    return NodeFilter.FILTER_SKIP
  }
  if (node.className !== 'findInPageMatch') {
    return NodeFilter.FILTER_SKIP
  }
  return NodeFilter.FILTER_ACCEPT
}

const walkBackwards = (startAt, whatToExamine, filter, action) => {
  let node, nodes = [], walker = document.createTreeWalker(startAt, whatToExamine, filter, false)
  // TreeWalker.nextNode() returns nodes in order of appearance.
  while (node = walker.nextNode()) nodes.push(node)
  for (let i = nodes.length - 1; i >= 0; i--) {
    action(nodes[i])
  }
}

const tagsToIgnore = new Set(['AUDIO', 'BASE', 'BR', 'CANVAS', 'HEAD', 'HTML', 'IMG', 'META', 'OL', 'SCRIPT', 'SELECT', 'STYLE', 'TR', 'UL'])

const findAndHighlightAllMatchesForSearchTerm = searchTerm => {
  removeSearchTermHighlights()
  searchTerm = searchTerm.trim()
  if (searchTerm.length === 0) {
    window.webkit.messageHandlers.findInPageMatchesFound.postMessage([])
    return
  }

  // const startTime = new Date()
  const matchMarker = node => addSearchTermHighlights(node, searchTerm.toLowerCase())
  const matchFilter = node => !tagsToIgnore.has(node.parentElement.tagName) && !isHidden(node.parentElement)
  walkBackwards(document.body, NodeFilter.SHOW_TEXT, matchFilter, matchMarker)

  const orderedMatchIDsToReport = [...document.querySelectorAll('span.findInPageMatch')].map(element => element.id)
  window.webkit.messageHandlers.findInPageMatchesFound.postMessage(orderedMatchIDsToReport)
  // printTimeElapsedDebugMessage('SET', startTime)
}

/*
const printTimeElapsedDebugMessage = (string, startTime) => {
  let div = document.querySelector('div#debugPanel')
  if (!div) {
    div = document.createElement('div')
    div.id = 'debugPanel'
    div.style = `
      position: fixed;
      top: 35%;
      z-index: 99;
      background-color: green;
      color: white;
      padding: 15px;
      font-weight: bold;
      font-size: xx-large;
      border-radius: 10px 40px 10px 40px;
      text-align: center;
    `
    document.body.appendChild(div)
    div.addEventListener('click', event => event.target.remove(), true)
  }
  let timeDiff = (new Date() - startTime) / 1000
  div.innerHTML = `${string}<hr>Elapsed<br>${timeDiff}s`
}
*/

const useFocusStyleForHighlightedSearchTermWithId = id => {
  deFocusPreviouslyFocusedSpan()
  document.getElementById(id).classList.add('findInPageMatch_Focus')
  PreviousFocusMatchSpanId = id
}

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
exports.removeSearchTermHighlights = removeSearchTermHighlights

},{}],7:[function(require,module,exports){

const requirements = {
  footerReadMore: require('wikimedia-page-library').FooterReadMore,
  footerMenu: require('wikimedia-page-library').FooterMenu,
  footerLegal: require('wikimedia-page-library').FooterLegal,
  footerContainer: require('wikimedia-page-library').FooterContainer
}

class Footer {
  // 'localizedStrings' is object containing the following localized strings key/value pairs: 'readMoreHeading', 'licenseString', 'licenseSubstitutionString', 'viewInBrowserString', 'menuHeading', 'menuLanguagesTitle', 'menuLastEditedTitle', 'menuLastEditedSubtitle', 'menuTalkPageTitle', 'menuPageIssuesTitle', 'menuDisambiguationTitle', 'menuCoordinateTitle'
  constructor(articleTitle, menuItems, hasReadMore, readMoreItemCount, localizedStrings, proxyURL) {
    this.articleTitle = articleTitle
    this.menuItems = menuItems
    this.hasReadMore = hasReadMore
    this.readMoreItemCount = readMoreItemCount
    this.localizedStrings = localizedStrings
    this.proxyURL = proxyURL
  }
  addContainer() {
    if (requirements.footerContainer.isContainerAttached(document) === false) {
      document.body.appendChild(requirements.footerContainer.containerFragment(document))
      window.webkit.messageHandlers.footerContainerAdded.postMessage('added')
    }
  }
  addDynamicBottomPadding() {
    window.addEventListener('resize', function(){requirements.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)})
  }
  addMenu() {
    requirements.footerMenu.setHeading(this.localizedStrings.menuHeading, 'pagelib_footer_container_menu_heading', document)
    this.menuItems.forEach(item => {
      let title = ''
      let subtitle = ''
      let menuItemTypeString = ''
      switch(item) {
      case requirements.footerMenu.MenuItemType.languages:
        menuItemTypeString = 'languages'
        title = this.localizedStrings.menuLanguagesTitle
        break
      case requirements.footerMenu.MenuItemType.lastEdited:
        menuItemTypeString = 'lastEdited'
        title = this.localizedStrings.menuLastEditedTitle
        subtitle = this.localizedStrings.menuLastEditedSubtitle
        break
      case requirements.footerMenu.MenuItemType.pageIssues:
        menuItemTypeString = 'pageIssues'
        title = this.localizedStrings.menuPageIssuesTitle
        break
      case requirements.footerMenu.MenuItemType.disambiguation:
        menuItemTypeString = 'disambiguation'
        title = this.localizedStrings.menuDisambiguationTitle
        break
      case requirements.footerMenu.MenuItemType.coordinate:
        menuItemTypeString = 'coordinate'
        title = this.localizedStrings.menuCoordinateTitle
        break
      case requirements.footerMenu.MenuItemType.talkPage:
        menuItemTypeString = 'talkPage'
        title = this.localizedStrings.menuTalkPageTitle
        break
      default:
      }
      const itemSelectionHandler = payload => window.webkit.messageHandlers.footerMenuItemClicked.postMessage({'selection': menuItemTypeString, 'payload': payload})
      requirements.footerMenu.maybeAddItem(title, subtitle, item, 'pagelib_footer_container_menu_items', itemSelectionHandler, document)
    })
  }
  addReadMore() {
    if (this.hasReadMore){
      requirements.footerReadMore.setHeading(this.localizedStrings.readMoreHeading, 'pagelib_footer_container_readmore_heading', document)
      const saveButtonTapHandler = title => window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})
      const titlesShownHandler = titles => {
        window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles)
        requirements.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)
      }
      requirements.footerReadMore.add(this.articleTitle, this.readMoreItemCount, 'pagelib_footer_container_readmore_pages', this.proxyURL, saveButtonTapHandler, titlesShownHandler, document)
    }
  }
  addLegal() {
    const licenseLinkClickHandler = () => window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked')
    const viewInBrowserLinkClickHandler = () => window.webkit.messageHandlers.footerBrowserLinkClicked.postMessage('linkClicked')
    requirements.footerLegal.add(document, this.localizedStrings.licenseString, this.localizedStrings.licenseSubstitutionString, 'pagelib_footer_container_legal', licenseLinkClickHandler, this.localizedStrings.viewInBrowserString, viewInBrowserLinkClickHandler)
  }
  add() {
    this.addContainer()
    this.addDynamicBottomPadding()
    this.addMenu()
    this.addReadMore()
    this.addLegal()
  }
}

exports.Footer = Footer
},{"wikimedia-page-library":1}],8:[function(require,module,exports){

const requirements = {
  editTransform: require('wikimedia-page-library').EditTransform,
  utilities: require('./utilities'),
  tables: require('wikimedia-page-library').CollapseTable,
  themes: require('wikimedia-page-library').ThemeTransform,
  redLinks: require('wikimedia-page-library').RedLinks,
  leadIntroductionTransform: require('wikimedia-page-library').LeadIntroductionTransform,
  widenImage: require('wikimedia-page-library').WidenImage,
  lazyLoadTransformer: require('wikimedia-page-library').LazyLoadTransformer,
  location: require('./elementLocation')
}

// Documents attached to Window will attempt eager pre-fetching of image element resources as soon
// as image elements appear in DOM of such documents. So for lazy image loading transform to work
// (without the images being eagerly pre-fetched) our section fragments need to be created on a
// document not attached to window - `lazyDocument`. The `live` document's `mainContentDiv` is only
// used when we append our transformed fragments to it. See this Android commit message for details:
// https://github.com/wikimedia/apps-android-wikipedia/commit/620538d961221942e340ca7ac7f429393d1309d6
const lazyDocument = document.implementation.createHTMLDocument()
const lazyImageLoadViewportDistanceMultiplier = 2 // Load images on the current screen up to one ahead.
const lazyImageLoadingTransformer = new requirements.lazyLoadTransformer(window, lazyImageLoadViewportDistanceMultiplier)
const liveDocument = document

const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

class Language {
  constructor(code, dir, isRTL) {
    this.code = code
    this.dir = dir
    this.isRTL = isRTL
  }
}

class Article {
  constructor(ismain, title, displayTitle, description, editable, language, addTitleDescriptionString, isTitleDescriptionEditable) {
    this.ismain = ismain
    this.title = title
    this.displayTitle = displayTitle
    this.description = description
    this.editable = editable
    this.language = language
    this.addTitleDescriptionString = addTitleDescriptionString
    this.isTitleDescriptionEditable = isTitleDescriptionEditable
  }
}

class Section {
  constructor(level, line, anchor, id, text, article) {
    this.level = level
    this.line = line
    this.anchor = anchor
    this.id = id
    this.text = text
    this.article = article
  }

  addAnchorAsIdToHeading(heading) {
    if (this.anchor === undefined || this.anchor.length === 0) {
      return
    }
    // TODO: consider renaming this 'id' to 'anchor' for clarity - would need to update native
    // code as well - used when TOC sections made to jump to sections.
    // If we make this change this method should probably be renamed to 'addAnchorToHeading'.
    heading.id = this.anchor
  }

  leadSectionHeading() {
    return requirements.editTransform.newEditLeadSectionHeader(lazyDocument, this.article.displayTitle, this.article.description, this.article.addTitleDescriptionString, this.article.isTitleDescriptionEditable, false, false)
  }

  nonLeadSectionHeading() {
    // Non-lead section edit pencils are added as part of the heading via `newEditSectionHeader`
    // because it provides a heading correctly aligned with the edit pencil. (Lead section edit
    // pencils are added in `applyTransformationsToFragment` because they need to be added after
    // the `moveLeadIntroductionUp` has finished.)
    const heading = requirements.editTransform.newEditSectionHeader(lazyDocument, this.id, this.level, this.line, true)
    this.addAnchorAsIdToHeading(heading)
    return heading
  }

  heading() {
    return this.isLeadSection() ? this.leadSectionHeading() : this.nonLeadSectionHeading()
  }

  isLeadSection() {
    return this.id === 0
  }

  isNonMainPageLeadSection() {
    return this.isLeadSection() && !this.article.ismain
  }

  shouldWrapInTable() {
    return ['References', 'External links', 'Notes', 'Further reading', 'Bibliography'].indexOf(this.line) != -1
  }

  html() {
    if(this.shouldWrapInTable()){
      return `<table><th>${this.line}</th><tr><td>${this.text}</td></tr></table>`
    }
    return this.text
  }

  containerDiv() {
    const container = lazyDocument.createElement('div')
    container.id = `section_heading_and_content_block_${this.id}`

    if(!this.article.ismain){
      container.appendChild(this.heading())
    }

    const block = lazyDocument.createElement('div')
    block.id = `content_block_${this.id}`
    block.classList.add('content_block')
    block.innerHTML = this.html()

    container.appendChild(block)

    return container
  }
}

const processResponseStatus = response => {
  if (response.status === 200) { // can use status 0 if loading local files
    return Promise.resolve(response)
  }
  return Promise.reject(new Error(response.statusText))
}

const extractResponseJSON = response => response.json()

// Backfill fragments with `createElement` and `createDocumentFragment` so transforms
// requiring `Document` parameters will also work if passed a `DocumentFragment`.
// Reminder: didn't use 'prototype' because it extends all instances.
const enrichFragment = fragment => {
  fragment.createElement = name => lazyDocument.createElement(name)
  fragment.createDocumentFragment = () => lazyDocument.createDocumentFragment()
  fragment.createTextNode = text => lazyDocument.createTextNode(text)
}

const fragmentForSection = section => {
  const fragment = lazyDocument.createDocumentFragment()
  enrichFragment(fragment)
  const container = section.containerDiv() // do not append this to document. keep unattached to main DOM (ie headless) until transforms have been run on the fragment
  fragment.appendChild(container)
  return fragment
}

const applyTransformationsToFragment = (fragment, article, isLead) => {
  requirements.redLinks.hideRedLinks(fragment)

  if(!article.ismain && isLead){
    requirements.leadIntroductionTransform.moveLeadIntroductionUp(fragment, 'content_block_0')
  }

  const isFilePage = fragment.querySelector('#filetoc') !== null
  const needsLeadEditPencil = !article.ismain && !isFilePage && isLead
  if(needsLeadEditPencil){
    // Add lead section edit pencil before the section html. Lead section edit pencil must be
    // added after `moveLeadIntroductionUp` has finished. (Other edit pencils are constructed
    // in `nonLeadSectionHeading()`.)
    const leadSectionEditButton = requirements.editTransform.newEditSectionButton(fragment, 0)
    leadSectionEditButton.style.float = article.language.isRTL ? 'left': 'right'
    const firstContentBlock = fragment.getElementById('content_block_0')
    firstContentBlock.insertBefore(leadSectionEditButton, firstContentBlock.firstChild)
  }
  fragment.querySelectorAll('a.pagelib_edit_section_link').forEach(anchor => {anchor.href = 'WMFEditPencil'})

  const tableFooterDivClickCallback = container => {
    if(requirements.location.isElementTopOnscreen(container)){
      window.scrollTo( 0, container.offsetTop - 10 )
    }
  }

  // Adds table collapsing header/footers.
  requirements.tables.adjustTables(window, fragment, article.title, article.ismain, this.collapseTablesInitially, this.collapseTablesLocalizedStrings.tableInfoboxTitle, this.collapseTablesLocalizedStrings.tableOtherTitle, this.collapseTablesLocalizedStrings.tableFooterTitle, tableFooterDivClickCallback)

  // Prevents some collapsed tables from scrolling side-to-side.
  // May want to move this to wikimedia-page-library if there are no issues.
  Array.from(fragment.querySelectorAll('.app_table_container *[class~="nowrap"]')).forEach(function(el) {el.classList.remove('nowrap')})

  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  Array.from(fragment.querySelectorAll('img'))
    .filter(image => image.getAttribute('data-image-gallery') === 'true')
    .forEach(requirements.widenImage.maybeWidenImage)

  // Classifies some tricky elements like math formula images (examples are first images on
  // 'enwiki > Quadradic equation' and 'enwiki > Away colors > Association football'). See the
  // 'classifyElements' method itself for other examples.
  requirements.themes.classifyElements(fragment)

  lazyImageLoadingTransformer.convertImagesToPlaceholders(fragment)
  lazyImageLoadingTransformer.loadPlaceholders()

  // Fix bug preventing audio from playing on 1st click of play button.
  fragment.querySelectorAll('audio[preload="none"]').forEach(audio => audio.setAttribute('preload', 'metadata'))
}

const transformAndAppendSection = (section, mainContentDiv) => {
  const fragment = fragmentForSection(section)
  // Transform the fragments *before* attaching them to the main DOM.
  applyTransformationsToFragment(fragment, section.article, section.isLeadSection())
  mainContentDiv.appendChild(fragment)
}

//early page-wide transforms which happen before any sections have been appended
const performEarlyNonSectionTransforms = article => {
  requirements.utilities.setPageProtected(!article.editable)
  requirements.utilities.setLanguage(article.language.code, article.language.dir, article.language.isRTL ? 'rtl': 'ltr')
}

const extractSectionsJSON = json => json['mobileview']['sections']

const transformAndAppendLeadSectionToMainContentDiv = (leadSectionJSON, article, mainContentDiv) => {
  const leadModel = new Section(leadSectionJSON.level, leadSectionJSON.line, leadSectionJSON.anchor, leadSectionJSON.id, leadSectionJSON.text, article)
  transformAndAppendSection(leadModel, mainContentDiv)
}

const transformAndAppendNonLeadSectionsToMainContentDiv = (sectionsJSON, article, mainContentDiv) => {
  sectionsJSON.forEach((sectionJSON, index) => {
    if (index > 0) {
      const sectionModel = new Section(sectionJSON.level, sectionJSON.line, sectionJSON.anchor, sectionJSON.id, sectionJSON.text, article)
      transformAndAppendSection(sectionModel, mainContentDiv)
    }
  })
}

const scrollToSection = hash => {
  if (hash !== '') {
    window.requestAnimationFrame(() => {
      location.hash = ''
      location.hash = hash
    })
  }
}

const fetchTransformAndAppendSectionsToDocument = (article, articleSectionsURL, hash, successCallback) => {
  performEarlyNonSectionTransforms(article)
  const mainContentDiv = liveDocument.querySelector('div.content')
  fetch(articleSectionsURL)
    .then(processResponseStatus)
    .then(extractResponseJSON)
    .then(extractSectionsJSON)
    .then(sectionsJSON => {
      if (sectionsJSON.length > 0) {
        transformAndAppendLeadSectionToMainContentDiv(sectionsJSON[0], article, mainContentDiv)
      }
      // Giving the lead section a tiny head-start speeds up its appearance dramatically.
      const nonLeadDelay = 50
      setTimeout(() => {
        transformAndAppendNonLeadSectionsToMainContentDiv(sectionsJSON, article, mainContentDiv)
        scrollToSection(hash)
        successCallback()
      }, nonLeadDelay)
    })
    .catch(error => console.log(`Promise was rejected with error: ${error}`))
}

// Object containing the following localized strings key/value pairs: 'tableInfoboxTitle', 'tableOtherTitle', 'tableFooterTitle'
exports.collapseTablesLocalizedStrings = undefined
exports.collapseTablesInitially = false

exports.sectionErrorMessageLocalizedString  = undefined
exports.fetchTransformAndAppendSectionsToDocument = fetchTransformAndAppendSectionsToDocument
exports.Language = Language
exports.Article = Article
},{"./elementLocation":5,"./utilities":9,"wikimedia-page-library":1}],9:[function(require,module,exports){

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
},{}],10:[function(require,module,exports){
// This file keeps the same area of the article onscreen after rotate or tablet TOC toggle.
const utilities = require('./utilities')

let topElement = undefined
let relativeYOffset = 0

const relativeYOffsetForElement = element => {
  const rect = element.getBoundingClientRect()
  return rect.top / rect.height
}

const recordTopElementAndItsRelativeYOffset = () => {
  topElement = document.elementFromPoint( window.innerWidth / 2, window.innerHeight / 3 )
  topElement = utilities.findClosest(topElement, 'div#content > div') || topElement
  if (topElement) {
    relativeYOffset = relativeYOffsetForElement(topElement)
  } else {
    relativeYOffset = 0
  }
}

const yOffsetFromRelativeYOffsetForElement = element => {
  const rect = element.getBoundingClientRect()
  return window.scrollY + rect.top - relativeYOffset * rect.height
}

const scrollToSamePlaceBeforeResize = () => {
  if (!topElement) {
    return
  }
  window.scrollTo(0, yOffsetFromRelativeYOffsetForElement(topElement))
}

window.addEventListener('resize', event => setTimeout(scrollToSamePlaceBeforeResize, 50))

let timer = null
window.addEventListener('scroll', () => {
  if(timer !== null) {
    clearTimeout(timer)
  }
  timer = setTimeout(recordTopElementAndItsRelativeYOffset, 250)
}, false)

exports.recordTopElementAndItsRelativeYOffset = recordTopElementAndItsRelativeYOffset
exports.scrollToSamePlaceBeforeResize = scrollToSamePlaceBeforeResize
},{"./utilities":9}]},{},[2,3,4,5,6,7,8,9,10]);
