# 1p_preprocessing
preprocessing for 1p imaging

## CellScreener.mlapp quickstart guide
1. click 'load V(mat/avi)' button, select .mat or .avi file of neuron recording, open. loading will take some moments. current version video file is loaded to memory for quick access.  

2. click load ms.mat, select ms.mat output from the cell extraction preprocessing you like. Use Convert_pcaSFPs_to_CNMFE_SFPs.m to batch convert the PCA/ICA footprints to ms file.
**minimum requirement for ms.mat**
ms.SFPs ------ Footprints of all ROIs, height x width x n_ROIs
ms.RawTraces ------ Temporal traces of all ROIs, n_time_points x n_ROIs
ms.FiltTraces ------ Filtered temporal traces of all ROIs, n_time_points x n_ROIs. This is only different from RawTraces when deconvolution is performed. Make this a copy of RawTraces if deconvoluted traces are not available
ms.ds ----- downsample ration. set this to 1 if no downsample is performed. 

**CellScreener can handle simple scenarios such as SFP is downsampled from video or SFP is cropped out of video (ms.roi_pos is required to map SFP back to video), but it will throw an error if mismatch is caused by both downsampling and cropping (SFP relative to video). It is recommended to always make SFP and video dimension match**

3. After ms is loaded, cell list will be shown in box 'Cell list 1' and 'Cell list 2'. Cell selected in Cell list 1 is the yellow contour. Cell selected in Cell list 2 is the red contour. A maxprojection image and all footprints will show up. 

4. To make the ROIs look cleaner, change 'Contour Thr' (0-1) to higher value like '0.9'. Only the footprint above the quantile will be shown. Both working axe and maxprojection axe are affected. Check LockContour checkbox to lock the view in maxprojection axe. Change Contour Thr to a value to a lower value (0.5) to get a better idea of the target cell in working axe.  

5. Select a cell in list 1, click Sort_ROI, list 2 will be sorted by their distance to the cell in list 1. Footprint overlap and temporal correlation will be shown on the right of the traces. 

6. Press 'g' to keep/reject cell selected in list 1. Press 'h' to keep/reject cell selected in list 2. Make sure GUI instead of individua components is selected. Rejected ROI will become red in maxprojection image. Keep/reject statuses are shown for both cells. Click 'Save' to save. keep/reject will be saved in ms.cell_label, 1 = keep, 0 = reject.  

7. 'RasterVideo' button will generate a raster video. Hit 'Play' to play the video.

 