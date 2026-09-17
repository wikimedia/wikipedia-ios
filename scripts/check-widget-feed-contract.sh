#!/usr/bin/env bash
# Decodes today's live feed/featured payload with the widget models from this checkout, for a few
# languages, and fails when a section fails to decode or an element inside a section is dropped.
# The widgets tolerate both at runtime, but each one is a feed change worth knowing about before
# it becomes "every widget is broken today".
#
# Usage: scripts/check-widget-feed-contract.sh [language ...]   (default: en de ja ar zh)
# Needs: swiftc, curl, python3. Runs on macOS and Linux with a Swift toolchain.
set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIRECTORY="$REPOSITORY_ROOT/WMF Framework/Widget/Models"
WORK_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "$WORK_DIRECTORY"' EXIT

LANGUAGES=("$@")
if [ ${#LANGUAGES[@]} -eq 0 ]; then
    LANGUAGES=(en de ja ar zh)
fi

USER_AGENT="WikipediaApp-iOS-feed-contract-check (https://github.com/wikimedia/wikipedia-ios)"
DATE_PATH="$(date -u +%Y/%m/%d)"

# The models depend only on Foundation. WidgetSettings/WidgetCache are left out: not needed.
cat "$MODELS_DIRECTORY/WidgetLossyDecodingArray.swift" \
    "$MODELS_DIRECTORY/WidgetContentURL.swift" \
    "$MODELS_DIRECTORY/WidgetTitles.swift" \
    "$MODELS_DIRECTORY/WidgetImageSource.swift" \
    "$MODELS_DIRECTORY/WidgetFeaturedArticle.swift" \
    "$MODELS_DIRECTORY/WidgetTopRead.swift" \
    "$MODELS_DIRECTORY/WidgetOnThisDayElement.swift" \
    "$MODELS_DIRECTORY/WidgetPictureOfTheDay.swift" \
    "$MODELS_DIRECTORY/WidgetFeaturedContent.swift" \
    > "$WORK_DIRECTORY/models.swift"

cat > "$WORK_DIRECTORY/main.swift" <<'SWIFT'
import Foundation

let path = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: path))
var problems: [String] = []
var content: WidgetFeaturedContent
do {
    content = try JSONDecoder().decode(WidgetFeaturedContent.self, from: data)
} catch {
    print("  payload is not decodable at all: \(WidgetDecodingErrorDescription.describe(error))")
    exit(1)
}
let sections = WidgetFeaturedContent.Section.allCases.filter { content.hasContent(for: $0) }.map { $0.rawValue }
print("  decoded sections: \(sections.joined(separator: ", "))")
for (section, error) in content.sectionDecodingErrors.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
    problems.append("section '\(section.rawValue)' failed to decode: \(error)")
}
for (section, errors) in content.droppedElementErrors.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
    for error in errors {
        problems.append("section '\(section.rawValue)' dropped an element: \(error)")
    }
}
if let pictureOfTheDay = content.pictureOfTheDay {
    if pictureOfTheDay.description == nil { print("  note: image has no description (widget shows it without a caption)") }
    if pictureOfTheDay.license == nil { print("  note: image has no license") }
}
for problem in problems {
    print("  PROBLEM: \(problem)")
}
exit(problems.isEmpty ? 0 : 1)
SWIFT

echo "Compiling widget models..."
if ! swiftc -O -o "$WORK_DIRECTORY/check" "$WORK_DIRECTORY/models.swift" "$WORK_DIRECTORY/main.swift" > "$WORK_DIRECTORY/swiftc.log" 2>&1; then
    echo "Could not compile the widget models:"
    cat "$WORK_DIRECTORY/swiftc.log"
    exit 1
fi

FAILED_LANGUAGES=()
for LANGUAGE in "${LANGUAGES[@]}"; do
    URL="https://$LANGUAGE.wikipedia.org/api/rest_v1/feed/featured/$DATE_PATH"
    PAYLOAD="$WORK_DIRECTORY/$LANGUAGE.json"
    echo "$LANGUAGE: $URL"
    HTTP_STATUS="$(curl -sS -A "$USER_AGENT" -o "$PAYLOAD" -w "%{http_code}" "$URL" || echo "000")"
    if [ "$HTTP_STATUS" != "200" ]; then
        echo "  PROBLEM: HTTP $HTTP_STATUS"
        FAILED_LANGUAGES+=("$LANGUAGE")
        continue
    fi
    if ! "$WORK_DIRECTORY/check" "$PAYLOAD"; then
        FAILED_LANGUAGES+=("$LANGUAGE")
    fi
done

if [ ${#FAILED_LANGUAGES[@]} -gt 0 ]; then
    echo
    echo "Feed contract problems for: ${FAILED_LANGUAGES[*]}"
    exit 1
fi
echo
echo "All feeds decode cleanly."
