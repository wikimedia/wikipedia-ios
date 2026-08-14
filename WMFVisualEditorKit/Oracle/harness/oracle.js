/**
 * Oracle API over VisualEditor's document model, driven by run_oracle.swift.
 *
 * For a given Parsoid HTML string this converts HTML → linear model → HTML twice,
 * so the runner can assert idempotence (round trip 2 must equal round trip 1),
 * and dumps the linear model for use as differential-test fixtures by the
 * future Swift implementation.
 */
/* global ve */

(function () {
	'use strict';

	function convertOnce(html) {
		const inputDocument = ve.createDocumentFromHtml(html);
		const model = ve.dm.converter.getModelFromDom(inputDocument, { lang: 'en', dir: 'ltr' });
		const outputDocument = ve.dm.converter.getDomFromModel(model);
		return {
			model: model,
			html: outputDocument.body.innerHTML
		};
	}

	// Linear data can reference DOM nodes through the hash-value store; keep the
	// dump JSON-safe and stable by keeping only primitive structure.
	function dumpLinearData(model) {
		const data = model.data.data;
		const dumped = [];
		for (let index = 0; index < data.length; index++) {
			const item = data[index];
			if (typeof item === 'string') {
				dumped.push(item);
			} else if (Array.isArray(item)) {
				dumped.push([item[0], item[1]]);
			} else {
				dumped.push(JSON.parse(JSON.stringify(item, function (key, value) {
					if (value instanceof Node || typeof value === 'function') {
						return undefined;
					}
					return value;
				})));
			}
		}
		return dumped;
	}

	function nodeTypeCounts(linearData) {
		const counts = {};
		for (const item of linearData) {
			if (item && typeof item === 'object' && !Array.isArray(item) && item.type && item.type[0] !== '/') {
				counts[item.type] = (counts[item.type] || 0) + 1;
			}
		}
		return counts;
	}

	window.wmfOracle = {
		version: function () {
			return {
				veVersion: ve.version || null,
				userAgent: navigator.userAgent
			};
		},

		process: function (html, includeLinearData) {
			try {
				// Captured with a fresh parse because the converter takes ownership of
				// (and mutates) the document handed to it.
				const inputBodyHTML = ve.createDocumentFromHtml(html).body.innerHTML;
				const first = convertOnce(html);
				const second = convertOnce(first.html);
				const linearData = dumpLinearData(first.model);
				return {
					ok: true,
					firstHTML: first.html,
					idempotent: first.html === second.html,
					inputMatchesOutput: inputBodyHTML === first.html,
					linearLength: linearData.length,
					nodeTypeCounts: nodeTypeCounts(linearData),
					linearData: includeLinearData ? linearData : null
				};
			} catch (error) {
				return {
					ok: false,
					error: String(error && error.message || error),
					stack: String(error && error.stack || '')
				};
			}
		}
	};
}());
