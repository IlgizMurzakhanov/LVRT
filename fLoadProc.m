function [CaseA,INL,NNL,PL,QL] = fLoadProc(CaseA,LM,CosFiLoad)
% This code processes the load.
PL = CaseA.bus(:,3);
QL = CaseA.bus(:,4);
SL = sqrt(PL.^2 + QL.^2);
tg_fi = QL./PL;
cos_fi = PL./SL;
    
if LM == 1
    % Changing CosFiLoad on all buses to a value given by a user
    QL_new = sqrt( (PL/CosFiLoad).^2 - PL.^2 );
    SL_new = sqrt(PL.^2 + QL_new.^2);
    cos_fi_new = PL./SL_new;
    CaseA.bus(:,4) = QL_new; % putting new QL values corresponding to provided CosFiLoad 
end

IndNL = find(CaseA.bus(:,3)); % indixes of non-zero loads
BusID_List = CaseA.bus(:,1); % list of buses ID
INL = BusID_List(IndNL);
NNL = size(INL,1);

% Some proto-code
% Some of the buses have PL = QL = 0, which is fine
% PL_med = median(PL); % median value of PL
% PL_mean = mean(PL); 
% histogram(PL,50) % to see load distribution
% NNL = nnz(CaseA.bus(:,3)); % number of non-zero loads

end

