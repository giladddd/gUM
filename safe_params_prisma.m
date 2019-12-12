function prisma=safe_params_prisma()
prisma=struct('name','prisma');
prisma.look_ahead=1.02; % ???
prisma.x.tau1=0.1884;
prisma.x.tau2=12;
prisma.x.tau3=0.8489;
prisma.x.a1=0.4835;
prisma.x.a2=0.21;
prisma.x.a3=0.3065;
prisma.x.stim_limit=42.7007;
prisma.x.stim_thresh=34.1606;

prisma.y.tau1=0.2324;
prisma.y.tau2=12;
prisma.y.tau3=0.9403;
prisma.y.a1=0.3584;
prisma.y.a2=0.2598;
prisma.y.a3=0.3818;
prisma.y.stim_limit=23.9732;
prisma.y.stim_thresh=19.1786;

prisma.z.tau1=0.1602;
prisma.z.tau2=12;
prisma.z.tau3=0.744;
prisma.z.a1=0.5299;
prisma.z.a2=0.2098;
prisma.z.a3=0.2603;
prisma.z.stim_limit=36.481;
prisma.z.stim_thresh=29.1848;
