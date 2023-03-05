function [CaseQgZero,PF_base,TotdP_base,TotPG,TotPL,TotQL,TotQG_ExclSlack_base,V_base_List] = fQgZeroPF(CaseA0,NBus,V_base_List,pfPrint,mpopt)
%Power flow for a case with preserved distributed generation and Qg = 0
CaseQgZero = CaseA0;

CaseQgZero.gen(:,3) = 0; %Qg = 0

CaseQgZero.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses
CaseQgZero.bus(1,2) = 3; % setting (ensuring) that bus 1 is a slack bus
if pfPrint == 0
    PF_base = runpf(CaseQgZero,mpopt); 
elseif pfPrint == 1
    PF_base = runpf(CaseQgZero); 
end
TotdP_base = real(sum(get_losses(PF_base)));
TotPG = sum(PF_base.gen(2:end,2)); % total PV active geneation
TotPL = sum(PF_base.bus(:,3)); % total active load
TotQL = sum(PF_base.bus(:,4)); % total reactive load

TotQG_ExclSlack_base = sum(PF_base.gen(2:end,3)); % except the slack node
V_base_List = [V_base_List; PF_base.bus(:,8)];

end

