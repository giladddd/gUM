eScanP='/media/deni/bigdrive/SPIRAL_ASL/S03/RawData/';
BaseFN='meas_MID129_gBP_ep2d_bold_multiecho_ASL_SMS_Spi_FID45302';
RefFldMapP=[ScanP 'meas_MID122_BP_fieldmap_5echosX_FID45295' filesep];

ScanP='/media/deni/bigdrive/SPIRAL_ASL/S04/RawData/';
BaseFN='meas_MID363_gBP_ep2d_bold_multiecho_ASL_SMS_Spi_FID46893';
RefFldMapP=[ScanP 'meas_MID354_BP_fieldmap_9echos_2mm_Full_FID46884' filesep];

ScanP='/autofs/cluster/kawin/Gilad/PhantomBay4/';
BaseFN='meas_MID00656_FID03768_gSpi2d_T20_VD1_800k_d110';
RefFldMapP=[ScanP 'meas_MID00526_FID03646_gre_te7_40' filesep];

ScanP='/autofs/cluster/kawin/Gilad/Bay3/';
BaseFN='meas_MID223_gBP_Spi_1200ns_T20_VD1_d110_FID65150';
RefFldMapP=[ScanP 'meas_MID209_MEMPRAGE_4e_p2_1mm_iso_FID65136' filesep];

ScanP='//autofs/cluster/kawin/Gilad/Bay4Prisma5ms10ms/';
BaseFN='meas_MID01067_FID07920_gSpi2d_Base_T12_30rep110_VD122_Dwell1100';
RefFldMapP=[ScanP 'meas_MID01026_FID07879_gre_te7_40' filesep];

ScanP='/autofs/cluster/kawin/Gilad/Bay4Kawin5ms10ms/';
BaseFN='meas_MID01088_FID09952_gSpi2d_T12_d110_Dw11_40rep_VD123';
RefFldMapP=[ScanP 'meas_MID01104_FID09968_gre_te7_40' filesep];

MIDStr=BaseFN(6:11);
FN=[ScanP BaseFN '.dat'];
disp('ok');
%%
mainP=[ScanP BaseFN];
mkdir(mainP);

system(['chmod +777 -R ' mainP]);
disp([mainP ' Created']);
%% Read raw
AData = mapVBVD(FN);
if(iscell(AData))
    ADatax=AData{end};
else
    ADatax=AData;
end
asSlice=ADatax.hdr.Phoenix.sSliceArray.asSlice;
if(iscell(asSlice(1)))
    asSlice=[ADatax.hdr.Phoenix.sSliceArray.asSlice{:}];
end

nSlices=numel(ADatax.hdr.Phoenix.sSliceArray.asSlice);
try
    WipMemBlock=ADatax.hdr.MeasYaps.sWiPMemBlock;
catch
    WipMemBlock=ADatax.hdr.MeasYaps.sWipMemBlock;
end
MB=1; %WipMemBlock.alFree{9};
% MB
nSlicesNoMB=nSlices/MB;

% nRepsHdr=1+ADatax.hdr.Meas.lRepetitions;
nRepsHdr=1+ADatax.hdr.MeasYaps.lRepetitions;
%%
TrajType=WipMemBlock.adFree{12};
ResType=floor((TrajType-10)/2)+1; % 2,1.5,1
TimingType=mod(TrajType-10,2)+1; % 5ms, 10ms
load('GAll5ms10ms.mat');
GTrajaCBase=GAll(:,TimingType,ResType);
%% Do something with the noise!
% noise=AData{1}.noise();
%%
for s=1:nSlices
    try
        SlbLoc(1,s)=asSlice(s).sPosition.dSag;
    catch
        SlbLoc(1,s)=0;
    end
    try
        SlbLoc(2,s)=asSlice(s).sPosition.dCor;
    catch
        SlbLoc(2,s)=0;
    end
    try
        SlbLoc(3,s)=asSlice(s).sPosition.dTra;
    catch
        SlbLoc(3,s)=0;
    end
end

RotMat = transpose(Quat2RotMat(ADatax.image.slicePos(4:7, 100)));
RotatedLocs=RotMat.'*SlbLoc;

[U IA IB]=unique(ADatax.image.slicePos(3,:));
Qoffset=ADatax.image.slicePos(1:3,IA);

Ord=[2:2:nSlices 1:2:nSlices];
[~,ROrd]=sort(Ord);

try
    FOVx=ADatax.hdr.Meas.ReadFOV;
catch
    FOVx=ADatax.hdr.Config.ReadFoV;
end

FOVx=220;

dFOV=FOVx/1000;

FOV_mm=FOVx;


disp('ok');

GradReduceFac=WipMemBlock.adFree{4};
PhiRotPerRep=WipMemBlock.adFree{8};
AcqDwellTime_us=WipMemBlock.adFree{13}/1000;
%%
ADCsToRead=1:10;
% ADCsToRead=1;
SlicesToRead=[3];
RepsToRead=1:(nRepsHdr-1);
ADataIsL=ADatax.image(:,:,:,:,SlicesToRead,3,:,:,RepsToRead,:,ADCsToRead,:,:,:,:,:,:);

% ADataIsL=ADatax.image(:,:,:,:,SlicesToRead,3,:,:,RepsToRead,:,:,:,:,:,:,:,:);

ADataIsL=permute(ADataIsL,[1 2 9 11 5 3:4 6:8 10]);
ADataIsL=CombineDims(ADataIsL,[4 1]);
disp('Read data');
%%
GTrajaC=GTrajaCBase/GradReduceFac;

gammaMHz=42.574; % MHz/T
TwoPiGammaMHz=gammaMHz*2*pi;
GradDwellTime_us=10;
GradDwellTime_ms=GradDwellTime_us/1000;

g=GTrajaC;
k=cumsum([0; g])*GradDwellTime_ms*TwoPiGammaMHz; % mT/m*ms * 2*pi*MHz/T = rad/m
s=diff(g)/GradDwellTime_ms;

kK=k*FOV_mm/1000/2/pi;

Kmax=ceil(max(abs(kK)));
NTrg=Kmax*2;
res_mm=FOVx/(max(abs(kK))*2);
%%
figure;
plot(kK);
axis square;
axis equal;
ylabel('k');
%%
ChRMS=grmss(ADataIsL,[1 3]);
[SChRMS ChOrd]=sort(ChRMS,'descend');
% Data=squeeze(ADataIsL(:,ChOrd(1),1:nRepsToUse));

Ch2D=CombineDims(ADataIsL,[3 1]);
[~,S,sccmtx] = svd(Ch2D(1:10:end,:),'econ');
clear Ch2D 

ncc=31;
ADataIsLCC=single(zeros([size(ADataIsL,1) ncc size(ADataIsL,3)]));
for i=1:ncc
    ADataIsLCC(:,i,:)=sum(ADataIsL.*permute(sccmtx(:,i),[3 1 4 5 6 7 8 9 2]),2);
end
DataC=permute(ADataIsLCC,[1 3 2]);
disp('ok cc');
%%
TrgSz=[NTrg NTrg];
OnesSens=ones(TrgSz);
%%
% Traj=interp1(1:5001,kK(1:5001),1:(AcqDwellTime_us/GradDwellTime_us):5001-0.0001);
%
Extra=4;
% Delay_us=-2.5; % positive data rightward %-6; % clockwise
Delay_us=4;
Delay_us=2;
Delay_us=1;
kKA=[zeros(4,1); kK; repmat(kK(end),[10 1])]; % in us
AcqTimePoints_us=Extra*GradDwellTime_us+Delay_us+(0:AcqDwellTime_us:50000);

Traj=interp1((0:(numel(kKA)-1))*GradDwellTime_us,kKA,AcqTimePoints_us);
disp('ok delay');
%%
TrajPeaks=quickFindPeaks(diff(abs(Traj),2,2),0.5);
figure;
DataToPlot=grmss(ADataIsL,2);
Mx=gmax(DataToPlot);
for i=1:numel(TrajPeaks)
    subplot(1,numel(TrajPeaks),i);
    plot(abs(Traj)/50000,'k','LineWidth',2);hold on
    plot([TrajPeaks(i) TrajPeaks(i)],gmax(DataToPlot(TrajPeaks(i)+(-100:100),:))*[0 1],'r','LineWidth',2);
    plot(DataToPlot);
    xlim( max(1,min(numel(Traj),TrajPeaks(i)+([-1 1]*100)))   );
    ylim([0,Mx]);
    title([ num2str(AcqTimePoints_us(TrajPeaks(i))/1000,'%.1f') 'ms'],'FontSize',20);
    set(gca,'YTick',[]);
    if(i==1)
        ylabel(BaseFN,'interpreter','None','FontSize',14);
    end
end
MaximizeFig;
%%
nRepsToUse=nRepsHdr-1;
TrajM=Traj.*exp(-1i*2*pi*PhiRotPerRep/360*(0:nRepsToUse-1)');
% Grad delay
% GradDelayPoints=0; % positive clockwise
TrajMa=TrajM;
DataC=permute(ADataIsLCC,[1 3 2]);
% DataC=circshift(DataC,-GradDelayPoints,1);
% TrajMa=[zeros([size(TrajM,1) GradDelayPoints]) TrajM(:,1:end-GradDelayPoints)];
%
% DataC=permute(ADataIsL,[1 3 2]);
%
TrajM=TrajMa*exp(1i*2*pi*0/360)/1.01; % positive counter clockwize

BARTTraj=cat(3,real(TrajM),imag(TrajM),imag(TrajM)*0);
BARTTrajP=permute(BARTTraj,[3 2 1]);

dx=RotatedLocs(2,1)/ADatax.hdr.Phoenix.sSliceArray.asSlice{1}.dReadoutFOV;
dy=RotatedLocs(1,1)/ADatax.hdr.Phoenix.sSliceArray.asSlice{1}.dPhaseFOV;

kx=BARTTrajP(1,:,:)*2*pi;
ky=BARTTrajP(2,:,:)*2*pi;

% modx=conj(exp(1i.*(dx*kx+dy*ky)));
modx=exp(-1i.*(dx*kx+dy*ky));
disp('ok mod');
%% Recon each channel separately, no CC
nTrajToUse=size(BARTTrajP,2);
TrajPartToUse=0000+(1:2000);
RepsToUse=1:(nRepsHdr-1);

DataPC=permute(ADataIsL(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 3 5 6 7 8 2]).*modx;
OnesSensC=repmat(OnesSens,[1 1 1 1 1 1 1 size(DataPC,8)]);

Rec1p=bart('pics -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),(DataPC(:,TrajPartToUse,RepsToUse,1,1,1,1,:)),OnesSensC);
% fgmontage(Rec1cp)
fgmontage(grmss(Rec1p,8));
title([num2str(numel(RepsToUse)) ' shots data x ' num2str(numel(TrajPartToUse)) 'points, pre channel recon, RMS']);
%%
Rec1pRMS=grmss(Rec1p,8);
Msk=imfillholesBySlices(Rec1pRMS>0.001);
se = strel('disk', 3);
DMsk=imdilate(Msk,se,'same');
SelfSens=RunESPIRiTForSensMapsMultiMap(squeeze(Rec1p).*DMsk,0,TrgSz);
SelfSens1=SelfSens(:,:,:,1);
disp('ok SelfSens');
%% Recon each channel separately, CC
DataPC=permute(DataC(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 2 5 6 7 8 3]).*modx;
OnesSensC=repmat(OnesSens,[1 1 1 1 1 1 1 ncc]);

% Rec1cp=bart('pics -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),(DataPC(:,TrajPartToUse,RepsToUse,1,1,1,1,:)),OnesSensC);
% % fgmontage(Rec1cp)
% fgmontage(grmss(Rec1cp,8));
% title([num2str(numel(RepsToUse)) ' shots data x ' num2str(numel(TrajPartToUse)) 'points, per compressed channel recon, RMS']);
disp('ok rec pre channel cc');
%%
% RLocs=load([RefFldMapP 'Locs.mat']);
% RefLocs=RLocs.RotatedLocs;
% CurzLocs=RotatedLocs(3,:);
% RefzLocs=RefLocs(3,:);
% CurSlizLoc=CurzLocs(Ord(SlicesToRead));
% [MinRefD, CorrespondingRefSliIdx]=min(abs(RefzLocs-CurSlizLoc));
%%
% RefFOV=240;
% % EffFOV=res_mm*NTrg;
% % cEffFOV=ceil(EffFOV);
% % 
% % cEffFOV=220
% 
% SensB=load([RefFldMapP 'Sens.mat']);
% SensB=SensB.SensB;
% 
% SensBx=padarray(SensB(:,:,:,:,1),[0 2 0 0],'both');
% SensBx=SensBx(:,:,:,CorrespondingRefSliIdx);
% SensBx=(imresizeBySlices(SensBx,TrgSz));
% SensBx=rot90(SensBx);
% CurSens=SensBx;
% % CurSens=SensBx(:,:,:,CorrespondingRefSliIdx);
% 
% FirstEcho=load([RefFldMapP 'FirstEcho.mat']);
% FirstEcho=FirstEcho.FirstEcho;
% 
% FirstEcho=gflip(FirstEcho,[]);
% Mg=grmss(FirstEcho,3);
% 
% 
% Mgx=padarray(Mg,[0 2 0],'both');
% MgCurSli=Mgx(:,:,CorrespondingRefSliIdx);
% % MgCurSli=imresizeBySlices(MgCurSli,[RefFOV RefFOV]);
% % MgCurSli=crop(MgCurSli,cEffFOV,cEffFOV);
% MgCurSli=rot90(imresizeBySlices(MgCurSli,TrgSz));
% % Mgx=rot90(imresizeBySlices(Mgx,TrgSz));
% fgmontage(MgCurSli)
% 
% B0S=load([RefFldMapP 'B0S.mat']);
% B0S=B0S.B0S;
% 
% disp('ok');
%%
SensCC=permute(sum(SelfSens1.*permute(sccmtx(:,1:ncc),[3 4 1 5 6 7 8 9 2]),3),[1:2 9 3:8]);
SensCC=permute43(SensCC);
disp('ok SensCC');
%% Recon using multi-channel
setenv('TOOLBOX_PATH','/autofs/space/daisy_002/users/Gilad/bart-0.4.04CleanL')
nccToUse=31;
RepsToUse=1:(nRepsHdr-1);
% TrajPartToUse=[1:5000 20000:25000];
% TrajPartToUse=30000+(1:2500);
TrajPartToUse=000+(1:2000);
% TrajPartToUse=7000+(1:7000);

DataCCP=permute(DataPC,[1:3 8 4:7]);
% Rec1ccp=bart('pics -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,:),SensCC);
% fgmontage(Rec1ccp)
% ShowAbsAngle(Rec1ccp)
Rec1ccp=bart('pics -m -R W:3:0:0.00010 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
fgmontage(Rec1ccp)
title([num2str(numel(RepsToUse)) ' shots data x ' num2str(numel(TrajPartToUse)) 'points, PI, using ' num2str(ncc) ' compressed channels']);
%% Per innershot recon (with added B0 variation)
InnerShotLen=floor(nTrajToUse/10);
EffTimeBetweenInnershots_ms=AcqDwellTime_us*InnerShotLen/1000;

nccToUse=31;
RepsToUse=1:(nRepsHdr-1);

DataCCP=permute(DataPC,[1:3 8 4:7]);
disp('ok x');
%%
% for i=1:4
%     TrajPartToUse=(i-1)*InnerShotLen+(1:2000);
%     
%     % add random phase
% %     CurTimems=(i-1)*InnerShotLen/1000;
% %     RandB0_Hz=(rand(numel(RepsToUse),1)*2-1)*4;
% %     PerShotPhase_rad=2*pi*RandB0_Hz*CurTimems/1000;
% %     PerShotPhase_radP=permute(PerShotPhase_rad,[2 3 1 4]);
% %     DataCCP=DataCCP.*exp(1i.*PerShotPhase_radP);
%     % end add random phase
%     
%     Rec1ccpM(:,:,i)=bart('pics -m -R W:3:0:0.00010 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
% %     Rec1ccpM(:,:,i)=bart('pics -m -R W:3:0:0.10 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
% %     Rec1ccpM(:,:,i)=bart('pics -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
% end
% disp('ok per innershot');
% %%
% ShowAbsAngle(Rec1ccpM);
% subplot(1,2,2);
% title('4 first innershots');
%% Per innershot recon, several together
clear InnerShotTraj InnerShotData
for i=1:10
    TrajPartToUseC{i}=(i-1)*InnerShotLen+(1:2000);
    InnerShotTraj{i}=BARTTrajP(:,TrajPartToUseC{i},RepsToUse);
    InnerShotData{i}=DataCCP(:,TrajPartToUseC{i},RepsToUse,1:nccToUse);
%     Rec1ccpM(:,:,i)=bart('pics -m -R W:3:0:0.00010 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
end
InnerShotTraj=cat(8,InnerShotTraj{:});
InnerShotData=cat(8,InnerShotData{:});
Rec1ccpMt=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTraj,InnerShotData,DMsk.*SensCC(:,:,:,1:nccToUse));
Rec1ccpMt=squeeze(Rec1ccpMt);
disp('ok per innershot together');
%%
ShowAbsAngle(Rec1ccpMt);
subplot(1,2,2);
title('per innershot');
%%
OutGifFN=[mainP filesep 'SpiralOut_' num2str(Delay_us) 'us.gif'];
delete(OutGifFN);
figure;imagesc(abs(Rec1ccpMt(:,:,1)));colormap gray
gif(OutGifFN)
for i=2:size(Rec1ccpMt,3)
    imagesc(abs(Rec1ccpMt(:,:,i)));colormap gray
    gif
end
disp(OutGifFN);
%%
HankelTemporalLen=2;
WhichInnIdxs=1:size(Rec1ccpMt,3);
[~, ~, ~,HInnerShot]=ghankel(numel(WhichInnIdxs),HankelTemporalLen,TrgSz);
%%
[ U_LLR, s_LLR, V_LLR ] = batch_svd(HInnerShot*(Rec1ccpMt(:,:,WhichInnIdxs)));

R1=V_LLR(:,:,2,1)./V_LLR(:,:,1,1); % R1 is simply the decay

InnerShotDiff_ms=InnerShotLen*AcqDwellTime_us/1e3;

UpdatedT2SMap_ms=-InnerShotDiff_ms./log(abs(R1));
UpdatedB0Map=-(angle(R1)/(2*pi))/(InnerShotDiff_ms/1e3); % in Hz

figure;subplot(1,2,1);
gmontage(UpdatedB0Map,[-100 100]);
title('Innershot temporal hankel based initial B_0');removeTicks;colorbar
subplot(1,2,2);
gmontage(UpdatedT2SMap_ms,[0 100])
% Updated_TSC_L2=exp(-1i*angle(R1).*permute(0:(nTS_L2-1),[1 3 2]));
% % Updated_TSC_L2=exp(1i.*2*pi*B0Q2*(1e-3).*TimePoints_ms3_L2);
SimSpiralIn=Rec1ccpMt.*(R1.^0.5);
%% Test TH annihilation
TH=HInnerShot*Rec1ccpMt(:,:,WhichInnIdxs);
VH_LLR=(permute43(V_LLR));
GoodDir=sum(TH.*VH_LLR(:,:,1,:),4);
BadDir=sum(TH.*VH_LLR(:,:,2,:),4);
BothDir=cat(4,GoodDir,BadDir);
ShowAbsAngle(BothDir)
%% Spiral-ins
clear InnerShotTrajIn InnerShotDataIn
for i=1:size(Rec1ccpMt,3)
    TrajPartToUseCIn{i}=i*InnerShotLen-2000+(1:2000);
    InnerShotTrajIn{i}=BARTTrajP(:,TrajPartToUseCIn{i},RepsToUse);
    InnerShotDataIn{i}=DataCCP(:,TrajPartToUseCIn{i},RepsToUse,1:nccToUse);
%     Rec1ccpM(:,:,i)=bart('pics -m -R W:3:0:0.00010 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
end
InnerShotTrajIn=cat(8,InnerShotTrajIn{:});
InnerShotDataIn=cat(8,InnerShotDataIn{:});
Rec1ccpMtIn=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTrajIn,InnerShotDataIn,SensCC(:,:,:,1:nccToUse));
Rec1ccpMtIn=squeeze(Rec1ccpMtIn);
disp('ok per innershot together spiral in');
%%
ShowAbsAngle(Rec1ccpMtIn);
subplot(1,2,2);
title('per innershot, spiral-ins');
%% Out+In gif
OutInGifFN=[mainP filesep 'SpiralOutandIn_' num2str(Delay_us) 'us.gif'];
delete(OutInGifFN);
figure;imagesc(cat(2,abs(Rec1ccpMt(:,:,1)),abs(Rec1ccpMtIn(:,:,1))));colormap gray;removeTicks;axis equal
gif(OutInGifFN)
for i=2:size(Rec1ccpMt,3)
    imagesc(cat(2,abs(Rec1ccpMt(:,:,i)),abs(Rec1ccpMtIn(:,:,i))));colormap gray;removeTicks;axis equal
    gif
end
disp(OutInGifFN);
%% out in rotation gif
OutInRotGifFN=[mainP filesep 'SpiralOutInRot_' num2str(Delay_us) 'us.gif'];
delete(OutInRotGifFN);
figure;imagesc(abs(Rec1ccpMt(:,:,5)));colormap gray;removeTicks;axis equal
gif(OutInRotGifFN);
imagesc(abs(Rec1ccpMtIn(:,:,5)));colormap gray;removeTicks;axis equal
gif
disp(OutInRotGifFN);
%% Spiral out-ins
clear InnerShotTrajOutIn InnerShotDataOutIn
for i=1:size(Rec1ccpMt,3)-1
    TrajPartToUseCOutIn{i}=i*InnerShotLen+(-1000:1000);
    InnerShotTrajOutIn{i}=BARTTrajP(:,TrajPartToUseCOutIn{i},RepsToUse);
    InnerShotDataOutIn{i}=DataCCP(:,TrajPartToUseCOutIn{i},RepsToUse,1:nccToUse);
%     Rec1ccpM(:,:,i)=bart('pics -m -R W:3:0:0.00010 -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),DataCCP(:,TrajPartToUse,RepsToUse,1:nccToUse),SensCC(:,:,:,1:nccToUse));
end
InnerShotTrajOutIn=cat(8,InnerShotTrajOutIn{:});
InnerShotDataOutIn=cat(8,InnerShotDataOutIn{:});
Rec1ccpMtOutIn=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTrajOutIn,InnerShotDataOutIn,DMsk.*SensCC(:,:,:,1:nccToUse));
Rec1ccpMtOutIn=squeeze(Rec1ccpMtOutIn);
disp('ok per innershot together spiral out-in');
%%
ShowAbsAngle(Rec1ccpMtOutIn);
subplot(1,2,2);
title('per innershot, spiral-out-ins');

%%
% delete('SpiralOutInRotation.gif')
XX=CombineDims(Rec1ccpMt,[3 2]);
XX=Rec1ccpMt(:,:,3);
figure;imagesc(abs(XX));colormap gray
gif(['SpiralOutInRotation_' num2str(Delay_us) 'us.gif'])
XX=CombineDims(Rec1ccpMtIn,[3 2]);
XX=Rec1ccpMtIn(:,:,3);
imagesc(abs(XX));colormap gray
gif
disp('ok gif')
disp(which('SpiralOutInRotation.gif'))
%%
figure;imshowpair(abs(Rec1ccpMt(:,:,3)),abs(Rec1ccpMtIn(:,:,3)),'checkerboard')
%%
[X Y]=ndgrid(linspace(-1,1,TrgSz(1)),linspace(-1,1,TrgSz(2)));
XY=[X(:) Y(:)];

IOut=abs(Rec1ccpMt(:,:,3));

IIn=abs(Rec1ccpMtIn(:,:,3));

W=IOut(:);
mu=sum(W.*XY)./sum(W);
XYm=XY-mu;
Sigma=squeeze(sum(W.* (XYm.*permute(XYm,[1 3 2])),1)/sum(W));
PhiOut=atan2(Sigma(1,2),Sigma(1,1))*180/pi;

W=IIn(:);
mu=sum(W.*XY)./sum(W);
XYm=XY-mu;
Sigma=squeeze(sum(W.* (XYm.*permute(XYm,[1 3 2])),1)/sum(W));
PhiIn=atan2(Sigma(1,2),Sigma(1,1))*180/pi;
[PhiOut PhiIn]
%% delay -4
DirsA=[PhiOut PhiIn];
Delay_usA=Delay_us;
%% delay 0
DirsB=[PhiOut PhiIn];
Delay_usB=Delay_us;
IsB=cat(3,IOut,IIn);
%% delay 2
DirsC=[PhiOut PhiIn];
Delay_usC=Delay_us;
IsC=cat(3,IOut,IIn);
%% delay 1
DirsD=[PhiOut PhiIn];
Delay_usD=Delay_us;
IsD=cat(3,IOut,IIn);
%%
DirsB=[Dir1 Dir2];
Delay_usB=Delay_us;
%% Analyze rotation
tform=imregcorr(abs(Rec1ccpMtIn(:,:,3)),abs(Rec1ccpMt(:,:,3)),'rigid');
AngOutIn=asin(tform.T(1,2))*180/pi;
%%
tformA=tform;
AngOutInA=AngOutIn;
Delay_usA=Delay_us;
%%
fgmontage(abs(Rec1ccpMtIn)>0.001)
Bout=abs(Rec1ccpMt)>0.001;
Bin=abs(Rec1ccpMtIn)>0.001;
fgmontage(Bout*2+Bin)

figure;imshowpair(abs(Rec1ccpMt(:,:,1)),abs(Rec1ccpMtIn(:,:,1)));

figure;imshowpair(Bout(:,:,1)*2,Bin(:,:,1)*2);

figure;[cnt_out,h]=contour(Bout(:,:,1)*2);
figure;[cnt_in,h]=contour(Bin(:,:,1)*2);
AA=cnt_out;
AA(AA<3)=NaN;
figure;plot(AA(1,:),AA(2,:))
hold on
AA=cnt_in;
AA(AA<3)=NaN;
plot(AA(1,:),AA(2,:),'r')

%%
setenv('TOOLBOX_PATH','/autofs/space/daisy_002/users/Gilad/bart-0.4.04b')
%%
nAcqPoints=numel(Traj);

Rows2Complex=@(X) X(1,:)+1i*X(2,:);

CTo2Rows=@(X) [real(X);imag(X)];
CTo3Rows=@(X) [real(X);imag(X);imag(X)*0];
%
% STraj=TrajQ.';
CurRep=1;
STraj=TrajM(CurRep,:);
STraj3=CTo3Rows(STraj);

% STraj3=BARTTrajP(:,:,CurRep);

Sz=TrgSz;
Sz16=FillOnesTo16(Sz);

SnufftStruct = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
disp('ok 0');
%%
nTS=20;
nTS=50;
TSB=GetTSCoeffsByLinear(nAcqPoints,nTS);

Kerns=NUFFT_to_Toep_2blocks(SnufftStruct,TSB);

% TimePoints_ms=linspace(0,nAcqPoints*1e3/SpBW,nTS);
% TimePoints_ms=(0:(nAcqPoints-1))*AcqDwellTime_us/1000;
TimePoints_ms=linspace(0,AcqTimePoints_us(end)/1000,nTS);
TimePoints_ms3=permute(TimePoints_ms,[1 3 2]);
TSC=exp(1i.*2*pi*UpdatedB0Map*(1e-3).*TimePoints_ms3);
% [x y z Channels 1 TS]

BaseSP='/autofs/space/daisy_002/users/Gilad/gUM/';

ScriptFN_TS=[BaseSP 'NuftTSC.txt'];
ScriptFN_TS=[BaseSP 'nuftTSC_N.txt'];

% # file 0 is sensitivity maps [x y z Ch Maps]
% # file 1 is sampling pattern/Trajectory [3 #Traj spokes]
% # file 2 is TSB [1 #traj 1 1 1 1 TS] 
% # file 3 is TSC [x y z 1 1 1 TS]
% # file 4 is Toeplitz kernel [2x 2y z 1 1 1 TS]
% # Data is [1 #Traj 1 Ch]
TSBP=permute(TSB,[3 1 4 5 6 7 2]);
TSCP=permute(TSC,[1 2 7 6 5 4 3]);
KernsP=permute(Kerns,[1 2 7 6 5 4 3]);
disp('ok a');
%%
% I1=phantom(Sz(1));
% NUFTB=bart(['linopScript ' ScriptFN_TS],Sz16,I1,SensCC,STraj3,TSBP,TSCP,KernsP);
% NUFTB_A=bart(['linopScript -A ' ScriptFN_TS],Sz16,NUFTB,SensCCP,STraj3,TSBP,TSCP,KernsP);
% NUFTB_N=bart(['linopScript -N ' ScriptFN_TS],Sz16,I1,SensCCP,STraj3,TSBP,TSCP,KernsP);
% ShowAbsAngle(NUFTB_A);colorbar
% ShowAbsAngle(NUFTB_N);colorbar
% %%
% ImSize=Sz16;
% DataSize=size(NUFTB);
% x = randn(ImSize) + 1j*randn(ImSize);
% y = randn(DataSize) + 1j*randn(DataSize);
% Ax = bart(['linopScript ' ScriptFN_TS],Sz16,x,SensCCP,STraj3,TSBP,TSCP,KernsP);
% Aty = bart(['linopScript -A ' ScriptFN_TS],Sz16,y,SensCCP,STraj3,TSBP,TSCP,KernsP);
% Out=abs(x(:)'*Aty(:) - conj(y(:)'*Ax(:)));
%% given B0
% nccToUse=7; % 7: 46 sec
nccToUse=31;
BigTrajPartToUse=1:45400;
%%
% RecTS=bart(['picsS ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),SensCC(:,:,:,1:nccToUse),STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCP,KernsP);
% fgmontage(RecTS);MaximizeFig;
%% given B0, wavelet regularization
% 7ch: 58sec. 31ch: 205 sec, slightly cleaner.
% tic
% RecTS_W=bart(['picsS -m -R W:3:0:1.01 ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),SensCC(:,:,:,1:nccToUse),STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCP,KernsP);
% t=toc;
% % RecTS_W=bart(['picsS -m -R W:3:0:1.01 ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartToUse,CurRep,1:nccToUse,:,1),SensCC(:,:,:,1:nccToUse),STraj3(:,TrajPartToUse),TSBP(:,TrajPartToUse,:,:,:,:,:,:,:),TSCP,KernsP);
% fgmontage(RecTS_W);MaximizeFig;xlabel(nccToUse);ylabel(t);
%% Given B0, T2S, W regularized
% 31Ch: 260sec.
R1x=min(max(abs(R1),0.3),1).*exp(-1i*angle(R1));
TSCx=R1x.^(TimePoints_ms3/InnerShotDiff_ms);
TSCxP=permute(TSCx,[1 2 7 6 5 4 3]);

WLambda=0.1;
RegStr=['-R W:3:0:' num2str(WLambda)];
tic;RecgD_W=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),...
    DMsk.*SensCC(:,:,:,1:nccToUse),STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCxP,KernsP);
t=toc;
fgmontage(RecgD_W);MaximizeFig;xlabel(nccToUse);ylabel(t);title(['Single shot, given B_0,T_2^* estimate, ' RegStr]);
%%
Rec1ccpMtC=Rec1ccpMt.*exp(-1i*angle(Rec1ccpMt(:,:,1)));
Rec1ccpMtCM=Rec1ccpMt./Rec1ccpMt(:,:,1);
fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');
%%
% TightMask=s_LLR(:,:,1)>0.0015;
% % CalcSlicesSNR?
% % se = strel('disk', 3);
% % TightMask=imdilate(TightMask,se,'same');
% fgmontage(TightMask);
% %% with tight mask ?
% WLambda=0.1;
% RegStr=['-R W:3:0:' num2str(WLambda)];
% tic;RecgD_WM=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),...
%     SensCC(:,:,:,1:nccToUse).*TightMask,STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCxP,KernsP);
% t=toc;
% fgmontage(RecgD_WM);MaximizeFig;xlabel(nccToUse);ylabel(t);title(['Single shot, given B_0,T_2^* estimate, ' RegStr ', tight mask']);
%% Per rep/s, given B0,T2*, Short part of traj
%% preparation
WhichInnerShot=3;
nTSShort=3;
TSBShort=GetTSCoeffsByLinear(numel(TrajPartToUseC{WhichInnerShot}),nTSShort);
TSBPShort=permute(TSBShort,[3 1 4 5 6 7 2]);

for CurRep=1:(nRepsHdr-1)
    disp(CurRep);
    STraj=TrajM(CurRep,TrajPartToUseC{WhichInnerShot});
    STraj3MShort(:,:,CurRep)=CTo3Rows(STraj);
    SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
    KernsByRepShort{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSBShort);
    KernsPShortC{CurRep}=permute(KernsByRepShort{CurRep},[1 2 7 6 5 4 3]);
end
KernsPMShort=cat(3,KernsPShortC{:});
clear KernsPShortC

TimePointsShort_ms=linspace(0,AcqTimePoints_us(TrajPartToUseC{1}(end))/1000,nTSShort);
TimePointsShort_ms3=permute(TimePointsShort_ms,[1 3 2]);
TSCxShort=R1x.^(TimePointsShort_ms3/InnerShotDiff_ms);
TSCxPShort=permute(TSCxShort,[1 2 7 6 5 4 3]);
%% given B0,T2*, several reps together
CurReps=1:39;
% 14 sec

RecgD_SReps=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartToUseC{WhichInnerShot},CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MShort(:,:,CurReps),TSBPShort,...
        TSCxPShort,sum(KernsPMShort(:,:,CurReps,:,:,:,:),3));

fgmontage(RecgD_SReps);title('Multi-shot, short part of traj, given B0,T2*');removeTicks

fgmontage(Rec1ccpMt(:,:,3));title('39 shots 2ms, for ref');
%% Longer
TrajPartMed=1:2000;
TrajPartMed=2200+(1:2000);

TrajPartMed=1:4600; % kind of ok
TrajPartMed=1:40000;

nPointsMed=numel(TrajPartMed);
nTSMed=ceil((nPointsMed+1)/1000);
% nTSMed=8;
TSBMed=GetTSCoeffsByLinear(nPointsMed,nTSMed);
TSBPMed=permute(TSBMed,[3 1 4 5 6 7 2]);

TimePointsMed_ms=linspace(0,AcqTimePoints_us(nPointsMed)/1000,nTSMed);
% TimePointsMed_ms=0;
TimePointsMed_ms3=permute(TimePointsMed_ms,[1 3 2]);
TSCxMed=R1x.^(TimePointsMed_ms3/InnerShotDiff_ms);
TSCxPMed=permute(TSCxMed,[1 2 7 6 5 4 3]);

clear STraj3MMed
for CurRep=1:(nRepsHdr-1)
    disp(CurRep);
    STraj=TrajM(CurRep,TrajPartMed);
    STraj3MMed(:,:,CurRep)=CTo3Rows(STraj);
    SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
    KernsByRepMed{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSBMed);
    KernsPMedC{CurRep}=permute(KernsByRepMed{CurRep},[1 2 7 6 5 4 3]);
end
KernsPMMed=cat(3,KernsPMedC{:});
clear KernsPMedC
%% given B0,T2*, several reps together
CurReps=1:2;
% 2000: 18v10 sec (Normal)

RegStrMed='-R W:3:0:0.0000001';

% ScriptFN_TS=[BaseSP 'NuftTSC.txt'];
% ScriptFN_TS=[BaseSP 'nuftTSC_N.txt'];

% RecgD_SReps_Med=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MMed(:,:,CurReps),TSBPMed,...
%         TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
    
RecgD_SReps_Med=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        DMsk.*SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,...
        TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));

fgmontage(RecgD_SReps_Med);title('Multi-shot, medium-length part of traj, given B0,T2*');removeTicks

fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');

fgmontage(Rec1ccpMtIn(:,:,1));title('39 shots 2ms, in, for ref');
%%

%% Longer, with masking of traj points
TrajPartMed=1:2000;
TrajPartMed=2200+(1:2000);

TrajPartMed=1:4600; % kind of ok
TrajPartMed=1:44000;
BTraj=(TrajPartMed*0).';
for i=1:numel(TrajPartToUseC)
%     BTraj(intersect(TrajPartMed,TrajPartToUseC{i}))=1;
    BTraj(intersect(TrajPartMed,TrajPartToUseCIn{i}))=1;
end

nPointsMed=numel(TrajPartMed);
nTSMed=ceil((nPointsMed+1)/1000);
% nTSMed=1;
% nTSMed=8;
TSBMed=GetTSCoeffsByLinear(nPointsMed,nTSMed);

TSBMed=TSBMed.*BTraj;

TSBPMed=permute(TSBMed,[3 1 4 5 6 7 2]);

TimePointsMed_ms=linspace(0,AcqTimePoints_us(nPointsMed)/1000,nTSMed);
% TimePointsMed_ms=0;
TimePointsMed_ms3=permute(TimePointsMed_ms,[1 3 2]);
TSCxMed=R1x.^(TimePointsMed_ms3/InnerShotDiff_ms);
TSCxPMed=permute(TSCxMed,[1 2 7 6 5 4 3]);

clear STraj3MMed
for CurRep=1:(nRepsHdr-1)
    disp(CurRep);
    STraj=TrajM(CurRep,TrajPartMed);
    STraj3MMed(:,:,CurRep)=CTo3Rows(STraj);
    SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
    KernsByRepMed{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSBMed);
    KernsPMedC{CurRep}=permute(KernsByRepMed{CurRep},[1 2 7 6 5 4 3]);
end
KernsPMMed=cat(3,KernsPMedC{:});
clear KernsPMedC
disp('Prepared KernsByRepMed with masking of traj points');
%% given B0,T2*, several reps together, with masking of traj points
CurReps=1:39;
% 2000: 18v10 sec (Normal)

RegStrMed='-R W:3:0:0.0000001';

% ScriptFN_TS=[BaseSP 'NuftTSC.txt'];
% ScriptFN_TS=[BaseSP 'nuftTSC_N.txt'];

% RecgD_SReps_Med=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MMed(:,:,CurReps),TSBPMed,...
%         TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
    
RecgD_SReps_MedB=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,...
        (BTraj.').*DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        DMsk.*SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,...
        TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));

fgmontage(RecgD_SReps_MedB);title('Multi-shot, medium-length part of traj, given B0,T2*');removeTicks
%%
fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');

fgmontage(Rec1ccpMtIn(:,:,1));title('39 shots 2ms, in, for ref');
%% Now per rep
% CurRep=10;
for CurRep=1:(nRepsHdr-1)
    disp(CurRep);
    STraj=TrajM(CurRep,:);
    STraj3=CTo3Rows(STraj);
    
    SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
    
    KernsByRep{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSB);
end



for CurRep=1:(nRepsHdr-1)
    STraj=TrajM(CurRep,:);
    STraj3=CTo3Rows(STraj);
    STraj3M(:,:,CurRep)=STraj3;
    KernsP=permute(KernsByRep{CurRep},[1 2 7 6 5 4 3]);
    KernsPC{CurRep}=KernsP;
end
KernsPM=cat(3,KernsPC{:});
clear KernsPC

for CurRep=1:(nRepsHdr-1)
    KernsP=permute(KernsByRep{CurRep},[1 2 7 6 5 4 3]);
    RecgD_WMR(:,:,CurRep)=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse).*TightMask,STraj3M(:,BigTrajPartToUse,CurRep),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),...
        TSCxP,KernsPM(:,:,:,CurRep,:,:,:));
end
fgmontage(RecgD_WMR(:,:,1:11:end));MaximizeFig;xlabel(nccToUse);ylabel(t);title(['Several reps, given B_0,T_2^* estimate, ' RegStr ', tight mask']);

fgmontage(mean(RecgD_WMR,3));title('Mean of single-shots');removeTicks
%% given B0,T2*, several reps together
CurReps=1:39;

RecgD_SReps=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse).*TightMask,STraj3M(:,BigTrajPartToUse,CurReps),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),...
        TSCxP,sum(KernsPM(:,:,CurReps,:,:,:,:),3));

fgmontage(RecgD_SReps);title('Multi-shot, given B0,T2*');removeTicks

fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');
%% By annihilating bad direction




%% Try to get all TSC
ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
Sz16AllTSC=FillOnesTo16(size(TSCxP));
tmp2=bart(['picsS -m -R K:64:3:0.1:2:1:2:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse).*TightMask,STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),1,KernsP);
%%
[~,~,~,H_AllTS]=ghankel(nTS,2,TrgSz);
[ ~, s_LLR_AllTS, V_LLR_AllTS] = batch_svd(H_AllTS*squeeze(tmp2));
R1ts=V_LLR_AllTS(:,:,2,1)./V_LLR_AllTS(:,:,1,1); % R1 is simply the decay
InnerTSDiff_ms=454*AcqDwellTime_us/1e3;
UpdatedT2SMap_ms1=-InnerTSDiff_ms./log(abs(R1ts));
UpdatedB0Map1=-(angle(R1ts)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz
fgmontage(UpdatedB0Map1,[-100 100]);
%%





%% Work on part of the data
nccToUse=7;

CurIdxs=0+(1:25000);
% CurIdxs=25000+(1:25000);

nTSp=20;
TSBp=GetTSCoeffsByLinear(numel(CurIdxs),nTSp);
STrajp=STraj(:,CurIdxs);
STraj3p=CTo3Rows(STrajp);

SnufftStructp = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STrajp),Sz), Sz, [6 6], Sz*2); % st.om

Kernsp=NUFFT_to_Toep_2blocks(SnufftStructp,TSBp);

TimePoints_msp=linspace(0,numel(CurIdxs)*AcqDwellTime_us/1000,nTSp);
TimePoints_ms3p=permute(TimePoints_msp,[1 3 2]);
TSCp=exp(1i.*2*pi*UpdatedB0Map*(1e-3).*TimePoints_ms3p);

TSBPp=permute(TSBp,[3 1 4 5 6 7 2]);
TSCPp=permute(TSCp,[1 2 7 6 5 4 3]);
KernsPp=permute(Kernsp,[1 2 7 6 5 4 3]);


RecTS_Wp=bart(['picsS -m -R W:3:0:10.01 ' ScriptFN_TS],Sz16,DataCCP(:,CurIdxs,CurRep,1:nccToUse,:,1),SensCC(:,:,:,1:nccToUse),STraj3p,TSBPp,TSCPp,KernsPp);
fgmontage(RecTS_Wp);MaximizeFig;
%%
% RecTS_Wp1=RecTS_Wp;
% RecTS_Wp2=RecTS_Wp;
% %%
% R=RecTS_Wp1./RecTS_Wp2;
%% Now two levels
% L1, e.g. 5
% *                  *                 *                    *
% |           / \              /\                 /         |        with large and decreasing radius
% * * * * * * * * * * * * * * * * * * * * * * * * * * * *      to Level 2, e.g. 50
%                                                                    <- Apply estimated B0
% |               |           |             |               |        Normal TS to traj
% 
% ...........................................................      
nTS_L1=5;
Rad_L12=25; % 5,25 good result
nTS_L2=50;
% nTS_L2=150;

TSB_L1=GetTSCoeffsByLinearWide(nTS_L2,nTS_L1,Rad_L12);
% figure;plot(TSB_L1)

TSB_L2=GetTSCoeffsByLinear(nAcqPoints,nTS_L2);

Kerns_L2=NUFFT_to_Toep_2blocks(SnufftStruct,TSB_L2);

TimePoints_ms_L2=linspace(0,nAcqPoints*AcqDwellTime_us/1000,nTS_L2);
TimePoints_ms3_L2=permute(TimePoints_ms_L2,[1 3 2]);
% TSC_L2=exp(1i.*2*pi*B0Q2*(1e-3).*TimePoints_ms3_L2);
Updated_TSC_L2=exp(1i.*2*pi*UpdatedB0Map*(1e-3).*TimePoints_ms3_L2);
disp('2L part 1');
%%
ScriptFN_TS_2L=[BaseSP 'nuftTSC_N_2L.txt'];

TSBP_L2=permute(TSB_L2,[3 1 4 5 6 7 2]);
KernsP_L2=permute(Kerns_L2,[1 2 7 6 5 4 3]);
TSBP_L1=permute(TSB_L1,[3:7 2 1]);
Sz16_2L=Sz16;
Sz16_2L(6)=nTS_L1;
% # file 0 is sensitivity maps [x y z Ch Maps]
% # file 1 is sampling pattern/Trajectory [3 #Traj spokes]
% # file 2 is TSB [1 #traj 1 1 1 1 TS] 
% # file 3 is TSC [x y z 1 1 1 TS]
% # file 4 is Toeplitz kernel [2x 2y z 1 1 1 TS]
% # file 5 is TSB_L1 [1 1 1 1 1 TS_L1 TS_L2] 
% # Data is [1 #Traj 1 Ch]
%%
HankelTemporalLen=2;
% WhichIdxs=1:nTS_L2;
% WhichIdxs=10:40;
WhichIdxs=floor(nTS_L2*0.2):floor(nTS_L2*0.8);
% WhichIdxs=1:nTS_L1;
[HankelMat, HankelizingMat, DeHankelizingMat]=ghankel(numel(WhichIdxs),HankelTemporalLen);
HankelizingMatP=permute(HankelizingMat,[3:4, 1:2]);
DeHankelizingMatP = permute(DeHankelizingMat,[3:4, 1:2]);

H_for=@(x) reshape(sum(x.*HankelizingMatP,3),[Sz size(HankelMat)]);
H_inv=@(x) squeeze(sum(reshape(x,[Sz, numel(HankelMat)]).*DeHankelizingMatP,3));
%%
nccToUse=31;

for Iter=2:100
    disp(Iter);
    TSC_L2=Updated_TSC_L2;
    TSCP_L2=permute(TSC_L2,[1 2 7 6 5 4 3]);
    disp('Prepared 2L');
%%
% RecTS_2L=bart(['picsS -m -R W:3:0:0.1 ' ScriptFN_TS_2L],Sz16_2L,DataCCP(:,:,:,:,:,5),SensCCP,STraj3,TSBP_L2,TSCP_L2,KernsP_L2,TSBP_L1);
% fgmontage(RecTS_2L);MaximizeFig;
%% -R K:7:7:.03:HankelizationK:BlkSize:Option:Dim	Hankelized low-rank.
RegCmd='-R K:3:3:1:2:1:0:5';
RegCmd='-R K:3:3:0.001:2:1:0:5';
RecTS_2Lb=bart(['picsS -m ' RegCmd ' ' ScriptFN_TS_2L],Sz16_2L,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse,:,1),SensCC(:,:,:,1:nccToUse),STraj3(:,BigTrajPartToUse),TSBP_L2(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCP_L2,KernsP_L2,TSBP_L1);
% RecTS_W=bart(['picsS -m -R W:3:0:1.01 ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartToUse,CurRep,1:nccToUse),SensCC(:,:,:,1:nccToUse),STraj3(:,TrajPartToUse),TSBP(:,TrajPartToUse,:,:,:,:,:,:,:),TSCP,KernsP);
% fgmontage(RecTS_2Lb);MaximizeFig;title(RegCmd);
%% Open to L2
RecTS_2LbX=squeeze(sum(RecTS_2Lb.*TSBP_L1,6));
RecTS_2LbY=RecTS_2LbX.*TSC_L2;
% fgmontage(RecTS_2LbY);MaximizeFig;title(RegCmd);

RecTS_2LbYx=RecTS_2LbY.*exp(-1i*angle(RecTS_2LbY(:,:,1)));
RecTS_2LbYxx=RecTS_2LbYx.*exp(-1i*angle(TSC_L2));
%%
%% Check that the data is low rank after (maximal) temporal Hankelization

%%
% RecTS_2LCbY
% [~, s_vals] = llr_thresh_OnPreparedBlocks(H_for(RecTS_2LbY(:,:,WhichIdxs)), 0);
% 
% fgmontage(s_vals)
%%
% [ U_LLR, s_LLR, V_LLR ] = batch_svd(H_for(RecTS_2LCbY(:,:,WhichIdxs)));
[ U_LLR, s_LLR, V_LLR ] = batch_svd(H_for(RecTS_2LbY(:,:,WhichIdxs)));

% For test: [ U_LLRa, s_LLRa, V_LLRa ] = batch_svd(H_for(repmat(permute(150*(0.8.^(1:50)),[1 3 2]),[Sz 1])));

R1=V_LLR(:,:,2,1)./V_LLR(:,:,1,1); % R1 is simply the decay
% fgmontage(angle(R1));
% fgmontage(-log(abs(R1)),[0 0.2])
% fgmontage(-1./log(abs(R1)),[0 100]) % TE is ~1ms, so ignore

R1s{Iter}=R1;

Updated_TSC_L2=exp(-1i*angle(R1).*permute(0:(nTS_L2-1),[1 3 2]));
% Updated_TSC_L2=exp(1i.*2*pi*B0Q2*(1e-3).*TimePoints_ms3_L2);

UpdatedB0Map=-angle(R1)*1e3*(nTS_L2/TimePoints_ms(end))/(2*pi);
%% Compare to estimated B0
% [ U_LLRa, s_LLRa, V_LLRa ] = batch_svd(H_for(TSC_L2(:,:,WhichIdxs)));
% 
% R1a=V_LLRa(:,:,2,1)./V_LLRa(:,:,1,1);
% fgmontage(angle(R1a));
% fgmontage(-log(abs(R1a)),[0 0.2]) % TE is ~1ms, so ignore
% fgmontage(-1./log(abs(R1a)),[0 100]) % TE is ~1ms, so ignore

% R1=exp(-TE/T2*)
% T2*=1/(log(R1)/(-TE))=-TE/log(R1)
% fgmontage(angle(R1)-angle(R1a))
end
%%
UpdatedB0MapM=UpdatedB0Map1;
for i=2:4
    UpdatedB0MapM(:,:,i)=-angle(R1s{i})*1e3*(nTS_L2/TimePoints_ms(end))/(2*pi);
end