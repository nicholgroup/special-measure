function [dBz,eps_array,fitparam] = Jay2Eps(dBz_file,JnB_file,J_seq,t,fitfun,JayNums)
% Jay2Eps: converts a J (exchange) vs time pulse sequence to an epsilon (detuning) vs time sequence
%
% J_seq:distinct values of J ordered sequentially
% dBz_file: the scan file (2D ramsey scan) of dBz_oscillation
% JnB_file: the scan file (2D ramsey scan) of total oscillation 
% fitfun: is the fitting function preferred with the following options:
%       exp = exponential decay fit (p0 + p1*exp(-x/p(3)
%       quadr = Quadratic fit (...)
%       log = logarithmic fit (...)
% t: the time steps in the initial J pulse sequence
% JayNums: is the number of J_seq
    delta_B = 3.9; %MHz
    if ~exist('dBz_file','var') || isempty(dBz_file)
        dbz = anaFreq(dBz_file);
    end
    if ~exist('JnB_file','var') || isempty(JnB_file)
        freq_tot = anaFreq(JnB_file);
    end
    dBz = mean(dbz.oscfreqs(round(length(dbz.oscfreqs)/2):end));%MHz
%     finder = find(freq_tot.oscfreqs == max(freq_tot.oscfreqs));
%     finder = round(length(dbz.oscfreqs)/2)-1;% for ramsey_eps_3697 & 3698
    finder = 
    J = sqrt((freq_tot.oscfreqs(1:finder)).^2-dBz^2);
    j_array = cell(1,length(J_seq));
    for i = 1:length(J_seq)
        j_array{i} = (dBz/delta_B)*J_seq(i)*ones(1,round((delta_B/dBz)*t(i)));%scaling factor as suggested by the Virginia Tech's team
    end
    j_array = cell2mat(j_array);
    J_array = repmat(j_array,1,JayNums);
    figure(4); n = length(J_array);
    time=linspace(1,n,n);plot(time,J_array);xlabel('time (ns)');ylabel('J(GHz)');
    %exponential fit
    if strfind(fitfun,'exp')
        fn = @(p,x) p(1) + p(2)*exp(-x./p(3));
%         xv = freq_tot.eps(finder:end-8);yv = real(J);% Edit this to remove noise data points from anaFreq() results
        xv = freq_tot.eps(1:finder);yv = real(J);
        beta0 = [10,100,10];
        [beta,~,~,~,~,~,se] = fitwrap('plinit plfit',xv,yv,beta0,fn,[1 1 1]);
        p = beta;
        eps_array = -p(3)*log((J_array-p(1))/(p(2))); 
    end
    if strfind(fitfun,'expvar')
        fn = @(p,x)  p(1)*exp(-(x./p(2)).^(p(3)));
%         xv = freq_tot.eps(finder:end-8);yv = real(J);% Edit this to remove noise data points from anaFreq() results
        xv = freq_tot.eps(1:finder);yv = real(J);
        beta0 = [100,10,1];
        [beta,~,~,~,~,~,se] = fitwrap('plinit plfit',xv,yv,beta0,fn,[1 1 1]);
        p = beta;
        eps_array = p(2)*(-log(J_array./p(1))).^(1/p(3)); 
    end
    %quadratic fit
    if strfind(fitfun,'qua')
        fn = @(p,x)(p(1).^2-x.^2)./(2*x.*p(2)) + p(3);
        xv = J;yv = freq_tot.eps(finder:end);% Edit this to remove noise data points from anaFreq() results
        beta0 = [10,1,20];
        [beta,~,~,~,~,~,se] = fitwrap('plinit plfit',xv,yv,beta0,fn,[1 1 1]);
        p = beta;
        eps_array = (p(1).^2-J_array.^2)./(2*J_array.*p(2))+p(3);
    end
    %Logarithm fit
    if strfind(fitfun,'log')
        fn =@(p,x) ((log(x)-p(1))./(p(2))).^(1/p(3)) + p(4);
        xv = freq_tot.eps(finder:end);yv = J;% Edit this to remove noise data points from anaFreq() results
        beta0 = [4 10 10 1];
        [beta,~,~,~,~,~,se] = fitwrap('plinit plfit',xv,yv,beta0,fn,[1 1 1]);
        p = beta;
        eps_array = p(1) + p(2)*exp((J_array-p(4)).^p(3));
    end
    fitparam = [beta;se];
%     tmp1 = find(eps_array == max(eps_array));
%     tmp2 = find(eps_array == min(eps_array));
%     T = [tmp1(1)-1 tmp2(tmp1(1))-tmp1(1)-1]; % time
    figure(5);
    plot(time,eps_array);xlabel('time');ylabel('\epsilon(t)');
end