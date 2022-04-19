%%
rTraces = ms.RawTraces;
fTraces = ms.FiltTraces;
sTraces = ms.S;
% 7332 - 7338
fstart = 26725;
fend =26740;
rTraces(fstart:fend,:) = (rTraces(fend+1,:) - rTraces(fstart-1,:)) /(fend-fstart+1) .* transpose(1:(fend-fstart+1)) + rTraces(fstart-1,:);
fTraces(fstart:fend,:) = (fTraces(fend+1,:) - fTraces(fstart-1,:)) /(fend-fstart+1) .* transpose(1:(fend-fstart+1)) + fTraces(fstart-1,:);
sTraces(:,fstart:fend) = (sTraces(:,fend+1) - sTraces(:,fstart-1)) /(fend-fstart+1) .* (1:(fend-fstart+1) + sTraces(:,fstart-1));
%%
startF = 11431;
endF = 11433;

increment = (double(vidmat(:,:,endF+1)) - double(vidmat(:,:,startF-1)))/(endF-startF+2);
f = figure;
a = axes;
for i = startF:endF
   vidmat(:,:,i) = uint8(double(vidmat(:,:,startF-1))+increment*(i-startF+1)); 
   imshow(vidmat(:,:,i),'Parent',a);
   drawnow;
   pause(0.1);
    
end
%%
vidw = VideoWriter('msvideo_dFF_interpolated.avi','Grayscale AVI');
vidw.FrameRate = 15;
open(vidw);
writeVideo(vidw,vidmat);
close(vidw);