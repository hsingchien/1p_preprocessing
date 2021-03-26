# 1p_preprocessing
preprocessing for 1p imaging
# Overview ##
![pipeline overview](https://github.com/hsingchien/1p_preprocessing/blob/master/pipeline_overview.png)

# Batch_NormCorre_FFT_CNMFE.m guide ##
This is the main script to batch process the videos. It does Motion Correction (NormCorre), FFT, and CNMFE. The output is ms.mat, which contains all ROIs and traces. 

**Prerequisite**
1. Raw video files generated by Miniscope is [number].avi. Do not alter the name or order.
2. Make sure matlab can read the videos (you may need to download codec, e.g. [K-Lite Codec Pack](https://codecguide.com/download_kl.htm) ). 
3. Follow guide of ImageJ to install plugins required and edit the path to ImageJ directory in the script
4. Make sure JAVA is allowed to use maximum memory (change this in matlab preferences -> General -> JAVA Heap Memory)
5. Make sure in matlab preferences -> General -> MAT-Files, MATLAB Version 7.3 or later is selected
6. Make sure you cloned the entire repository and have run Initialize.m (or make sure the toolboxes and other necessaties are added to the path)
7. Install toolboxes: Parallel computing toolbox, Deep learning toolbox, Statistics and machine learning toolbox, Deep learning toolbox converter for tensorflow models, Image processing toolbox, Signal processing toolbox.
8. If you have 'out of memory' error, try using less cores in parallel computing settings  

After Batch_NormCorre_FFT_CNMFE, you will get a ms.mat, which contains all the outputs. In ms.mat,  
RawTraces -- raw GCaMP video signal trace  
FiltTraces -- traces from model-based deconvolution. Usually this is what you want to use for further analysis  
SFPs -- ROI contours  

**Parameters**  
Batch_NormCorre_FFT_CNMFE has 3 options: downsample ratio (default 2), non-rigid registration toggle (default false) and doFFT (default true).  
If you are unsatisfied with the CNMFE output, major parameters can be set in msRunCNMFE_large_batch.m <p><code>edit msRunCNMFE_large_batch</code></p>
These are the key parameters you want to focus:
- min_corr = 0.8; min correlation to initialize an ROI. Increase this value if you get too many false positive ROIs. (in most cases, 0.8 is ok)
- min_pnr = 20; min peak-to-noise ratio. Increase this value if you get too many false positive ROIs. (usually ~15-20 is fine for FFT videos. If run on raw videos, try 4-8 to get the optimal results)
- min_corr_res = 0.8; Keep this value same or close to min_corr
- min_pnr_res = 17; Keep this value same or close to min_pnr
- merge_thr_spatial = [0.3, 0.1, -inf]; these parameters governs merging. The first and second values are spatial and temporal correlation respectively, the third value is spike correlation (keep this one -Inf in all cases). Lower these values if CNMFE is too sensitive and you get too many duplicated ROIs. Usually [0.3-0.5, 0.1-0.3,-Inf] is ok.   

Once you are happy with the paramters, rerun CNMFE <p><code>XZ_CNMFE_batch(dirName, vName)</code></p> dirName is the folder path containing the video file you want to run CNMFE , vName is the filename of this video file (usually msvideo_FFT.avi or msvideo_corrected.avi). Follow the guide to finish CNMFE. Be sure to backup any outputs from previous CNMFE runs if you want, as this might overwrite old ms.mat. 

# Cell Screening
Once you get ms.mat, you want to do screening. Label the good ones and bad ones.
There are 2 tools you can use.
## FastScreener
<p><code>FastScreener;</code></p>
In the pop-out window, select ms.mat. RawTraces of will be displayed. Good cells will have green title, and bad cells are red.


Keys: 
- 'a' -- previous cell    
- 'd' -- next cell    
- 's' -- save, cell label is saved as 'c_label.mat' in the same directory as ms.mat you selected. Load this and ms.mat, set ms.cell_label to c_label and overwrite the original ms.mat    
- 'j' -- toggle cell label    

## CellScreener
<p><code>CellScreener;</code></p>
This GUI provides a more versatile solution for cell screening. You can easily visualize and compare ROIs in the video.    

**Quick guide**  
1. click 'load V(mat/avi)' button, select .avi or .mat file of GCaMP video. Loading will take some moments. In the current version, video file is loaded to memory for quick access.  
2. click load ms.mat, select ms.mat. If what you have are PCA/ICA outputs, use Convert_pcaSFPs_to_CNMFE_SFPs.m to batch convert the PCA/ICA footprints to readable ms files. 
***minimum requirement for ms.mat***  
ms.SFPs ------ Footprints of all ROIs, **height x width x n_ROIs**  
ms.RawTraces ------ Temporal traces of all ROIs, **n_time_points x n_ROIs**  
ms.FiltTraces ------ Filtered temporal traces of all ROIs, **n_time_points x n_ROIs**. This is only different from RawTraces when deconvolution is performed. Make this a copy of RawTraces if deconvoluted traces are not available  
ms.ds ----- downsample ration. set this to 1 if no downsample is performed.   

**CellScreener can handle simple scenarios such as SFP is downsampled from video or SFP is cropped out of video (ms.roi_pos is required to map SFP back to video), but it will throw an error if mismatch is caused by both downsampling and cropping (SFP relative to video). It is recommended to always make SFP and video dimension match**  

3. After ms is loaded, cell list will be shown in box 'Cell list 1' and 'Cell list 2'. Video is presented in 2 axes. In axes 1, cell selected in Cell list 1 is the yellow contour; cell selected in Cell list 2 is the red contour. In axes 2, all ROIs are shown, with good ones in yellow and bad ones in red.  

4. To make the ROIs look cleaner, change 'Contour Thr' (0-1) to higher value like '0.9'. Only the footprint above the quantile will be shown (e.g. 0.9 --> only contour top 10% pixels). Both video axes are affected. Check LockContour checkbox to lock the view in axes 2. Change Contour Thr to a value to a lower value (0.5) to get a better idea of the target cell in axes 1.  

5. Select a cell in list 1, click Sort_ROI, list 2 will be sorted by their distance to the cell in list 1. Footprint overlap and temporal correlation will be shown on the right of the traces. 

6. Press 'g' to toggle label of cell1. Press 'h' to toggle label of cell2. **All key press functions are only functional when the GUI instead of GUI components are selected. This can be assured by clicking on the blank area of the GUI** Rejected ROI will become red in axe 2. Good/Bad statuses are shown for both cells. Click 'Save' to save. Good/Bad will be saved in ms.cell_label, 1 = keep, 0 = reject.
7. Click ROIs in axe 2, the ROI is selected as cell 1. 
7.  Other useful keypress functions:  
- 'j' pop-out dialog jump to frame#  
- 'i'/'o', move up (previous cell) of cell1/2
- 'k'/'l', move down (next cell) of cell1/2
- 'b'/'n', jump to max signal frame of cell1/2 (quickly switch between 'b' and 'n' is a good way to tell 2 neighboring cells apart)
- 'leftarrow'/'rightarrow', previous/next 'step' frame.
9. 'RasterVideo' button will generate a raster video. Hit 'Play' to quick play the video. Left/Right key will move current frame by step. 'Step' sets the step size of Left/Right keypressing as well as video play.


 
