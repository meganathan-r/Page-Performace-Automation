API_KEY="AIzaSyAZ0joOqb5bq39UJNZzG_zuVDAj4teuVNc"
URL_FILE="urls.txt"
OUT_FILE="psi_log.csv"

# header once
echo "DATE,URL,PERF" > "$OUT_FILE"

for STRATEGY in mobile desktop; do
  while IFS= read -r URL || [[ -n $URL ]]; do
    printf '→ %s %s\n' "$STRATEGY" "$URL"   # progress

    JSON=$(curl -sS --fail \
      "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${URL}&strategy=${STRATEGY}&category=performance&category=accessibility&category=best-practices&category=seo&key=${API_KEY}") \
      || { echo "curl fail ⇒ skip $URL" >&2; continue; }

    # field: use origin fallback if url-level missing
    LCP=$(jq -r '(.loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.percentile //
                  .originLoadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.percentile //
                  "NA")' <<<"$JSON")
    INP=$(jq -r '(.loadingExperience.metrics.INTERACTION_TO_NEXT_PAINT_MS.percentile //
                  .originLoadingExperience.metrics.INTERACTION_TO_NEXT_PAINT_MS.percentile //
                  "NA")' <<<"$JSON")
    CLS=$(jq -r '(.loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile //
                  .originLoadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile //
                  "NA")' <<<"$JSON")

    # lab scores (always present)
    PERF=$(jq -r '.lighthouseResult.categories.performance.score             // "NA"' <<<"$JSON")
    ACC=$(jq  -r '.lighthouseResult.categories.accessibility.score          // "NA"' <<<"$JSON")
    BEST=$(jq -r '.lighthouseResult.categories["best-practices"].score      // "NA"' <<<"$JSON")
    SEO=$(jq  -r '.lighthouseResult.categories.seo.score                    // "NA"' <<<"$JSON")

    printf '%s-%s-%s-%s\n' \
      "$(date -Iseconds)" "$STRATEGY" "$URL" \
       "$PERF" >> "$OUT_FILE"

    sleep 1   # stay under PSI rate-limit
  done < "$URL_FILE"
done