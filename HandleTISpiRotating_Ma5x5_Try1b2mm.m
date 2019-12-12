ScanP='/media/deni/bigdrive/SPIRAL_ASL/S03/RawData/';
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

BaseFN='meas_MID01090_FID09954_gSpi2d_T13_d110_Dw11_40rep_VD123';

BaseFN='meas_MID01106_FID09970_gSpi2d_T12_d110_Dw11_40rep_VD123_Thin';

BaseFN='meas_MID01092_FID09956_gSpi2d_T14_d110_Dw11_40rep_VD123';
BaseFN='meas_MID01094_FID09958_gSpi2d_T15_d110_Dw11_40rep_VD123';
MIDStr=BaseFN(6:11);
FN=[ScanP BaseFN '.dat'];
disp('ok');
%%
mainP=[ScanP BaseFN];
mkdir(mainP);

system(['chmod +777 -R ' mainP]);
disp([mainP ' Created']);

setenv('TOOLBOX_PATH','/autofs/space/daisy_002/users/Gilad/bart-0.4.04b')

BaseSP='/autofs/space/daisy_002/users/Gilad/gUM/';
nccToUse=31;

Rows2Complex=@(X) X(1,:)+1i*X(2,:);

CTo2Rows=@(X) [real(X);imag(X)];
CTo3Rows=@(X) [real(X);imag(X);imag(X)*0];

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
disp('Read raw');
%%
TrajType=WipMemBlock.adFree{12};
ResType=floor((TrajType-10)/2)+1; % 2,1.5,1
TimingType=mod(TrajType-10,2)+1; % 5ms, 10ms
load('GAll5ms10ms.mat');
GTrajaCBase=GAll(:,TimingType,ResType);

if(TimingType==1)
    nInnerShots=10;
else
    nInnerShots=5;
end
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
FOVx=200;

dFOV=FOVx/1000;

FOV_mm=FOVx;


disp('ok');

GradReduceFac=WipMemBlock.adFree{5};
PhiRotPerRep=WipMemBlock.adFree{9};
% AcqDwellTime_us=WipMemBlock.adFree{13}/1000;
AcqDwellTime_us=2;
TotalAcqTime_us=25000;
%%
% ADCsToRead=1:10;
% ADCsToRead=1;
SlicesToRead=[10];
for SlicesToRead=1:nSlices
RepsToRead=1:(nRepsHdr-1);
% ADataIsL=ADatax.image(:,:,:,:,SlicesToRead,3,:,:,RepsToRead,:,ADCsToRead,:,:,:,:,:,:);
% ADataIsL=ADatax.image(:,:,:,:,SlicesToRead,3,:,:,RepsToRead,:,:,:,:,:,:,:,:);
ADataIsL=ADatax.image(:,:,:,:,SlicesToRead,1,:,:,RepsToRead,:,:,:,:,:,:,:,:);

ADataIsL=permute(ADataIsL,[1 2 9 11 5 3:4 6:8 10]);
ADataIsL=CombineDims(ADataIsL,[4 1]);


dx=RotatedLocs(2,1)/FOVx;
dy=RotatedLocs(1,1)/FOVx;

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
%
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
Extra=4;
kKA=[zeros(4,1); kK; repmat(kK(end),[10 1])]; % in us

% Delay_us=-2.5; % positive data rightward %-6; % clockwise
Delays_us=-2:0.1:4;

Delays_us=1.6;
dlyI=1;
% for dlyI=1:numel(Delays_us)
    disp('-------');
    disp(dlyI);
    Delay_us=Delays_us(dlyI);
    AcqTimePoints_us=Extra*GradDwellTime_us+Delay_us+(0:AcqDwellTime_us:(TotalAcqTime_us-0.0001));

    Traj=interp1((0:(numel(kKA)-1))*GradDwellTime_us,kKA,AcqTimePoints_us);
    disp('ok delay');
    % plotTrajCrossPoints;
    
    nRepsToUse=nRepsHdr-1;

    TrajM=Traj.*exp(-1i*2*pi*PhiRotPerRep/360*(0:nRepsToUse-1)');

    DataC=permute(ADataIsLCC,[1 3 2]);
%     TrajM=TrajMa*exp(1i*2*pi*0/360)/1.01; % positive counter clockwize

    BARTTraj=cat(3,real(TrajM),imag(TrajM),imag(TrajM)*0);
    BARTTrajP=permute(BARTTraj,[3 2 1]);

    kx=BARTTrajP(1,:,:)*2*pi;
    ky=BARTTrajP(2,:,:)*2*pi;

    modx=exp(-1i.*(dx*kx+dy*ky));
    disp('ok mod');
    %% Recon each channel separately, no CC
nTrajToUse=size(BARTTrajP,2);
TrajPartToUse=0000+(1:1000);
RepsToUse=1:(nRepsHdr-1);
% RepsToUse=13;

DataPC=permute(ADataIsL(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 3 5 6 7 8 2]).*modx;
OnesSensC=repmat(OnesSens,[1 1 1 1 1 1 1 size(DataPC,8)]);

Rec1p=bart('pics -t ',BARTTrajP(:,TrajPartToUse,RepsToUse),(DataPC(:,TrajPartToUse,RepsToUse,1,1,1,1,:)),OnesSensC);
% fgmontage(Rec1cp)
fgmontage(grmss(Rec1p,8));removeTicks;
title([num2str(numel(RepsToUse)) ' shots data x ' num2str(numel(TrajPartToUse)) 'points, pre channel recon, RMS']);
%%
Rec1pRMS=grmss(Rec1p,8);
[Out B BN]=CalcSlicesSNR(Rec1pRMS,true,7);
Msk=imfillholesBySlices(~BN);
Msk=getLargestComponent(Msk);
% Msk=imfillholesBySlices(Rec1pRMS>0.001);
se = strel('disk', 7);
DMsk=imdilate(Msk,se,'same');
SelfSens=RunESPIRiTForSensMapsMultiMap(squeeze(Rec1p).*DMsk,0,TrgSz);
SelfSens1=SelfSens(:,:,:,1);
disp('ok SelfSens');
%% Recon each channel separately, CC
DataPC=permute(DataC(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 2 5 6 7 8 3]).*modx;
OnesSensC=repmat(OnesSens,[1 1 1 1 1 1 1 ncc]);

disp('ok rec pre channel cc');
%%
SensCC=permute(sum(SelfSens1.*permute(sccmtx(:,1:ncc),[3 4 1 5 6 7 8 9 2]),3),[1:2 9 3:8]);
SensCC=permute43(SensCC);
disp('ok SensCC');
%%
%     Sensx=imresize(SensB(:,:,:,9,1),[NTrg NTrg]);
%     Sensy=gflip(Sensx,1:2);
%     SensCC=permute(sum(Sensy.*permute(sccmtx(:,1:ncc),[3 4 1 5 6 7 8 9 2]),3),[1:2 9 3:8]);
%     SensCC=permute43(SensCC);
%     disp('ok SensCC');
%%
    %% Per innershot recon (with added B0 variation)
    DataPC=permute(DataC(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 2 5 6 7 8 3]).*modx;

    InnerShotLen=floor(nTrajToUse/nInnerShots);
    EffTimeBetweenInnershots_ms=AcqDwellTime_us*InnerShotLen/1000;

    RepsToUse=1:(nRepsHdr-1);

    DataCCP=permute(DataPC,[1:3 8 4:7]);
    disp('ok x');
    %% Per innershot recon, several together
    clear InnerShotTraj InnerShotData
    for i=1:nInnerShots
        TrajPartToUseC{i}=(i-1)*InnerShotLen+(1:1000);
        InnerShotTraj{i}=BARTTrajP(:,TrajPartToUseC{i},RepsToUse);
        InnerShotData{i}=DataCCP(:,TrajPartToUseC{i},RepsToUse,1:nccToUse);
    end
    InnerShotTraj=cat(8,InnerShotTraj{:});
    InnerShotData=cat(8,InnerShotData{:});
    
    %%

    Rec1ccpMt=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTraj,InnerShotData,DMsk.*SensCC(:,:,:,1:nccToUse));
    Rec1ccpMt=squeeze(Rec1ccpMt);
    
%     fgmontage(grmss(Rec1ccpMt,3))
    
    disp('ok per innershot together');
    %% Spiral-ins
    clear InnerShotTrajIn InnerShotDataIn
    for i=1:size(Rec1ccpMt,3)
        TrajPartToUseCIn{i}=i*InnerShotLen-2000+(1:2000);
        InnerShotTrajIn{i}=BARTTrajP(:,TrajPartToUseCIn{i},RepsToUse);
        InnerShotDataIn{i}=DataCCP(:,TrajPartToUseCIn{i},RepsToUse,1:nccToUse);
    end
    InnerShotTrajIn=cat(8,InnerShotTrajIn{:});
    InnerShotDataIn=cat(8,InnerShotDataIn{:});
    Rec1ccpMtIn=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTrajIn,InnerShotDataIn,DMsk.*SensCC(:,:,:,1:nccToUse));
    Rec1ccpMtIn=squeeze(Rec1ccpMtIn);
    disp('ok per innershot together spiral in');
    %% Spiral out-ins
    clear InnerShotTrajOutIn InnerShotDataOutIn
    for i=1:size(Rec1ccpMt,3)-1
        TrajPartToUseCOutIn{i}=i*InnerShotLen+(-1000:1000);
        InnerShotTrajOutIn{i}=BARTTrajP(:,TrajPartToUseCOutIn{i},RepsToUse);
        InnerShotDataOutIn{i}=DataCCP(:,TrajPartToUseCOutIn{i},RepsToUse,1:nccToUse);
    end
    InnerShotTrajOutIn=cat(8,InnerShotTrajOutIn{:});
    InnerShotDataOutIn=cat(8,InnerShotDataOutIn{:});
    Rec1ccpMtOutIn=bart('pics -m -R W:3:0:0.0000001 -t ',InnerShotTrajOutIn,InnerShotDataOutIn,DMsk.*SensCC(:,:,:,1:nccToUse));
    Rec1ccpMtOutIn=squeeze(Rec1ccpMtOutIn);
    disp('ok per innershot together spiral out-in');
    
    ResByDelay{dlyI}={Rec1ccpMt,Rec1ccpMtIn,Rec1ccpMtOutIn};
% end
%%
% for dlyI=1:numel(ResByDelay)
%     ResByDelayM(:,:,:,:,dlyI)=cat(4,ResByDelay{dlyI}{1}(:,:,2:end),ResByDelay{dlyI}{2}(:,:,1:end-1),ResByDelay{dlyI}{3});
% end
% %%
% ResByDelayM=single(ResByDelayM);
% save('ForDelayCalibByOutInRot.mat','ResByDelayM');
%%
% fgmontage(ResByDelayM(:,:,5,1,1:3:end),'Size',[3 7]);MaximizeFig
% fgmontage(ResByDelayM(:,:,5,2,1:3:end),'Size',[3 7]);MaximizeFig
%% Chosen: 1.6us
% fgmontage(ResByDelayM(:,:,5,1,37+(-2:2)),'Size',[1 5]);
% fgmontage(ResByDelayM(:,:,5,2,37+(-2:2)),'Size',[1 5]);
%%
% ShowAbsAngle(Rec1ccpMtOutIn);subplot(1,2,2);title('per innershot, spiral-out-ins');
% ShowAbsAngle(Rec1ccpMt(:,:,2:end));subplot(1,2,2);title('per innershot, spiral-outs');
% ShowAbsAngle(Rec1ccpMtIn(:,:,1:end-1));subplot(1,2,2);title('per innershot, spiral-ins');
%%
OutGifFN=[mainP filesep 'SpiralOut_' num2str(Delay_us) 'us_Sli' num2str(SlicesToRead) '.gif'];
delete(OutGifFN);
figure;
pause(1);
imagesc(abs(Rec1ccpMt(:,:,1)));colormap gray
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
gmontage(abs(UpdatedT2SMap_ms),[0 100]);removeTicks;
% Updated_TSC_L2=exp(-1i*angle(R1).*permute(0:(nTS_L2-1),[1 3 2]));
% % Updated_TSC_L2=exp(1i.*2*pi*B0Q2*(1e-3).*TimePoints_ms3_L2);
SimSpiralIn=Rec1ccpMt.*(R1.^0.5);

UpdatedB0Map0=UpdatedB0Map;
UpdatedT2SMap_ms0=UpdatedT2SMap_ms;
%% Test TH annihilation
% TH=HInnerShot*Rec1ccpMt(:,:,WhichInnIdxs);
% VH_LLR=(permute43(V_LLR));
% GoodDir=sum(TH.*VH_LLR(:,:,1,:),4);
% BadDir=sum(TH.*VH_LLR(:,:,2,:),4);
% BothDir=cat(4,GoodDir,BadDir);
% ShowAbsAngle(BothDir)
%% Out+In gif
OutInGifFN=[mainP filesep 'SpiralOutandIn_' num2str(Delay_us) 'us_Sli' num2str(SlicesToRead) '.gif'];
delete(OutInGifFN);
figure;pause(1);
imagesc(cat(2,abs(Rec1ccpMt(:,:,1)),abs(Rec1ccpMtIn(:,:,1))));colormap gray;removeTicks;axis equal
gif(OutInGifFN)
for i=2:size(Rec1ccpMt,3)
    imagesc(cat(2,abs(Rec1ccpMt(:,:,i)),abs(Rec1ccpMtIn(:,:,i))));colormap gray;removeTicks;axis equal
    gif
end
disp(OutInGifFN);
%% out in rotation gif
OutInRotGifFN=[mainP filesep 'SpiralOutInRot_' num2str(Delay_us) 'us_Sli' num2str(SlicesToRead) '.gif'];
delete(OutInRotGifFN);
figure;
pause(1)
imagesc(abs(Rec1ccpMt(:,:,1)));colormap gray;removeTicks;axis equal
% pause(1)
gif(OutInRotGifFN);
imagesc(abs(Rec1ccpMtIn(:,:,1)));colormap gray;removeTicks;axis equal
gif
disp(OutInRotGifFN);
%%
figure;imshowpair(abs(Rec1ccpMt(:,:,3)),abs(Rec1ccpMtIn(:,:,3)),'checkerboard')
%%
nAcqPoints=numel(Traj);

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
%% given B0
% nccToUse=7; % 7: 46 sec
% nccToUse=31;
% BigTrajPartToUse=1:45400;
BigTrajPartToUse=1:25000;
%% Given B0, T2S, W regularized
% 31Ch: 260sec.
CurRep=1;
R1x=min(max(abs(R1),0.3),1).*exp(-1i*angle(R1));
TSCx=R1x.^(TimePoints_ms3/InnerShotDiff_ms);
TSCxP=permute(TSCx,[1 2 7 6 5 4 3]);

WLambda=0.1;
% RegStr=['-R W:3:0:' num2str(WLambda)];
% tic;RecgD_W=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,BigTrajPartToUse,CurRep,1:nccToUse),...
%     DMsk.*SensCC(:,:,:,1:nccToUse),STraj3(:,BigTrajPartToUse),TSBP(:,BigTrajPartToUse,:,:,:,:,:,:,:),TSCxP,KernsP);
% t=toc;
% fgmontage(RecgD_W);MaximizeFig;xlabel(nccToUse);ylabel(t);title(['Single shot, given B_0,T_2^* estimate, ' RegStr]);
%%
% Rec1ccpMtC=Rec1ccpMt.*exp(-1i*angle(Rec1ccpMt(:,:,1)));
% Rec1ccpMtCM=Rec1ccpMt./Rec1ccpMt(:,:,1);
% fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');
%% Per rep/s, given B0,T2*, Short part of traj
% %% preparation
% WhichInnerShot=3;
% nTSShort=3;
% TSBShort=GetTSCoeffsByLinear(numel(TrajPartToUseC{WhichInnerShot}),nTSShort);
% TSBPShort=permute(TSBShort,[3 1 4 5 6 7 2]);
% 
% for CurRep=1:(nRepsHdr-1)
%     disp(CurRep);
%     STraj=TrajM(CurRep,TrajPartToUseC{WhichInnerShot});
%     STraj3MShort(:,:,CurRep)=CTo3Rows(STraj);
%     SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
%     KernsByRepShort{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSBShort);
%     KernsPShortC{CurRep}=permute(KernsByRepShort{CurRep},[1 2 7 6 5 4 3]);
% end
% KernsPMShort=cat(3,KernsPShortC{:});
% clear KernsPShortC
% 
% TimePointsShort_ms=linspace(0,AcqTimePoints_us(TrajPartToUseC{1}(end))/1000,nTSShort);
% TimePointsShort_ms3=permute(TimePointsShort_ms,[1 3 2]);
% TSCxShort=R1x.^(TimePointsShort_ms3/InnerShotDiff_ms);
% TSCxPShort=permute(TSCxShort,[1 2 7 6 5 4 3]);
% %% given B0,T2*, several reps together
% CurReps=1:39;
% % 14 sec
% 
% RecgD_SReps=bart(['picsS -m ' RegStr ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartToUseC{WhichInnerShot},CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MShort(:,:,CurReps),TSBPShort,...
%         TSCxPShort,sum(KernsPMShort(:,:,CurReps,:,:,:,:),3));
% 
% fgmontage(RecgD_SReps);title('Multi-shot, short part of traj, given B0,T2*');removeTicks
% 
% fgmontage(Rec1ccpMt(:,:,3));title('39 shots 2ms, for ref');
%% Longer
% TrajPartMed=1:2000;
% TrajPartMed=2200+(1:2000);
% 
% TrajPartMed=1:4600; % kind of ok
% TrajPartMed=1:40000;

% TrajPartMed=1:25000;

TrajPartMed=1:(floor(TotalAcqTime_us/AcqDwellTime_us/10)*10);

nPointsMed=numel(TrajPartMed);

dTS_planned_ms=2.5;
% nTSMed=ceil((nPointsMed+1)/1000);
nTSMed=ceil((nPointsMed+1)*AcqDwellTime_us/1000/dTS_planned_ms);

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
disp('Prepared Med');
%% given B0,T2*, several reps together
% CurReps=1:2;
% % 2000: 18v10 sec (Normal)
% 
% RegStrMed='-R W:3:0:0.0000001';
% 
% % ScriptFN_TS=[BaseSP 'NuftTSC.txt'];
% % ScriptFN_TS=[BaseSP 'nuftTSC_N.txt'];
% 
% % RecgD_SReps_Med=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
% %         SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MMed(:,:,CurReps),TSBPMed,...
% %         TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
%     
% RecgD_SReps_Med=bart(['picsS -m ' RegStrMed ' ' ScriptFN_TS],Sz16,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         DMsk.*SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,...
%         TSCxPMed,sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
% 
% fgmontage(RecgD_SReps_Med);title('Multi-shot, medium-length part of traj, given B0,T2*');removeTicks
% 
% fgmontage(Rec1ccpMt(:,:,1));title('39 shots 2ms, for ref');
% 
% fgmontage(Rec1ccpMtIn(:,:,1));title('39 shots 2ms, in, for ref');
%%
TightMask=DMsk;
%% Try to get all TSC, multi-shot, for B0,T2*
CurReps=1:39;

ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
Sz16AllTSC=FillOnesTo16(size(TSCxPMed));

% THLR_lambda=0.1;
THLR_lambda=10;
% RhoStr='';
RhoStr=[' -u ' num2str(1e-3) ' '];

THLRMultiShot=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,1,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
%%
WhichEchoToUse_THLR=1:(nTSMed-2);
[~,~,~,H_AllTS]=ghankel(numel(WhichEchoToUse_THLR),2,TrgSz);
[ ~, s_LLR_AllTS, V_LLR_AllTS] = batch_svd(H_AllTS*squeeze(THLRMultiShot(:,:,:,:,:,:,WhichEchoToUse_THLR)));
R1ts=V_LLR_AllTS(:,:,2,1)./V_LLR_AllTS(:,:,1,1); % R1 is simply the decay
InnerTSDiff_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
UpdatedT2SMap_ms1=-InnerTSDiff_ms./log(abs(R1ts));
UpdatedB0Map1=-(angle(R1ts)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz
%%
figure;subplot(1,2,1);gmontage(UpdatedB0Map1,[-100 100]);title('B_0,T_2^* from TH-LR multi-shot');removeTicks;colorbar
subplot(1,2,2);gmontage(UpdatedT2SMap_ms1,[0 100]);removeTicks;
%%
UpdatedB0Map=UpdatedB0Map1;
UpdatedT2SMap_ms=UpdatedT2SMap_ms1;
R1=R1ts;
R1x=min(max(abs(R1),0.3),1).*exp(-1i*angle(R1));
% R1x=R1;
InnerShotDiff_ms=InnerTSDiff_ms;
%%
DataForSlice{SlicesToRead}={UpdatedB0Map,UpdatedT2SMap_ms,UpdatedB0Map0,UpdatedT2SMap_ms0,THLRMultiShot,Rec1ccpMtOutIn,Rec1ccpMt,Rec1ccpMtIn,SelfSens1,sccmtx};

close all;

end % Slices loop
%%
save([mainP filesep 'DataForSlice.mat'],'DataForSlice');
%%
for i=1:nSlices
    THLRMultiShotSx(:,:,:,i)=squeeze(DataForSlice{i}{5});
end
%%
SliI=5;
WhichEchoToUse_THLR=1:(nTSMed-2);
[~,~,~,H_AllTS]=ghankel(numel(WhichEchoToUse_THLR),2,TrgSz);
[ ~, s_LLR_AllTS, V_LLR_AllTS] = batch_svd(H_AllTS*squeeze(THLRMultiShotSx(:,:,WhichEchoToUse_THLR,SliI)));
R1ts=V_LLR_AllTS(:,:,2,1)./V_LLR_AllTS(:,:,1,1); % R1 is simply the decay
InnerTSDiff_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
UpdatedT2SMap_ms1=-InnerTSDiff_ms./log(abs(R1ts));
UpdatedB0Map1=-(angle(R1ts)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz

%%
% load([mainP filesep 'DataForSlice.mat']);
%%
clear KernsByRepMed              	1513758480    		1513.76MB
clear KernsPMMed                 	1513754112    		1513.75MB
clear ADataIsL                   	499200000     		499.20MB
clear DataForSlice               	492372000     		492.37MB
clear ADataIsLCC                 	483600000     		483.60MB
clear DataC                      	483600000     		483.60MB
clear DataCCP                    	439640760     		439.64MB
clear DataPC                     	439640760     		439.64MB
clear InnerShotData              	193440000     		193.44MB
clear InnerShotDataIn            	193440000     		193.44MB
save([mainP filesep 'CurStatus.mat']);
%%
SliI=2;
for SliI=1:10
%%
ncc=31;

UpdatedB0Map=DataForSlice{SliI}{1};
UpdatedT2SMap_ms=DataForSlice{SliI}{2};
UpdatedB0Map0=DataForSlice{SliI}{3};
UpdatedT2SMap_ms0=DataForSlice{SliI}{4};
THLRMultiShot=DataForSlice{SliI}{5};
Rec1ccpMtOutIn=DataForSlice{SliI}{6};
Rec1ccpMt=DataForSlice{SliI}{7};
Rec1ccpMtIn=DataForSlice{SliI}{8};
SelfSens1=DataForSlice{SliI}{9};
sccmtx=DataForSlice{SliI}{10};

SensCC=permute(sum(SelfSens1.*permute(sccmtx(:,1:ncc),[3 4 1 5 6 7 8 9 2]),3),[1:2 9 3:8]);
SensCC=permute43(SensCC);
disp('ok SensCC');

%% more slice read
RepsToRead=1:(nRepsHdr-1);
ADataIsL=ADatax.image(:,:,:,:,SliI,1,:,:,RepsToRead,:,:,:,:,:,:,:,:);
ADataIsL=permute(ADataIsL,[1 2 9 11 5 3:4 6:8 10]);
ADataIsL=CombineDims(ADataIsL,[4 1]);

dx=RotatedLocs(2,1)/FOVx;
dy=RotatedLocs(1,1)/FOVx;

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
%
figure;
plot(kK);
axis square;
axis equal;
ylabel('k');
%%
ADataIsLCC=single(zeros([size(ADataIsL,1) ncc size(ADataIsL,3)]));
for i=1:ncc
    ADataIsLCC(:,i,:)=sum(ADataIsL.*permute(sccmtx(:,i),[3 1 4 5 6 7 8 9 2]),2);
end
DataC=permute(ADataIsLCC,[1 3 2]);
disp('ok cc');

DataPC=permute(DataC(1:nTrajToUse,:,:,:,:,:,:,:,:),[4 1 2 5 6 7 8 3]).*modx;

DataCCP=permute(DataPC,[1:3 8 4:7]);
disp('ok x');

%%
TrgSz=[NTrg NTrg];
%%
Extra=4;

kKA=[zeros(4,1); kK; repmat(kK(end),[10 1])]; % in us

Delays_us=1.6;
dlyI=1;
% for dlyI=1:numel(Delays_us)
    disp('-------');
    disp(dlyI);
    Delay_us=Delays_us(dlyI);
    AcqTimePoints_us=Extra*GradDwellTime_us+Delay_us+(0:AcqDwellTime_us:(TotalAcqTime_us-0.0001));

    Traj=interp1((0:(numel(kKA)-1))*GradDwellTime_us,kKA,AcqTimePoints_us);
    disp('ok delay');
    % plotTrajCrossPoints;
    
    nRepsToUse=nRepsHdr-1;

    TrajM=Traj.*exp(-1i*2*pi*PhiRotPerRep/360*(0:nRepsToUse-1)');

    DataC=permute(ADataIsLCC,[1 3 2]);

    BARTTraj=cat(3,real(TrajM),imag(TrajM),imag(TrajM)*0);
    BARTTrajP=permute(BARTTraj,[3 2 1]);

    kx=BARTTrajP(1,:,:)*2*pi;
    ky=BARTTrajP(2,:,:)*2*pi;

    modx=exp(-1i.*(dx*kx+dy*ky));
    disp('ok mod');
    
nTrajToUse=size(BARTTrajP,2);
%% end slice read
%% general stuff to redo
% TrajPartMed=1:40000;
TrajPartMed=1:(floor(TotalAcqTime_us/AcqDwellTime_us/10)*10);

nPointsMed=numel(TrajPartMed);

dTS_planned_ms=2.5;

nTSMed=ceil((nPointsMed+1)*AcqDwellTime_us/1000/dTS_planned_ms);
% nTSMed=ceil((nPointsMed+1)/1000);
TSBMed=GetTSCoeffsByLinear(nPointsMed,nTSMed);
TSBPMed=permute(TSBMed,[3 1 4 5 6 7 2]);

TimePointsMed_ms=linspace(0,AcqTimePoints_us(nPointsMed)/1000,nTSMed);
TimePointsMed_ms3=permute(TimePointsMed_ms,[1 3 2]);

% TSCxMed=R1x.^(TimePointsMed_ms3/InnerShotDiff_ms);
% TSCxPMed=permute(TSCxMed,[1 2 7 6 5 4 3]);

%%
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
disp('Prepared Med');
%%
% TightMask=DMsk;
DMsk=grmss(SensCC,3:4)>0.01;
%% Try to get all TSC, multi-shot, for B0,T2*
CurReps=1:39;

ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
% Sz16AllTSC=FillOnesTo16(size(TSCxPMed));
Sz16AllTSC=FillOnesTo16([Sz 1 1 1 1 nTSMed]);

% THLR_lambda=0.1;
THLR_lambda=10;
% RhoStr='';
RhoStr=[' -u ' num2str(1e-3) ' '];

THLRMultiShot=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,1,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));

%%
[~,~,~,H_AllTS]=ghankel(nTSMed,2,TrgSz);
[ ~, s_LLR_AllTS, V_LLR_AllTS] = batch_svd(H_AllTS*squeeze(THLRMultiShot));
R1ts=V_LLR_AllTS(:,:,2,1)./V_LLR_AllTS(:,:,1,1); % R1 is simply the decay
InnerTSDiff_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
UpdatedT2SMap_ms1=-InnerTSDiff_ms./log(abs(R1ts));
UpdatedB0Map1=-(angle(R1ts)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz
% fgmontage(UpdatedB0Map1,[-100 100]);removeTicks;title('B0 from TH-LR multi-shot');
%%
figure;subplot(1,2,1);gmontage(UpdatedB0Map1,[-100 100]);title('B_0,T_2^* from TH-LR multi-shot');removeTicks;colorbar
subplot(1,2,2);gmontage(UpdatedT2SMap_ms1,[0 100]);removeTicks;
%%
UpdatedB0Map=UpdatedB0Map1;
UpdatedT2SMap_ms=UpdatedT2SMap_ms1;
R1=R1ts;
R1x=min(max(abs(R1),0.3),1).*exp(-1i*angle(R1));
% R1x=R1;
InnerShotDiff_ms=InnerTSDiff_ms;

TSCxMed=R1x.^(TimePointsMed_ms3/InnerShotDiff_ms);
TSCxPMed=permute(TSCxMed,[1 2 7 6 5 4 3]);

Sz=TrgSz;


% clear STraj3MMed
% for CurRep=1:(nRepsHdr-1)
%     disp(CurRep);
%     STraj=TrajM(CurRep,TrajPartMed);
%     STraj3MMed(:,:,CurRep)=CTo3Rows(STraj);
%     SnufftStruct_CurRep = nufft_init(BART2Fes_NUFT_Idxs(CTo2Rows(STraj),Sz), Sz, [6 6], Sz*2); % st.om
%     KernsByRepMed{CurRep}=NUFFT_to_Toep_2blocks(SnufftStruct_CurRep,TSBMed);
%     KernsPMedC{CurRep}=permute(KernsByRepMed{CurRep},[1 2 7 6 5 4 3]);
% end
% KernsPMMed=cat(3,KernsPMedC{:});
% clear KernsPMedC
disp('Prepared Med');

%% end general stuff to redo

%% T2* histogram
TempRMS=grmss(THLRMultiShot,3:30);
T2sCenters=1:100;
T2Sbins=[-Inf T2sCenters-0.5 Inf];
[HT2s,edges,T2sbin] = histcounts(UpdatedT2SMap_ms(:),T2Sbins);
WHT2s=HT2s*0;
for i=1:numel(HT2s)
    WHT2s(i)=sum(TempRMS(T2sbin==i));
end
SWHT2s=max(WHT2s,sum(WHT2s)*0.03/numel(WHT2s));

clear WDecays WDecays4
for i=2:numel(HT2s)-1
    WDecays(i,:)=SWHT2s(i)*exp(-TimePointsMed_ms./T2sCenters(i-1));
%     WDecays4(i,:)=SWHT2s(i)*exp(-TimePointsMed4_ms./T2sCenters(i-1));
end


%% Using components
T2svalues_ms=linspace(5,300,200);
Decays=exp(-TimePointsMed_ms./(T2svalues_ms.'));

[Ud,Sd,Vd]=svd(Decays,'econ');
[WUd,WSd,WVd]=svd(WDecays,'econ');
% [WUd4,WSd4,WVd4]=svd(WDecays4,'econ');
Mag_THLRMultiShot=squeeze(abs(THLRMultiShot));
Mag_THLRMultiShot2D=reshape(Mag_THLRMultiShot,prod(gsize(Mag_THLRMultiShot,1:2)),size(Mag_THLRMultiShot,3));
[MUd,MSd,MVd]=svd(Mag_THLRMultiShot2D(:,:),'econ');

% figure;
% for i=1:4
%     subplot(2,2,i);
%     plot(Vd(:,i),'--');hold on
%     plot(WVd(:,i));hold on
% end
% legend({'T2* decays','W T2* decays'});
%%
CurReps=1;
nComponentsToUse=4;

ScriptFN_CompgBo=[BaseSP 'nuftCompgB0_N.txt'];
TSCxPMedOnlyB0=exp(1i.*angle(TSCxPMed));

Sz16CompgB0=FillOnesTo16([Sz 1 1 1 nComponentsToUse]);
% CompsP=permute(WVd(:,1:nComponentsToUse),[7:-1:3 2 1]);
CompsP=permute(MVd(:,1:nComponentsToUse),[7:-1:3 2 1]);
% # Img is [x y z 1 1 Comp]
% # file 0 is sensitivity maps [x y z Ch Maps]
% # file 1 is sampling pattern/Trajectory [3 #Traj spokes]
% # file 2 is TSB [1 #traj 1 1 1 1 TS] 
% # file 3 is TSC [x y z 1 1 1 TS]
% # file 4 is Toeplitz kernel [2x 2y z 1 1 1 TS]
% # file 5 is Components [1 1 1 1 1 Comp TS]

% THLR_lambda=0.1;
% LLR_lambda=10;
LLR_lambda=0.1;
% RhoStr='';
RhoStr=[' -u ' num2str(1e-3) ' '];
BlkSz=4;
disp('Prepared LLR');
%%
% Rec_CompgB0=bart(['picsS -m ' RhoStr ' -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],Sz16CompgB0,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,TSCxPMedOnlyB0,...
%         sum(KernsPMMed(:,:,CurReps,:,:,:,:),3),CompsP);
%     
% Rec_CompgB0X=squeeze(sum(Rec_CompgB0.*CompsP,6));
% %%
% [ ~, s_LLR_gB0, V_LLR_gB0] = batch_svd(H_AllTS*Rec_CompgB0X);
% R1gB0=V_LLR_gB0(:,:,2,1)./V_LLR_gB0(:,:,1,1); % R1 is simply the decay
% InnerTSDiff_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
% UpdatedT2SMap_ms_gB0=-InnerTSDiff_ms./log(abs(R1gB0));
% UpdatedB0Map_gB0=-(angle(R1gB0)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz
% % figure;subplot(1,2,1);gmontage(UpdatedB0Map_gB0,[-100 100]);title('B_0,T_2^* from single-shot T_2^* components LLR given B_0');removeTicks;colorbar
% % subplot(1,2,2);gmontage(UpdatedT2SMap_ms_gB0,[0 100]);removeTicks;
%% By rep (160sec per rep)
% for CurRep=1:(nRepsHdr-1)
for CurRepa=1:3 %(nRepsHdr-2)
% for CurRep=[2 17]
%     CurRep=CurRepa;
    CurRep=[CurRepa (CurRepa+1)];
    disp('aAaAaAa');
    disp('aAaAaAa');
    disp(CurRep);
    disp('aAaAaAa');
    Rec_CompgB0_C{CurRepa}=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
        Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,TSCxPMedOnlyB0,...
        sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
end
%%
Rec_CompgB0_M=cat(4,Rec_CompgB0_C{:});
Rec_CompgB0_MX=squeeze(sum(Rec_CompgB0_M.*CompsP,6));

Rec_CompgB0_MS{SliI}=Rec_CompgB0_M;
CompsPS{SliI}=CompsP;
THLRMultiShotS{SliI}=THLRMultiShot;
close all
end % SliI loop

save([mainP filesep 'PerSliceRec3.mat'],'Rec_CompgB0_MS','CompsPS','THLRMultiShotS');
%%
clear KernsByRepMed              	1513758480    		1513.76MB
clear KernsPMMed                 	1513754112    		1513.75MB
clear ADataIsL                   	499200000     		499.20MB
clear DataForSlice               	492372000     		492.37MB
clear ADataIsLCC                 	483600000     		483.60MB
clear DataC                      	483600000     		483.60MB
clear DataCCP                    	439640760     		439.64MB
clear DataPC                     	439640760     		439.64MB
clear InnerShotData              	193440000     		193.44MB
clear InnerShotDataIn            	193440000     		193.44MB
clear Rec_CompgB0_MX             	344258304     		344.26MB
% clear Rec_CompgB0_MS             	335862880     		335.86MB
clear InnerShotDataOutIn         	174183048     		174.18MB

save([mainP filesep 'CurStatus2.mat']);
%% LLR with B0 variation components
% ScriptFN_CompgBo=[BaseSP 'nuftCompgB0_N.txt'];
TSCxPMedOnlyB0=exp(1i.*angle(TSCxPMed));
% BaseComponents=WVd(:,1:nComponentsToUse);
BaseComponents=MVd(:,1:nComponentsToUse);
        
% B0VarEst=2;
% for nComponentsToUsewB0Var=2:4
nComponentsToUsewB0Var=3;
B0VarEst=2;
%     for B0VarEst=1:5
        CurRep=1;
        
        ComponentsToUse=BaseComponents(:,1:nComponentsToUsewB0Var);
        B0VarVec=exp(1i.*2*pi*B0VarEst*(1e-3).*(TimePointsMed_ms.'));
        B0VarVecm=exp(-1i.*2*pi*B0VarEst*(1e-3).*(TimePointsMed_ms.'));
        
        Comps=[ComponentsToUse ComponentsToUse.*B0VarVec ComponentsToUse.*B0VarVecm];
        
%         Comps=ComponentsToUse;
        
        nComponentsIncB0Var=size(Comps,2);
        
        Sz16CompgB0=FillOnesTo16([Sz 1 1 1 nComponentsIncB0Var]);
        CompsP=permute(Comps,[7:-1:3 2 1]);
        
%         LLR_lambda=0.1;
%         RhoStr=[' -u ' num2str(1e-3) ' '];
%         BlkSz=4;
        
%         LLR_lambda=10^-4;
        LLR_lambda=10^1;
        RhoStr=[' -u ' num2str(0.01) ' '];
%         RhoStr=[' -u ' num2str(0.1) ' '];
        BlkSz=3;
        for CurRep=1:(nRepsHdr-1)
            Rec_CompgB0_C_WB0Var=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
                Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
                SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,TSCxPMedOnlyB0,...
                sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
            Rec_CompgB0_C_WB0VarC{CurRep}=Rec_CompgB0_C_WB0Var;
        end
%         Rec_CompgB0_C_WB0Var_TestB0Var{B0VarEst,nComponentsToUsewB0Var}=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
%             Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
%             SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,TSCxPMedOnlyB0,...
%             sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
%     end
% end
disp('Prepared LLR');

Rec_CompgB0_C_WB0VarCS(:,SliI)=Rec_CompgB0_C_WB0VarC;
Rec_CompgB0_C_WB0VarX1=squeeze(sum(Rec_CompgB0_C_WB0Var.*CompsP,6));
% Rec_CompgB0_C_WB0VarXS1=SmoothBySlices(Rec_CompgB0_C_WB0VarX1,[8 8],1.1);
%% open the results: Interesting - nComponentsToUsewB0Var=3, B0VarEst=2 (B0VarEst can be 1-5, doesn't matter)
for nComponentsToUsewB0Var=2:4
    for B0VarEst=1:5
        CurRep=1;
        
        ComponentsToUse=BaseComponents(:,1:nComponentsToUsewB0Var);
        B0VarVec=exp(1i.*2*pi*B0VarEst*(1e-3).*(TimePointsMed_ms.'));
        B0VarVecm=exp(-1i.*2*pi*B0VarEst*(1e-3).*(TimePointsMed_ms.'));
        
        Comps=[ComponentsToUse ComponentsToUse.*B0VarVec ComponentsToUse.*B0VarVecm];
        
        nComponentsIncB0Var=size(Comps,2);
        
        Sz16CompgB0=FillOnesTo16([Sz 1 1 1 nComponentsIncB0Var]);
        CompsP=permute(Comps,[7:-1:3 2 1]);
        
        LLR_lambda=0.1;
        RhoStr=[' -u ' num2str(1e-3) ' '];
        BlkSz=4;
        
        
        Rec_CompgB0_C_WB0Var_TestB0VarM(:,:,:,B0VarEst,nComponentsToUsewB0Var)=squeeze(sum(Rec_CompgB0_C_WB0Var_TestB0Var{B0VarEst,nComponentsToUsewB0Var}.*CompsP,6));
    end
end
%%
NoB0Var=squeeze(Rec_CompgB0_MX(:,:,23,:));
WithB0Var4Comp=Rec_CompgB0_C_WB0Var_TestB0VarM(:,:,:,2,4);
WithB0Var3Comp=Rec_CompgB0_C_WB0Var_TestB0VarM(:,:,:,2,3);
WithB0Var3Comp1=Rec_CompgB0_C_WB0Var_TestB0VarM(:,:,:,1,3);
LLRB0VarTest=cat(4,NoB0Var,WithB0Var4Comp,WithB0Var3Comp,WithB0Var3Comp1,Rec_CompgB0_C_WB0VarX,Rec_CompgB0_C_WB0VarX1,squeeze(THLRMultiShot*grmss(WithB0Var3Comp)/grmss(THLRMultiShot)));

for i=1:size(LLRB0VarTest,4)
    WhichInnerShotsToUse=7:20;
    [~,~,~,H_tmp]=ghankel(numel(WhichInnerShotsToUse),2,TrgSz);
    [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze(LLRB0VarTest(:,:,WhichInnerShotsToUse,i)));
    R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
%     InnerTSDiff_PerShot_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
    UpdatedT2SMap_tmp=-InnerTSDiff_PerShot_ms./log(abs(R1a));
    UpdatedB0Map_tmp=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz
    
    s_tmpx(:,:,:,i)=s_tmp;
    UpdatedT2SMap_tmpx(:,:,i)=UpdatedT2SMap_tmp;
    UpdatedB0Map_tmpx(:,:,i)=UpdatedB0Map_tmp;
end
fgmontage(permute43(s_tmpx))

ZZ=grmss(PartitionDim(LLRB0VarTest,3,4),3);

fgmontage(CombineDims(UpdatedT2SMap_tmpx,[3 2]),[0 100]);removeTicks
%%
    WhichInnerShotsToUse=11:20;
    [~,~,~,H_tmp]=ghankel(numel(WhichInnerShotsToUse),2,TrgSz);

%     [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze((LLRB0VarTest(:,:,WhichInnerShotsToUse,6))));
    [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze((Rec_CompgB0_C_WB0VarX1(:,:,WhichInnerShotsToUse))));
    R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
    UpdatedT2SMap_tmp=-InnerTSDiff_PerShot_ms./log(abs(R1a));
    UpdatedB0Map_tmp=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz
fgmontage(UpdatedT2SMap_tmp,[0 100])
fgmontage(UpdatedB0Map_tmp,[-5 5]);
%%
% XX=LLRB0VarTest(:,:,15,6).*(R1a.^permute32(-14:5)); % MPBD from here?
XX=Rec_CompgB0_C_WB0VarX1(:,:,15).*(R1a.^permute32(-14:5)); % MPBD from here?
%% Per Rep analysis LLR+B0var
Rec_CompgB0_C_WB0VarM=cat(4,Rec_CompgB0_C_WB0VarC{:});
Rec_CompgB0_C_WB0VarM1=permute(sum(Rec_CompgB0_C_WB0VarM.*CompsP,6),[1 2 7 4 6 5 3]);
%%
    WhichInnerShotsToUse=11:20;
    [~,~,~,H_tmp]=ghankel(numel(WhichInnerShotsToUse),2,TrgSz);

for CurRep=1:(nRepsHdr-1)
    [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze((Rec_CompgB0_C_WB0VarM1(:,:,WhichInnerShotsToUse,CurRep))));
    R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
    UpdatedT2SMap_LLR_B0VarR(:,:,CurRep)=-InnerTSDiff_PerShot_ms./log(abs(R1a));
    UpdatedB0Map_LLR_B0VarR(:,:,CurRep)=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz    
end
%%
fgmontage(UpdatedB0Map_LLR_B0VarR(:,:,[1 2 3 37 38 39]),[-5 5]);

fgmontage(UpdatedT2SMap_LLR_B0VarR(:,:,[1 2 3 37 38 39]).*DMsk,[0 100]);

fgmontage(UpdatedT2SMap_LLR_B0VarR(:,:,[1 2 3 37 38 39]).*DMsk,[0 200]);colormap hot;olorbar;removeTicks

YY=CombineDims(CombineDims(PartitionDim(UpdatedT2SMap_LLR_B0VarR(:,:,[1 2 3 37 38 39]).*DMsk,3,2),[4 1]),[3 2]);
fgmontage(YY,[0 200]);colormap hot;colorbar;removeTicks;title('Per-shot T_2^* maps');

fgmontage((UpdatedT2SMap_LLR_B0VarR(:,:,[1 3 5])+UpdatedT2SMap_LLR_B0VarR(:,:,[2 4 6])*0.5).*DMsk,[0 200]);colormap hot;
YY=CombineDims((UpdatedT2SMap_LLR_B0VarR(:,:,[1 3 5])+UpdatedT2SMap_LLR_B0VarR(:,:,[2 4 6]))*0.5.*DMsk,[3 2]);
fgmontage(YY,[0 200]);colormap hot;colorbar;removeTicks;title('Per-shot T_2^* maps, 2-shots average (of the map)');
%% 2nd phase
for CurRep=1:(nRepsHdr-1)
    CurB0VarUpdate=exp(1i.*2*pi*UpdatedB0Map_LLR_B0VarR(:,:,CurRep)*(1e-3).*TimePointsMed_ms3);
    CurB0VarUpdateP=permute(CurB0VarUpdate,[1 2 7 6 5 4 3]);
    CurTSCxPMedOnlyB0=TSCxPMedOnlyB0.*CurB0VarUpdateP;
    Rec_CompgB0_C_WB0Var_I2=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
        Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,CurTSCxPMedOnlyB0,...
        sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
    Rec_CompgB0_C_WB0VarC_I2{CurRep}=Rec_CompgB0_C_WB0Var_I2;
end
%% Per Rep analysis LLR+B0var
Rec_CompgB0_C_WB0VarM_I2=cat(4,Rec_CompgB0_C_WB0VarC_I2{:});
Rec_CompgB0_C_WB0VarM1_I2=permute(sum(Rec_CompgB0_C_WB0VarM_I2.*CompsP,6),[1 2 7 4 6 5 3]);
%%
    WhichInnerShotsToUse=11:20;
    WhichInnerShotsToUse=7:20;
    [~,~,~,H_tmp]=ghankel(numel(WhichInnerShotsToUse),2,TrgSz);

for CurRep=1:(nRepsHdr-1)
    [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze((Rec_CompgB0_C_WB0VarM1_I2(:,:,WhichInnerShotsToUse,CurRep))));
    R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
    UpdatedT2SMap_LLR_B0VarR_I2(:,:,CurRep)=-InnerTSDiff_PerShot_ms./log(abs(R1a));
    UpdatedB0Map_LLR_B0VarR_I2(:,:,CurRep)=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz    
end
%%
fgmontage(UpdatedT2SMap_LLR_B0VarR(:,:,1),[0 100])
fgmontage(UpdatedT2SMap_LLR_B0VarR_I2(:,:,1),[0 100])
%% 2nd phase, no B0var components
Comps=ComponentsToUse;
nComponentsIncB0Var=size(Comps,2);
Sz16CompgB0=FillOnesTo16([Sz 1 1 1 nComponentsIncB0Var]);
CompsP=permute(Comps,[7:-1:3 2 1]);
for CurRep=1:(nRepsHdr-1)
    CurB0VarUpdate=exp(1i.*2*pi*UpdatedB0Map_LLR_B0VarR(:,:,CurRep)*(1e-3).*TimePointsMed_ms3);
    CurB0VarUpdateP=permute(CurB0VarUpdate,[1 2 7 6 5 4 3]);
    CurTSCxPMedOnlyB0=TSCxPMedOnlyB0.*CurB0VarUpdateP;
    Rec_CompgB0_C_WB0Var_I2b=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
        Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,CurTSCxPMedOnlyB0,...
        sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
    Rec_CompgB0_C_WB0VarC_I2b{CurRep}=Rec_CompgB0_C_WB0Var_I2b;
end
%% Per Rep analysis LLR+B0updated
Rec_CompgB0_C_WB0VarM_I2b=cat(4,Rec_CompgB0_C_WB0VarC_I2b{:});
Rec_CompgB0_C_WB0VarM1_I2b=permute(sum(Rec_CompgB0_C_WB0VarM_I2b.*CompsP,6),[1 2 7 4 6 5 3]);
%%
for CurRep=1:(nRepsHdr-1)
    [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*squeeze((Rec_CompgB0_C_WB0VarM1_I2b(:,:,WhichInnerShotsToUse,CurRep))));
    R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
    UpdatedT2SMap_LLR_B0VarR_I2b(:,:,CurRep)=-InnerTSDiff_PerShot_ms./log(abs(R1a));
    UpdatedB0Map_LLR_B0VarR_I2b(:,:,CurRep)=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz    
end
%%
fgmontage(UpdatedT2SMap_LLR_B0VarR(:,:,1),[0 100])
fgmontage(UpdatedT2SMap_LLR_B0VarR_I2(:,:,1),[0 100])
fgmontage(UpdatedT2SMap_LLR_B0VarR_I2b(:,:,1),[0 100])
%% saving not big
a=whos;
[S Ord]=sort([a.bytes],'descend');
VarNamesOrderedBySize={a(Ord).name};
% save([mainP filesep 'Status_LLRPerShotB0Var.mat'],'DataCCP',VarNamesOrderedBySize{16:end});
%% Prepare updated B0 TSC
for CurRep=1:(nRepsHdr-1)
    CurB0VarUpdate=exp(1i.*2*pi*UpdatedB0Map_LLR_B0VarR(:,:,CurRep)*(1e-3).*TimePointsMed_ms3);
    CurB0VarUpdateP=permute(CurB0VarUpdate,[1 2 7 6 5 4 3]);
    CurTSCxPMedOnlyB0M(:,:,CurRep,1,1,1,:)=TSCxPMedOnlyB0.*CurB0VarUpdateP;
end
%% Rec several slices together, given updated B0
ScriptFN_CompgB0VarSomeShots=[BaseSP 'nuftCompgB0VarSomeShots_N.txt'];

Perm93=@(X) permute(X,[1 2 9 4 5 6 7 8 3]);
CurRep=[1 2 3];

Sz16CompgB0VarSomeShots=Sz16CompgB0;
% Sz16CompgB0VarSomeShots(9)=numel(CurRep); % Uncomment this to calculate each shot separately

tmp=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgB0VarSomeShots],...
        Sz16CompgB0VarSomeShots,Perm93(DataCCP(:,TrajPartMed,CurRep,1:nccToUse)),...
        SensCC(:,:,:,1:nccToUse),Perm93(STraj3MMed(:,:,CurRep)),TSBPMed,Perm93(CurTSCxPMedOnlyB0M(:,:,CurRep,:,:,:,:,:,:)),...
        Perm93(KernsPMMed(:,:,CurRep,:,:,:,:)),CompsP);
    
tmpX=permute(sum(Perm93(tmp).*CompsP,6),[1 2 7 4 6 5 3]);
%%
MaxShotsTogether=5;
for CurRepa=1:(nRepsHdr-MaxShotsTogether-1)
    for nShotsTogether=1:MaxShotsTogether
        CurRep=CurRepa+(0:(nShotsTogether-1));
        Rec_CompgB0_C_gB0Var_SomeShots{CurRepa,nShotsTogether}=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgB0VarSomeShots],...
            Sz16CompgB0VarSomeShots,Perm93(DataCCP(:,TrajPartMed,CurRep,1:nccToUse)),...
            SensCC(:,:,:,1:nccToUse),Perm93(STraj3MMed(:,:,CurRep)),TSBPMed,Perm93(CurTSCxPMedOnlyB0M(:,:,CurRep,:,:,:,:,:,:)),...
            Perm93(KernsPMMed(:,:,CurRep,:,:,:,:)),CompsP);
    end
end
%%
for i=1:15
    Rec_CompgB0_C_gB0Var_SomeShotsMC{i}=cat(5,Rec_CompgB0_C_gB0Var_SomeShots{i,:});
end
Rec_CompgB0_C_gB0Var_SomeShotsM=cat(4,Rec_CompgB0_C_gB0Var_SomeShotsMC{:});
Rec_CompgB0_C_gB0Var_SomeShotsM=squeeze(sum(Rec_CompgB0_C_gB0Var_SomeShotsM.*CompsP,6));

fgmontagex((squeeze(Rec_CompgB0_C_gB0Var_SomeShotsM(:,:,[1 7 13],2,[1 2 5 10 15 20]))),[0 0.002]);
title('2shot, with per-shot B_0 variation, 3 different (2-)shots, several echos')

ZZ=grmss(PartitionDim(Rec_CompgB0_C_gB0Var_SomeShotsM,5,4),5);
fgmontagex(permute43(squeeze(ZZ(:,:,[1 6 12 15],2,2:4))));
title('2-shot, 4 representing shots, 3 combined echos');
%%
XX=permute(Rec_CompgB0_C_gB0Var_SomeShotsM,[1 2 5 3 4]);
WhichInnerShotsToUse=7:20;
[~,~,~,H_tmp]=ghankel(numel(WhichInnerShotsToUse),2,TrgSz);
for i=1:size(XX,4)
    for j=1:size(XX,5)
        [ ~, s_tmp, V_tmp] = batch_svd(H_tmp*XX(:,:,WhichInnerShotsToUse,i,j));
        R1a=V_tmp(:,:,2,1)./V_tmp(:,:,1,1); % R1 is simply the decay
        UpdatedT2SMap_tmp(:,:,i,j)=-InnerTSDiff_PerShot_ms./log(abs(R1a));
        UpdatedB0Map_tmp(:,:,i,j)=-(angle(R1a)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz
    end
end

fgmontagex(UpdatedT2SMap_tmp(:,:,[1 7 13],:).*B,[0 200]);
colormap hot;title('T_2^* map, using 1-5 shots, 3 different shots');

%% By rep (160sec per rep)
% for CurRep=1:(nRepsHdr-1)
% for CurRepa=1:(nRepsHdr-2)
% % for CurRep=[2 17]
%     CurRep=CurRepa;
% %     CurRep=[CurRepa (CurRepa+1)];
%     disp('aAaAaAa');
%     disp('aAaAaAa');
%     disp(CurRep);
%     disp('aAaAaAa');
%     Rec_CompgB0_C_WB0Var{CurRep}=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
%         Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,TSCxPMedOnlyB0,...
%         sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
% end
%%
Rec_CompgB0_WB0Var_M=cat(4,Rec_CompgB0_C_WB0Var{:});
Rec_CompgB0_WB0Var_MX=squeeze(sum(Rec_CompgB0_WB0Var_M.*CompsP,6));
%%




%% LLR Hyperparameter test
CurRep=20;

LLR_lambda=0.1;
BlkSzs=1:8;

Rhos=10.^(-5:5);
LLR_lambdas=10.^(-5:5);

Rec_CompgB0_Hyp_C=cell(numel(BlkSzs),numel(Rhos),numel(LLR_lambdas));
%%
for b=3:numel(BlkSzs)
    BlkSz=BlkSzs(b);
    for i=1:4 % numel(Rhos)
        RhoStr=[' -u ' num2str(Rhos(i)) ' '];
        for j=1:numel(LLR_lambdas)
            LLR_lambda=LLR_lambdas(j);
            tic
            Rec_CompgB0_Hyp_C{b,i,j}=bart(['picsS -m ' RhoStr ' -w 1 -b ' num2str(BlkSz) ' -R L:3:3:' num2str(LLR_lambda) ' ' ScriptFN_CompgBo],...
                Sz16CompgB0,DataCCP(:,TrajPartMed,CurRep,1:nccToUse),...
                SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRep),TSBPMed,TSCxPMedOnlyB0,...
                sum(KernsPMMed(:,:,CurRep,:,:,:,:),3),CompsP);
            t=toc;
            Timings(b,i,j)=t;
        end
    end
end
%%
save('Rec_CompgB0_Hyp_C.mat','Rec_CompgB0_Hyp_C');
Rec_CompgB0_C12=Rec_CompgB0_Hyp_C;
save('Rec_CompgB0_C12.mat','Rec_CompgB0_C12','CompsP');

for i=1:numel(Rhos)-1
    Rec_CompgB0_Hyp_C1M{i}=cat(5,Rec_CompgB0_Hyp_C{1,i,:});
end
Rec_CompgB0_Hyp_1M=cat(3,Rec_CompgB0_Hyp_C1M{:});

Rec_CompgB0_Hyp_1MX=squeeze(sum(Rec_CompgB0_Hyp_1M.*CompsP,6));
Rec_CompgB0_Hyp_1MXN=Rec_CompgB0_Hyp_1MX./grms(Rec_CompgB0_Hyp_1MX,1:2);

Rec_CompgB0_Hyp_1MX_rms=grmss(Rec_CompgB0_Hyp_1MX,5);

for i=1:7
    Rec_CompgB0_Hyp_C2M{i}=cat(5,Rec_CompgB0_Hyp_C{2,i,:});
end

Rec_CompgB0_Hyp_2M=cat(3,Rec_CompgB0_Hyp_C2M{:});

Rec_CompgB0_Hyp_2MX=squeeze(sum(Rec_CompgB0_Hyp_2M.*CompsP,6));
Rec_CompgB0_Hyp_2MXN=Rec_CompgB0_Hyp_2MX./grms(Rec_CompgB0_Hyp_2MX,1:2);

Rec_CompgB0_Hyp_2MX_rms=grmss(Rec_CompgB0_Hyp_2MX,5);

%% THLR With different lambda, U vals
% CurReps=1:39;
% 
% ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
% % Sz16AllTSC=FillOnesTo16(size(TSCxPMed));
% Sz16AllTSC=FillOnesTo16([Sz 1 1 1 1 nTSMed]);
% 
% % THLR_lambda=0.1;
% THLR_lambda=10;
% % RhoStr='';
% RhoStr=[' -u ' num2str(1e-3) ' '];
% 
% THLRMultiShot=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,1,...
%         sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
%%
CurReps=13;

Rhos=10.^(-6:5);
THLR_lambdas=10.^(-5:6);

% THLR_MultiShotC=cell(numel(Rhos),numel(THLR_lambdas));
THLR_SingleShotC=cell(numel(Rhos),numel(THLR_lambdas));
%%
for i=1:numel(Rhos)
    for j=1:numel(THLR_lambdas)
%         THLR_MultiShotC{i,j}=bart(['picsS -m -u ' num2str(Rhos(i)) ' -R K:64:3:' num2str(THLR_lambdas(j)) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse).*TightMask,STraj3MMed(:,:,CurReps),TSBPMed,1,...
%         sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
        THLR_SingleShotC{i,j}=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,1,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
    end
end
%%
save('THLR_SingleShotC.mat','THLR_SingleShotC');
% save('THLR_MultiShot_C.mat','THLR_MultiShotC');
%% all kind of the same. Chose Rho=10^-3, THLR_lambda=10^1
for i=1:numel(Rhos)
%     THLR_MultiShotMC{i}=cat(4,THLR_MultiShotC{i,1:10});
    THLR_SingleShotMC{i}=cat(4,THLR_SingleShotC{i,1:10});
end
% THLR_MultiShotM=cat(5,THLR_MultiShotMC{:});
% THLR_MultiShotM=permute(THLR_MultiShotM,[1 2 7 4 5 6 3]);
THLR_SingleShotM=cat(5,THLR_SingleShotMC{:});
THLR_SingleShotM=permute(THLR_SingleShotM,[1 2 7 4 5 6 3]); % all similar, lower values a bit cleaner, Rho=10^-3, THLR_lambda=10^1 seems ok
%%


%% THLR pershot
CurReps=10;
for CurReps=1:39
    ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
    % Sz16AllTSC=FillOnesTo16(size(TSCxPMed));
    Sz16AllTSC=FillOnesTo16([Sz 1 1 1 1 nTSMed]);
    
    % THLR_lambda=0.1;
    THLR_lambda=10;
    % RhoStr='';
    RhoStr=[' -u ' num2str(1e-3) ' '];
    
    THLRMultiShot=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSC,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,1,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3));
    
    THLRPerShotC{CurReps}=THLRMultiShot;
%     THLRPerShot(:,:,:,CurReps)=squeeze(THLRMultiShot);
end
%%
save('THLR_PerShotC.mat','THLRPerShotC');
%%
THLR_MS=squeeze(THLRMultiShotS{SliI});
THLR_MS_Mag=grmss(THLR_MS,3:30);
[~,BMS,BNMS]=CalcSlicesSNR(THLR_MS_Mag,true,5);
BMSX=getLargestComponent(BMS);
for CurRep=1:39
    disp(CurRep);
    tmp=squeeze(THLRPerShotC{CurRep}).*exp(-1i*angle(THLR_MS));
% [~,~,~,H_AllTS]=ghankel(nTSMed,2,TrgSz);
    [ ~, s_THLR_PerShot, V_THLR_PerShot] = batch_svd(H_AllTS*tmp);
    R1ps=V_THLR_PerShot(:,:,2,1)./V_THLR_PerShot(:,:,1,1); % R1 is simply the decay
    InnerTSDiff_PerShot_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
    UpdatedT2SMap_PerShot_ms=-InnerTSDiff_PerShot_ms./log(abs(R1ps));
    UpdatedB0Map_PerShot=-(angle(R1ps)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz

    UpdatedB0Map_PerShotM(:,:,CurRep)=UpdatedB0Map_PerShot;
end
%%
fgmontage(UpdatedB0Map_PerShotM(:,:,1:9).*BMSX,[-100 100]);

UpdatedB0Map_PerShotMX=UpdatedB0Map_PerShotM;
UpdatedB0Map_PerShotMX(abs(UpdatedB0Map_PerShotMX)>10)=0;

fgmontage(UpdatedB0Map_PerShotMX(:,:,:).*BMSX,[-10 10]);
%%
figure;subplot(1,2,1);gmontage(UpdatedB0Map_PerShot,[-100 100]);title('B_0,T_2^* from single-shot T_2^* components THLR');removeTicks;colorbar
subplot(1,2,2);gmontage(UpdatedT2SMap_PerShot_ms,[0 100]);removeTicks;

fgmontage(UpdatedB0Map_PerShot,[-100 100]);
fgmontage(UpdatedB0Map1,[-100 100]);

figure;subplot(1,2,1);gmontage(UpdatedB0Map1,[-100 100]);title('B_0,T_2^* from TH-LR multi-shot');removeTicks;colorbar
subplot(1,2,2);gmontage(UpdatedT2SMap_ms1,[0 100]);removeTicks;

fgmontage(UpdatedB0Map_PerShotMX(:,:,[1 2 3 37 38 39]).*BMSX,[-10 10]);
%% Now 2L THLR per shot, gB0
nTS_L1=5;
nTS_L2=nTSMed;
TSB_L1=GetTSCoeffsByLinear(nTS_L2,nTS_L1);
TSBP_L1=permute(TSB_L1,[3:7 2 1]);

ScriptFN_TS_2L=[BaseSP 'nuftTSC_N_2L.txt'];
Sz16_2L=FillOnesTo16([Sz 1 1 1 nTS_L1]);
    
% # file 0 is sensitivity maps [x y z Ch Maps]
% # file 1 is sampling pattern/Trajectory [3 #Traj spokes]
% # file 2 is TSB_L2 [1 #traj 1 1 1 1 TS_L2] 
% # file 3 is TSC_L2 [x y z 1 1 1 TS_L2]
% # file 4 is Toeplitz kernel L2 [2x 2y z 1 1 1 TS_L2]
% # file 5 is TSB_L1 [1 1 1 1 1 TS_L1 TS_L2] 
% # Data is [1 #Traj 1 Ch]

THLRMultiShot=THLRMultiShotS{SliI};

[~,~,~,H_AllTS]=ghankel(nTSMed,2,TrgSz);
[ ~, s_LLR_AllTS, V_LLR_AllTS] = batch_svd(H_AllTS*squeeze(THLRMultiShot));
R1ts=V_LLR_AllTS(:,:,2,1)./V_LLR_AllTS(:,:,1,1); % R1 is simply the decay
InnerTSDiff_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
% UpdatedT2SMap_ms1=-InnerTSDiff_ms./log(abs(R1ts));
% UpdatedB0Map1=-(angle(R1ts)/(2*pi))/(InnerTSDiff_ms/1e3); % in Hz

R1=R1ts;
R1x=min(max(abs(R1),0.3),1).*exp(-1i*angle(R1));

TSCxMed=R1x.^(TimePointsMed_ms3/InnerShotDiff_ms);
TSCxPMed=permute(TSCxMed,[1 2 7 6 5 4 3]);

TSCxPMedOnlyB0=exp(1i.*angle(TSCxPMed));
%% 125 sec per shot
CurReps=10;
for CurReps=[1 2 3 37 38 39]
    % THLR_lambda=0.1;
    THLRgB0_lambda=10;
    % RhoStr='';
    RhoStr=[' -u ' num2str(1e-3) ' '];
    
    THLRPerShotgB0=bart(['picsS -m ' RhoStr ' -R K:32:3:' num2str(THLRgB0_lambda) ':2:1:0:5 ' ScriptFN_TS_2L],Sz16_2L,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,TSCxPMedOnlyB0,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3),TSBP_L1);
    
    THLRPerShotgB0C{CurReps}=THLRPerShotgB0;
    THLRPerShotgB0R(:,:,:,CurReps)=squeeze(THLRPerShotgB0);
end
% THLRPerShotgB0R=permute(cat(4,THLRPerShotgB0C{:}),[1 2 6 4 3 5]);
%%
[~,~,~,H_L1]=ghankel(nTS_L1,2,TrgSz);
for CurReps=1:6 % [1 2 3 37 38 39]
    [ ~, s_2L, V_2L] = batch_svd(H_L1*squeeze(THLRPerShotgB0R(:,:,:,CurReps)));
    R1_2L=V_2L(:,:,2,1)./V_2L(:,:,1,1); % R1 is simply the decay
    InnerTSDiff_L1_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTS_L1-1);
    UpdatedT2SMap_2L_ms=-InnerTSDiff_L1_ms./log(abs(R1_2L));
    dUpdatedB0Map=-(angle(R1_2L)/(2*pi))/(InnerTSDiff_L1_ms/1e3); % in Hz
    dUpdatedB0MapM(:,:,CurReps)=dUpdatedB0Map;
end
%%
for CurReps=1:6 % [1 2 3 37 38 39]
    disp(CurReps);
    CurW=grmss(THLRPerShotgB0R(:,:,:,3),3);
    CurW=CurW.*(abs(dUpdatedB0MapM(:,:,CurReps))<10);
    dB0S(:,:,CurReps)=FitB0ToRemoveGaps(dUpdatedB0MapM(:,:,CurReps),CurW,5);
end
%%
fgmontage(dUpdatedB0MapM(:,:,[1 2 3 4 5 6]).*BMSX,[-10 10]);title('dUpdatedB0MapM, THLR 2L')

fgmontage(dB0S(:,:,[1 2 3 4 5 6]).*BMSX,[-10 10]);title('dUpdatedB0MapM, Smoothed, THLR 2L')
%% for comparison with full THLR per shot
fgmontage(UpdatedB0Map_PerShotMX(:,:,[1 2 3 37 38 39]).*BMSX,[-10 10]);
%% Now THLR, Several shots, separately
CurRepsx=1:2;
nCurShots=numel(CurRepsx);
% ScriptFN_AllTS=[BaseSP 'nuftAllTSC_N.txt'];
Sz16AllTSCsShots=FillOnesTo16([Sz nCurShots 1 1 1 nTSMed]);
THLRsomeShots_lambda=10;
RhoStr=[' -u ' num2str(1e-3) ' '];
    
    THLR_SomeShot=bart(['picsS -m ' RhoStr ' -R K:64:7:' num2str(THLRsomeShots_lambda) ':2:1:0:6 ' ScriptFN_AllTS],Sz16AllTSCsShots,DataCCP(:,TrajPartMed,CurRepsx,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRepsx),TSBPMed,1,...
        KernsPMMed(:,:,CurRepsx,:,:,:,:));
    
    THLRPerShotC{CurReps}=THLRMultiShot;
%     THLRPerShot(:,:,:,CurReps)=squeeze(THLRMultiShot);
%% THLR, given full ITS, just a factor, low res
ScriptFN_AllTSgTSC=[BaseSP 'nuftAllTSgTSC_N.txt'];
CurRepsx=2;
Sz16AllTSC=FillOnesTo16([Sz 1 1 1 1 nTSMed]);
    
    % THLR_lambda=0.1;
    THLR_lambda=10;
    % RhoStr='';
    RhoStr=[' -u ' num2str(1e-3) ' '];
%     ' K:64:3:' num2str(THLR_lambda) ':2:1:0:6 '
    THLRgITS=bart(['picsS -m ' RhoStr ' -R K:64:3:' num2str(THLR_lambda) ':2:1:0:6 ' ' -R T:3:3:10000 ' ScriptFN_AllTSgTSC],Sz16AllTSC,DataCCP(:,TrajPartMed,CurRepsx,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRepsx),TSBPMed,THLRMultiShot,...
        sum(KernsPMMed(:,:,CurRepsx,:,:,:,:),3));
%%
[ ~, s_THLR_gTSC, V_THLR_gTSC] = batch_svd(H_AllTS*squeeze(THLRgITS));
R1gTSC=V_THLR_PerShot(:,:,2,1)./V_THLR_PerShot(:,:,1,1); % R1 is simply the decay
%     InnerTSDiff_PerShot_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTSMed-1);
UpdatedT2SMap_gTSC=-InnerTSDiff_PerShot_ms./log(abs(R1gTSC));
UpdatedB0Map_gTSC=-(angle(R1gTSC)/(2*pi))/(InnerTSDiff_PerShot_ms/1e3); % in Hz
%%
TSBP_L1=permute(TSB_L1,[3:7 2 1]);
Sz16_2L=Sz16;
Sz16_2L(6)=nTS_L1;

[~,~,~,H_L1]=ghankel(nTS_L1,2,TrgSz);
%% 2L, given full ITS - add low res by fftc and masking!
% ScriptFN_TS_2L=[BaseSP 'nuftTSC_N_2L.txt'];
% ScriptFN_TS_2L_Smooth=[BaseSP 'nuftTSC_N_2L_Smooth.txt'];
ScriptFN_TS_2L_Smoothx=[BaseSP 'nuftTSC_N_2L_Smoothx.txt'];

MainOps_2L_S={'_sm1 fftc 3','_smm fmac 6 0','_sm2 ifftc 3','FMAC 5 32','_sensop FMAC 0 16','fmac 3 0','NUFFT 1 -1 -1 7 0 0 0 0','FMAC 2 64','NORMAL','f 0','f 1','f 2','f 3','f sensop','f 5','dblsz 3','fft 3','fmac 4 0','ifft 3','halfsz 3','a 5','a sensop','a 3','a 2','a 1','a 0'};
To_1L_Ops={'fftc 3','fmac 6 0','ifftc 3','hankel 5 6 2'};
WriteLinopToFile(ScriptFN_TS_2L_Smoothx,{MainOps_2L_S,To_1L_Ops});

HalfN=NTrg/2;
HalfNp1=HalfN+1;
HalfNm1=HalfN-1;
% SmoothCenterHalfSize=9;
% FMsk=zeros(TrgSz);
% FMsk(HalfNp1+(-SmoothCenterHalfSize:SmoothCenterHalfSize),HalfNp1+(-SmoothCenterHalfSize:SmoothCenterHalfSize))=1;
FMskSig=3;
FMsk1D=normpdf(-HalfN:HalfNm1,0,FMskSig)./normpdf(0,0,FMskSig);
FMsk=FMsk1D.*(FMsk1D.');
% CurReps=10;
CurReps=37;
% for CurReps=[1 2 3 37 38 39]
    % THLR_lambda=0.1;
    THLRgB0_lambda=10;
    % RhoStr='';
    RhoStr=[' -u ' num2str(1e-3) ' '];

    THLRPerShotgITS_S=bart(['picsS -m ' RhoStr ' -R 3:32:3:' num2str(THLRgB0_lambda) ':1 ' ScriptFN_TS_2L_Smoothx],Sz16_2L,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
        SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,THLRMultiShot,...
        sum(KernsPMMed(:,:,CurReps,:,:,:,:),3),TSBP_L1,FMsk);
%     THLRPerShotgITS_S=bart(['picsS -m ' RhoStr ' -R K:32:3:' num2str(THLRgB0_lambda) ':2:1:0:5 ' ScriptFN_TS_2L_Smooth],Sz16_2L,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,THLRMultiShot,...
%         sum(KernsPMMed(:,:,CurReps,:,:,:,:),3),TSBP_L1,FMsk);
%     THLRPerShotgITS=bart(['picsS -m ' RhoStr ' -R K:32:3:' num2str(THLRgB0_lambda) ':2:1:0:5 ' ScriptFN_TS_2L],Sz16_2L,DataCCP(:,TrajPartMed,CurReps,1:nccToUse),...
%         SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurReps),TSBPMed,THLRMultiShot,...
%         sum(KernsPMMed(:,:,CurReps,:,:,:,:),3),TSBP_L1);
    
%     THLRPerShotgITSSC{CurReps}=THLRPerShotgITS_S;
    THLRPerShotgITS_SM(:,:,:,CurReps)=squeeze(THLRPerShotgITS_S);
% end
%%
THLRPerShotgITS_S=permute(THLRPerShotgITS_SM(:,:,:,37),[1 2 6 5 4 3]);
THLRPerShotgITS_S1=ifft2cg(fft2cg(THLRPerShotgITS_S).*FMsk);
THLRPerShotgITS_SX=sum(THLRPerShotgITS_S1.*TSBP_L1,6);
THLRPerShotgITS_SY=THLRPerShotgITS_SX.*THLRMultiShot;
%%
% 
% for CurReps=1:6 % [1 2 3 37 38 39]
    [ ~, s_2L, V_2L] = batch_svd(H_L1*squeeze(THLRPerShotgITS_S1));
%     [ ~, s_2L, V_2L] = batch_svd(H_L1*squeeze(XX));
%     fgmontage((s_2L(:,:,2)./s_2L(:,:,1)).*DMsk,[0 0.2])
    R1_2L=V_2L(:,:,2,1)./V_2L(:,:,1,1); % R1 is simply the decay
    InnerTSDiff_L1_ms=numel(TrajPartMed)*AcqDwellTime_us/1e3/(nTS_L1-1);
    UpdatedT2SMap_2L_ms=-InnerTSDiff_L1_ms./log(abs(R1_2L));
    dUpdatedB0Map=-(angle(R1_2L)/(2*pi))/(InnerTSDiff_L1_ms/1e3); % in Hz
%     dUpdatedB0MapM(:,:,CurReps)=dUpdatedB0Map;
% end
%%
%% Hyperparameters for many shots half separately
% CurRepsx=1:5;
% nCurShots=numel(CurRepsx);
% Sz16AllTSCsShots=FillOnesTo16([Sz nCurShots 1 1 1 nTSMed]);
% 
% THLRsomeShots_lambdax=10;
% RhoStr=[' -u ' num2str(1e-3) ' '];
% LLRsomeShots_lambda=10;
% 
% THLR_LLR_SomeShot=bart(['picsS -m ' RhoStr ' -b 8 -R L:67:3:' num2str(LLRsomeShots_lambda) ' ' ScriptFN_AllTS],...
%     Sz16AllTSCsShots,DataCCP(:,TrajPartMed,CurRepsx,1:nccToUse),...
%     SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRepsx),TSBPMed,1,...
%     KernsPMMed(:,:,CurRepsx,:,:,:,:));
% % MAPS (dim 5) is set to 1 on LLRblk
% 
% THLR_SomeShot=bart(['picsS -m ' RhoStr ' -R K:64:7:' num2str(THLRsomeShots_lambdax) ':2:1:0:6 ' ' ScriptFN_AllTS],...
%     Sz16AllTSCsShots,DataCCP(:,TrajPartMed,CurRepsx,1:nccToUse),...
%     SensCC(:,:,:,1:nccToUse),STraj3MMed(:,:,CurRepsx),TSBPMed,1,...
%     KernsPMMed(:,:,CurRepsx,:,:,:,:));

%%
XX=Rec_CompgB0_MX;
fgmontage(XX(:,:,1),[0 max(abs(XX(:)))]);
for i=1:size(XX,3)
    gmontage(XX(:,:,i),[0 max(abs(XX(:)))]);
%     pause(.5);
end
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














%%
RLocs=load([RefFldMapP 'Locs.mat']);
RefLocs=RLocs.RotatedLocs;
CurzLocs=RotatedLocs(3,:);
RefzLocs=RefLocs(3,:);
CurSlizLoc=CurzLocs(Ord(SlicesToRead));
[MinRefD, CorrespondingRefSliIdx]=min(abs(RefzLocs-CurSlizLoc));
%%
IandsTwix=load([RefFldMapP 'IandsTwix.mat']);
%%
% RefFOV=240;
% % EffFOV=res_mm*NTrg;
% % cEffFOV=ceil(EffFOV);
% % 
% % cEffFOV=220
% 
SensB=load([RefFldMapP 'Sens.mat']);
SensB=SensB.SensB;
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