% This Script does the following:
% Input RAW videos (already converted from FFV1 to compatible codecs if necessary)
% First do motion correction using non reigid Normcorre, spatial downsample
% by 2(default). Corrected video is saved as msvideo_corrected.avi. Then
% FFT (using ImageJ) on motion corrected & downsampled video. This part of 
% the code has to be run in base workspace. At last, CNMFE on the FFT video. 
% Reject cells with CellScreener after this. 


%% Set paths to your raw videos

RawInputDir = {
    'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\14_27_16\Miniscope2_XZ71';
    'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\14_39_09\Miniscope1_XZ70';
    'E:\MiniscopeData(processed)\NewCage_free_dual\CMK_vs_CMK\XZ71_XZ70(m)\14_39_09\Miniscope2_XZ71';
    };
downsample_ratio = 2;
isnonrigid = false;
doFFT = true; % set false if you want to run CNMFE on motion corrected raw video
%% Start batch
for i = 1:length(RawInputDir)
   
   cd(RawInputDir{i});
   %% motion correction
   XZ_NormCorre_Batch(downsample_ratio,isnonrigid); 
   % this will generate a 'processed' folder containing the motion
   % corrected & downsampled video as 'msvideo_corrected.avi'
   clearvars -except RawInputDir downsample_ratio isnonrigid i doFFT;
   cd('processed\');
   %% FFT video generation
   if ~doFFT
       vName = 'msvideo_corrected.avi';
   else
       vName = 'msvideo_dFF.avi';
       addpath 'C:\Program Files (x86)\Fiji.app\scripts'
       FFT = 1;
       skip = 0;
       videoPath = pwd;
       if FFT == 1
        if exist('IJM', 'var')
            if ~isempty(IJM)
                fprintf(1, 'ImageJ is open\n')
            else
                ImageJ
            end
        else
            ImageJ;
        end
       end
       block = 500;
       v = VideoReader([videoPath,'\msvideo_corrected.avi']);
       nFrames = v.NumberOfFrames;
       [x, y] = size(read(v,1));
       allFrame = zeros([x y]);
        nHalf = floor(nFrames/2);
        meanPix = zeros([1 nHalf]);
        tic
        for i = 1:nHalf
            tempMat = read(v, i*2);
            meanPix(i) = mean(tempMat, 'all');
            allFrame = allFrame + double(tempMat);
            if mod(i, round(nHalf/10)) == 0
                fprintf(1, '.');
            end
        end
        fprintf(1, '\n')
        toc

        meanFrameRaw = allFrame / nHalf;
        meanPix = imresize(double(meanPix), [1 nFrames]);
        dFFinfo.meanPixSmooth1 = smoothdata(meanPix, 'movmean', 200);
        dFFinfo.meanPixSmooth2 = smoothdata(meanPix, 'movmean', 500);
        dFFinfo.meanPixSmooth3 = smoothdata(meanPix, 'movmean', 1000);
        dFFinfo.meanPixSmooth4 = smoothdata(meanPix, 'movmean', 2000);
        scal = dFFinfo.meanPixSmooth3/max(dFFinfo.meanPixSmooth3);
        dFFinfo.meanPixScal = meanPix ./ scal';
        dFFinfo.meanPix = meanPix;
        C  = VideoWriter([videoPath, '\','msvideo_dFF'], 'Grayscale AVI');
        C2 = VideoWriter([videoPath, '\','msvideo_dFFs'], 'Motion JPEG AVI');
        open(C2); open(C);
        meanFrame = meanFrameRaw;
        meanFrame(meanFrame<0.03) = 0.03;
            satuNum = zeros(1, nFrames);
        zeroNum = zeros(1, nFrames);
        histRaw = [];
        histDff = [];

        for i = 1:ceil(nFrames/block)
            L = (i-1)*block+1;
            if i*block <= nFrames
                R = i*block;
            else
                R = nFrames;
            end
            len = R-L+1;

            fprintf(1, '\n************\ndF/F processing frames %d - %d (%3.1f%%)\n', L, R, R/nFrames*100)
            tic

            clear dFFmat2;

            tempMat = read(v, [L R]);
            dFFmat = zeros([x y R-L+1]);

            for j = L:R
                dFF = (double(tempMat(:,:,1,j-L+1)) / scal(j) ./meanFrame) - 1; % (F-F0')/F0' = F/F0' - 1 = F/(F0*scal) - 1 = F/scal/F0 - 1;
                satuNum(j) = nnz(dFF>1)/(x*y)*100;
                zeroNum(j) = nnz(dFF<0)/(x*y)*100;
                % fprintf(1, '%d | %3.3f%% - %3.3f%%\n', i, zeroNum(i), satuNum(i));
                dFFmat(:,:,j-L+1) = dFF;
            end


            if skip == 1
                tempMat = tempMat(:,:,:,1:10:end);
                dFFmat = dFFmat(:,:,1:10:end);
            end

            dFFmat(dFFmat>1.2) = 1.2;
            dFFmat(dFFmat<0) = 0;

            dFFmat = dFFmat * 255;
            dFFmatRGB = uint8(colorThres(dFFmat));
            toc

            if FFT == 1
                fprintf(1, '\nApply spatial bandpass filter through ImageJ\n')
                tic

                IJM.show('dFFmat');
                ij.IJ.run("Duplicate...", "duplicate");
                ij.IJ.selectWindow("-1");
                ij.IJ.run("Bandpass Filter...", "filter_large=40 filter_small=3 suppress=Vertical tolerance=5 process");
                toc
                IJM.getDatasetAs('I');
                ij.IJ.run("Close All");
                if I(:,:,1) == dFFmat(:,:,1)
                    disp('ImageJ error: failed to apply bandpass filter')
                else
                    disp('Bandpass filter applied')
                end
                toc

                I2 = imgaussfilt(I, 15, 'FilterDomain', 'Spatial');
                I3 = (I - I2);
                FFTmat = I3 * 2.5;
                FFTmat(FFTmat<0) = 0;
                FFTmat(FFTmat>255) = 255;
                FFTmatRGB = uint8(colorThres(FFTmat));
                toc
                fig11 = tempMat;
                fig11 = repmat(fig11, [1 1 3 1]);
                fig12 = dFFmatRGB;
                fig13 = FFTmatRGB;
                fig21 = squeeze(tempMat)-uint8(dFFmat);
                fig22 = uint8(dFFmat-I3);
                fig23 = uint8(FFTmat);
                leng = size(tempMat, 4);
                pad1 = ones(x, 5, 3, leng)*255;
                pad2 = ones(x, 5, leng)*255;
                row1 = [fig11, pad1, fig12, pad1, fig13];
                row2 = [fig21, pad2, fig22, pad2, fig23];

                clear row22
                row22(:,:,1,:) = row2;
                row22 = repmat(row22, [1 1 3 1]);
                stitched = [row1; ones(5, y*3+10, 3, leng)*255; row22];
                fprintf(1, '\nWriting movie blocks\n')
                tic
                clear FFTmat2
                FFTmat2(:,:,1,:) = FFTmat;
                writeVideo(C, uint8(FFTmat2));
                writeVideo(C2, stitched);
                histRaw = cat(3, histRaw, tempMat(:,:,1));
                histDff = cat(3, histDff, dFFmat(:,:,1));
                histFFT = cat(3, histDff, FFTmat2(:,:,1));
                figure(1)
                clf;
                imshow(stitched(:,:,:,1))
                toc
                end
        end

        close(C);
        close(C2);
        ij.IJ.run("Quit","");
        clearvars -except RawInputDir downsample_ratio isnonrigid i doFFT vName;
        close all;
   end
    %% CNMFE on FFT output
    XZ_CNMFE_batch(pwd, vName);

end