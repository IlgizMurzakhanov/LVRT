function [CaseQContrRevFlow,PF_QContrRevFlow,V_NoCom_List,TotQG_ExclSlack_NoCom,TotdP_NoCom] = fStep3(CaseQContrPasFlow,...
        NS,send_QContrPasFlow_all_Tab,send_Tur_all_Tab,V_NoCom_List,NBus,pfPrint,mpopt)
%(Step 3) changing generation for the nodes which detected reverse flows to slack nodes
CaseQContrRevFlow = CaseQContrPasFlow; % start from passing flow case

for i = 1:NS
    send_ind = table2array(send_QContrPasFlow_all_Tab(i,1)); % i is line number, send_ind is index of line in gen structure
    if table2array(send_QContrPasFlow_all_Tab(i,11)) == 1 && table2array(send_QContrPasFlow_all_Tab(i,9)) > 0% if flag for reverse Q flow to slack node is 1 and there is at least
        % one outcoming neighbor (not a leaf node)
        if table2array(send_Tur_all_Tab(i,7))*table2array(send_QContrPasFlow_all_Tab(i,7)) > 0 % check if the outcoming flow
        % did NOT change its direction since increasing the generation by passing flow
            Qg_decrease = abs(table2array(send_QContrPasFlow_all_Tab(i,6))); % generation should be decreased by the value abs value of incoming (negative) flow
            CaseQContrRevFlow.gen(send_ind,3) = CaseQContrRevFlow.gen(send_ind,3) - Qg_decrease; % substituting abs decrease value
        elseif table2array(send_Tur_all_Tab(i,7))*table2array(send_QContrPasFlow_all_Tab(i,7)) < 0 % if outcoming flow direction changed 
            CaseQContrRevFlow.gen(send_ind,3) = table2array(send_QContrPasFlow_all_Tab(i,5)); % then set generation to the load
        end
%         CaseQContrRevFlow.gen(send_ind,4) = CaseQContrRevFlow.gen(send_ind,3); % enforcing limits
%         CaseQContrRevFlow.gen(send_ind,5) = CaseQContrRevFlow.gen(send_ind,3); % enforcing limits
    end
end

CaseQContrRevFlow.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses
% running power flow with updated generaiton vaiues

if pfPrint == 0
    PF_QContrRevFlow = runpf(CaseQContrRevFlow,mpopt);
elseif pfPrint == 1
    PF_QContrRevFlow = runpf(CaseQContrRevFlow);
end

TotQG_ExclSlack_NoCom = sum(PF_QContrRevFlow.gen(2:end,3));
TotdP_NoCom = sum(real(get_losses(PF_QContrRevFlow))); % no communication
V_NoCom_List = [V_NoCom_List; PF_QContrRevFlow.bus(:,8)];

end

