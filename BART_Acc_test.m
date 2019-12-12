load brain_8ch
I=ifft2c(DATA);
Sens=RunESPIRiTForSensMaps(I);
Im=CalcSENSE1f(I,Sens);
ImWithSens=Im.*Sens;
FData=fft2cg(ImWithSens);
FDataP=permute(FData,[1 2 4 3]);
SensP=permute(Sens,[1 2 4 3]);
%%
Accs=1.4:0.05:3;
for i=1:numel(Accs)
    Acc=Accs(i);
    Msk=bart(['poisson -Y 200 -Z 200 -y ' num2str(Acc) ' -z ' num2str(Acc) ' -v -e -C 8']);
    Msk=squeeze(Msk);
    MskM(:,:,i)=Msk;
end
%%
Lam=1e-7;
Cmd=['pics -m -R W:7:0:' num2str(Lam) ' -p'];

FDataP=permute(Msk.*FData,[1 2 4 3]);
Rec=bart(Cmd,Msk,FDataP,SensP);
RecN=Rec*grmss(Im)/grmss(Rec);
%%
Lams=10.^([-8,-7,-6,-5,-4,-3.5,-3,-2.5,-2,-1.5,-1]);
%%
RecNM=zeros(200,200,numel(Accs),numel(Lams));
%%
for i=1:numel(Accs)
    Msk=MskM(:,:,i);
    for j=1:numel(Lams)
        disp([num2str(i) ' ' num2str(j) ' ' datestr(now)]);
        
        Lam=Lams(j);
        Cmd=['pics -m -R W:7:0:' num2str(Lam) ' -p'];
        
        FDataP=permute(Msk.*FData,[1 2 4 3]);
        Rec=bart(Cmd,Msk,FDataP,SensP);
        RecN=Rec*grmss(Im)/grmss(Rec);
        RecNM(:,:,i,j)=RecN;
    end
end
%%
for i=1:numel(Accs)
    for j=1:numel(Lams)
        disp([num2str(i) ' ' num2str(j) ' ' datestr(now)]);
        SM(i,j)=ssim(abs(Im),abs(RecNM(:,:,i,j)));
        RM(i,j)=grmss(Im-RecNM(:,:,i,j));
    end
end
[SMV, MI]=max(SM,[],2);
%%
save('Bart_Acc_test.mat','SMV','MI','RecNM','MskM');
% save('Bart_Acc_testAll.mat');
%%
figure;plot(Accs,SMV)
xlabel('Acceleration on each axis');
ylabel('SSIM');
title('BART performance, 8ch');
%%
for i=1:numel(Accs)
    RecNMG(:,:,i)=RecNM(:,:,i,MI(i));
end
%% BART:
WhichAcc=1;
fgmontage(RecNM(:,:,WhichAcc,MI(WhichAcc)))
%% To MLN
CurMask=MskM(:,:,WhichAcc);
[F1 F2]=find(CurMask);
nTraj=numel(F1);

clear MData
Traj=[F1.';F2.']-100;
for i=1:nTraj
    MData(i,:)=FData(F1(i),F2(i),:);
end

P2DFPBase='/media/a/DATA/P2DF/';

CurAccStr=num2str(Accs(WhichAcc),'%.2f');
P2DFP=[P2DFPBase CurAccStr filesep];
mkdir(P2DFP);

Trajm2=Traj;
% Kd=gsize(DATA,1:2);
% SN=ones(Kd);
% P=sparse(1:nTraj,(F1-1)*200+F2,ones(1,nTraj),nTraj,prod(Kd));

% save([P2DFP 'TrajForNUFT.mat'],'Trajm2','Kd','SN','P');

Sz200=[200 200];
% trajectory, imageDim, sensmaps, os, Neighborhood)
% [FesNUFTOp,st] = nuFTOperator(BART2Fes_NUFT_Idxs(Trajm2,Sz200),Sz200);
[FesNUFTOp,st] = nuFTOperator(BART2Fes_NUFT_Idxs(Trajm2,Sz200),Sz200,{},1,[1 1]);
Kd=st.nufftStruct.Kd;
SN=st.nufftStruct.sn*0+1;
P=st.nufftStruct.p/sqrt(prod(Sz200));
% save('ForTFNUFT.mat','SN','Kd','P','A','NUbyFS3');
save([P2DFP 'TrajForNUFT.mat'],'Trajm2','SN','Kd','P');

TSBF=ones(2,nTraj);
TSC=ones([Kd 2]);
save([P2DFP 'B0TS.mat'],'TSBF','TSC');

SensCC=Sens;
SensMsk=single(grmss(Sens,3)>0.1);
save([P2DFP 'SensCC1.mat'],'SensCC','SensMsk');

%
tmp=MData; % squeeze(DataPCC);
% RealDataFac=grmss(AllData(5656:34:6767,:,:))/grmss(tmp)
% RealDataFac=100;
RealDataFac=2;
CurIDataV=Row(tmp)*RealDataFac;
CurIDataVR=[real(CurIDataV) imag(CurIDataV)];

Data=repmat(single(CurIDataVR),[16 1]);
RealDataFN=[P2DFP 'RealDataForNN.mat'];
save(RealDataFN,'Data');
disp('Saved Data for MLN');
%%
St=getParamsStructFromFN('/media/a/DATA/P2DF/2.65/RegridTry3C2_7TS_P2DF_2.65__2018-07-16_19-19-28_train/');
St.nTraj=nTraj;
St.DataH=nTraj*8*2;
St.SessionNameBase=['RegridTry3C2_7TS_P2DF_' CurAccStr];
St.BaseTSDataP=P2DFP;
St.BaseNUFTDataP=P2DFP;
St.RealDataFN=[P2DFP 'RealDataForNN.mat'];

Txt=gStruct2txt(St,'~/HomeA/TF/Params.txt');
disp('Prepared Params');
%%
BaseTFRes='/media/a/f38a5baa-d293-4a00-9f21-ea97f318f647/home/a/TF/srez/';
Prefix=['RegridTry3C2_7TS_P2DF_' CurAccStr];
% Prefix='RegridTry1C2_TS2';
DB=dir([BaseTFRes Prefix '*']);
LastDir=DB(end).name;

VP=[BaseTFRes LastDir filesep];

[ScrNC,BatchNC,MinNC,LastFN]=GraphOptFromFolderf(VP);

X=imread([VP LastFN]);

NNRes=double((X(1:200,200*5+(1:200),1)))/255;
NNResP=-(double((X(1:200,200*7+(1:200),1)))/255);
NNResP=exp(1i*2*pi*(NNResP-0.5));
NNRes=NNRes.*NNResP;

NNResN=NNRes*grmss(Im)/grmss(NNRes);
SM_NNRes=ssim(abs(Im),abs(NNResN));


fgmontage(cat(3,Im,RecNM(:,:,WhichAcc,MI(WhichAcc)),NNResN),'Size',[1 3])
title([PadStringWithBlanks('Orig',60) PadStringWithBlanks(['BART: ' num2str(SMV(WhichAcc),'%.2f')],60) num2str(SM_NNRes,'%.2f')])

xlabel([VP LastFN],'Interpreter','None')
%%
figure;
subplot(2,2,[1 2]);
gmontage(cat(3,Im,RecNM(:,:,WhichAcc,MI(WhichAcc)),NNResN),'Size',[1 3])
title([PadStringWithBlanks('Orig',67) PadStringWithBlanks(['BART: ' num2str(SMV(WhichAcc),'%.2f')],67) 'MLN: ' num2str(SM_NNRes,'%.2f') ' (SSIM)'])
subplot(2,2,3);
gmontage(CurMask);axis equal
title(['Acc=' num2str(numel(Im)/nTraj,'%.2f')]);
Acc=Accs(WhichAcc);
xlabel(['poisson -Y 200 -Z 200 -y ' num2str(Acc) ' -z ' num2str(Acc) ' -v -e -C 8']);
subplot(2,2,4);
% gmontage(Sens,'Size',[2 4]);axis equal
gmontage(cat(3,abs(Sens),(angle(Sens)+pi)/(2*pi)),'Size',[4 4]);axis equal
title('Sensitivity maps used');
%%
% figure;
% subplot(2,3,[1 2 3]);
% gmontage(cat(3,Im,RecNM(:,:,WhichAcc,MI(WhichAcc)),NNResN),'Size',[1 3])
% title([PadStringWithBlanks('Orig',67) PadStringWithBlanks(['BART: ' num2str(SMV(WhichAcc),'%.2f')],67) 'MLN: ' num2str(SM_NNRes,'%.2f') ' (SSIM)'])
% subplot(2,3,4);
% gmontage(CurMask);axis equal
% title(['Acc=' num2str(numel(Im)/nTraj,'%.2f')]);
% Acc=Accs(WhichAcc);
% xlabel(['poisson -Y 200 -Z 200 -y ' num2str(Acc) ' -z ' num2str(Acc) ' -v -e -C 8']);
% subplot(2,3,5);
% gmontage(cat(3,abs(Sens),(angle(Sens)+pi)/(2*pi)),'Size',[4 4]);axis equal
% % gmontage(Sens,'Size',[2 4]);axis equal
% title('Sensitivity maps used');
% subplot(2,3,6);
% gmontage(angle(cat(3,Im,RecNM(:,:,WhichAcc,MI(WhichAcc)),NNResN)),'Size',[1 3])
% title([PadStringWithBlanks('Orig',17) PadStringWithBlanks('BART',17) 'MLN'])
%% Other images:
%
Ne=100;
Val=rand(Ne,1)*10-5;
% WH=randn(Ne,2)*2-1;
WH=randn(Ne,2,1)/4;
XY=rand(Ne,2,1)*2-1;
Phi=rand(Ne,1)*360;
i=1;
CurE=[Val(:,i) WH(:,:,i) XY(:,:,i) Phi(:,i)];
IP=single(min(1,abs(phantom(CurE,200))/15));

M1=rgb2gray(imread('Optima_MR450w_Foot_ex220_clinical.jpg'));
M1x=imresize(M1(340+(1:500),657+(1:500)),[200 200]);
%%
M2=rgb2gray(imread('Abdominal_Untitled-12.jpg'));
M2x=imresize(M2(100+(1:300),700+(1:300)),[200 200]);
%%
M3=rgb2gray(imread('5.6_Abdominal-MRI.jpg'));
M3x=imresize(M3(200+(1:700),560+(1:700)),[200 200]);
%%
M4=rgb2gray(imread('pexels-photo-106399.jpeg'));
M4x=imresize(M4(40+(1:700),160+(1:700)),[200 200]);
%%
IR1=imresize(gflip(squeeze(C(:,130,:,1,4)),[]),[200 200]);
IR2=imresize(gflip(squeeze(C(:,130,:,2,4)),[]),[200 200]);
%%
TIs={M1x,M2x,M3x,M4x,IP,IR1,IR2};
nTIs=numel(TIs);
MskS=grmss(Sens,3)>0.1;
%%
RecNMX=zeros(200,200,numel(Accs),numel(Lams),numel(TIs));
%%
for t=1:nTIs
    ImN=double(TIs{t}).*MskS;
    ImN=ImN*0.3/grmss(ImN);
    ImWithSens=ImN.*Sens;
    FData=fft2cg(ImWithSens);
    
    for i=1:numel(Accs)
        Msk=MskM(:,:,i);
        for j=1:numel(Lams)
            disp([num2str(t) ' ' num2str(i) ' ' num2str(j) ' ' datestr(now)]);
            
            Lam=Lams(j);
            Cmd=['pics -m -R W:7:0:' num2str(Lam) ' -p'];
            
            FDataP=permute(Msk.*FData,[1 2 4 3]);
            Rec=bart(Cmd,Msk,FDataP,SensP);
            RecN=Rec*grmss(ImN)/grmss(Rec);
            RecNMX(:,:,i,j,t)=RecN;
        end
    end
end
%%
for t=1:nTIs
    ImN=double(TIs{t}).*MskS;
    ImN=ImN*0.3/grmss(ImN);
    for i=1:numel(Accs)
        disp([num2str(t) ' ' num2str(i) ' ' datestr(now)]);
        for j=1:numel(Lams)
            SMX(i,j,t)=ssim(abs(ImN),abs(RecNMX(:,:,i,j,t)));
            RMX(i,j,t)=grmss(ImN-RecNMX(:,:,i,j,t));
        end
    end
    [SMVX, MIX]=max(SMX,[],2);
end
disp('ok');
%%
for t=1:nTIs
    ImN=double(TIs{t}).*MskS;
    for i=1:numel(Accs)
        RecNMXB(:,:,i,t)=RecNMX(:,:,i,MIX(i,t),t);
    end
end
disp('ok');
%%
save('Bart_Acc_testX.mat','RecNMX','SMX','RMX','SMVX','MIX','RecNMXB','TIs');
disp('Saved Bart_Acc_testX.mat');
%%
Ttls={'Foot','Abdominal','Abdominal Ax','House','Phantom','MP2RAGE Inv1','MP2RAGE Inv2'};
Clrs={'r','r','r','m','m','g','g'};
Mrkr={'.','o','*','.','o','.','o'};
figure;
for t=1:numel(TIs)
    plot(squeeze(SMVX(:,:,t)),[Clrs{t} Mrkr{t} '-']);
    hold on;
end
legend(Ttls)





%%
WhichAcc=33;
%% To MLN
CurMask=MskM(:,:,WhichAcc);
[F1 F2]=find(CurMask);
nTraj=numel(F1);

clear MDataT
Traj=[F1.';F2.']-100;
for t=1:nTIs
    ImN=double(TIs{t}).*MskS;
    ImN=ImN*0.3/grmss(ImN);
    ImWithSens=ImN.*Sens;
    FData=fft2cg(ImWithSens);
    for i=1:nTraj
        MDataT(i,:,t)=FData(F1(i),F2(i),:);
    end
end
CurAccStr=num2str(Accs(WhichAcc),'%.2f');
P2DFP=[P2DFPBase CurAccStr filesep];


%
clear CurIDataVR
for t=1:nTIs
    tmp=MDataT(:,:,t); % squeeze(DataPCC);
    RealDataFac=2;
    CurIDataV=Row(tmp)*RealDataFac;
    CurIDataVR(t,:)=[real(CurIDataV) imag(CurIDataV)];
end
% Data=repmat(single(CurIDataVR),[16 1]);
Data=CurIDataVR;
Data(16,1)=0;
RealDataFN=[P2DFP 'RealDataForNN01.mat'];
save(RealDataFN,'Data');
disp('Saved Data for MLN');
%%
St=getParamsStructFromFN('/media/a/DATA/P2DF/2.65/RegridTry3C2_7TS_P2DF_2.65__2018-07-16_19-19-28_train/');
St.nTraj=nTraj;
St.DataH=nTraj*8*2;
St.SessionNameBase=['RegridTry3C2_7TS_P2DF_' CurAccStr];
St.BaseTSDataP=P2DFP;
St.BaseNUFTDataP=P2DFP;
St.RealDataFN=[P2DFP 'RealDataForNN.mat'];
St.LoadAndRunOnData=1;
D=dir([P2DFP 'RegridTry3C2_7TS_P2DF_' CurAccStr '*checkpoint*']);
St.LoadAndRunOnData_checkpointP=[P2DFP D.name];
St.LoadAndRunOnData_Prefix=[P2DFP 'RealDataForNN'];
St.LoadAndRunOnData_OutP=P2DFP;
Txt=gStruct2txt(St,'~/HomeA/TF/Params.txt');
disp('Prepared Params');
%%
system('sudo -H -u a /media/a/f38a5baa-d293-4a00-9f21-ea97f318f647/home/a/RunTFForMatlabx.sh');
%%
clear ACX
WhichAccs=[1 12 19 26 33];
for i=1:numel(WhichAccs)
    WhichAcc=WhichAccs(i);
    CurAccStr=num2str(Accs(WhichAcc),'%.2f');
    P2DFP=[P2DFPBase CurAccStr filesep];
    
    A=load([P2DFP 'OnRealData01.mat']);
    AC=permute(A.x(:,:,:,1)+1i*A.x(:,:,:,2),[2 3 1]);
    ACX(:,:,:,i)=AC;
end
ACX=ACX(:,:,1:nTIs,:);
% fgmontage(ACX(:,:,1:nTIs,:))
%%
WhichAccs=[1 12 19 26 33];
for i=1:numel(WhichAccs)
    WhichAcc=WhichAccs(i);
    CurAccStr=num2str(Accs(WhichAcc),'%.2f');
    P2DFP=[P2DFPBase CurAccStr filesep];
    D=dir(P2DFP);
    D=D([D.isdir]);
    VP=[P2DFP D(4).name filesep];
    [ScrNC,BatchNC,MinNC,LastFN]=GraphOptFromFolderf(VP);
    X=imread([VP LastFN]);
    
    NNRes=double((X(1:200,200*5+(1:200),1)))/255;
    
    NNResN=NNRes*grmss(Im)/grmss(NNRes);
    NNResNM(:,:,i)=NNResN;
    SMV_NNRes(i)=ssim(abs(Im),abs(NNResN));
end
%%
for i=1:numel(WhichAccs)
    for t=1:nTIs
        ImN=double(TIs{t}).*MskS;
        ImN=ImN*0.3/grmss(ImN);
        
        Rec=double(squeeze(ACX(:,:,t,i)));
        RecN=Rec*grmss(ImN)/grmss(Rec);
            
        SMX_MLN(i,t)=ssim(abs(ImN),abs(RecN));
    end
end
%%
AccAct=40000./squeeze(gsum(MskM,1:2)).';
figure;
plot(WhichAccs,SMX_MLN)
%%
SMX_MLNF=[SMV_NNRes.' SMX_MLN];
SMVXF=[SMV(WhichAccs) squeeze(SMVX(WhichAccs,:))];
TblBoth=cat(3,SMVXF,SMX_MLNF);
TblBoth=CombineDims(TblBoth,[2 3]);
TblTtls=CombineDims([strcat('BART_',Ttls).' strcat('MLN_',Ttls).'],[1 2]).';
CTxt=[TblTtls; gmat2cell(TblBoth)].';
CTxt=[[{' '} gmat2cell(floor(AccAct(WhichAccs)*100)/100)]; CTxt];
fileID = fopen('BART_ACC_Test.csv','w');
% formatSpec = '%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n';
formatSpec = '%s,%.2f,%.2f,%.2f,%.2f,%.2f\n';
fprintf(fileID,'%s,%s,%s,%s,%s,%s\n',CTxt{1,:});
[nrows,ncols] = size(CTxt);
for row = 2:nrows
    fprintf(fileID,formatSpec,CTxt{row,:});
end
fclose(fileID);
%%
Ttls={'Test','Foot','Abdominal','Abdominal Ax','House','Phantom','MP2RAGE Inv1','MP2RAGE Inv2'};
Clrs={'k','r','r','r','m','m','g','g'};
Mrkr={'.','.','o','*','.','o','.','o'};
figure;
clear h
for t=1:numel(TIs)+1
%     h(t)=plot(AccAct,squeeze(SMVX(:,:,t)),[Clrs{t} Mrkr{t} '-']);
    h(t)=plot(AccAct(WhichAccs),squeeze(SMVXF(:,t)),[Clrs{t} Mrkr{t} '-']);
    hold on;
end

for t=1:numel(TIs)+1
    plot(AccAct(WhichAccs),squeeze(SMX_MLNF(:,t)),[Clrs{t} Mrkr{t} '--'],'LineWidth',2);
    hold on;
end
legend(h,Ttls)

setXaxis([AccAct(1) AccAct(33)])
xlabel('Acceleration');
ylabel('SSIM');
title('BART and MLN recon performance');
%%
RecNMXBP=permute(RecNMXB(:,:,WhichAccs,:),[1 2 4 3]);
RecNMXBP=cat(3,permute(RecNMG(:,:,WhichAccs),[1 2 4 3]),RecNMXBP);
ACXF=cat(3,permute(NNResNM,[1 2 4 3]),ACX);
Both=cat(5,RecNMXBP,ACXF);
Both4=CombineDims(Both,[3 5]);

Both4A=cat(3,permute(MskM(:,:,WhichAccs),[1 2 4 3]),Both4(:,:,1:8,:));
Both4B=cat(3,permute(MskM(:,:,WhichAccs),[1 2 4 3]),Both4(:,:,9:end,:));
%%
fgmontage(Both4A);
gprint(get(gcf,'Number'),'BART_Acc_test_BothA',[]) 
close(gcf);
save('BART_Acc_test_BothA.mat','Both4A');

fgmontage(Both4B);
gprint(get(gcf,'Number'),'BART_Acc_test_BothB',[]) 
close(gcf);
save('BART_Acc_test_BothB.mat','Both4B');
%%
fgmontage(permute(Both4A(:,:,2:3,:),[1 2 4 3]));
xlabel(num2str(AccAct(WhichAccs)))
ylabel('MLN                                               BART')
%% Noise test
WhichAcc=26;
NoiseLevel=grmss(FData)*5/100;
nNoise=16;
for i=1:nNoise
    Msk=MskM(:,:,WhichAcc);
    j=7;
    Lam=Lams(j);
    Cmd=['pics -m -R W:7:0:' num2str(Lam) ' -p'];
    
    FDataP=permute(Msk.*FData,[1 2 4 3]);
    FDataP=FDataP+(randn(size(FDataP))+1i*randn(size(FDataP)))*NoiseLevel;
    Rec=bart(Cmd,Msk,FDataP,SensP);
    RecNoise(:,:,i)=Rec;
end
figure;
subplot(1,2,1);
gmontage(mean(RecNoise,3));
subplot(1,2,2);
gmontage(std(RecNoise,[],3));colorbar
%% To MLN
CurMask=MskM(:,:,WhichAcc);
[F1 F2]=find(CurMask);
nTraj=numel(F1);

clear MData
Traj=[F1.';F2.']-100;
for i=1:nTraj
    MData(i,:)=FData(F1(i),F2(i),:);
end

MDataN=repmat(MData,[1 1 nNoise]);
MDataN=MDataN+(randn(size(MDataN))+1i*randn(size(MDataN)))*NoiseLevel;

CurAccStr=num2str(Accs(WhichAcc),'%.2f');
P2DFP=[P2DFPBase CurAccStr filesep];


%
clear CurIDataVR
for t=1:nNoise
    tmp=MDataN(:,:,t); % squeeze(DataPCC);
    RealDataFac=2;
    CurIDataV=Row(tmp)*RealDataFac;
    CurIDataVR(t,:)=[real(CurIDataV) imag(CurIDataV)];
end
% Data=repmat(single(CurIDataVR),[16 1]);
Data=CurIDataVR;
% Data(16,1)=0;
RealDataFN=[P2DFP 'RealDataForNN01.mat'];
save(RealDataFN,'Data');
disp('Saved Data for MLN');
%%
St=getParamsStructFromFN('/media/a/DATA/P2DF/2.65/RegridTry3C2_7TS_P2DF_2.65__2018-07-16_19-19-28_train/');
St.nTraj=nTraj;
St.DataH=nTraj*8*2;
St.SessionNameBase=['RegridTry3C2_7TS_P2DF_' CurAccStr];
St.BaseTSDataP=P2DFP;
St.BaseNUFTDataP=P2DFP;
St.RealDataFN=[P2DFP 'RealDataForNN.mat'];
St.LoadAndRunOnData=1;
D=dir([P2DFP 'RegridTry3C2_7TS_P2DF_' CurAccStr '*checkpoint*']);
St.LoadAndRunOnData_checkpointP=[P2DFP D.name];
St.LoadAndRunOnData_Prefix=[P2DFP 'RealDataForNN'];
St.LoadAndRunOnData_OutP=P2DFP;
Txt=gStruct2txt(St,'~/HomeA/TF/Params.txt');
disp('Prepared Params');
%%
system('sudo -H -u a /media/a/f38a5baa-d293-4a00-9f21-ea97f318f647/home/a/RunTFForMatlabx.sh');
%%
CurAccStr=num2str(Accs(WhichAcc),'%.2f');
P2DFP=[P2DFPBase CurAccStr filesep];

A=load([P2DFP 'OnRealData01.mat']);
AC=permute(A.x(:,:,:,1)+1i*A.x(:,:,:,2),[2 3 1]);
%%
RecNoiseMLN=AC(:,:,1:nNoise);
RecNoiseBART=RecNoise*grmss(RecNoiseMLN)/grmss(RecNoise);

figure;
subplot(2,2,1);
gmontage(mean(RecNoiseBART,3));colorbar; title('BART mean');
subplot(2,2,2);
gmontage(std(RecNoiseBART,[],3),[0 5e-2]);colorbar; title('BART std');
subplot(2,2,3);
gmontage(mean(RecNoiseMLN,3));colorbar; title('MLN mean');
subplot(2,2,4);
gmontage(std(RecNoiseMLN,[],3),[0 5e-2]*5);colorbar; title('MLN std');
%%
figure;
subplot(1,2,1);
gmontage(std(RecNoiseBART,[],3),[0 5e-2]);colorbar; title('BART std');
subplot(1,2,2);
gmontage(std(RecNoiseMLN,[],3),[0 5e-2]*5);colorbar; title('MLN std');

















