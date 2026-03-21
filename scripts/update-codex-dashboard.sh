#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_REPO="${1:-${CODEX_USAGE_DASHBOARD_REPO:-$PROFILE_ROOT/../codex-usage-dashboard}}"
OUTPUT_PATH="$PROFILE_ROOT/assets/codex-stats-dashboard.png"
README_PATH="$PROFILE_ROOT/README.md"

if [[ ! -d "$DASHBOARD_REPO/.git" ]]; then
  echo "Dashboard repo not found at: $DASHBOARD_REPO" >&2
  echo "Pass the repo path as the first argument or set CODEX_USAGE_DASHBOARD_REPO." >&2
  exit 1
fi

if [[ ! -x "$DASHBOARD_REPO/node_modules/.bin/bun" ]]; then
  echo "Bun runtime not found at: $DASHBOARD_REPO/node_modules/.bin/bun" >&2
  echo "Run 'npm install' in $DASHBOARD_REPO first." >&2
  exit 1
fi

mkdir -p "$PROFILE_ROOT/assets"

(
  cd "$DASHBOARD_REPO"
  OUTPUT_PATH="$OUTPUT_PATH" ./node_modules/.bin/bun -e "
    import { calculateDashboardStats } from './src/stats.ts';
    import { generateImage } from './src/image/generator.tsx';

    const outputPath = process.env.OUTPUT_PATH;
    if (!outputPath) {
      throw new Error('OUTPUT_PATH is required');
    }

    const stats = await calculateDashboardStats();
    const image = await generateImage(stats);
    await Bun.write(outputPath, image.fullSize);
    console.log('Wrote ' + outputPath);
  "
)

GENERATED_AT_UTC="$(date -u '+%Y-%m-%d %H:%M UTC')"

printf '%s\n' \
  '# Anthony Russano' \
  '' \
  '## Codex Usage Dashboard' \
  '' \
  '<p align="center">' \
  '  <img src="./assets/codex-stats-dashboard.png" alt="Anthony Russano Codex usage dashboard" width="900" />' \
  '</p>' \
  '' \
  "Last updated: $GENERATED_AT_UTC" \
  '' \
  'Generated with [`codex-usage-dashboard`](https://github.com/anthonyrussano/codex-usage-dashboard).' \
  > "$README_PATH"

echo "Updated $README_PATH"
