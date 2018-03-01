(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
const wmf = {}

wmf.applyDarkThemeLogo = () => {
  hideElementById('dark-logo')
  showElementById('light-logo')
}

wmf.applyLightThemeLogo = () => {
  hideElementById('light-logo')
  showElementById('dark-logo')
}

const showElementById = id => {
  show(document.getElementById(id))
}

const hideElementById = id => {
  hide(document.getElementById(id))
}

const show = element => {
  element.style.display = ''
}

const hide = element => {
  element.style.display = 'none'
}

window.wmf = wmf
},{}]},{},[1]);
