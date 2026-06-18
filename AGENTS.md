# AGENTS.md — OmniSegger (SuperSegger 2)

Compact orientation for AI agents. Every item here is something you'd likely miss without reading the codebase.

---

## What this repo is

A MATLAB + Python scientific pipeline for bacterial time-lapse microscopy segmentation and tracking. Based on [SuperSegger-Omnipose](https://github.com/tlo-bot/supersegger-omnipose). **No build system, no package manager, no CI, no test suite, no linter.**

All source code is under `SuperSegger-master/`. The root contains only docs, assets, and a MATLAB Drive marker (`.MATLABDriveTag` — ignore it).

---

## MATLAB path setup (no install script)

Add `SuperSegger-master/` with all subfolders to MATLAB path via:
Home → Environment → Set Path → "Add Folder with Subfolders"

If original SuperSegger is already on the path, **replace** its entries with OmniSegger's — function shadowing will break things silently.

**Required MATLAB toolboxes** (checked at runtime by `intCheckForInstallLib`; pipeline exits if missing):
- Image Processing Toolbox
- Neural Network Toolbox (Deep Learning Toolbox)
- Statistics and Machine Learning Toolbox
- Optimization Toolbox
- Global Optimization Toolbox

Optional: Parallel Computing Toolbox (enables xy-parallel mode).

---

## Python / Omnipose setup

```bash
conda create -n omnipose 'python==3.10.12' pytorch
conda activate omnipose
git clone https://github.com/kevinjohncutler/omnipose.git
cd omnipose
pip install -e .
```

Stable alternative: `pip install omnipose` (if mahotas errors: `pip install numpy` first, then retry).

Remove conflicting old package if present: `pip uninstall cellpose_omni && pip cache remove cellpose_omni`

ND2 conversion deps (into omnipose env): `pip install aicsimageio[nd2] bioformats-jar`

**The Python files in `SuperSegger-master/omnipose_files/` (`io.py`, `transforms.py`) are patched Omnipose internals — they are NOT auto-installed.** Follow `docs/install_omnipose.md` for the manual copy step.

---

## Image naming convention (strict)

```
[basename]t[time]xy[xy]c[channel].tif
```
- `t`: 5-digit zero-padded (`%05d`)
- `xy`: 3-digit zero-padded (`%03d`)
- `c1` = phase contrast (always required); `c2`, `c3` = fluorescence channels

Convert from other naming:
```matlab
convertImageNames(dirname)               % interactive MATLAB
% or
superSeggerGui → "Convert Image Names"
% or (ND2 files)
python SuperSegger-master/Internal/nd2totiff.py /path/to/file.nd2
```

`convertImageNames` moves originals to `dirname/original/`, copies renamed files to `dirname/`. It silently returns if files are already in NIS-Elements format or already aligned.

---

## Running the pipeline

### Non-GUI (recommended)
```matlab
processExp('dirname')            % all defaults
processExp('dirname', 1)         % + save clist as .xls
processExp('dirname', [], 1)     % + auto-run Omnipose from MATLAB
processExp('dirname', 1, 1)      % + both
processExp('dirname', [], [], 1) % + write output_log.txt
```

`processExp` is a thin wrapper: edit it directly to change constants before it calls `BatchSuperSeggerOpti`. The `convertImageNames` call near the top is commented-in by default — **check and disable it if your images are already correctly named**, or it will try to rename them on every run.

### GUI
```matlab
superSeggerGui
```

### Direct call (for partial re-runs)
```matlab
BatchSuperSeggerOpti(dirname, skip, cleanflag, CONST, startEnd, showWarnings, autoomni)
% Example: restart from linking onward
BatchSuperSeggerOpti(dirname, 1, false, CONST, [4 10])
```

### Listing available constants presets
```matlab
[~, list] = getConstantsList; list'
```

### Testing segmentation constants on one image (without full pipeline)
```matlab
data = tryDifferentConstants('path/to/image.tif')  % tries all presets
data = tryDifferentConstants('path/to/image.tif', {'60XEc','100XEc'})  % specific presets
```

---

## Pipeline step order

Steps are sequential per xy position; multiple xy positions can run in parallel (outer `parfor` in `BatchSuperSeggerOpti`).

The true call chain is:
```
processExp → BatchSuperSeggerOpti → intProcessXY (parfor over xy)
                                        ├── trackOptiAlignPad   (step 1)
                                        ├── trackOptiPD         (step 2, dir setup)
                                        ├── [Omnipose external] (step 3)
                                        ├── doSeg (parfor over frames) (step 3/4)
                                        └── trackOpti           (steps 4–10)
                                               ├── trackOptiLinkCellMulti  (step 4)
                                               ├── [trackOptiSkipMerge if skip>1]
                                               ├── trackOptiCellMarker     (step 5)
                                               ├── trackOptiFluor          (step 6)
                                               ├── trackOptiMakeCell       (step 7)
                                               ├── saveosmasks             (automatic)
                                               ├── trackOptiFindFoci       (step 8, if numSpots>0)
                                               ├── trackOptiClist          (step 9)
                                               └── trackOptiCellFiles      (step 10)
```

`startEnd` numbers (for `BatchSuperSeggerOpti`'s 6th arg):
- 1 = alignment
- 2 = segmentation (doSeg)
- 3 = stripping (trackOptiStripSmall — currently disabled/commented out)
- 4 = linking (trackOptiLinkCellMulti)
- 5 = cell marker
- 6 = fluorescence
- 7 = foci (trackOptiFindFoci)
- 8 = cellA structures (trackOptiMakeCell)
- 9 = clist
- 10 = cell files

**The pipeline always pauses after alignment** for Omnipose to run (unless `autoomni=1`). This is by design — Omnipose command is printed to MATLAB Command Window and copied to clipboard.

Resume: completed steps are skipped via hidden stamp files in `xy*/seg/` (e.g., `.doSegFull`, `.trackOptiLinkCell-Step2.mat`). To force restart, `cleanflag = true` prompts confirmation (or skips prompt in eval mode).

Partial restart:
```matlab
BatchSuperSeggerOpti(dirname, skip, false, CONST, [4 10])  % restart at linking
```

---

## Stamp files and resume logic

Each major step saves a hidden `.mat` stamp file in `xy*/seg/`. If the stamp exists, the step is skipped. `cleanSuperSegger.m` deletes the appropriate stamps (and data files) when restarting from a given step.

| Step | Stamp file name |
|------|-----------------|
| doSeg | `.doSegFull` |
| Linking | `.trackOptiLinkCell-Step2.mat` |
| Skip merge (if skip>1) | `.trackOptiSkipMerge-Step2merge.mat` |
| Cell marker | `.trackOptiCellMarker-Step3.mat` |
| Fluor | `.trackOptiFluor-Step4.mat` |
| MakeCell | `.trackOptiMakeCell-Step5.mat` |
| FindFoci | `.trackOptiFindFoci-Step6.mat` |
| Clist | `.trackOptiClist-Step7.mat` |
| Cell files | `.trackOptiCellFiles-Step8.mat` |

To manually delete stamps for a specific step, delete the corresponding `.mat` file from `xy*/seg/` and rerun.

---

## Batch processing internals

### `BatchSuperSeggerOpti.m`
- Accepts `res` as either a string preset name (e.g. `'60XEc'`) or a full `CONST` struct — `processExp` always passes a struct.
- If `loadConstantsMine` exists on the MATLAB path, it is preferred over `loadConstants` (`BatchSuperSeggerOpti.m:97–101`).
- Parallelism: if `num_xy > 1` and `parallel_pool_num > 0`, the outer loop over xy positions is parallelized (`parfor`). Within a parallelized outer loop, `parallel_pool_num` is forced to 0 for inner loops (to avoid nested pools).
- After alignment, moves originals to `raw_im/` and aligned images back to the main folder; removes the temporary `align/` directory.
- After Omnipose, deletes `xy*/cp_output/` (a CLI artifact).

### `doSeg.m` (frame segmentation)
- Skips frames according to `skip` parameter: only processes frame `i` if `~mod(i-1, skip)`.
- Loads phase image from `xy*/phase/`, loads fluor images from `xy*/fluor1/`, `xy*/fluor2/`, etc.
- Calls `CONST.seg.segFun` (set in the constants file) for segmentation — defaults to `superSeggerOpti`.
- `superSeggerOpti` uses watershed + neural network scoring to classify segment boundaries as real or spurious.
- Saves `*_seg.mat` in `xy*/seg/`. If file already exists, skips silently.
- For z-stacks: averages across z slices before segmenting.

### `trackOptiLinkCellMulti.m` (cell linking)
- Operates on `*_seg.mat` files (or `*_err.mat` if they already exist).
- Processes frames sequentially (time-ordered while loop — not parallelized).
- Uses `CONST.trackOpti.linkFun` (default: `@multiAssignmentSparse`) to compute assignment between frames.
- Calls `errorRez` for each frame to resolve linking inconsistencies.
- Saves `*_err.mat` files (replacing `*_seg.mat` as the active data).
- Can restart mid-sequence: `startFrom` parameter; pass `-1` to relink without deleting existing err files.

### `errorRez.m` (error resolution)
- Runs within `trackOptiLinkCellMulti` for each frame.
- Tries up to `maxIterPerFrame = 3` iterations per frame before accepting errors as-is (`finalIteration = true`).
- Key behaviors:
  - Stray regions (no backward mapping): deleted if `REMOVE_STRAY=true` and no forward mapping; else become new cells.
  - 1-to-1 mapping: continue cell line.
  - Division event (1 mother → 2 daughters): marks division if area change is within `[DA_MIN, DA_MAX]`.
  - Merge (2 cells → 1): merges regions if area change is consistent.
  - Missing segment: calls `missingSeg2to1` to try inserting a segment.
- `CONST.ignoreerror = 1` disables all merging/splitting; cells get new IDs instead. Set this when trusting Omnipose masks over error correction.

### `trackOptiClist.m` (primary output)
- Reads all `*_err.mat` files sequentially.
- Fields recorded "at birth" vs "at death" (division/end of movie) — controlled by column 3 of `clistSetter`.
- Also builds `clist.data3D` (cells × variables × time) for time-resolved analysis.
- Automatically computes growth rate (`log(L_death/L_birth) / age`) and lineage info (generation, progenitor ID).
- Adds computed gate from `CONST.trackLoci.gate` if set.
- To inspect column definitions: `clist.def'` (2D) or `clist.def3D'` (3D).

### `saveosmasks.m` — runs automatically
- Called unconditionally inside `trackOpti` after `trackOptiMakeCell` completes.
- Saves post-linking OmniSegger masks (from `*_err.mat` `regs.regs_label`) as PNG files to `xy*/masksOS/`.
- Prints "masksOS directory already exists" if rerunning — harmless warning.

---

## Omnipose: canonical command

Auto-generated by `genOmniposeCommand` in `BatchSuperSeggerOpti.m:436–443`:

```bash
conda activate omnipose
python -m omnipose --dir <xy*/phase/> --save_png --dir_above --no_npy \
  --in_folders --omni --pretrained_model bact_phase_omni \
  --cluster --mask_threshold 1 --flow_threshold 0 \
  --diameter 30 --exclude_on_edges
```

**Do not change options before `--omni`** — they control folder structure that OmniSegger depends on.

Tunable options:
- `--mask_threshold 1` — decrease to find more/larger masks (default 0)
- `--flow_threshold 0` — error threshold (0 = off; default 0.4)
- `--diameter 30` — cell short-axis in pixels (0 = auto)
- `--cluster` — DBscan clustering, reduces oversegmentation
- `--exclude_on_edges` — discard border cells
- `--use_gpu`, `--affinity_seg`, `--tile` — optional extras

Test parameters interactively: `python -m omnipose` (Omnipose GUI).

Mask folder logic: if `xy*/cp_masks/` (or `xy*/masks/`) doesn't exist or has fewer masks than phase images → Omnipose runs. If count matches → skipped.

**Auto-run from MATLAB (Linux/macOS):** conda bin/condabin must be in MATLAB's `PATH`. Verify with `[status,~] = system('source activate omnipose')` — must return `status=0`.

**Auto-run from MATLAB (Windows):** Uses `condaactivateomnipose.m`. Auto-detects `miniconda3` or `anaconda3` under `C:\Users\Name\`. Set `omniPath` manually in `condaactivateomnipose.m` if conda is elsewhere. Windows PATH is restored to `initPath` after Omnipose finishes.

---

## Key CONST fields

All parameters live in a `CONST` struct. Default presets are `.mat` files in `SuperSegger-master/settings/`.

Common ones to change in `processExp.m`:
```matlab
CONST.trackLoci.numSpots = [2];        % foci per fluor channel; [] = skip foci fitting
CONST.trackOpti.NEIGHBOR_FLAG = false; % calculate cell neighbors (slow)
CONST.imAlign.AlignChannel = 1;        % reference channel for alignment
CONST.align.ALIGN_FLAG = 1;            % 0 = skip alignment
CONST.view.fluorColor = {'g'};         % display color per channel
CONST.frameRate = 5;                   % minutes per frame
CONST.res = 0.108;                     % um/px
CONST.ignoreerror = 0;                 % 1 = skip error resolution, use raw Omnipose masks
CONST.savexls = 0;                     % 1 = also save clist.xls
CONST.parallel.parallel_pool_num = N;  % 0 = serial
```

Less obvious defaults (from `loadConstants.m`):
```matlab
CONST.trackOpti.DA_MAX = 0.3;           % max area change allowed in linking (r->c)
CONST.trackOpti.DA_MIN = -0.2;          % min area change
CONST.trackOpti.REMOVE_STRAY = 0;       % delete stray (unmapped) regions
CONST.trackOpti.SMALL_AREA_MERGE = 55;  % regions smaller than this may be merged
CONST.trackOpti.MIN_CELL_AGE = 5;       % min frames for a "complete" cell cycle
CONST.trackOpti.linkFun = @multiAssignmentSparse;  % linking algorithm
CONST.regionOpti.MAX_NUM_RESOLVE = 10000; % skip region optimization above this
```

`skip` parameter (set in `processExp.m`): `1` = every frame; `5` = every 5th phase frame (faster; fluor still every frame). When `skip > 1`, a second linking pass runs on the merged `seg_full/` directory.

---

## Customization: never edit `loadConstants.m` directly

Create `loadConstantsMine.m` anywhere on the MATLAB path — it is automatically preferred (`BatchSuperSeggerOpti.m:97`). Change line 207's display text to mark it as custom. Reference it in `processExp.m` line 101.

For channel alignment registration:
```matlab
[out] = intAlignIm2('pathA', 'pathB', 1000)
% Returns [error, diffphase, row_shift, col_shift]
% Enter coordinates into CONST.imAlign.out in loadConstantsMine.m
% CONST.imAlign.out{1} = reference channel = [0 0 0 0]
% CONST.imAlign.out{2} = [row_shift col_shift row_shift col_shift] for c2
```

---

## Output structure

```
dirname/
  raw_im/        # originals pre-alignment (+ cropbox.mat)
  CONST.mat      # constants used for the run
  xy001/
    phase/       # brightfield frames
    fluor1/      # fluorescence channel 1
    cp_masks/    # Omnipose PNG masks (or masks/)
    seg/         # *_seg.mat → *_err.mat + hidden stamp files
    seg_full/    # only when skip>1: merged frames for second linking pass
    cell/        # per-cell .mat files (cell001.mat, etc.)
    clist.mat    # primary output: ~100 descriptors per cell
    clist.xls    # optional
    masksOS/     # post-linking OmniSegger masks (saved automatically)
```

The `seg/` directory contains both the segmentation data (`*_seg.mat`) and the linked/error-resolved data (`*_err.mat`). The `*_err.mat` files are the active working data for all post-linking steps.

---

## Resetting a run

Fully reset (moves images back, deletes all generated dirs):
```matlab
cleanSSresults('path/to/dirname')  % Internal/cleanSSresults.m
```
This copies tifs from `raw_im/` back to the top level, removes `raw_im/`, all `xy*/` dirs, `superSeggerViewer/`, and `CONST.mat`.

Partial reset (delete stamps for specific steps):
```matlab
cleanSuperSegger('path/to/xy001', [4 10], skip)  % cleans steps 4–10 for one xy dir
```
Or just delete specific stamp files manually from `xy*/seg/`.

---

## Critical gotcha: `seg` is a reserved name

**Never name any folder `seg` anywhere in the data path.** It breaks mask path resolution with "Unrecognized function or variable 'maskdir'". Rename to `seg1` or anything else.

---

## Post-processing / visualization

```matlab
superSeggerViewerGui    % main viewer
gateToolGui             % gate and plot clist data
editSegmentsGui         % manual segment editing
clist2xls('path/xy/clist.mat')   % export clist post-hoc
saveosmasks('path/to/xy/seg')    % save PNG masks for review (also auto-runs in pipeline)
```

Inspect clist fields:
```matlab
clist = load('path/xy/clist.mat');
clist.def'    % 2D field definitions (index: name)
clist.def3D'  % time-resolved field definitions
```

Known viewer bugs (non-fatal, documented in `docs/so_errors.md`):
- Kymograph Mosaic creates 2 duplicate + 1 empty figure (ignore extras)
- Cell movie saving fails for variable frame sizes (use `makeCellMovie.m` directly)
- Kymograph for specific cell numbers errors (use `makeKymographC.m` or Cell Kymo in viewer for individual cells)

---

## Segmentation models

| Model | Use case |
|-------|----------|
| `bact_phase_omni` | Phase contrast (default) |
| `bact_fluor_omni` | Fluorescence |
| Brightfield model | Download from Zenodo: https://doi.org/10.5281/zenodo.14225611 |

Use `--pretrained_model <path>` for custom models.

---

## `.MATLABDriveTag` files

These are MATLAB Drive sync markers scattered throughout the tree. They are not source files — ignore them.

---

## No automation infrastructure

There are no CI workflows, automated tests, linters, formatters, or task runners. All validation is visual inspection of pipeline output on real microscopy data.
