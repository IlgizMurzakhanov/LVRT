function [CaseOnlySlackGen,PF_OnlySlackGen,TotdP_OnlySlackGen,TotQG_ExclSlack_OnlySlackGen,...
    V_CaseOnlySlackGen_List] = fOnlySlackGenPF(CaseA0,V_CaseOnlySlackGen_List,pfPrint,mpopt)
% Power flow in a case without distributed generation (even it was
% presented originally, for this simulation, only slack gen is left)

% Copy the case, so that for each iteration we reset to CaseA
CaseOnlySlackGen = CaseA0;

% Deleting all generators and their costs except a slack bus (assume it goes first)
CaseOnlySlackGen.gen(2:end,:) = [];
CaseOnlySlackGen.gencost(2:end,:) = [];

if pfPrint == 0
    PF_OnlySlackGen = runpf(CaseOnlySlackGen,mpopt); 
elseif pfPrint == 1
    PF_OnlySlackGen = runpf(CaseOnlySlackGen); 
end

TotdP_OnlySlackGen = real(sum(get_losses(PF_OnlySlackGen))); 
TotQG_ExclSlack_OnlySlackGen = sum(PF_OnlySlackGen.gen(2:end,3)); % except the slack node
V_CaseOnlySlackGen_List = [V_CaseOnlySlackGen_List; PF_OnlySlackGen.bus(:,8)];

end


