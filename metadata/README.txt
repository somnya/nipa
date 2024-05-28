### 17/04/2024 - Eddy Mendoza
///
From Izamar's database (palmeri-collection_20220305.csv)
I kept 6 columns:
-population
-latitude
-longitude
-sex
-species-wo-genus
-species

**Edits:
I removed spaces, replaced capital letters, replaced "NA" entries in "sex" as "unknown" and created a new column with the whole species name (including the genus)
felipe1 had one single coordinate for all samples
arenas, clara, montague one coordinate for the population - francisco molina collected and took one coordinate per population
mona one entry didn't have coordinates
gato and navopatia - I took the coordinates from google maps
mona-026 had coordinates of 0, they were changed to NA 

- take single random coordinate per pop

choya and barco coordinates are swap

choya-22-151 is sequenced but not in the database - was extra, remove

Carlos are the same in both databases

spicatas from gonzaga are also removed, they are a different species - Izamar indication

///
From Kashiff database, Supp Mat for the spicata paper

Carlos removed
S100-CA doesn't have coordinates
S9032-CA was indicated as CA manually
Sandlake has long extended names, i shortened them
I replaced Virginia to Maryland in the W6-54762 pop
I removed the state codes from the population names (they're in the "population-state" column)
Some samples were already trimmed "val_1_fastq-gz"
Judy and Reid had ambigous states in the name, both removed
2021-KS was replaced to 2021_KS, 2021 would be not very informative
I split S9032 into S9032_spi and S9032_stri; same for Tom, so this wouldn't interfer with popxspecies grouping

/// batch 2

I isolated the population names directly form the read files
277 samples - 8 bad files = 269 samples
I intersected manually the metadata from the 16 populations, from the passport codes mostly
I assumed gurley was spicata as indicated by Jessee
Cheyenne is the only stricta so far


/// Final DB ///

Latest update: 28 - 05 - 2024

# First batch = 916 final samples
544 palmeri, 228 spicata, 138 stricta, 6 unknown

# Second batch = 277 samples
239 spicata, 38 stricta

# All samples = 1193 samples
544 palmeri, 467 spicata, 176 stricta, 6 unknown
