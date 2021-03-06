function [Vm,Vv] = CompMemPotStat_aEIF_Net(r,rx,ModPar,ConPar)
% This functions computes the mean and the variance of the membrane
% potential for all populations modeled by aEIF neurons 
%
% r = vector of mean firing rates (1/r = mean ISI)
% rx = vector of external rates
% ModPar = matrix of neuron model parameters (rows = neuron populations,
%          columns = parameters)
% ConPar = structure containing connection probabilities (ConPar.p), number
%          of neurons per population (ConPar.N) and 
%          connection strengths (ConPar.J)
% Vm = vector of mean membrane potentials
% Vv = vector of variances of membrane potential

tm = ModPar(:,1)/1000.0;

eps = ConPar.R;
N = ConPar.NN;
J = ConPar.J; 
NTypes = length(N); % plus external excitatory pool
Vm = zeros(1,NTypes-1);
Vv = zeros(1,NTypes-1);

for i=1:NTypes-1
    
    % influence of external pool
    Iex = eps(i,NTypes)*N(NTypes)*J(i,NTypes)*rx(i)*tm(i);
    mu = Iex;
    sig2 = J(i,NTypes)*Iex;
    
    for j=1:NTypes-1
        mu = mu + tm(i)*eps(i,j)*N(j)*r(j)*J(i,j);
        sig2 = sig2 + tm(i)*eps(i,j)*N(j)*r(j)*J(i,j).^2;
    end 
    
    % compute membrane potential statistics  
    InpPar=[mu,sqrt(sig2)];   
    [Vm(i),Vv(i)] = CompMemPotStat_aEIF(r(i),ModPar(i,:),InpPar);

end

end

