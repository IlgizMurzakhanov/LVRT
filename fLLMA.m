function [CaseTur,PF_Tur,TotQG_ExclSlack_Tur,TotdP_Tur,V_Tur_List] = fLLMA(CaseA0,NBus,NGen,V_Tur_List,pfPrint,mpopt)
% Local Load Measuring Algorithm. Its old name was Heuristic Algorithm.
% Originated from Turitsyn's approach

% Qg is set to the smallest value between QL,Pg*tan(fi),sqrt(S^2-P^2)
CaseTur = CaseA0;

for i = 2:NGen % except the slack bus, slack bus assumed to be #1
    BusID = CaseTur.gen(i,1); % on which bus is generator
    for j = 1:NBus
        if CaseTur.bus(j,1) == BusID
            QL = CaseTur.bus(j,4);
            Qmax = CaseTur.gen(i,4); 
            % Choose the minimum over load and Qg_max
            CaseTur.gen(i,3) = min([QL,Qmax]); %Qg
        end 
    end
end

CaseTur.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses

if pfPrint == 0
    PF_Tur = runpf(CaseTur,mpopt);
elseif pfPrint == 1
    PF_Tur = runpf(CaseTur);
end

TotQG_ExclSlack_Tur = sum(PF_Tur.gen(2:end,3)); % except the slack node
TotdP_Tur = real(sum(get_losses(PF_Tur)));
V_Tur_List = [V_Tur_List; PF_Tur.bus(:,8)];

end

