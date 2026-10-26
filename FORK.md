# Tile Markers + Sprites

Development fork of [PrettyRS/TileMarkers](https://github.com/PrettyRS/tilemarkers), based on commit `339a8af30ce539df745aefbdbfa678d242115f8d` (1.2.1). The upstream license is retained unchanged in LICENSE. The original project and contributors do not endorse this fork.

## Install / test

The runtime folder is **tilemarkers-sprites**. It depends on PrettyUI (6398181) and the separately installed **rsprite** development library. [RSprite installation](https://github.com/sereselene/rsprite#installing) uses a sibling `rsprite` folder and dependency alias `rsprite`. This fork was developed against RSprite 0.1.2 at `fdd79f9d918f1ece1e24c208403b78f3b86d28d6`. RSprite is not on the Plugin Hub yet.

RSprite's current upstream license is PolyForm Strict, not the MIT license shown by some cached pages. Its author explicitly documents use as a separate dependency. No RSprite source or assets are included in this fork or its distributable. Install the unmodified upstream library separately and retain its notices. Do not publish a bundle containing RSprite under this fork's license.

Disable the original Tile Markers in the Plugin Hub while testing this fork, so two plugins do not handle the same marking shortcut and draw overlapping markers. The original plugin and its database are not replaced.

In the developer console:

```text
prf
pon rsprite
pon tilemarkers-sprites
```

Use `prl tilemarkers-sprites` for subsequent reloads. PrettyUI must also be enabled; the manifest declares it as a required dependency. This plugin requests no permissions and performs no HTTP requests.

## Place a sprite

1. Hold **Ctrl+Shift** (or your configured marking keybind), right-click a tile and choose **Mark tile**.
2. Right-click it again with the keybind held and choose **Set Tile Sprite**.
3. Search RSprite names/aliases, page through six matches at a time, and click a result. Or enter an exact sprite name or numeric ID.
4. Adjust size (**8–128 interface units**) and opacity (**0–100%**). The selected icon previews on the tile and in the dialog.
5. Choose **Save sprite**. Cancel or closing the dialog discards the preview. **Remove sprite** clears the draft; Save commits removal.

Normal tile outlines, fills, labels, customization and presets remain available. Labels move above icons. Icons use white tint to preserve their original colours. Unavailable or RSprite-blocked sprites are not drawn; arbitrary Lua expressions and file paths are not accepted.

Icons are screen-facing overlays projected from tile centres, at a fixed interface size. They follow the tile as the camera moves, use the same floor/range culling as marker labels, and do not intercept clicks. They are not perspective-warped textures painted on the ground. Scenery depth settings affect the original shapes; these overlay icons behave like labels and may appear over scenery.

## Presets and storage

Sprite metadata is stored in the fork's own PersistentDB, alongside each tile's existing style. Original TileMarkers data is isolated; export its presets and import their **TM2** tokens here to transfer markers without copying databases.

Sprite-free exports remain byte-compatible **TM2** tokens. Presets containing sprites use **TM3**, adding a bounded sprite section to the existing encoding. This fork reads both. Original TileMarkers does not understand TM3. Sprite source, size and opacity survive preset editing, region remapping, activation, export/import and reload. Exported opacity is quantized to an 8-bit alpha, matching rendering. Normal colour/label edits preserve sprites. Saving a direct sprite rolls back its metadata if persistence fails.

To change an icon on a preset-owned tile, use **Edit in preset**, then the same **Set Tile Sprite** menu. Save the preset from the edit overlay to persist the working copy; cancelling the preset edit discards it.

## Build and checks

`python tools/package.py` creates `dist/tilemarkers-sprites-dev.zip` with runtime files, README, attribution and license only. It excludes Git metadata, tests, databases, and all dependency code/assets. The workspace-level builder also supports `python tools/package_plugin.py tilemarkers-sprites`.

Install Python package `lupa`, then run `python tests/run.py` to execute the original upstream Lua tests and the new sprite contracts in isolated Lua 5.4 states. The tests cover picker search/validation/preview/cancel, sprite persistence/rollback, TM2 compatibility/TM3 round trips, preset storage and region remapping, and range/floor/removal rendering. Native sprite loading, dialog input, camera movement/zoom/interface scale, real instances, and clean shutdown still need an in-game pass.
