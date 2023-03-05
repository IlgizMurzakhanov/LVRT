function [CaseQMax,PF_QMax,TotQG_ExclSlack_QMax,TotdP_QMax,V_QMax_List] = fQMaxPF(CaseA0,NBus,V_QMax_List,pfPrint,mpopt)

% Qg is set to the smallest value betweenPg*tan(fi),sqrt(S^2-P^2)
CaseQMax = CaseA0;

CaseQMax.gen(:,3) = CaseQMax.gen(:,4); %Qg = Qg_max
CaseQMax.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses

if pfPrint == 0
    PF_QMax = runpf(CaseQMax,mpopt);
elseif pfPrint == 1
    PF_QMax = runpf(CaseQMax);
end

TotQG_ExclSlack_QMax = sum(PF_QMax.gen(2:end,3)); % except the slack node
TotdP_QMax = real(sum(get_losses(PF_QMax)));
V_QMax_List = [V_QMax_List; PF_QMax.bus(:,8)];

end

