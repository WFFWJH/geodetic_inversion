% load('greens_cache.mat');
% addpath("../OtherFunc/");



lambdas = [0.1,0.01,1,10];

lambda = 0;
Greens = [G_raw;H*lambda/h1;Wb;Wl;Wr];


nflt = max(slip_model(:,1));
tSm = zeros(1,nflt+1);
fault_id = slip_model(:,1);
for i=1:nflt
    tSm(i+1) = length(find(fault_id == i));
end
add_col = 0; NT = 2; NS = nflt;  % the number of segments
Con = [0 0 0];
[lb,ub] = bounds_new(NS,NT,tSm,add_col,Con);
%     [lb,ub] = bounds_new_M5(NS,NT,tSm,add_col);
%     [lb,ub] = bounds_resolution(NS,NT,tSm,add_col);


% linear inversion
options = optimset('LargeScale','on','DiffMaxChange',1e-1,'DiffMinChange',1e-12, ...
    'TolCon',1e-12,'TolFun',1e-12,'TolPCG',1e-12,'TolX',1e-12,'MaxIter',1e9,'MaxPCGIter',1e9);
[u,resnorm,residual,exitflag] = lsqlin(Greens,double(bdata_sm),[],[],[],[],lb,ub,[],options);
% [u,resnorm,residual,exitflag] = lsqlin(GrF,double(Bdata),[],[],[],[],lb,ub,[],options);


% compute the reduction of total variance (before weighing) of the downsampled data
rms0 = sum(Bdata.^2);
rms1 = sum((GrF*u-Bdata).^2);
redu_perc = 100*(rms0-rms1)/rms0;
fprintf('rms misfit (dat., res.) = %e %e (%f%%) \n',rms0,rms1,redu_perc);
fprintf('RMS: %f\n',rms(GrF*u-Bdata));
fprintf('resnorm, resid. = %e %e \n',sqrt(resnorm),mean(residual));
fprintf('exitflag is %d\n',exitflag);   % 1 means the function converged to a solution x

rough_matrix = H*u;
RMS_misfit = sum((G_raw*u - bd_raw).^2);   % use chi-square statistic instead
model_roughness = sqrt(sum(rough_matrix.^2)/length(rough_matrix));
fprintf("RMS_misfit: %f , model_roughness: %f \n",RMS_misfit,model_roughness);
compute_moment(slip_model);
show_slip_model(slip_model,'ref_lon',95,'lonc', 95.33,'latc', 19.61,'axis_range',[50 150 -100 300 -50 0]);


function [lb,ub]=bounds_new(NS,NT,tSm,add_col,Con)

Npatch = sum(tSm);
lb=-7e2*ones(NT*Npatch,1);  %lower bound in cm
ub= 7e2*ones(NT*Npatch,1);  %upper bound
lb(Npatch+1:2*Npatch) = -10e2;   % dominated by strike slip
ub(Npatch+1:2*Npatch) = 10e2;

for i=1:NS
 k1=sum(tSm(1:i))+1;
 k2=sum(tSm(1:i+1));
 for k=k1:k2
     if Con(1) > 0, lb(k) = 0; end
     if Con(2) > 0, lb(k+Npatch) = 0; end
     if Con(1) < 0, ub(k) = 0; end
     if Con(2) < 0, ub(k+Npatch) = 0; end

 end  
end  
 
lb((NT*sum(tSm)+1):(NT*sum(tSm)+add_col),1)=-Inf;  
ub((NT*sum(tSm)+1):(NT*sum(tSm)+add_col),1)=Inf;   

end


function compute_moment(slip_model)
    % compute the scalar seismic moment
    strike_u = slip_model(:,12) ./ 100;     % in meters
    strike_d = slip_model(:,13) ./ 100;
    D = sqrt(strike_u.^2 + strike_d.^2);
    lpatch = slip_model(:,7);
    wpatch = slip_model(:,8);
    Apatch = lpatch .* wpatch;   
    mu = 33e9;
    M0 = sum(mu .* D .* Apatch);
    Mw = 2/3*(log10(M0) - 9.1);
    disp(['The moment magnitude is Mw = ',num2str(Mw)]);
    fprintf('\n');
end