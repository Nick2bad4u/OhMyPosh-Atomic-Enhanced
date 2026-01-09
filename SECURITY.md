# Security & Privacy

This repository **does not store secrets**. Oh My Posh reads credentials directly from **environment variables** (for example API keys for weather/music/fitness integrations).

## External network calls

Some segments and tooltips are configured to make outbound HTTP requests to enrich the prompt. Common examples in this repo:

- **Weather (`owm`)**: calls OpenWeatherMap.
- **Public IP (`ipify`)**: calls ipify to display IPv4/IPv6.
- **Package/tool version tooltips (`http`)**: calls public endpoints such as the npm registry (e.g. `https://registry.npmjs.org/<package>/latest`).
- Optional integrations used by some themes/tooltips (depending on your enabled segments): **Last.fm (`lastfm`)**, **Strava (`strava`)**, **Withings (`withings`)**, **WakaTime (`wakatime`)**, **Brewfather (`brewfather`)**.

These calls are typically protected with **timeouts** and **caching** in the theme config, but they are still outbound requests.

## Disabling network calls (recommended)

Use the included script to generate a **NoNetwork** variant of a theme that removes all segments/tooltips that can make outbound requests.

Examples (run from repo root):

```pwsh
# Create an offline variant of the main theme
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom.json

# Create an offline variant of the ExperimentalDividers theme
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

The script will output a sibling file with the suffix `.NoNetwork.json`.

Then use the generated config:

```pwsh
oh-my-posh init pwsh --config .\OhMyPosh-Atomic-Custom.NoNetwork.json | Invoke-Expression
```

## Disabling network calls (manual)

If you prefer to edit JSON directly, remove (or disable) segments/tooltips with these types:

- `http`
- `ipify`
- `owm`
- `lastfm`
- `strava`
- `withings`
- `wakatime`
- `brewfather`

## Reporting security issues

If you believe you have found a security issue (for example: a secret committed to the repo, or a workflow vulnerability), please open a GitHub issue with details and remove/rotate any affected credentials immediately.
