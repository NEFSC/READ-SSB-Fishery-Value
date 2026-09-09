# READ-SSB-Fishery-Value

Code for the Fishery Value project. It assembles, by stock and year:

- **Commercial gross revenue**, from CAMS landings and value.
- **Recreational expenditures and value-added**, from MRIP trip data combined with per-trip expenditure and multiplier data.

The project is written in R and R Markdown. The two R Markdown documents in `writing/` are the deliverables; everything in `R_code/` exists to feed them.

There is no wrapper script. The pipeline is run by hand, in the order described below.

## Repository layout

| Folder | What is in it |
|---|---|
| `R_code/data_extraction_processing/extraction/` | Scripts that pull data from Oracle, FRED, and the MRIP SAS files |
| `R_code/data_extraction_processing/processing/` | Superseded processing code, kept for reference |
| `R_code/analysis/` | Exploratory analysis, not part of the pipeline |
| `R_code/project_logistics/` | Credential setup and path helpers |
| `writing/` | The two R Markdown documents that produce the deliverables |
| `data_folder/raw/` | Extracted data, as pulled |
| `data_folder/main/` | Processed data and final outputs |
| `data_folder/external/` | Data gathered from outside sources |
| `stata_code/` | Sample code inherited from the project template. **Not used by this project.** |
| `results/`, `tables/`, `images/` | Template folders; the current pipeline does not write to them |

Data files are gitignored. A fresh clone has the code and an empty `data_folder`.

`REPO-STATUS.md` classifies every file in the repository as production or not, with the reasoning. `ISSUES.md` tracks known bugs.

## One-time setup

1. **Install R and RStudio.** Open the project in RStudio so that `here()` resolves paths correctly.

2. **Store your credentials.** `R_code/project_logistics/R_and_keyring.R` documents how to put your Oracle credentials and API keys into the Windows credential store, and gives the boilerplate that belongs in your `.Rprofile`. Read that file and follow it — do **not** `source()` it, as it opens interactive dialogs and would fire real queries.

   The extraction scripts expect these to already exist in your session:

   - `id`, `novapw`, `nefscusers.connect.string` — the Oracle connection
   - `FRED_API_KEY` — an environment variable, for the deflator pull

   If they are missing, the extraction scripts fail at `dbConnect()` with an unhelpful error.

3. **Obtain the two external CSVs.** `Recreational_Value.Rmd` reads the 2022 trip expenditure survey and its impact multipliers:

   - `data_folder/external/Trip_Exp_Imp_2022survey.csv`
   - `data_folder/external/trip_impacts_multipliers_2022.csv`

   These live outside the repository and are gitignored. Put them in `data_folder/external/` before knitting.

4. **Check `Incomplete_year`.** `MRIP_Data_Extraction.R` drops the most recent year of MRIP data, which is preliminary until MRIP publishes final estimates. The script stops with an error if that constant has gone stale; if it does, check the current MRIP release and update it.

## Running the pipeline

Four extraction scripts and two documents, in this order. **The order matters** — see the note after step 4.

### 1. Commercial extraction

Run both, on the same day:

```r
source(here("R_code", "data_extraction_processing", "extraction", "FRED_extraction.R"))
source(here("R_code", "data_extraction_processing", "extraction", "fmp_value_datapull.R"))
```

These are also in the `extract_data` chunk at the top of `Commercial_Value.Rmd`, set `eval=FALSE` so that they do not re-run on every knit.

Writes `deflators_*.Rds` to `data_folder/raw/`, and `fmp_listing_*`, `species_area_landings_*`, `Other_species_landings_*`, and `stock_area_definitions_*` to `data_folder/main/`.

### 2. Knit `writing/Commercial_Value.Rmd`

Writes `Commercial_Value_*.Rds` and `.csv`, and `stock_keyfile_*.Rds`, to `data_folder/main/`.

### 3. Recreational extraction

Run both, on the same day:

```r
source(here("R_code", "data_extraction_processing", "extraction", "MRIP_Sites.R"))
source(here("R_code", "data_extraction_processing", "extraction", "MRIP_Data_Extraction.R"))
```

These are in the `extract_data` chunk of `Recreational_Value.Rmd`, likewise `eval=FALSE`. Reading the MRIP SAS files is slow.

Writes `mrip_sites_*`, `rectrip_*`, and `reccatch_*` to `data_folder/raw/`. Nothing currently reads `reccatch_*`; it is staged for future work.

### 4. Knit `writing/Recreational_Value.Rmd`

Writes the recreational expenditure and value-added outputs to `data_folder/main/`, as both `.Rds` and `.csv`.

### Why the order matters

**Step 2 must happen before step 4.** `Commercial_Value.Rmd` writes `stock_keyfile_*.Rds`, and `Recreational_Value.Rmd` reads it. Nothing enforces this. Knitting the recreational document first against an empty `data_folder` fails on a missing file, and the error does not say why.

Steps 1 and 3 are independent of each other, but each must precede its own document.

### Why "on the same day" matters

There is no vintage global. Each extraction script stamps its output with the date it ran (`Sys.Date()`), and the documents recover a vintage by globbing a folder and taking the most recent date string:

- `vintage_string` comes from `species_area_landings_*.Rds` — the commercial datapull's date. Both documents use it for the commercial-side inputs.
- `rec_vintage_string` comes from `mrip_sites_*.Rds` — the MRIP site pull's date. `Recreational_Value.Rmd` uses it for the MRIP inputs and to stamp everything it writes.

So the two scripts in step 1 must share a day, and so must the two in step 3. If a run straddles midnight, re-run the pair.

## Conventions

1. Base R and tidyverse where possible.
2. `snake_case` for names — not `camelCase`.
3. Forward slashes in paths (`C:/path/to/folder`), for compatibility with unix and mac.



## Potential Issues


- **`process_deflators` references `params$deflate_year` with no `params:` block** (`Commercial_Value.Rmd`). Would error if enabled, but the author has confirmed commercial value is not meant to be deflated. Dead by design, not a defect. Documented inline.
- **Deflators read but never applied** (`Commercial_Value.Rmd`). Same reason.
- **Same-day coupling between extraction scripts.** `Commercial_Value.Rmd` looks up the deflator file with the vintage discovered from the commercial landings file, and `Recreational_Value.Rmd` reads `rectrip_` with the vintage from `mrip_sites_`. Confirmed intended: all extraction is run on one day. Documented inline in both files.
- **Windowpane `tsn1==172746` handled twice** in consecutive `case_when` blocks (`Recreational_Value.Rmd`). The second is unreachable. Style; output is correct.
- **Missing underscore in `Recreational_Expenditures_avg_NER_managed{rec_vintage_string}`** — the vintage runs into the filename. Cosmetic; the data is correct and the file is still discoverable.
- **Tautological `stopifnot`** (`Commercial_Value.Rmd`): the check that no `stockarea` is missing runs immediately after the mutate that fills every missing value, so it cannot fail. Harmless, and arguably still useful as a guard if that mutate is ever changed.
- **Stale chunk comment** on `compute_trips` (`Recreational_Value.Rmd`): says to set `eval=TRUE` only on the first run, but the chunk is set `eval=TRUE`. Clarified with an inline note rather than logged.


## NOAA Requirements

This repository is a scientific product and is not official communication of the National Oceanic and Atmospheric Administration, or the United States Department of Commerce. All NOAA GitHub project code is provided on an 'as is' basis and the user assumes responsibility for its use. Any claims against the Department of Commerce or Department of Commerce bureaus stemming from the use of this GitHub project will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the Department of Commerce. The Department of Commerce seal and logo, or the seal and logo of a DOC bureau, shall not be used in any manner to imply endorsement of any commercial product or activity by DOC or the United States Government."

## Project information

- **Who worked on this project:** Min-Yang Lee
- **When this project was created:** June, 2025
- **What the project does:** Fishery Value project
- **Why the project is useful:** ST5 asked us to do it.
- **How to get started:** Download and follow this readme.
- **Where to get help:** email me or open an issue.
- **Who maintains it:** Min-Yang

## License

See here for the [license file](License.txt)
