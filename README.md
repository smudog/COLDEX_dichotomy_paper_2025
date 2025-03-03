# Scripts supporting "Dome A basal ice truncated at an extensive geologic dichotomy in the South Pole Basin of East Antarctica"

## Introduction
These scripts are intented to support a paper on airborne results over the South Pole Basin conducted by the National Science Foundations Center for Oldest Ice Exploration (NSF COLDEX).

Requirements are:
* A UNIX style environment
* python 3.12
* GMT >6.5
* Scipts being in a path with `code` as a directory
* Downloaded datasets being in a parallel path with `orig` as a directory
* Processed data and figures being in a parallel path with `targ` as a directory

Installed pip packages include:
numpy | pandas | rioxarray | xarray | pygmt | PIL | h5py | pyproj | netCDF4

## Datasets to download to orig
Relevent **ice thickness** datasets from [Open Polar Radar](https://www.openpolarradar.org) and [Bedmap](https://www.bas.ac.uk/project/bedmap/) can be automatically downloaded using the script `get_data.sh`.  
A relevent dataset for Titan Dome, [Beem et al., 2021](https://doi.org/10.15784/601437) required passing a Capcha.

Other relevent datasets to download:
* **Basal Ice Layer Thickness:** Yan, Shuia, Alejandra Vega Gonzàlez, Shivangini Singh, Megan Kerr and Duncan Young: TBD at USAP-DC (includes a file defining the dichotomy)
* **Basal Specularity Data:** Young, Duncan; Kerr, Megan E.; Singh, Shivangini; Yan, Shuai; Kempf, Scott D; Buhl, Dillon P; Ng, Gregory; Blankenship, Donald D., 2025, "NSF COLDEX 2023-24 Level 2 Basal Specularity Content Profiles", https://doi.org/10.18738/T8/KHUT1U, Texas Data Repository, V1; Young, Duncan; Kerr, Megan E.; Singh, Shivangini; Yan, Shuai; Kempf, Scott D; Buhl, Dillon P; Ng, Gregory; Blankenship, Donald D., 2025, "NSF COLDEX 2022-23 Level 2 Basal Specularity Content Profiles", https://doi.org/10.18738/T8/6T5JS6, Texas Data Repository, V1
Note the above are used to generate the grids at *Young, Duncan, 2025, "NSF COLDEX gridded airborne datasets", https://doi.org/10.18738/T8/M77ANK, Texas Data Repository,*
* **Ice Surface Velocity:** Mouginot, J., Rignot, E. & Scheuchl, B. (2019). MEaSUREs Phase-Based Antarctica Ice Velocity Map. (NSIDC-0754, Version 1). [Data Set]. Boulder, Colorado USA. NASA National Snow and Ice Data Center Distributed Active Archive Center. https://doi.org/10.5067/PZ3NJ5RXRH10.
* **Surface Elevation:** Howat, Ian; Porter, Claire; Noh, Myoung-Jon; Husby, Erik; Khuvis, Samuel; Danish, Evan; Tomko, Karen; Gardiner, Judith; Negrete, Adelaide; Yadav, Bidhyananda; Klassen, James; Kelleher, Cole; Cloutier, Michael; Bakker, Jesse; Enos, Jeremy; Arnold, Galen; Bauer, Greg; Morin, Paul, 2022, "The Reference Elevation Model of Antarctica - Mosaics, Version 2", https://doi.org/10.7910/DVN/EBW8UC, Harvard Dataverse, V1
* **Projected CSARP Radargrams:** Young, Duncan A.; Paden, John D.; Greenbaum, Jamin S.; Kerr, Megan E.; Singh, Shivangini; Kaundinya, Shravan R.; Chan, Kristian; Buhl, Dillon P.; Ng, Gregory; Kempf, Scott D., 2024, "COLDEX VHF MARFA Open Polar Radar radargrams", https://doi.org/10.18738/T8/NEF2XM, Texas Data Repository
* **Example Delay Doppler data:** Young, Duncan A., Gregory Ng, Scott Kempf
* **Englacial Isochrons:** Sanderson, R., Ross, N., Winter, K., Bingham, R., Callard, L., Jordan, T., & Young, D. (2023). Dated radar stratigraphy between Dome A and South Pole, East Antarctica, derived from AGAP North PASIN (2008-2009) and PolarGAP PASIN2 (2015-2016) surveys (Version 1.0) [Data set]. NERC EDS UK Polar Data Centre. https://doi.org/10.5285/cfafb639-991a-422f-9caa-7793c195d316

## Scripts under `submission`
* `read_h5.py` reads the MEaSUREs ice velocity data an converts it into GIS friendly GeoTiffs
* `process_data.py` generates GeoTiffs for bed elevation, ice thickness, specularity content, basal ice thickness, [roughness](http://dx.doi.org/10.1029/2000JE001429) as well as profiles of high pass bed elevation.
* `make_context_map.py` generates Figure 1 and requires the projected radargrams.
* `make_coldex_cuestas.py` generates Figure 3, and requires the projected radargrams, the Sanderson et al. englacial isochrons, and the delay doppler product.  This script generates files that are required for Figures 2 and Figure S2.
* `make_coldex_overview_maps.sh` generates Figure S2 and Figure 2.  These figures requires the gridded COLDEX products, the projected radargrams (ie the associated metadata), the velocity grids, and the high pass bed product.

* Additional scipts under `map` provide additional supplemental figures, but have not be adapted to run outside the UTIG environment.


