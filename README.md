
# <p> <b>OmniSegger (SuperSegger 2)</b> </p>

![Phase image, old SuperSegger segmentation, new OmniSegger segmentation.](/assets/githubfig2.png)


OmniSegger is the Supersegger MATLAB-based suite modified to work with improved Omnipose segmentation. Omnipose should be installed before running OmniSegger. Read more about the capabilities of OmniSegger in our paper: [Lo TW, Cutler KJ, James Choi H, Wiggins PA (2025) OmniSegger: A time-lapse image analysis pipeline for bacterial cells. PLOS Computational Biology 21(5): e1013088](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1013088).

More information about Omnipose can be found at the [Omnipose Github](https://github.com/kevinjohncutler/omnipose/) and [documentation page](https://omnipose.readthedocs.io/).


- [Software Requirements](#software-requirements)
- [Software Documentation](#software-documentation)
- [Installation Instructions](#installation-instructions)
- [Setting the Path](#setting-the-path)
- [Running OmniSegger (GUI)](#running-omnisegger-gui)
- [Running OmniSegger from MATLAB (no GUI) - Recommended!](#running-omnisegger-from-matlab-no-gui---recommended)
- [Saving clist as Excel file](#saving-clist-as-excel-file)
- [ND2 to TIFF](#nd2-to-tiff)
- [Running Omnipose directly from MATLAB](#running-omnipose-directly-from-matlab)
- [Segmentation of alternative imaging modalities](#segmentation-of-alternative-imaging-modalities)
- [Troubleshooting \& Known Issues](#troubleshooting--known-issues)
- [Citation](#citation)

---
### Software Requirements

OmniSegger uses the same MATLAB toolboxes as the original Supersegger:

- Curve Fitting Toolbox
- Deep Learning Toolbox (fka Neural Network Toolbox)
- Global Optimization Toolbox
- Image Processing Toolbox
- Optimization Toolbox
- Parallel Computing Toolbox (not necessary)
- Statistics and Machine Learning Toolbox


---
### Software Documentation

#### OmniSegger
The GitHub for the original Supersegger is [here](https://github.com/wiggins-lab/SuperSegger). For more detailed documentation, the website for Supersegger can be found [here](http://mtshasta.phys.washington.edu/website/tutorials.php), the [wiki](https://github.com/wiggins-lab/SuperSegger/wiki), and detailed documentation on functions found [here](http://mtshasta.phys.washington.edu/website/superSegger/). OmniSegger uses the same MATLAB functions as the original Supersegger.

[Quick-start guide for new users](../main/docs/quick_start_guide.md) \ [Original SuperSegger guide to segmentation](https://github.com/wiggins-lab/SuperSegger/wiki/Segmenting-with-SuperSegger) \ [Viewing the results](https://github.com/wiggins-lab/SuperSegger/wiki/Visualization-and-post-processing-tools) \ [The clist](https://github.com/wiggins-lab/SuperSegger/wiki/The-clist-data-file) 

#### Omnipose
[Omnipose](https://omnipose.readthedocs.io/) options have been preselected to work directly with OmniSegger, but if needed, suggestions for segmentation options are discussed [here](../main/docs/segmentation_options.md). Recommended options can also be found on the [documentation page](https://omnipose.readthedocs.io/command.html). 



---
### Installation Instructions

1. Install [MATLAB](https://www.mathworks.com/help/install/install-products.html) and [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).
2. Cd to desired folder and clone OmniSegger with git
```
git clone https://github.com/tlo-bot/supersegger-omnipose.git
```
3. Add OmniSegger to MATLAB path, with its subfolders (see "Setting the Path").
4. Install Omnipose:
   - Find step-by-step instructions [here](../main/docs/install_omnipose.md).
   - Further advanced installation instructions for Omnipose can be found [here](https://pypi.org/project/omnipose/).
   - GPU usage is discussed [here](https://omnipose.readthedocs.io/installation.html#gpu-support). The OmniSegger command defaults to using CPU only.


---
### Setting the Path

In order for Matlab to be able to find OmniSegger, the OmniSegger folder needs to be in your path*. In the Home tab, in the Environment section, click Set Path. The Set Path dialog box appears. Click 'add folder with subfolders' and add the OmniSegger folder. 

>*note that if the original Supersegger is already installed and on the MATLAB path, you should replace the paths of the original Supersegger folders & subfolders with the paths to the new OmniSegger folders & subfolders.


---
### Running OmniSegger (GUI)

1. Put images (.tif) into a folder.
2. Convert image file names to OmniSegger convention (in MATLAB with `superSeggerGui`, or `convertImageNames`; or manually with command line).
3. Run `superSeggerGui` with the desired parameters. OmniSegger will begin aligning the images.
   - After aligning, OmniSegger will pause for segmentation through Omnipose. The Omnipose command should be displayed on the MATLAB Command Window and also automatically copied to your clipboard.
4. Open terminal/Anaconda Prompt and activate the Omnipose environment (ie `conda activate omnipose`)
   - Note that you should see the conda environment change from "(base)" to "(omnipose)"
5. Paste in the Omnipose command that was generated by MATLAB into the terminal. Wait for Omnipose to segment images and generate masks.
   - Can also change the segmentation command options in this step, if needed. For example, append `--use_gpu` to utilize the GPU.
6. Once Omnipose has completed, continue running OmniSegger by pressing the return/Enter key in the MATLAB Command Window.


---
### Running OmniSegger from MATLAB (no GUI) - Recommended!

1. Configure the analysis parameters in MATLAB: `edit processExp`. In particular, the 'Calculation Options' section should be edited depending on the desired fluorescence analysis. If not concerned with fluorescence, processExp probably doesn't need to be changed.
2. Run `processExp('dirname')` to begin running the segmentation, where 'dirname' is the path to your image files. OmniSegger will begin aligning the images. 
   - After aligning, OmniSegger will pause for segmentation through Omnipose. The Omnipose command should be displayed on the MATLAB Command Window and also automatically copied to your clipboard.
3. Open terminal/Anaconda Prompt and activate the Omnipose environment (ie `conda activate omnipose`)
   - Note that you should see the conda environment change from "(base)" to "(omnipose)"
4. Paste in the Omnipose command that was generated by MATLAB into the terminal. Wait for Omnipose to segment images and generate masks.
   - Can also change the segmentation command options in this step, if needed. For example, append `--use_gpu` to utilize the GPU.
5. Once Omnipose has completed, continue running OmniSegger by pressing the return/Enter key in the MATLAB Command Window.


---
### Saving clist as Excel file

Only supported when using `processExp`. Specify savexls=1 input for processExp (ie `processExp('dirname',1)`). Disabled by default.

If the clist has already been generated, running `clist2xls('path/clist.mat')` will save the clist as an xls in the xy directory.

---
### ND2 to TIFF

Convert ND2 to individual TIFF images in OmniSegger naming format, and save out the metadata.

Dependencies can be installed to the Omnipose conda environment via: `pip install aicsimageio[nd2] bioformats-jar`

Usage: `python /path/to/OmniSegger/SuperSegger-master/Internal/nd2totiff.py /path/to/your/file.nd2`


---
### Running Omnipose directly from MATLAB 

Only supported when using `processExp`. Specify autoomni=1 input for processExp (ie `processExp('dirname',[],1)`). Disabled by default.
See documentation for setup linked below.

---
### Segmentation of alternative imaging modalities

OmniSegger supports analysis and segmentation of fluorescence and brightfield cell images. The fluorescence model is included with Omnipose, while the [brightfield model is available on Zenodo](https://zenodo.org/records/14225612).
To analyze fluorescence data, the fluorescence images should be labeled as channel 1 in the filenames. Then when running Omnipose, replace the argument for the pretrained model from ``bact_phase_omni`` to ``bact_fluor_omni``.
To analyze brightfield data, download the brightfield model and set the brightfield images as channel 1 in the filenames. Then when running Omnipose, replace the argument for the pretrained model from ``bact_phase_omni`` to the path of the locally downloaded brightfield model (ex., ``/home/tlo/Documents/omnipose_BF_model6_2023_09_21_14_57_02.689653``). 


---
### Troubleshooting & Known Issues

- [Omnipose Segmentation options](../main/docs/segmentation_options.md)
- [Omnipose installation instructions (Windows, Linux & MacOS)](../main/docs/install_omnipose.md)
- [Possible OmniSegger errors](../main/docs/so_errors.md)
- [Running Omnipose directly from MATLAB for Windows (verified)](../main/docs/omni_in_matlab_windows.md)
- [Running Omnipose directly from MATLAB for Linux (verified) & MacOS](../main/docs/omni_in_matlab_unix.md)


---
### Citation

If you use OmniSegger, please cite our [paper](https://doi.org/10.1371/journal.pcbi.1013088):
Lo TW, Cutler KJ, James Choi H, Wiggins PA (2025) OmniSegger: A time-lapse image analysis pipeline for bacterial cells. PLOS Computational Biology 21(5): e1013088.

Additionally, a brightfield model for Omnipose is available at Zenodo: [https://doi.org/10.5281/zenodo.14225611](https://doi.org/10.5281/zenodo.14225611) under the CC-BY-NC 4.0 license.

The brightfield images and ground truth masks used to train the brightfield Omnipose model are available on Zenodo at [https://doi.org/10.5281/zenodo.14225852](https://doi.org/10.5281/zenodo.14225852) under the CC-BY-NC 4.0 license. 









