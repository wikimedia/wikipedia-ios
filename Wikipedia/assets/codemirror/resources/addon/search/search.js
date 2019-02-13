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
  
    function searchOverlay(query, caseInsensitive) {
      if (typeof query == "string")
        query = new RegExp(query.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"), caseInsensitive ? "gi" : "g");
      else if (!query.global)
        query = new RegExp(query.source, query.ignoreCase ? "gi" : "g");
  
      return {token: function(stream) {
        query.lastIndex = stream.pos;
        var match = query.exec(stream.string);
        if (match && match.index == stream.pos) {
          stream.pos += match[0].length || 1;
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
      return typeof query == "string" && query == query.toLowerCase();
    }
  
    function getSearchCursor(cm, query, pos) {
      // Heuristic: if the query string is all lowercase, do a case insensitive search.
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
      state.overlay = searchOverlay(state.query, queryCaseInsensitive(state.query));
      cm.addOverlay(state.overlay);
      if (cm.showMatchesOnScrollbar) {
        if (state.annotate) { state.annotate.clear(); state.annotate = null; }
        state.annotate = cm.showMatchesOnScrollbar(state.query, queryCaseInsensitive(state.query));
      }
    }
  
    function doSearch(cm, rev, focus) {
      var state = getSearchState(cm);
      if (state.query) return findNext(cm, rev, focus);
      var q = cm.getSelection() || state.lastQuery;
      if (q instanceof RegExp && q.source == "x^") q = null
      const query = cm.state.query;
      if (query && !state.query) cm.operation(function () {
        startSearch(cm, state, query);
        state.posFrom = state.posTo = cm.getCursor();
        findNext(cm, rev);
      });
      focusOnMatch(state)
    }

    function clearFocusedMatches(cm) {
      const focusClassName = "cm-searching-focus";
      const focusedElements = document.getElementsByClassName(focusClassName);
      const focusedMatchID = getSearchState(cm).focusedMatchID;

      while (focusedElements.length > 0) {
        var element = focusedElements[0];
        element.classList.remove(focusClassName);
        if (element.id === focusedMatchID) element.id = "";
      }
    } 

    function focusOnMatch(state, focus) {
      const matches = document.getElementsByClassName("cm-searching");
      const matchesCount = matches.length;
      var focusedMatchIndex = state.focusedMatchIndex || 0;

      if (focus) {
        if (focus.next) {
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

      const focusedMatchID = `cm-searching-focus-id-${focusedMatchIndex}`;
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
    }

    function focusOnMatchAtIndex(matches, index, id) {
      if (matches.length == 0) return null;
      const focusClassName = "cm-searching-focus";
      const match = matches[index];
      if (!match) return null;
      match.classList.add(focusClassName);
      match.id = id;
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
  
    function findNext(cm, rev, focus) {cm.operation(function() {
      var state = getSearchState(cm);
      var cursor = getSearchCursor(cm, state.query, rev ? state.posFrom : state.posTo);
      if (!cursor.find(rev)) {
        cursor = getSearchCursor(cm, state.query, rev ? CodeMirror.Pos(cm.lastLine()) : CodeMirror.Pos(cm.firstLine(), 0));
        if (!cursor.find(rev)) return;
      }
      state.posFrom = cursor.from(); state.posTo = cursor.to();
      if (focus) focusOnMatch(state, focus)
    });}
  
    function clearSearch(cm) {cm.operation(function() {
      var state = getSearchState(cm);
      state.lastQuery = state.query;
      if (!state.query) return;
      clearFocusedMatches(cm);
      state.focusedMatchIndex = null
      state.query = state.queryText = null;
      cm.removeOverlay(state.overlay);
      if (state.annotate) { state.annotate.clear(); state.annotate = null; }
    });}
  
    function replaceAll(cm, query, text) {
      cm.operation(function() {
        for (var cursor = getSearchCursor(cm, query); cursor.findNext();) {
          if (typeof query != "string") {
            var match = cm.getRange(cursor.from(), cursor.to()).match(query);
            cursor.replace(text.replace(/\$(\d)/g, function(_, i) {return match[i];}));
          } else cursor.replace(text);
        }
      });
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
  
    CodeMirror.commands.find = function(cm) {clearSearch(cm); doSearch(cm);};
    CodeMirror.commands.findNext = function(cm) {clearFocusedMatches(cm); doSearch(cm, false, {next: true});};
    CodeMirror.commands.findPrev = function(cm) {clearFocusedMatches(cm); doSearch(cm, true, {prev: true});};
    CodeMirror.commands.clearSearch = clearSearch;
    CodeMirror.commands.replace = replace;
    CodeMirror.commands.replaceAll = function(cm) {replace(cm, true);};
  });