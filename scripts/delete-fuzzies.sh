#!/usr/bin/env bash

# --- CONFIGURE YOUR KEYS HERE ---
KEYS=(
"microsite-yir-english-edits-bytes-slide-subtitle"
"microsite-yir-english-edits-bytes-slide-title"
"microsite-yir-english-edits-slide-subtitle"
"microsite-yir-english-edits-slide-title"
"microsite-yir-english-reading-slide-subtitle"
"microsite-yir-english-reading-slide-subtitle-short"
"microsite-yir-english-reading-slide-title"
"microsite-yir-english-saved-reading-slide-subtitle"
"microsite-yir-english-saved-reading-slide-title"
"microsite-yir-english-top-read-slide-subtitle"
"year-in-review-base-editors-title"
"year-in-review-base-edits-subtitle"
"year-in-review-base-edits-title"
"year-in-review-base-reading-subtitle"
"year-in-review-base-reading-title"
"year-in-review-base-saved-title"
"year-in-review-base-viewed-title"
"year-in-review-contributor-slide-subtitle-donor"
"year-in-review-contributor-slide-subtitle-editor"
"year-in-review-contributor-slide-subtitle-editor-and-donor"
"year-in-review-feature-explore-body-personalized"
"year-in-review-noncontributor-slide-subtitle"
"year-in-review-personalized-edit-views-subtitle-format"
"year-in-review-personalized-edit-views-title-format"
"year-in-review-personalized-editing-subtitle-2"
"year-in-review-personalized-editing-title-format"
"year-in-review-personalized-location-title-format"
"year-in-review-personalized-reading-subtitle-format-v3"
"year-in-review-personalized-reading-title-v3-format"
"year-in-review-personalized-saved-subtitle-format-v3"
)

# Build regex for matching
KEYS_REGEX=$(printf "%s|" "${KEYS[@]}")
KEYS_REGEX="${KEYS_REGEX%|}"

# Move from scripts/ → project root
cd "$(dirname "$0")/.."

find Wikipedia/Localizations -type f -path "*/Localizable.strings" | while read -r file; do
  echo "Processing: $file"

  awk -v keys="$KEYS_REGEX" '
    {
      # Detect a fuzzy marker line
      if ($0 == "// Fuzzy") {

        # Read the next line (the key line)
        getline nextline

        # If this next line contains one of the target keys…
        if (nextline ~ "\"" keys "\"") {

          # Extract the key manually (POSIX compatible)
          keyline = nextline
          start = index(keyline, "\"")
          if (start > 0) {
            rest = substr(keyline, start + 1)
            end = index(rest, "\"")
            if (end > 0) {
              foundKey = substr(rest, 1, end - 1)
              print "Removed key: " foundKey > "/dev/stderr"
            }
          }

          # Delete: skip both lines
          next
        } else {
          # Keep the fuzzy line and the next line
          print $0
          print nextline
        }

      } else {
        # Normal line
        print $0
      }
    }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

done
