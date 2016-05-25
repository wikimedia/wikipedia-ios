(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

// Implementation of https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
function findClosest (el, selector) {
    while ((el = el.parentElement) && !el.matches(selector));
    return el;
}

function isNestedInTable(el) {
    while ((el = el.parentElement)){
        if(el.tagName === 'TD'){
            return true;
        }
    }
    return false;
}

function setLanguage(lang, dir, uidir){
    var html = document.querySelector( "html" );
    html.lang = lang;
    html.dir = dir;
    html.classList.add( 'content-' + dir );
    html.classList.add( 'ui-' + uidir );
    document.querySelector('base').href = 'https://' + lang + '.wikipedia.org/';
}

function setPageProtected(){
    document.getElementsByTagName( "html" )[0].classList.add( "page-protected" );
}

function scrollToFragment(fragmentId){
    location.hash = '';
    location.hash = fragmentId;
}

function accessibilityCursorToFragment(fragmentId){
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
    var focus_element = document.getElementById(fragmentId);
    var other_element = document.body;
    other_element.setAttribute('tabindex', 0);
    other_element.focus();
    focus_element.setAttribute('tabindex', 0);
    focus_element.focus();
}

exports.accessibilityCursorToFragment = accessibilityCursorToFragment;
exports.scrollToFragment = scrollToFragment;
exports.setPageProtected = setPageProtected;
exports.setLanguage = setLanguage;
exports.findClosest = findClosest;
exports.isNestedInTable = isNestedInTable;

},{}],2:[function(require,module,exports){
var wmf = {};

wmf.utilities = require("./js/utilities");

window.wmf = wmf;
},{"./js/utilities":1}]},{},[2,1]);
