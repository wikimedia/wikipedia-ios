// CodeMirror, copyright (c) by Marijn Haverbeke and others
// Distributed under an MIT license: https://codemirror.net/LICENSE

// Define search commands. Depends on dialog.js or another
// implementation of the openDialog method.

// Replace works a little oddly -- it will do the replace on the next
// Ctrl-G (or whatever is bound to findNext) press. You prevent a
// replace by making sure the match is no longer selected when hitting
// Ctrl-G.

(function(mod) {
    if (typeof exports == "object" && typeof module == "object") // CommonJS
      mod(require("../../lib/codemirror"), require("./searchcursor"));
    else if (typeof define == "function" && define.amd) // AMD
      define(["../../lib/codemirror", "./searchcursor"], mod);
    else // Plain browser env
      mod(CodeMirror);
  })(function(CodeMirror) {
    "use strict";
  
    function searchOverlay(cm, state, caseInsensitive) {

      var query = state.query;
      var loopMatchPositionIndex = 0;
      state.initialFocusedMatchIndex = -1;

      if (typeof query == "string")
        query = new RegExp(query.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), caseInsensitive ? "gi" : "g");
      else if (!query.global)
        query = new RegExp(query.source, query.ignoreCase ? "gi" : "g");
  
      return {token: function(stream) {
        query.lastIndex = stream.pos;
        var match = query.exec(stream.string);
        if (match && match.index == stream.pos) {
          stream.pos += match[0].length || 1;

          if (state.initialFocusedMatchIndex == -1) {
            var fromCursor = cm.getCursor('from')
            if (stream.lineOracle.line > fromCursor.line || (stream.lineOracle.line == fromCursor.line && stream.start >= fromCursor.ch)) {
              state.initialFocusedMatchIndex = loopMatchPositionIndex;
             }
             loopMatchPositionIndex++;
          }

          return "searching";
        } else if (match) {
          stream.pos = match.index;
        } else {
          stream.skipToEnd();
        }
      }};
    }
  
    function SearchState() {
      this.posFrom = this.posTo = this.lastQuery = this.query = null;
      this.overlay = null;
    }
  
    function getSearchState(cm) {
      return cm.state.search || (cm.state.search = new SearchState());
    }
  
    function queryCaseInsensitive(query) {
      //codemirror default is if the query string is all lowercase, do a case insensitive search.
      //commenting out here so it's case insensitive whether query is lowercase or not.
      return typeof query == "string" // && query == query.toLowerCase();
    }
  
    function getSearchCursor(cm, query, pos) {
      return cm.getSearchCursor(query, pos, {caseFold: queryCaseInsensitive(query), multiline: true});
    }
  
    function parseString(string) {
      return string.replace(/\\(.)/g, function(_, ch) {
        if (ch == "n") return "\n"
        if (ch == "r") return "\r"
        return ch
      })
    }
  
    function parseQuery(query) {
      var isRE = query.match(/^\/(.*)\/([a-z]*)$/);
      if (isRE) {
        try { query = new RegExp(isRE[1], isRE[2].indexOf("i") == -1 ? "" : "i"); }
        catch(e) {} // Not a regular expression after all, do a string search
      } else {
        query = parseString(query)
      }
      if (typeof query == "string" ? query == "" : query.test(""))
        query = /x^/;
      return query;
    }
  
    function startSearch(cm, state, query) {
      state.queryText = query;
      state.query = parseQuery(query);
      cm.removeOverlay(state.overlay, queryCaseInsensitive(state.query));
      state.overlay = searchOverlay(cm, state, queryCaseInsensitive(state.query));
      cm.addOverlay(state.overlay);
      if (cm.showMatchesOnScrollbar) {
        if (state.annotate) { state.annotate.clear(); state.annotate = null; }
        state.annotate = cm.showMatchesOnScrollbar(state.query, queryCaseInsensitive(state.query));
      }
    }
  
    function doSearch(cm, rev) {
      var state = getSearchState(cm);
      if (state.query) return findNext(cm, rev);
      var q = cm.getSelection() || state.lastQuery;
      if (q instanceof RegExp && q.source == "x^") q = null
      const query = cm.state.query;
      if (query && !state.query) cm.operation(function () {
        startSearch(cm, state, query);
        state.posFrom = state.posTo = cm.getCursor();
        findNext(cm, rev);
      });
    }

    const ClassNames = {
      searching: 'cm-searching',
      searchingFocus: 'cm-searching-focus',
      searchingReplaced: 'cm-searching-replaced',
      searchingFocusIdPrefix: 'cm-searching-focus-id-'
    }

    function clearFocusedMatches(cm) {
      Array.from(document.getElementsByClassName(ClassNames.searchingFocus)).forEach(element => setFocusOnMatchElement(element, false))
    }

    function markReplacedText(cm, cursor) {
      const state = getSearchState(cm);
      const marker = cm.markText(cursor.from(), cursor.to(), { className: ClassNames.searchingReplaced })
      if (state.replacedMarkers) {
        state.replacedMarkers.push(marker);
      } else {
        state.replacedMarkers = [marker];
      }
    }

    function clearReplaced(state) {
      if (state.replacedMarkers) {
        state.replacedMarkers.forEach((marker) => { marker.clear() });
        state.replacedMarkers = null;
      }
    }

    function focusOnMatch(state, focus, forceIncrement) {
      const matches = document.getElementsByClassName(ClassNames.searching);
      const matchesCount = matches.length;
      
      var focusedMatchIndex;
      //here we're using focus as a flag for whether they came from find next / prev or from replace. 
      //if they came from find next/previous, we are okay with focusedMatchIndex being -1 because it will get decremented/incremented below
      //if they came from replace (where focus is null), we want to reset focusedMatchIndex to 0 but NOT increment
      if (state.focusedMatchIndex != undefined && state.focusedMatchIndex != null && ((state.focusedMatchIndex > -1 && !focus) || (state.focusedMatchIndex >= -1 && focus) || (state.focusedMatchIndex == -1 && !focus && forceIncrement))) {
        focusedMatchIndex = state.focusedMatchIndex;
      } else if (state.initialFocusedMatchIndex != undefined && state.initialFocusedMatchIndex != null && state.initialFocusedMatchIndex > -1) {
        focusedMatchIndex = state.initialFocusedMatchIndex;
      } else {
        focusedMatchIndex = 0;
      }

      if (forceIncrement || focus) {
        if (forceIncrement || focus.next) {
          if (focusedMatchIndex >= matchesCount - 1) {
            focusedMatchIndex = 0;
          } else {
            focusedMatchIndex++;
          }
        } else if (focus.prev) {
          if (focusedMatchIndex > 0) {
            focusedMatchIndex--;
          } else {
            focusedMatchIndex = matchesCount - 1;
          }
        }
      }

      const focusedMatchID = `${ClassNames.searchingFocusIdPrefix}${focusedMatchIndex}`;
      const focusedMatch = focusOnMatchAtIndex(matches, focusedMatchIndex, focusedMatchID);

      state.matchesCount = matchesCount;
      state.focusedMatch = focusedMatch;

      if (state.focusedMatch) {
        state.focusedMatchIndex = focusedMatchIndex;
        state.focusedMatchID = focusedMatchID;
      } else {
        state.focusedMatchIndex = -1;
        state.focusedMatchID = null;
      }

      const message = {
        findInPageMatchesCount: state.matchesCount,
        findInPageFocusedMatchIndex: state.focusedMatchIndex,
        findInPageFocusedMatchID: state.focusedMatchID
      };

      window.webkit.messageHandlers.codeMirrorSearchMessage.postMessage(message);
      state.initialFocusedMatchIndex = -1;
    }

    function setFocusOnMatchElement(element, enable, id = null) {
      if (enable) {
        element.classList.add(ClassNames.searchingFocus)
        element.id = id
      } else {
        element.classList.remove(ClassNames.searchingFocus)
        element.removeAttribute('id')  
      }
    }

    function focusOnMatchAtIndex(matches, index, id) {
      if (matches.length == 0) return null;
      const match = matches[index];
      if (!match) return null;
      setFocusOnMatchElement(match, true, id)
      return match
    }

    function selectLastFocusedMatch(cm) {
      if (cm.hasFocus()) return;
      if (cm.getSelection() !== "") return focusWithoutScroll(cm);
      const scrollTop = document.body.scrollTop;
      var state = getSearchState(cm);
      var sel = window.getSelection()
      if (sel.rangeCount > 0) {
        sel.removeAllRanges();
      }
      const range = document.createRange();
      range.selectNode(state.focusedMatch)
      sel.addRange(range);
      document.body.scrollTop = scrollTop;
    } 
  
    function findNext(cm, rev) {cm.operation(function() {
      var state = getSearchState(cm);
      var cursor = getSearchCursor(cm, state.query, rev ? state.posFrom : state.posTo);
      if (!cursor.find(rev)) {
        cursor = getSearchCursor(cm, state.query, rev ? CodeMirror.Pos(cm.lastLine()) : CodeMirror.Pos(cm.firstLine(), 0));
        state.focusedMatchIndex = -1;
        state.initialFocusedMatchIndex = -1;
        if (!cursor.find(rev)) return;
      }
      state.posFrom = cursor.from(); state.posTo = cursor.to();
    });}
  
    function clearSearch(cm) {cm.operation(function() {
      var state = getSearchState(cm);
      state.lastQuery = state.query;
      if (!state.query) return;
      clearFocusedMatches(cm);
      clearReplaced(state);
      state.focusedMatchIndex = null
      state.initialFocusedMatchIndex = null;
      state.query = state.queryText = null;
      cm.removeOverlay(state.overlay);
      if (state.annotate) { state.annotate.clear(); state.annotate = null; }
    });}
  
    function replaceAll(cm, query, text) {
      var count = 0;
      cm.operation(function() {
        for (var cursor = getSearchCursor(cm, query); cursor.findNext();) {
          if (typeof query != "string") {
            var match = cm.getRange(cursor.from(), cursor.to()).match(query);
            cursor.replace(text.replace(/\$(\d)/g, function(_, i) {return match[i];}));
          } else {
            cursor.replace(text);
            markReplacedText(cm, cursor);
          }
          count++;
        }
      });
      cm.state.replaceAllCount = count;
    }

    //same as replace(cm, all) but bypasses CodeMirror dialogs. Split this up into all & single variants for simplicity
    function replaceAllWithoutDialogs(cm) {
      var replaceText = cm.state.replaceText;
      if (cm.getOption("readOnly")) return;
      if (!replaceText) return;

      var query = cm.state.query;
      query = parseQuery(query);
      replaceText = parseString(replaceText);
      cm.isReplacing = true;
      replaceAll(cm, query, replaceText);
      cm.isReplacing = false;

      //resets count to 0/0
      let state = getSearchState(cm);
      focusOnMatch(state, null, false);
    }

    function replaceSingleWithoutDialogs(cm) {
      if (cm.getOption("readOnly")) return;
      var replaceText = cm.state.replaceText;
      if (!replaceText) return;

      var state = getSearchState(cm);
      var query = state.query;
      query = parseQuery(query);
      replaceText = parseString(replaceText);
      var cursor = getSearchCursor(cm, query, state.posFrom);

      var advance = function(shouldReplace) {
        var start = cursor.from(), match;
        if (!(match = cursor.findNext())) {
          cursor = getSearchCursor(cm, query);
          state.focusedMatchIndex = 0;
          state.focusedMatchIndex = -1;
          state.initialFocusedMatchIndex = -1;
          if (!(match = cursor.findNext()) || (start && cursor.from().line == start.line && cursor.from().ch == start.ch)) {
            focusOnMatch(state, null, false); //resets count to 0/0
            return;
          }
        }

        state.posFrom = cursor.from(); state.posTo = cursor.to();
        if (shouldReplace) {
          cm.isReplacing = true;

          cm.setCursor(state.posFrom)

          doReplace(cm, state);
          cm.isReplacing = false;
        }
      }
      var doReplace = function(cm, state) {
        cursor.replace(replaceText);
        markReplacedText(cm, cursor);
        advance(false);
        var forceIncrement = replaceText.includes(query) || replaceText.toLowerCase() === query.toLowerCase();
        focusOnMatch(state, null, forceIncrement);
      };
      advance(true);
    }
  
    function replace(cm, all) {
      if (cm.getOption("readOnly")) return;
      var query = cm.getSelection() || getSearchState(cm).lastQuery;
      var dialogText = '<span class="CodeMirror-search-label">' + (all ? cm.phrase("Replace all:") : cm.phrase("Replace:")) + '</span>';
      dialog(cm, dialogText + getReplaceQueryDialog(cm), dialogText, query, function(query) {
        if (!query) return;
        query = parseQuery(query);
        dialog(cm, getReplacementQueryDialog(cm), cm.phrase("Replace with:"), "", function(text) {
          text = parseString(text)
          if (all) {
            replaceAll(cm, query, text)
          } else {
            clearSearch(cm);
            var cursor = getSearchCursor(cm, query, cm.getCursor("from"));
            var advance = function() {
              var start = cursor.from(), match;
              if (!(match = cursor.findNext())) {
                cursor = getSearchCursor(cm, query);
                if (!(match = cursor.findNext()) ||
                    (start && cursor.from().line == start.line && cursor.from().ch == start.ch)) return;
              }
              cm.setSelection(cursor.from(), cursor.to());
              cm.scrollIntoView({from: cursor.from(), to: cursor.to()});
              confirmDialog(cm, getDoReplaceConfirm(cm), cm.phrase("Replace?"),
                            [function() {doReplace(match);}, advance,
                             function() {replaceAll(cm, query, text)}]);
            };
            var doReplace = function(match) {
              cursor.replace(typeof query == "string" ? text :
                             text.replace(/\$(\d)/g, function(_, i) {return match[i];}));
              advance();
            };
            advance();
          }
        });
      });
    }
  
    CodeMirror.commands.find = function(cm) { 
      cm.operation(function () { 
        clearSearch(cm); 
        doSearch(cm); 
      }); 
      focusOnMatch(getSearchState(cm), null, false); 
    };
    CodeMirror.commands.findNext = function(cm) { 
      cm.operation(function () { 
        clearFocusedMatches(cm); 
        doSearch(cm, false);
      }); 
      focusOnMatch(getSearchState(cm), {next: true}, false); 
    };
    CodeMirror.commands.findPrev = function(cm) {
      cm.operation(function () { 
        clearFocusedMatches(cm); 
        doSearch(cm, false);
      }); 
      focusOnMatch(getSearchState(cm), {prev: true}, false);
    };
    CodeMirror.commands.clearSearch = clearSearch;
    CodeMirror.commands.replace = replace;
    CodeMirror.commands.replaceAll = function(cm) {replace(cm, true);};
    CodeMirror.commands.replaceAllWithoutDialogs = function(cm) { replaceAllWithoutDialogs(cm);};
    CodeMirror.commands.replaceSingleWithoutDialogs = function(cm) { replaceSingleWithoutDialogs(cm);};
  });