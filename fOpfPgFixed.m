function [CaseA_OPF,OPF,TotdP_OPF_Feas_List,TotdP_OPF_Infeas_List,...
    TotdP_OPF_List,V_OPF_List,TotQG_ExclSlack_OPF,TotPG_ExclSlack_OPF] = fOpfPgFixed(CaseA0,...
    TotdP_OPF_Feas_List,TotdP_OPF_Infeas_List,TotdP_OPF_List,V_OPF_List,NBus,pfPrint,mpopt)

CaseA_OPF = CaseA0; % each time taking "preserved" CaseA0 

if pfPrint == 0
    OPF = runopf(CaseA_OPF,mpopt); 
elseif pfPrint == 1
    OPF = runopf(CaseA_OPF); 
end

if OPF.success == 1
    OPFsuccess = OPF;
    TotdP_OPF_Feas = sum(real(get_losses(OPFsuccess)));
    TotdP_OPF = TotdP_OPF_Feas;
    TotdP_OPF_Feas_List = [TotdP_OPF_Feas_List; TotdP_OPF_Feas];
    V_OPF_List = [V_OPF_List; OPFsuccess.bus(:,8)];
    TotQG_ExclSlack_OPF = sum(OPFsuccess.gen(2:end,3)); % except the slack node
    TotPG_ExclSlack_OPF = sum(OPFsuccess.gen(2:end,2)); % except the slack node

else
    % If OPF does not work, then the best is to run pf with Qg = 0
    CaseA_OPF.gen(:,3) = 0; %Qg = 0
    CaseA_OPF.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses
    
    
    if pfPrint == 0
        OPFnosuccess = runpf(CaseA_OPF,mpopt);
    elseif pfPrint == 1
        OPFnosuccess = runpf(CaseA_OPF);
    end
    
    TotdP_OPF_Infeas = sum(real(get_losses(OPFnosuccess)));
    TotdP_OPF = TotdP_OPF_Infeas;
    TotdP_OPF_Infeas_List = [TotdP_OPF_Infeas_List; TotdP_OPF_Infeas];
    V_OPF_List = [V_OPF_List; OPFnosuccess.bus(:,8)];
    TotQG_ExclSlack_OPF = sum(OPFnosuccess.gen(2:end,3)); % except the slack node
    TotPG_ExclSlack_OPF = sum(OPFnosuccess.gen(2:end,2)); % except the slack node
end    

TotdP_OPF_List = [TotdP_OPF_List; TotdP_OPF];

end

