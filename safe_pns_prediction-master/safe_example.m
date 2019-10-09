clear
clf

% Load an exampe gradient waveform
[gwf, dt] = safe_example_gwf;

% Load reponse parameters for example hardware
hw = safe_example_hw();

% Predict PNS levels
pns = safe_gwf_to_pns(gwf, dt, hw);

% Plot some results
safe_plot(pns, dt);

prisma=struct('name','prisma');
prisma.look_ahead=1.05; % ???
prisma.x.tau1=0.18965;
prisma.x.tau2=0.0278;
prisma.x.tau3=2;
prisma.x.a1=0.4374;
prisma.x.a2=0.001;
prisma.x.a3=0.5616;
prisma.x.stim_limit=31.1914;
prisma.x.stim_thresh=24.9531;

prisma.y.tau1=2;
prisma.y.tau2=2;
prisma.y.tau3=0.2183;
prisma.y.a1=0.5682;
prisma.y.a2=0.181;
prisma.y.a3=0.2508;
prisma.y.stim_limit=16.9797;
prisma.y.stim_thresh=13.5838;

prisma.z.tau1=2;
prisma.z.tau2=0.1742;
prisma.z.tau3=2;
prisma.z.a1=0.4157;
prisma.z.a2=0.4863;
prisma.z.a3=0.098;
prisma.z.stim_limit=26.8349;
prisma.z.stim_thresh=21.4679;