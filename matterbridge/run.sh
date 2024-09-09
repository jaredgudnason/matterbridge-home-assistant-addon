#!/usr/bin/with-contenv bashio

CONFIG_INCLUDE_DOMAINS=$(bashio::config 'include_domains' | jq --raw-input --compact-output --slurp 'split("\n")')
CONFIG_EXCLUDE_DOMAINS=$(bashio::config 'exclude_domains' | jq --raw-input --compact-output --slurp 'split("\n")')

CONFIG_INCLUDE_PATTERNS=$(bashio::config 'include_patterns' | jq --raw-input --compact-output --slurp 'split("\n")')
CONFIG_EXCLUDE_PATTERNS=$(bashio::config 'exclude_patterns' | jq --raw-input --compact-output --slurp 'split("\n")')

CONFIG_INCLUDE_LABELS=$(bashio::config 'include_labels' | jq --raw-input --compact-output --slurp 'split("\n")')
CONFIG_EXCLUDE_LABELS=$(bashio::config 'exclude_labels' | jq --raw-input --compact-output --slurp 'split("\n")')

CONFIG_INCLUDE_PLATFORMS=$(bashio::config 'include_platforms' | jq --raw-input --compact-output --slurp 'split("\n")')
CONFIG_EXCLUDE_PLATFORMS=$(bashio::config 'exclude_platforms' | jq --raw-input --compact-output --slurp 'split("\n")')

MATCHER=$(jq --null-input --compact-output \
  --argjson includeDomains "$CONFIG_INCLUDE_DOMAINS" \
  --argjson excludeDomains "$CONFIG_EXCLUDE_DOMAINS" \
  --argjson includePatterns "$CONFIG_INCLUDE_PATTERNS" \
  --argjson excludePatterns "$CONFIG_EXCLUDE_PATTERNS" \
  --argjson includeLabels "$CONFIG_INCLUDE_LABELS" \
  --argjson excludeLabels "$CONFIG_EXCLUDE_LABELS" \
  --argjson includePlatforms "$CONFIG_INCLUDE_PLATFORMS" \
  --argjson excludePlatforms "$CONFIG_EXCLUDE_PLATFORMS" \
  '{ "includeDomains": $includeDomains, "excludeDomains": $excludeDomains, "includePatterns": $includePatterns, "excludePatterns": $excludePatterns, "includeLabels": $includeLabels, "excludeLabels": $excludeLabels, "includePlatforms": $includePlatforms, "excludePlatforms": $excludePlatforms }'
)

HOME_ASSISTANT_CONFIG=$(jq --null-input --compact-output \
  --argjson matcher "$MATCHER" \
  --arg accessToken "$SUPERVISOR_TOKEN" \
  '{ "url": "http://supervisor/core", "accessToken": $accessToken, "matcher": $matcher }'
)

OVERRIDES_CONFIG=$(bashio::config 'overrides')

MHA_CONFIG=$(jq --null-input --compact-output \
  --argjson homeAssistant "$HOME_ASSISTANT_CONFIG" \
  --argjson overrides "$OVERRIDES_CONFIG" \
  '{ "homeAssistant": $homeAssistant, "overrides": $overrides }'
)

FRONTEND_PORT=$(bashio::config 'frontend_port')
MATTER_PORT=$(bashio::config 'matter_port')

echo "#############################"
echo "CURRENT CONFIGURATION:"
echo "$MHA_CONFIG" | jq
echo "#############################"

export LOG_LEVEL
export MHA_CONFIG

# Workaround to fix https://github.com/t0bst4r/matterbridge-home-assistant/issues/115
if grep -q /app/node_modules/matterbridge-home-assistant ~/.matterbridge/storage/.matterbridge/*; then
  sed -i 's/\/app\/node_modules\/matterbridge-home-assistant/\/usr\/local\/lib\/node_modules\/matterbridge-home-assistant/g' ~/.matterbridge/storage/.matterbridge/*
fi

matterbridge -add matterbridge-home-assistant

MATTERBRIDGE_OPTIONS=("-childbridge" "-docker" "-port $MATTER_PORT" "-frontend $FRONTEND_PORT")

matterbridge "${MATTERBRIDGE_OPTIONS[@]}"
