function behavior_annotator( fName, aName, tName )
% Caltech Behavior Annotator.
%
% Use space bar to play/pause the video.  Other controls are as follows:
%    [Left]/[Right] Jump forward/backward in from current point in video.
%    [Up]/[Down]    Increase/decrease play velocity.
%    [Q]            Reset play speed to 1x (forward direction).
% You can explicitly enter a frame or use the slider to jump in the video.
%
% USAGE
%  behavior_annotator( [fName], [aName], [tName] )
%
% INPUTS
%  fName    - optional seq file to load at start
%  aName    - optional annotation file to load or import at start
%  tName    - optional tracking or detection file to load at start
%
% OUTPUTS
%
% EXAMPLE
%  behavior_annotator
%
% See also BEHAVIOR_DATA
%
% Caltech Behavior Annotator     Version NEW
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Modified by Michael Maire [mmaire-at-caltech.edu]
% Please email us if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see lgpl.txt]

% handles to gui objects / other globals
[hFig,menu,pTop,pMid,pBot,dispApi,A,trk] = deal([]);

% initialize fly to track association
trk.is_valid       = false; % is tracking data valid?
trk.frame_seq_list = {};    % list of sequences present in each frame
trk.sequences      = {};    % actual track data
trk.f1.fr_start = [];       % fly1 - interval start frames
trk.f1.fr_end   = [];       % fly1 - interval end frames
trk.f1.seq_id   = [];       % fly1 - sequence id associated with each interval
trk.f2.fr_start = [];       % fly2 - interval start frames
trk.f2.fr_end   = [];       % fly2 - interval end frames
trk.f2.seq_id   = [];       % fly2 - sequence id associated with each interval

% initialize key modifiers currently pressed down;
key_modifiers = {};

% initialize all
makeLayout();
menuApi = menuMakeApi();
dispApi = dispMakeApi();
annApi  = annMakeApi();
menuApi.vidClose();

% fprintf(1, 'Program initiated\n');
%%% aSdFg = fopen('C:\Users\Public\Documents\aSdFg.hjk', 'a');

% open vid, annotation and tracking results if given
if(nargin>=1 && ~isempty(fName)), menuApi.vidOpen(fName); end
if(nargin>=2 && ~isempty(aName)), menuApi.annOpen(aName); end
if(nargin>=3 && ~isempty(tName)), menuApi.trkOpen(tName); end

    function makeLayout()
        % common properties
        name = 'Caltech Behavior Annotator';
        bg='BackgroundColor'; fg='ForegroundColor';
        fs='FontSize'; ha='HorizontalAlignment';
        units = {'Units','pixels'}; st='String'; ps='Position';
        
        % initial figures size / pos
        set(0,'Units','pixels');  ss = get(0,'ScreenSize');
        if( ss(3)<800 || ss(4)<715 ); error('screen too small'); end;
        figPos = [(ss(3)-700)/2 (ss(4)-600)/2 700 715];
        
        % create main figure
        figPrp = {'NumberTitle','off', 'Toolbar','auto', 'MenuBar','none', 'Color','k'};
        hFig = figure(figPrp{:},'Visible','off', ps,figPos, 'Name',name );
        set(hFig,'DeleteFcn',@exitProg,'ResizeFcn',@figResized);
        
        % mid panel
        pMid.hAx=axes(units{:},'Parent',hFig); set(pMid.hAx,'XTick',[],'YTick',[]);
        pMid.hSl=uicontrol(hFig,'Style','slider','Min',0,'Max',1,bg,'k'); imshow(0);
        pMid.hBar1=uicontrol(hFig,'Style','pushbutton',units{:},'Enable','inactive');
        pMid.hBar2=uicontrol(hFig,'Style','pushbutton',units{:},'Enable','inactive');
        pMid.hTrkBar1=uicontrol(hFig,'Style','pushbutton',units{:},'Enable','inactive');
        pMid.hTrkBar2=uicontrol(hFig,'Style','pushbutton',units{:},'Enable','inactive');
        pMid.hAdd=uicontextmenu('Parent',hFig); pMid.hAdds=[]; pMid.hTxt=[];
        
        % mid panel - tracking information
        hold(pMid.hAx,'on');
        pMid.hDetections = [];
        pMid.hFly1Dot = plot(pMid.hAx,0,0,'g.','MarkerSize',25);
        pMid.hFly2Dot = plot(pMid.hAx,0,0,'r.','MarkerSize',25);
        pMid.hTrack1 = plot(pMid.hAx,0,0,'g-');
        pMid.hTrack2 = plot(pMid.hAx,0,0,'r-');
        set([pMid.hFly1Dot pMid.hFly2Dot pMid.hTrack1 pMid.hTrack2],'Visible','off');
        
        % top panel
        pnlProp = [units {bg,[.1 .1 .1],'BorderType','none'}];
        txtPrp = {'Style','text',bg,[.1 .1 .1],fg,'w',ha};
        edtPrp = {'Style','edit',bg,[.1 .1 .1],fg,'w',ha};
        pTop.h = uipanel(pnlProp{:},'Parent',hFig);
        pTop.hBh1=uicontrol(pTop.h,units{:},'Style','popupmenu',fg,'w',bg,'k',st,{''});
        pTop.hBh2=uicontrol(pTop.h,units{:},'Style','popupmenu',fg,'w',bg,'k',st,{''});
        pTop.hFrmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'frame:');
        pTop.hFrmInd=uicontrol(pTop.h,edtPrp{:},'Right');
        pTop.hTmLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'time:');
        pTop.hTmVal=uicontrol(pTop.h,txtPrp{:},'Left');
        pTop.hFrmNum=uicontrol(pTop.h,txtPrp{:},'Left');
        pTop.hPlyLbl=uicontrol(pTop.h,txtPrp{:},'Left',st,'speed:');
        pTop.hPlySpd=uicontrol(pTop.h,txtPrp{:},'Left',st,'0x');
        
        % bottom panel
        pBot.h=uipanel(pnlProp{:},'Parent',hFig); uiPr={pBot.h,units{:},'Style'};
        uiButPr=[uiPr,'pushbutton', bg,[.9 .9 .9], fs,11, 'FontWeight','bold'];
        pBot.hFly1=uicontrol(uiPr{:},'togglebutton',fg,'g',bg,[0.1 0.1 0.1],st,'Fly1','Value',1);
        pBot.hFly2=uicontrol(uiPr{:},'togglebutton',fg,'r',bg,[0.1 0.1 0.1],st,'Fly2','Value',0);
        pBot.hBh1=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',st,{''});
        pBot.hBh2=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',st,{''});
        pBot.hBar1=uicontrol(uiPr{:},'pushbutton','Enable','inactive');
        pBot.hBar2=uicontrol(uiPr{:},'pushbutton','Enable','inactive');
        pBot.hTrkBar1=uicontrol(uiPr{:},'pushbutton','Enable','inactive');
        pBot.hTrkBar2=uicontrol(uiPr{:},'pushbutton','Enable','inactive');
        pBot.hShwTrk1=uicontrol(uiPr{:},'checkbox','Enable','on','String',' Track 1',fg,'g',bg,[0.1 0.1 0.1]);
        pBot.hShwTrk2=uicontrol(uiPr{:},'checkbox','Enable','on','String',' Track 2',fg,'r',bg,[0.1 0.1 0.1]);
        pBot.hZm=uicontrol(uiPr{:},'popupmenu',fg,'w',bg,'k',...
            st,int2str2([30 60 120 250*2.^(0:5)]),'Value',5);
        pBot.hArrL=uicontrol(uiButPr{:},fg,'k',st,'<<');
        pBot.hSl=uicontrol(uiPr{:},'slider',bg,'k');
        pBot.hArrR=uicontrol(uiButPr{:},fg,'k',st,'>>');
        pBot.hSetL=uicontrol(uiPr{:},'pushbutton',fg,'k',bg,[.9 .9 .9],fs,8);
        pBot.hSetR=uicontrol(uiPr{:},'pushbutton',fg,'k',bg,[.9 .9 .9],fs,8);
        pBot.hDel=uicontrol(uiButPr{:},fg,[.5 0 0],st,'X');
        
        % icons for set region button
        I=ones(20,18); I(9:15,10:16)=triu(ones(7));
        I(14:15,4:13)=0; I=repmat(I,[1 1 3]);
        set(pBot.hSetL,'CData',I(:,end:-1:1,:));
        set(pBot.hSetR,'CData',I);
        
        % set the keyPressFcn for all focusable components (except popupmenus)
        set( [hFig, pMid.hSl pBot.hArrL pBot.hSl pBot.hArrR ...
            pBot.hSetL pBot.hSetR pBot.hDel], 'keyPressFcn',@keyPress );
        set( [hFig], 'keyReleaseFcn',@keyRelease );
        
        % create menus
        menu.hVid = uimenu(hFig,'Label','Video');
        menu.hVidOpn = uimenu(menu.hVid,'Label','Open');
        menu.hVidsOpn = uimenu(menu.hVid,'Label','Open dual');
        menu.hVidCls = uimenu(menu.hVid,'Label','Close');
        menu.hVidExp = uimenu(menu.hVid,'Label','Export');
        menu.hVidAud = uimenu(menu.hVid,'Label','Audio');
        menu.hAnn = uimenu(hFig,'Label','Annotation');
        menu.hAnnNew = uimenu(menu.hAnn,'Label','New');
        menu.hAnnOpn = uimenu(menu.hAnn,'Label','Open');
        menu.hAnnCls = uimenu(menu.hAnn,'Label','Close');
        menu.hAnnSav = uimenu(menu.hAnn,'Label','Save');
        menu.hAnnCnf = uimenu(menu.hAnn,'Label','Config');
        menu.hAnnMrg = uimenu(menu.hAnn,'Label','Merge','Enable','off');
        menu.hTrk = uimenu(hFig,'Label','Tracking');
        menu.hTrkOpn = uimenu(menu.hTrk,'Label','Open');
        menu.hTrkCls = uimenu(menu.hTrk,'Label','Close');
        
        % set hFig to visible upon completion
        set(hFig,'Visible','on'); drawnow;
        
        function keyPress( h, evnt )
            % fprintf(1, 'KeyPress\n');
            %%% fprintf(aSdFg, '%f\r\n', now);
            
            % record active key modifier
            key_modifiers = evnt.Modifier;
            % process event
            char=int8(evnt.Character); if(isempty(char)), char=0; end;
            % check for up/down arrow keys (speed control)
            if ( char>=30 && char<=31 )
                flag=-(double(char-30)*2-1);
                dispApi.setSpeedCb(flag);
                return;
            end
            % check for spacebar (play/pause)
            if ( char==32 )
                dispApi.setSpeedCbPlayPause();
                return;
            end
            % check for Q (reset play speed)
            if ( char=='q' )
                dispApi.setSpeedCbReset();
                return;
            end
            % left/right arrow keys jump forward/backward
            if ( char>=28 && char<=29 )
                flag=double(char-28)*2-1;
                if ( h==hFig )
                    if(~isempty(A))
                        info = dispApi.getInfo();
                        flag = flag .* 2 .* info.fps;
                        dispApi.setSpeedCbPause();
                        annApi.setFrame(flag);
                    end
                elseif ( h~=pBot.hSl && h~=pMid.hSl )
                    flag = mod(double(char),2)*2-1;
                    annApi.setFrame(flag);
                end
                return;
            end
            % arrow keys control either video, main slider, or bottom slider
            %if( char>=28 && char<=31 ) % L/R/U/D = 28/29/30/31
            %  if( h==hFig )
            %    if(char>=30), flag=0; else flag=double(char-28)*2-1; end
            %    dispApi.setSpeedCb(flag);
            %  elseif( h~=pBot.hSl && h~=pMid.hSl )
            %    flag = mod(double(char),2)*2-1;
            %    annApi.setFrame(flag);
            %  end
            %  return;
            %end
            % all other keys require an annotation to be loaded
            if(isempty(A)), return; end; bp=[];
            % '-'/'=' control jumps, ','/'.' control moveLeft/Right
            if(char=='-'), bp='prevBeh'; end
            if(char=='='), bp='nextBeh'; end
            if(char==','), bp='moveLeft'; end
            if(char=='.'), bp='moveRight'; end
            % check for fly selection switch
            if(char=='1'), bp='selectFly1'; end
            if(char=='2'), bp='selectFly2'; end
            if(~isempty(bp)), annApi.buttonPress(bp); return; end
            % make bindings for behavior creation
            [member,type]=ismember( char, int8(A.getKeys()) );
            if(member), annApi.insertBh(type); return; end;
        end
        
        function keyRelease( h, evnt )
            key_modifiers = {};
        end
        
        function figResized( h, evnt ) %#ok<INUSD>
            % aspect ratio of video
            if(isempty(dispApi)), info=[]; else info=dispApi.getInfo(); end
            if(isempty(info)), ar=4/3; else ar=info.width/info.height; end
            % enforce minimum size (min width=600+pad*2)
            pos=get(hFig,ps); pad=8; htBot=85; htMid=80; htSl=20; htTop=20;
            mWd=600+pad*2; mHt=500/ar+htBot+htMid+htTop+pad*2;
            persistent posPrv;
            if(pos(3)<mWd || pos(4)<mHt && ~isempty(posPrv))
                set(hFig,ps,[posPrv(1:2) mWd mHt]); figResized(); return;
            end; posPrv=pos;
            % overall layout
            wd=pos(3)-2*pad; ht=pos(4)-2*pad-htMid-htTop-htBot;
            wd=min(wd,ht*ar); ht=min(ht,wd/ar); x=(pos(3)-wd)/2; y=pad;
            set(pBot.h,  ps,[x y wd htBot]); y=y+htBot;
            set(pMid.hSl,ps,[x y wd htSl]);
            set(pMid.hBar1,ps,[x y+50 wd 14]);
            set(pMid.hBar2,ps,[x y+25 wd 14]);
            set(pMid.hTrkBar1,ps,[x y+64 wd 6]);
            set(pMid.hTrkBar2,ps,[x y+39 wd 6]);
            y=y+htMid-2;
            if(~isempty(pMid.hTxt)), set(pMid.hTxt,ps,[wd/2 ht]); end
            set(pMid.hAx,ps,[x y wd ht]); y=y+ht;
            set(pTop.h,ps,[x y wd htTop]);
            % position stuff in top panel
            x=10;
            set(pTop.hBh1,   ps,[x 7 140 14]); x=x+150;
            set(pTop.hBh2,   ps,[x 7 140 14]); x=wd-370;
            set(pTop.hPlyLbl,ps,[x 3 40 14]);  x=x+40;
            set(pTop.hPlySpd,ps,[x 3 45 14]);  x=x+50;
            set(pTop.hTmLbl, ps,[x 3 30 14]);  x=x+30;
            set(pTop.hTmVal, ps,[x 3 45 14]);  x=x+50;
            set(pTop.hFrmLbl,ps,[x 3 35 14]);  x=x+35;
            set(pTop.hFrmInd,ps,[x 3 80 16]);  x=x+80;
            set(pTop.hFrmNum,ps,[x 3 80 14]);
            % position stuff in bottom panel
            x=5; wd0=wd-295;
            set(pBot.hFly1,ps,[x 55 35 20]);
            set(pBot.hFly2,ps,[x 30 35 20]);
            set(pBot.hBh1,    ps,[x+40 58 145 20]);
            set(pBot.hBh2,    ps,[x+40 33 145 20]);
            set(pBot.hZm,     ps,[x 5 160 20]);
            x=x+165; x0=x;
            set(pBot.hArrL,ps,[x 4 25 20]);  x=x+25;
            set(pBot.hSl,  ps,[x 4 wd0 20]); x=x+wd0;
            set(pBot.hArrR,ps,[x 4 25 20]);  x=x+30;
            set(pBot.hSetL,ps,[x 4 20 20]);  x=x+20;
            set(pBot.hSetR,ps,[x 4 20 20]);  x=x+25;
            set(pBot.hDel, ps,[x 4 20 20]);
            x=x0+25;
            set(pBot.hBar1,ps,[x 57 wd0 14]);
            set(pBot.hBar2,ps,[x 32 wd0 14]);
            set(pBot.hTrkBar1,ps,[x 71 wd0 6]);
            set(pBot.hTrkBar2,ps,[x 46 wd0 6]);
            x=x+wd0+5;
            set(pBot.hShwTrk1,ps,[x 57 85 20]);
            set(pBot.hShwTrk2,ps,[x 32 85 20]);
            % disable figure resizing
            % set(hFig,'Resize','off');
            % update display
            if(~isempty(dispApi)); dispApi.requestUpdate(); end;
        end
        
        function exitProg( h, evnt ) %#ok<INUSD>
            menuApi.vidClose();
        end
    end

    function api = annMakeApi()
        % create api
        clrs=[]; fM=0;
        api = struct( ...
            'getActiveStream', @getActiveStream, ...
            'updateDisp',  @updateDisp, ...
            'updateAnn',   @updateAnn, ...
            'setFrame',    @setFrame, ...
            'buttonPress', @buttonPress, ...
            'insertBh',    @insertBh, ...
            'setCenter',   @setCenter, ...
            'getActiveTrkSequence',   @getActiveTrkSequence, ...
            'removeActiveTrkSequence',@removeActiveTrkSequence, ...
            'setActiveTrkSequence',   @setActiveTrkSequence, ...
            'startActiveTrkSequence', @startActiveTrkSequence, ...
            'endActiveTrkSequence',   @endActiveTrkSequence, ...
            'flyClick',               @flyClick, ...
            'flyClickDet',            @flyClickDet ...
            );
        set( pBot.hFly1, 'callback', @(h,evnt) buttonPress('selectFly1'));
        set( pBot.hFly2, 'callback', @(h,evnt) buttonPress('selectFly2'));
        set( pBot.hBh1,  'callback', @(h,evnt) buttonPress('setType1'));
        set( pBot.hBh2,  'callback', @(h,evnt) buttonPress('setType2'));
        set( pBot.hZm,   'callback', @(h,evnt) buttonPress('setZoom'));
        set( pBot.hSetL, 'callback', @(h,evnt) buttonPress('moveLeft'));
        set( pBot.hSetR, 'callback', @(h,evnt) buttonPress('moveRight'));
        set( pBot.hDel,  'callback', @(h,evnt) buttonPress('delete'));
        set( pBot.hArrL, 'callback', @(h,evnt) buttonPress('prevBeh'));
        set( pBot.hArrR, 'callback', @(h,evnt) buttonPress('nextBeh'));
        set( pBot.hSl,   'callback', @(h,evnt) setFrame(0));
        set( pBot.hShwTrk1, 'callback', @(h,evnt) buttonPress('toggleTrack1'));
        set( pBot.hShwTrk2, 'callback', @(h,evnt) buttonPress('toggleTrack2'));
        set( pTop.hBh1,   'callback', @(h,evnt) buttonPress('gotoBeh1'));
        set( pTop.hBh2,   'callback', @(h,evnt) buttonPress('gotoBeh2'));
        set([pMid.hFly1Dot pMid.hFly2Dot],'ButtonDownFcn',@(h,e) flyClick(h));
        
        % return the active annotation stream
        function strm = getActiveStream()
            % get selected status
            is_sel1 = get(pBot.hFly1,'Value');
            is_sel2 = get(pBot.hFly2,'Value');
            % enforce single selection
            if ((is_sel1) && (~is_sel2))
                strm = 1;
            elseif ((~is_sel1) && (is_sel2))
                strm = 2;
            else
                set(pBot.hFly1,'Value',1);
                set(pBot.hFly2,'Value',0);
                strm = 1;
            end
        end
        
        % return active track sequence for given fly
        function [seq_id ind f] = getActiveTrkSequence(fly)
            f=dispApi.getFrame()+1;
            ind = max(find(fly.fr_start <= f));
            if ((~isempty(ind)) && (fly.fr_end(ind) >= f))
                seq_id = fly.seq_id(ind);
            else
                ind = [];
                seq_id = [];
            end
        end
        
        % remove the active track sequence for the given fly
        function fly = removeActiveTrkSequence(fly)
            [seq_id ind] = annApi.getActiveTrkSequence(fly);
            if (~isempty(ind))
                fly.fr_start(ind) = [];
                fly.fr_end(ind) = [];
                fly.seq_id(ind) = [];
            end
        end
        
        % set the active track sequence for the given fly
        function fly = setActiveTrkSequence(fly, seq_id)
            annApi.removeActiveTrkSequence(fly);
            t_start = trk.sequences{seq_id}.time_start;
            t_end   = trk.sequences{seq_id}.time_end;
            f=dispApi.getFrame()+1;
            prev_end_ind   = max(find(fly.fr_end < f));
            next_start_ind = min(find(fly.fr_start > f));
            if (~isempty(prev_end_ind))
                t_start = max(t_start, fly.fr_end(prev_end_ind)+1);
            end
            if (~isempty(next_start_ind))
                t_end = min(t_end, fly.fr_start(next_start_ind)-1);
            end
            if (isempty(prev_end_ind))
                start_before = []; end_before = []; seq_before = [];
            else
                start_before = fly.fr_start(1:prev_end_ind);
                end_before   = fly.fr_end(1:prev_end_ind);
                seq_before   = fly.seq_id(1:prev_end_ind);
            end
            if (isempty(next_start_ind))
                start_after = []; end_after = []; seq_after = [];
            else
                start_after = fly.fr_start(next_start_ind:end);
                end_after = fly.fr_end(next_start_ind:end);
                seq_after = fly.seq_id(next_start_ind:end);
            end
            fly.fr_start = [start_before t_start start_after];
            fly.fr_end   = [end_before   t_end   end_after];
            fly.seq_id   = [seq_before   seq_id  seq_after];
        end
        
        % set start of active sequence to the current frame
        function fly = startActiveTrkSequence(fly)
            [seq_id ind] = annApi.getActiveTrkSequence(fly);
            if (~isempty(ind))
                fly.fr_start(ind) = dispApi.getFrame()+1;
            end
        end
        
        % set end of active sequence to the current frame
        function fly = endActiveTrkSequence(fly)
            [seq_id ind] = annApi.getActiveTrkSequence(fly);
            if (~isempty(ind))
                fly.fr_end(ind) = dispApi.getFrame()+1;
            end
        end
        
        % clicked on tracked fly
        function flyClick(h)
            if (h == pMid.hFly1Dot) fly = trk.f1; else fly = trk.f2; end
            if (ismember('shift',key_modifiers))
                fly = annApi.endActiveTrkSequence(fly);
            elseif (ismember('control',key_modifiers))
                fly = annApi.startActiveTrkSequence(fly);
            else
                fly = annApi.removeActiveTrkSequence(fly);
            end
            if (h == pMid.hFly1Dot) trk.f1 = fly; else trk.f2 = fly; end
            dispApi.requestUpdate();
        end
        
        % clicked on detection
        function flyClickDet(h)
            seq_id = get(h,'UserData');
            strm = annApi.getActiveStream();
            if (strm == 1)
                trk.f1 = annApi.removeActiveTrkSequence(trk.f1);
                trk.f1 = annApi.setActiveTrkSequence(trk.f1,seq_id);
            elseif (strm == 2)
                trk.f2 = annApi.removeActiveTrkSequence(trk.f2);
                trk.f2 = annApi.setActiveTrkSequence(trk.f2,seq_id);
            end
            dispApi.requestUpdate();
        end
        
        function updateAnn()
            % new annotation loaded or annotation closed
            isAnn=~isempty(A); if(isAnn), en='on'; else en='off'; end;
            hAll=[ ...
                pTop.hBh1 pTop.hBh2 pBot.hBh1 pBot.hBh2 pBot.hFly1 pBot.hFly2 ...
                pBot.hSetL pBot.hArrL pBot.hSl pBot.hArrR pBot.hSetR pBot.hZm pBot.hDel];
            set(hAll,'Enable',en);
            set([pBot.hBar1    pBot.hBar2    pMid.hBar1    pMid.hBar2],   'Visible',en);
            set([pBot.hTrkBar1 pBot.hTrkBar2 pMid.hTrkBar1 pMid.hTrkBar2],'Visible',en);
            if(~isAnn), strs={''}; else strs=A.getNames(); end
            set(pBot.hBh1,'Value',1,'String',strs);
            set(pBot.hBh2,'Value',1,'String',strs);
            set(pTop.hBh1,'Value',1,'String',{''});
            set(pTop.hBh2,'Value',1,'String',{''});
            %if(~isAnn), strs={''}; else strs=int2str2(1:A.nStrm()); end
            %set(pBot.hStrm,'Value',1,'String',strs);
            if(isAnn), clrs=[.3 .3 .3; uniqueColors(ceil((A.k()-1)/6),6)]; end
            if(~isempty(pMid.hTxt)), set(pMid.hTxt,'String',''); end
            % update context menu for inserting behaviors
            if(isAnn), ns=A.getNames(); ks=A.getKeys(); k=A.k(); else k=0; end
            delete(pMid.hAdds); pMid.hAdds=zeros(1,k);
            ls=cell(1,k); for t=1:k, ls{t}=[ns{t} ' (' ks(t) ')']; end
            for t=1:k, pMid.hAdds(t)=uimenu(pMid.hAdd,'Label',ls{t}); end
            for t=1:k, set(pMid.hAdds(t),'callback',@(h,e) insertBh(t)); end
            % finally update display
            updateDisp();
        end
        
        function updateDisp()
            if(isempty(A)), return; end
            % record active stream
            strm = getActiveStream();
            % get current frame / annotation info
            f=dispApi.getFrame(); id=A.getId(f); type=A.getType(id); n=A.n();
            nFrame=A.nFrame(); bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
            % set bounds for zoomed slider
            h=pBot.hZm; s=get(h,'String'); v=get(h,'Value'); w=str2double(s{v});
            fL=max(0,fM-w/2); fR=min(nFrame,fL+w); fL=max(0,fR-w);
            % update standard GUI controls
            if( nFrame==1 ), set(pBot.hSl,'Enable','off'); else
                set(pBot.hSl,'Min',fL,'Max',fR-1,'Value',f,'Enable','on');
                s=1/(fR-fL-1); set(pBot.hSl,'SliderStep',[s s]);
            end
            % update behavior lists for fly 1
            A.setStrm(1);
            id=A.getId(f); type=A.getType(id); n=A.n();
            bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
            clr={'ForegroundColor',clrs(type,:)};
            set(pBot.hBh1,'Value',type,clr{:}); ss=ns(ts);
            for i=1:n, ss{i}=sprintf('%i-%i %s',bs(i)+1,bs(i+1),ss{i}); end
            set(pTop.hBh1,'String',ss,'Value',id,clr{:});
            % update behavior lists for fly 2
            A.setStrm(2);
            id=A.getId(f); type=A.getType(id); n=A.n();
            bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
            clr={'ForegroundColor',clrs(type,:)};
            set(pBot.hBh2,'Value',type,clr{:}); ss=ns(ts);
            for i=1:n, ss{i}=sprintf('%i-%i %s',bs(i)+1,bs(i+1),ss{i}); end
            set(pTop.hBh2,'String',ss,'Value',id,clr{:});
            % display text label containing info about all streams
            nSt=A.nStrm(); s=cell(1,nSt);
            for i=1:nSt,
                A.setStrm(i); j=A.getId(f);
                s{i}=A.getName(j);
                s{i}=['\color[rgb]{' num2str(clrs(A.getType(j),:)) '}' s{i}];
                if(i==1 && nSt>1),     clr_brk = [0 1 0];
                elseif(i==2 && nSt>1), clr_brk = [1 0 0];
                else,                  clr_brk = [1 1 1];
                end
                if (i==strm), brk1 = '[[['; brk2 = ']]]'; else, brk1 = '['; brk2 = ']'; end
                s{i}=['\color[rgb]{' num2str(clr_brk) '}' brk1 ...
                    s{i} ...
                    '\color[rgb]{' num2str(clr_brk) '}' brk2];
                if (i < nSt), s{i} = [s{i} '\color[rgb]{' num2str([1 1 1]) '}' '/']; end
            end
            s=[s{:}]; %s=s(1:end-3);
            s(s=='_')='-';% A.setStrm(strm0);
            set(pMid.hTxt,'String',s);
            % update bars - fly 1
            A.setStrm(1);
            bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
            idL=A.getId(fL); idR=A.getId(fR-1);
            bs1=[fL bs(idL+1:idR) fR]-fL; ts1=ts(idL:idR);
            colBar( pBot.hBar1, pBot.hSl, bs1, ts1);
            colBar( pMid.hBar1, pMid.hSl, bs, ts, fL, fR );
            % update bars - fly 2
            A.setStrm(2);
            bs=A.getBnds(); ts=A.getTypes(); ns=A.getNames();
            idL=A.getId(fL); idR=A.getId(fR-1);
            bs1=[fL bs(idL+1:idR) fR]-fL; ts1=ts(idL:idR);
            colBar( pBot.hBar2, pBot.hSl, bs1, ts1);
            colBar( pMid.hBar2, pMid.hSl, bs, ts, fL, fR );
            % update track bars - fly 1
            trkBar( pBot.hTrkBar1, pMid.hTrkBar1, trk.f1, fL+1, fR, nFrame, [0 1 0] );
            % update track bars - fly 2
            trkBar( pBot.hTrkBar2, pMid.hTrkBar2, trk.f2, fL+1, fR, nFrame, [1 0 0] );
            % update display of tracks
            if (trk.is_valid)
                % get positions of detections in current frame
                seq_ids = trk.frame_seq_list{f+1};
                xs = zeros([numel(seq_ids) 1]);
                ys = zeros([numel(seq_ids) 1]);
                for snum = 1:numel(seq_ids)
                    seq_id = seq_ids(snum);
                    seq = trk.sequences{seq_id};
                    xs(snum) = seq.pos.x((f+1)-seq.time_start+1);
                    ys(snum) = seq.pos.y((f+1)-seq.time_start+1);
                end
                % plot detections
                delete(pMid.hDetections);
                pMid.hDetections = zeros([numel(seq_ids) 1]);
                for snum = 1:numel(seq_ids)
                    hdet = plot(pMid.hAx,xs(snum),ys(snum),'b.','MarkerSize',25);
                    set(hdet,'UserData',seq_ids(snum));
                    set(hdet,'ButtonDownFcn',@(h,e) annApi.flyClickDet(h));
                    pMid.hDetections(snum) = hdet;
                end
                % plot active sequence for fly1
                [seq_id ind]= annApi.getActiveTrkSequence(trk.f1);
                if (~isempty(seq_id))
                    % get sequence
                    seq = trk.sequences{seq_id};
                    seq_time = ((f+1)-seq.time_start+1);
                    seq_len  = min(1000,((f+1)-trk.f1.fr_start(ind)+1));
                    % show tracks
                    if (get(pBot.hShwTrk1,'Value'))
                        delete(pMid.hTrack1);
                        pMid.hTrack1 = plot(pMid.hAx, ...
                            seq.pos.x((max(1,seq_time-seq_len)):seq_time), ...
                            seq.pos.y((max(1,seq_time-seq_len)):seq_time),'g' ...
                            );
                    else
                        set([pMid.hTrack1],'Visible','off');
                    end
                    % show detection
                    delete(pMid.hFly1Dot);
                    pMid.hFly1Dot = plot(pMid.hAx, ...
                        seq.pos.x(seq_time), seq.pos.y(seq_time),'g.','MarkerSize',25);
                    set(pMid.hFly1Dot,'ButtonDownFcn',@(h,e) annApi.flyClick(h));
                else
                    set([pMid.hFly1Dot pMid.hTrack1],'Visible','off');
                end
                % plot active sequence for fly2
                [seq_id ind]= annApi.getActiveTrkSequence(trk.f2);
                if (~isempty(seq_id))
                    % get sequence
                    seq = trk.sequences{seq_id};
                    seq_time = ((f+1)-seq.time_start+1);
                    seq_len  = min(1000,((f+1)-trk.f2.fr_start(ind)+1));
                    % show tracks
                    if (get(pBot.hShwTrk2,'Value'))
                        delete(pMid.hTrack2);
                        pMid.hTrack2 = plot(pMid.hAx, ...
                            seq.pos.x((max(1,seq_time-seq_len)):seq_time), ...
                            seq.pos.y((max(1,seq_time-seq_len)):seq_time),'r' ...
                            );
                    else
                        set([pMid.hTrack2],'Visible','off');
                    end
                    % show detection
                    delete(pMid.hFly2Dot);
                    pMid.hFly2Dot = plot(pMid.hAx, ...
                        seq.pos.x(seq_time), seq.pos.y(seq_time),'r.','MarkerSize',25);
                    set(pMid.hFly2Dot,'ButtonDownFcn',@(h,e) annApi.flyClick(h));
                else
                    set([pMid.hFly2Dot pMid.hTrack2],'Visible','off');
                end
            end
            % restore active stream
            A.setStrm(strm);
            % finally backup annotation
            menuApi.annBackup();
            
            function colBar( hBar, hSl, bs, ts, fL, fR )
                % get position of hBar
                p = get(hBar,'Position'); w=ceil(p(3)); h=ceil(p(4));
                % get hbar image
                nFrame=bs(end); bs=round(bs/nFrame*w); I=zeros(w,1);
                for i1=1:length(ts), I(bs(i1)+1:bs(i1+1),:)=ts(i1); end
                I=permute(clrs(I,:),[3 1 2]); I=I(ones(1,h),:,:);
                if(nargin==6)
                    fL=round(fL/nFrame*w); fR=max(1,round(fR/nFrame*w));
                    I(:,[fL+1 fR],:)=1; I([1 end],fL+1:fR,:)=1;
                end
                set(hBar,'CData',I);
            end
            
            function trkBar( hTrkBotBar, hTrkMidBar, fly, fL, fR, nFrame, clr )
                % get positions of bars
                p_mid = get(hTrkMidBar,'Position'); w_mid=ceil(p_mid(3)); h_mid=ceil(p_mid(4));
                p_bot = get(hTrkBotBar,'Position'); w_bot=ceil(p_bot(3)); h_bot=ceil(p_bot(4));
                % set bar images
                I_mid = zeros([1 w_mid]);
                I_bot = zeros([1 w_bot]);
                if (trk.is_valid)
                    for n=1:numel(fly.seq_id)
                        s = fly.fr_start(n); e = fly.fr_end(n);
                        s_mid = max(1,round(s./nFrame.*w_mid));
                        e_mid = max(1,round(e./nFrame.*w_mid));
                        I_mid(s_mid:e_mid)=1;
                        if (~((e < fL) || (s > fR)))
                            s_bot = max(1,round(max(s-fL+1,1)./(fR-fL+1).*w_bot));
                            e_bot = max(1,round(min(e-fL+1,fR-fL+1)./(fR-fL+1).*w_bot));
                            I_bot(s_bot:e_bot)=1;
                        end
                    end
                end
                I_mid = repmat(I_mid,[h_mid 1 3]).*repmat(reshape(clr,[1 1 3]),[h_mid w_mid]);
                I_bot = repmat(I_bot,[h_bot 1 3]).*repmat(reshape(clr,[1 1 3]),[h_bot w_bot]);
                set(hTrkMidBar,'CData',I_mid);
                set(hTrkBotBar,'CData',I_bot);
            end
        end
        
        function setFrame(flag)
            assert(~isempty(A)); rng=get(pBot.hSl,{'Min','Max'});
            f = min(max(round(get(pBot.hSl,'Value')+flag),rng{1}),rng{2});
            setCenter = (f==rng{1} && f>0) || (f==rng{2} && f<A.nFrame()-1);
            set(pBot.hSl,'Value',f); dispApi.setFrame(f,0,setCenter);
        end
        
        function buttonPress( str )
            assert(~isempty(A));
            f=dispApi.getFrame(); id=A.getId(f);
            switch str
                case 'selectFly1'
                    set(pBot.hFly1,'Value',1); set(pBot.hFly2,'Value',0);
                    A.setStrm(1); dispApi.requestUpdate();
                case 'selectFly2'
                    set(pBot.hFly1,'Value',0); set(pBot.hFly2,'Value',1);
                    A.setStrm(2); dispApi.requestUpdate();
                case 'setType1'
                    type = get(pBot.hBh1,'Value'); strm = annApi.getActiveStream();
                    A.setStrm(1); A.setType(id,type); dispApi.requestUpdate();
                    A.setStrm(strm); set(pBot.hBh1,'BackgroundColor','k');
                case 'setType2'
                    type = get(pBot.hBh2,'Value'); strm = annApi.getActiveStream();
                    A.setStrm(2); A.setType(id,type); dispApi.requestUpdate();
                    A.setStrm(strm); set(pBot.hBh2,'BackgroundColor','k');
                case 'setZoom'
                    dispApi.setFrame(f,0)
                case 'moveRight'
                    if(id==A.n()), return; end %id==A.getId(get(pBot.hSl,'Max'))
                    A.move(id+1,f+1); dispApi.requestUpdate();
                case 'moveLeft'
                    if(id==1), return; end %id==A.getId(get(pBot.hSl,'Min'))
                    A.move(id,f); dispApi.requestUpdate();
                case 'delete'
                    A.setType(id,1); %A.delete( id );
                    dispApi.requestUpdate();
                case 'prevBeh'
                    f1=A.getStart(id); if(id>1 && f==f1), f1=A.getStart(id-1); end
                    dispApi.setFrame(f1,0);
                case 'nextBeh'
                    f1=A.getEnd(id); if(id<A.n()), f1=f1+1; end
                    dispApi.setFrame(f1,0);
                case 'toggleTrack1'
                    dispApi.requestUpdate();
                case 'toggleTrack2'
                    dispApi.requestUpdate();
                case 'gotoBeh1'
                    strm = annApi.getActiveStream(); A.setStrm(1);
                    f1=A.getStart(get(pTop.hBh1,'Value')); dispApi.setFrame(f1,0);
                    A.setStrm(strm); set(pTop.hBh1,'BackgroundColor','k');
                case 'gotoBeh2'
                    strm = annApi.getActiveStream(); A.setStrm(2);
                    f1=A.getStart(get(pTop.hBh2,'Value')); dispApi.setFrame(f1,0);
                    A.setStrm(strm); set(pTop.hBh2,'BackgroundColor','k');
                otherwise
                    assert(false);
            end
        end
        
        function insertBh( type )
            if(isempty(A)), return; end
            A.add(type,dispApi.getFrame());
            dispApi.requestUpdate();
        end
        
        function setCenter( frame ), fM=round(frame); end
    end

    function api = dispMakeApi()
        % create api
        lastspeed = 0;
        [sr, audio, info, nFrame, speed, curInd, hs, ...
            hImg, needUpdate, prevTime, looping ]=deal([]);
        api = struct( ...
            'setVid',@setVid, 'setAud',@setAud, ...
            'setSpeedCb',@setSpeedCb, ...
            'setSpeedCbPlayPause',@setSpeedCbPlayPause, ...
            'setSpeedCbPause',@setSpeedCbPause, ...
            'setSpeedCbReset',@setSpeedCbReset, ...
            'getInfo',@getInfo, ...
            'getFrame',@getFrame, ...
            'setFrame',@setFrame, ...
            'requestUpdate',@requestUpdate, ...
            'exportVid',@exportVid);
        set(pMid.hSl,    'Callback',@(h,evnt) setFrameCb(0));
        set(pTop.hFrmInd,'Callback',@(h,evnt) setFrameCb(1));
        
        function setVid( sr1 )
            % reset local variables
            if(isstruct(sr)), sr=sr.close(); end
            if(~isempty(hs)), delete(hs); hs=[]; end
            [sr, audio, info, nFrame, speed, curInd, hs, ...
                hImg, needUpdate, prevTime, looping ]=deal([]);
            sr=sr1; nFrame=0; looping=0; speed=-1; setFrame( 0, 0 );
            % update GUI
            %if(~isstruct(sr)), cla(pMid.hAx); pMid.hTxt=[]; else
            if(~isstruct(sr)), pMid.hTxt=[]; else
                info=sr.getinfo(); nFrame=info.numFrames;
                sr.seek(0); s=1/(nFrame-1); ss={'SliderStep',[s,s]};
                if(nFrame>1), set(pMid.hSl,'Max',nFrame-1,ss{:}); end
                hImg = imshow( zeros(info.height,info.width,'uint8') );
                set(pMid.hAx,'XLim',[0 info.width]);
                set(pMid.hAx,'YLim',[0 info.height]);
                set(hImg,'UIContextMenu',pMid.hAdd);
                pMid.hTxt=text(0,0,'','FontSize',25,'Units','pixels',...
                    'HorizontalAlignment','center', 'VerticalAlignment','top');
                %fprintf('fps of video = %f\n', info.fps); % temp display
            end
            set(pMid.hSl,'Value',0); v=(nFrame>1)+1;
            en={'off','on'}; set(pMid.hSl,'Enable',en{v});
            en={'inactive','on'}; set(pTop.hFrmInd,'Enable',en{v});
            set(pTop.hFrmInd,'String','0'); set(pTop.hTmVal,'String','0:00');
            set(pTop.hFrmNum,'String',[' / ' int2str(nFrame)]);
            % update display
            feval(get(hFig,'ResizeFcn'));
            requestUpdate();
        end
        
        function exportVid( nm )
            % prompt for range of frames to export
            prompt={'Start frame:','End frame:','Frame Skip','Quality (0-100)'};
            wi=getInfo(); dfs={'1', num2str(wi.numFrames),'1','80'};
            rng=str2double(inputdlg(prompt,'Select Export Range',1,dfs));
            if(any(isnan(rng)) || rng(1)>rng(2)), error('invalid range'); end
            f0=max(1,rng(1)); f1=min(rng(2),wi.numFrames); skip=max(1,rng(3));
            wi.codec='jpg'; wi.quality=rng(4);
            try %#ok<ALIGN> % export video
                for f=f0:skip:f1
                    setFrame(f,0); I=getframe(pMid.hAx); I=I.cdata;
                    c=2; I=I(1+c:end-c,1+c:end-c,:); h=size(I,1); w=size(I,2);
                    if(f==f0), wi.height=h; wi.width=w; sw=seqIo(nm,'w',wi); end
                    sw.addframe(I);
                end; sw.close();
            catch err, sw.close(); throw(err); end
        end
        
        function setAud(y,fs,nb)
            a = abs(1 - (length(y)/fs) / (nFrame/info.fps));
            if(a>.01), error('Audio/video mismatch.'); end
            audio.fPlay=audioplayer(y,fs,nb);
            audio.bPlay=audioplayer(flipud(y),fs,nb);
            audio.fs=fs; audio.ln=length(y); setSpeed(speed);
            requestUpdate();
        end
        
        function dispLoop()
            if(looping), return; end; looping=1;
            while( 1 )
                % exit if appropriate, or if vid not loaded do nothing
                if(~isstruct(sr) || ~isstruct(info)), looping=0; return; end
                
                % stop playing video if at begin/end
                if((speed>0&&curInd==nFrame-1) || (speed<0&&curInd==0))
                    setSpeed(0); needUpdate=1;
                end
                
                % increment/decrement curInd appropriately
                if( speed~=0 )
                    t=clock(); eTime=etime(t,prevTime);
                    del = speed * max(10,info.fps) * min(.1,eTime);
                    if( speed>0 ), del=min(del, nFrame-curInd-1 ); end
                    if( speed<0 ), del=max(del, -curInd ); end
                    setFrame(curInd+del, speed); prevTime=t; needUpdate=1;
                end
                
                % update display if necessary
                if(~needUpdate), looping=0; return; else
                    sr.seek( round(curInd) ); I=sr.getframe();
                    if(~isempty(hs)), delete(hs); hs=[]; end
                    assert(~isempty(I)); set(hImg,'CData',I);
                    set(pMid.hSl,'Value',curInd);
                    set(pTop.hFrmInd,'String',int2str(round(curInd+1)));
                    c=round(curInd/info.fps); c1=floor(c/60); c2=mod(c,60);
                    set(pTop.hTmVal,'String',sprintf('%i:%02i',c1,c2));
                    annApi.updateDisp(); needUpdate=false; drawnow();
                end
            end
        end
        
        function setSpeedCb( flag )
            if(~isstruct(sr)),return; end
            if( flag==0 )
                setSpeed( 0 );
            elseif( speed==0 )
                setSpeed( flag ); prevTime=clock();
            elseif( abs(speed) < 8 )
                setSpeed( speed + 0.2.*sign(flag) );
            elseif( sign(speed)==flag && abs(speed)<256 )
                setSpeed( speed*2 );
            elseif( sign(speed)~=flag && abs(speed)>8 )
                setSpeed( speed/2 );
                %elseif( sign(speed)~=flag )
                %  setSpeed( 0 );
            end
            if (abs(speed)<0.2), setSpeed(0); end
            lastspeed = speed;
            requestUpdate();
        end
        
        function setSpeedCbPlayPause()
            if ( speed == 0 )
                setSpeed(lastspeed);
            else
                lastspeed = speed;
                setSpeed(0);
            end
            requestUpdate();
        end
        
        function setSpeedCbPause()
            if ( speed ~= 0 )
                lastspeed = speed;
                setSpeed(0);
            end
            requestUpdate();
        end
        
        function setSpeedCbReset()
            setSpeed(0);
            setSpeed(1);
            requestUpdate();
        end
        
        function setSpeed( speed1 )
            if((speed1>0&&curInd==nFrame-1)||(speed1<0&&curInd==0)),speed1=0;end
            speed=speed1; p=abs(speed); if(speed<0), ss='-'; else ss=''; end
            %if(p<1 && p~=0), s=['1/' int2str(1/p)]; else s=int2str(p); end
            s=num2str(p);
            set(pTop.hPlySpd,'String',[ss s 'x']);
            if(~isempty(audio))
                stop(audio.fPlay); stop(audio.bPlay); if(speed==0), return; end;
                st=curInd/(nFrame-1); if(speed<0), st=1-st; end; st=st*audio.ln+1;
                if(speed>0), plr=audio.fPlay; else plr=audio.bPlay; end;
                set(plr,'SampleRate',audio.fs*p); play(plr,st);
            end
        end
        
        function setFrameCb(flag)
            if( flag==0 )
                f=round(get(pMid.hSl,'Value')); set(pMid.hSl,'Value',f);
            elseif(flag==1)
                f=str2double(get(pTop.hFrmInd,'String'));
                if(isnan(f)), requestUpdate(); return; else f=f-1; end
            end
            setFrame(f,0);
        end
        
        function setFrame( curInd1, speed1, setCenter )
            curInd=max(0,min(curInd1,nFrame-1));
            if( speed~=speed1 ), setSpeed(speed1); end
            if(nargin<3 || setCenter), annApi.setCenter(curInd); end
            requestUpdate();
        end
        
        function requestUpdate(), needUpdate=true; dispLoop(); end
        
        function info1 = getInfo(), info1=info; end
        
        function curInd1 = getFrame(), curInd1=round(curInd); end
    end

    function api = menuMakeApi()
        % create api
        [fVid fAnn lastSave]=deal([]);
        api = struct('vidClose',@vidClose, 'annClose',@annClose, ...
            'vidOpen',@vidOpen, 'audOpen',@audOpen, 'trkOpen',@trkOpen, ...
            'annOpen',@annOpen, 'annBackup',@annBackup );
        set(menu.hVidOpn,'Callback',@(h,envt) vidOpen(1) );
        set(menu.hVidsOpn,'Callback',@(h,envt) vidOpen(2) );
        set(menu.hVidExp,'Callback',@(h,envt) vidExport() );
        set(menu.hVidCls,'Callback',@(h,envt) vidClose() );
        set(menu.hVidAud,'Callback',@(h,envt) audOpen() );
        set(menu.hAnnNew,'Callback',@(h,envt) annNew(0) );
        set(menu.hAnnOpn,'Callback',@(h,envt) annOpen(0) );
        set(menu.hAnnCls,'Callback',@(h,envt) annClose() );
        set(menu.hAnnSav,'Callback',@(h,envt) annSave() );
        set(menu.hAnnCnf,'Callback',@(h,envt) annNew(1) );
        set(menu.hAnnMrg,'Callback',@(h,envt) annOpen(1) );
        set(menu.hTrkOpn,'Callback',@(h,envt) trkOpen(0) );
        set(menu.hTrkCls,'Callback',@(h,envt) trkOpen([]) );
        
        function updateMenus()
            m=menu; if(isempty(fVid)), en='off'; else en='on'; end
            set([m.hVidExp m.hVidCls m.hVidAud m.hAnnNew m.hAnnOpn ...
                m.hTrkOpn m.hTrkCls],'Enable',en);
            if(isempty(A)), en='off'; else en='on'; end
            set([m.hAnnSav m.hAnnCls m.hAnnCnf],'Enable',en);
            nm='Caltech Behavior Annotator';
            if(~isempty(fVid)), [d,nm1]=fileparts(fVid); nm=[nm ' - ' nm1]; end
            set(hFig,'Name',nm); annApi.updateAnn(); dispApi.requestUpdate();
        end
        
        function vidClose()
            if(~isempty(A))
                annClose();
            end;
            trkOpen([]);
            fVid=[];
            dispApi.setVid([]);
            updateMenus();
        end
        
        function vidOpen( flag )
            if(isempty(fVid))
                d='D:\Videos\';
            else
                d=fileparts(fVid);
            end
            if(all(ischar(flag)))
                [d f]=fileparts(flag);
                if(isempty(d))
                    d='.';
                end;
                d=[d '/'];
                f=[f '.seq'];
                flag=1;
            elseif( flag==1 )
                [f,d]=uigetfile('*.seq','Select video',[d '/*.seq']);
            elseif( flag==2 )
                [f,d]=uigetfile('*.seq','Select first video',[d '/*.seq']);
                [f2,d2]=uigetfile('*.seq','Select second video',[d '/*.seq']);
                if( f2==0 )
                    return;
                end
            end
            if( f==0 )
                return;
            end
            vidClose();
            fVid=[d f];
            try
                if( flag==1 )
                    sr=seqIo(fVid,'r');
                else
                    sr=seqIo({fVid,[d2 f2]},'rdual');
                end
                dispApi.setVid(sr);
                updateMenus();
            catch er
                errordlg(['Failed to load: ' fVid '. ' er.message],'Error');
                fVid=[];
                return;
            end
        end
        
        function vidExport()
            assert(~isempty(fVid)); fNm=[fVid(1:end-4) '-copy.seq'];
            [f,d] = uiputfile('*.seq','Select export file',fNm);
            if(f==0), return; end; f=[d f];
            try dispApi.exportVid(f); catch er
                errordlg(['Failed to export: ' f '. ' er.message],'Error'); end
        end
        
        function audOpen( fAud )
            if( nargin==0 ), [f,d]=uigetfile('*.wav','Select audio',...
                    [fVid(1:end-3) 'wav']); if(f==0), return; end; fAud=[d f]; end
            try
                [y,fs,nb]=wavread(fAud); dispApi.setAud(y,fs,nb);
            catch er
                errordlg(['Failed to load: ' fAud '. ' er.message],'Error');
            end
        end
        
        function annClose()
            assert(~isempty(A)); qstr='Save Current Annotation?';
            button = questdlg(qstr,'Save','yes','no','yes');
            if(strcmp(button,'yes')); annSave(); end
            [fAnn A lastSave]=deal([]);
            trk.f1.fr_start = [];
            trk.f1.fr_end   = [];
            trk.f1.seq_id   = [];
            trk.f2.fr_start = [];
            trk.f2.fr_end   = [];
            trk.f2.seq_id   = [];
            updateMenus();
        end
        
        function annOpen( flag )
            assert(~isempty(fVid)); A1=A; if(~isempty(A)), annClose(); end; e='';
            
            if( all(ischar(flag)) )
                f=flag;
                flag=0;
                [d,f,e]=fileparts(f);
                if(isempty(d))
                    d='.';
                end;
                d=[d '/'];
                if(isempty(e) && exist([d f '.txt'],'file'))
                    e='.txt';
                end
                if(isempty(e) && exist([d f '.bAnn'],'file'))
                    e='.bAnn';
                end
            else
                if(isempty(fAnn))
                    fAnn=[fVid(1:end-3) 'txt'];
                end
                % Open Weizhe's annotation file
                [dA, fA, eA] = fileparts(fVid);
%                 path = setVideoPath(dA, [fA, eA]);  XZ
                path.outputPath = dA;
                DefaultAnnFolder = path.outputPath;
                % End of defining the path of Weizhe's annotation file
                [f, d] = uigetfile('*.txt;*.bAnn','Select Annotation',DefaultAnnFolder);
            end
            if( f==0 )
                return;
            end
            fAnn=[d f e];
            try
                if( flag==1 )
                    A=A1; assert(~isempty(A)); A.merge(fAnn);
                elseif( flag==0 )
                    % load annotations
                    A=behaviorData('load',fAnn);
                    info=dispApi.getInfo(); nFrame=info.numFrames;
                    if(A.nFrame()~=nFrame), error('Annotation/video mismatch.'); end
                    % load track annotations
                    [pathstr name ext] = fileparts(fAnn);
                    fTrk = fullfile(pathstr,[name '-ann.mat']);
                    if (exist(fTrk,'file'))
                        tmp = load(fTrk);
                        trk.f1 = tmp.f1;
                        trk.f2 = tmp.f2;
                    end
                end
                updateMenus();
            catch er
                errordlg(['Failed to load: ' fAnn '. ' er.message],'Error');
                [fAnn A lastSave]=deal([]);
                trk.f1.fr_start = [];
                trk.f1.fr_end   = [];
                trk.f1.seq_id   = [];
                trk.f2.fr_start = [];
                trk.f2.fr_end   = [];
                trk.f2.seq_id   = [];
                return;
            end
        end
        
        function annSave()
            assert(~isempty(fVid) && ~isempty(A) && ~isempty(fAnn));
            [f,d] = uiputfile('*.txt;*.bAnn','Select annotation',fAnn);
            if( f==0 ), return; end; fAnn=[d f]; A.save(fAnn);
            [pathstr name ext] = fileparts(fAnn);
            fTrk = fullfile(pathstr,[name '-ann.mat']);
            f1 = trk.f1; f2 = trk.f2;
            % save(fTrk,'f1','f2');
        end
        
        function annNew( update )
            assert(~isempty(fVid)); A1=A; if(~isempty(A)), annClose(); end
            fNm=[fileparts(fVid) '/config.txt'];
            [f,d] = uigetfile('*.txt','Select config file',fNm);
            if( f==0 ), return; end; f=[d f]; fAnn=[fVid(1:end-3) 'txt'];
            try
                if( update )
                    A=A1; assert(~isempty(A)); A.recreate(f); updateMenus();
                else
                    info=dispApi.getInfo(); nFrame=info.numFrames;
                    A=behaviorData('create',f,nFrame); updateMenus();
                    trk.f1.fr_start = [];
                    trk.f1.fr_end   = [];
                    trk.f1.seq_id   = [];
                    trk.f2.fr_start = [];
                    trk.f2.fr_end   = [];
                    trk.f2.seq_id   = [];
                end
            catch er
                errordlg(er.message, 'File Error'); A=[];
            end
        end
        
        function annBackup()
            if( isempty(lastSave) || etime(clock,lastSave)>60 )
                [d f]=fileparts(fAnn); f=[d '/' f '-backup.txt'];
                assert(~isempty(A)); % A.save(f);
                [pathstr name ext] = fileparts(fAnn);
                fTrk = fullfile(pathstr,[name '-ann-trk-backup.mat']);
                f1 = trk.f1; f2 = trk.f2;
                % save(fTrk,'f1','f2');
                lastSave=clock();
            end
        end
        
        function trkOpen( flag )
            % check if closing track
            if(isempty(flag))
                % reset track
                trk.is_valid = false;
                trk.frame_seq_list = {};
                trk.sequences      = {};
                % hide track display
                delete(pMid.hDetections); pMid.hDetections=[];
                set([pMid.hFly1Dot pMid.hFly2Dot pMid.hTrack1 pMid.hTrack2],'Visible','off');
                dispApi.requestUpdate();
                return;
            end
            % select track to open
            if( all(ischar(flag)) ), f=flag; else fNm=[fVid(1:end-3) 'mat'];
                [f,d]=uigetfile('*-track.mat','Load Tracking',fNm); f=[d f];
            end
            assert(~isempty(fVid)); if(f==0), return; end
            try
                tmp=load(f);
                trk.is_valid       = true;
                trk.frame_seq_list = tmp.trk.frame_seq_list;
                trk.sequences      = tmp.trk.sequences;
            catch er
                trk.is_valid = false;
                trk.frame_seq_list = {};
                trk.sequences      = {};
                errordlg(['Failed to load: ' f '. ' er.message],'Error');
            end
            dispApi.requestUpdate();
        end
    end
end
