function    [CaseHybrid,OPFHybrid,GenID_dQ_DecrOrd,CenInv_Iter_array_tab,NNonZerdQ_List,...
            TotdP_Hybrid_OPFFeas_List,TotdP_Hybrid_OPFInfeas_List,TotdP_Hybrid_List,V_Hybrid_List,...
            TotQG_ExclSlack_Hybrid] = fHybrid(CaseQContrRevFlow,PF_QContrRevFlow,SelectNCenInv,NNonZerdQ_List,...
            TotdP_Hybrid_OPFFeas_List,TotdP_Hybrid_OPFInfeas_List,TotdP_Hybrid_List,V_Hybrid_List,...
            NCenInv_user,NGen,NPV,NTimePoints,iter,iPoint,CenInv_Iter_array,CenInv_Iter_array_tab,pfPrint,mpopt)
    % 1. Use the output of LFMA: rank in decreasing order, how much reactive reserve is left in inverters: Qg_max – Qg
    % Copying the case
    CaseHybrid = CaseQContrRevFlow;
    % Qg_max - Qg for all gens except slack
    dQ_ExclSlack = CaseHybrid.gen(2:end,4) - CaseHybrid.gen(2:end,3); 
    GenID_dQ_ExclSlack = horzcat(CaseHybrid.gen(2:end,1),dQ_ExclSlack); 
    % sorting rows in decreasing order of dQ
    GenID_dQ_DecrOrd = sortrows(GenID_dQ_ExclSlack,2,'descend'); 

    % How many non-zero dQ values are there 
    NNonZerdQ = nnz(GenID_dQ_DecrOrd(:,2));
    
    % Input we select number of centrally controlled inverters (1) or let it be defined by NNonZerdQ (0)
    if SelectNCenInv == 1 % if a user can select number of centrally controlled inverters
        NCenInv = NCenInv_user; % number of centralized inverters
    else
        NCenInv = NNonZerdQ; % otherwise choose all inverters with non-zero dQ
    end

    NNonZerdQ_List = [NNonZerdQ_List;NNonZerdQ];

    % Number of decentrally controlled inverters
    NDecInv = NPV - NCenInv;

    CenInv_Iter_array_line = CenInv_Iter_array(NTimePoints,NPV);
    CenInv_Iter_array_tab = [CenInv_Iter_array_tab; CenInv_Iter_array_line];
    
    % Centrally controlled inverters
    GenID_CenInv = GenID_dQ_DecrOrd(1:end-NDecInv,1);
    if isempty(GenID_CenInv)
        CenInv_Iter_array_tab(iter*iPoint,1:NCenInv) = 0; % this happens if NDecInv = 0
    else
        CenInv_Iter_array_tab(iter*iPoint,1:NCenInv) = GenID_CenInv'; % in decending order       
    end

    % Indices of last NDecInv inverters in GenID_dQ_DecrOrd =
    % decentrally controlled inverters
    GenID_DecInv = GenID_dQ_DecrOrd(end-NDecInv+1:end,1);

    % Fix the Qg limits for inverters which are NOT selected by a user
    if NDecInv > 0
        for i = 1:NDecInv % in all decenralized controlled inverters
            GenID = GenID_DecInv(i); % on which bus is generator
            for j = 1:NGen
                if CaseHybrid.gen(j,1) == GenID
                    % set both Qg_max and Qg_min to Qg, kept from LFMA
                    CaseHybrid.gen(j,4) = CaseHybrid.gen(j,3); 
                    CaseHybrid.gen(j,5) = CaseHybrid.gen(j,3); 
                end 
            end
        end
    end

    % Running OPF for centralized inverters
    
    
    if pfPrint == 0
        OPFHybrid = runopf(CaseHybrid,mpopt);
    elseif pfPrint == 1
        OPFHybrid = runopf(CaseHybrid);
    end

    % Flag showing if OPF for Hybrid setup is successful
    OPFHybrid_flag = OPFHybrid.success; 

        % 2. Run centralized OPF in N first inverters in the ranked list, where N is defined by a system operator, computation burden, etc.
    if  OPFHybrid_flag == 1
        OPFHybrid_converged = OPFHybrid;
        TotdP_Hybrid_OPFFeas = sum(real(get_losses(OPFHybrid_converged)));
        TotdP_Hybrid = TotdP_Hybrid_OPFFeas;
        TotdP_Hybrid_OPFFeas_List = [TotdP_Hybrid_OPFFeas_List; TotdP_Hybrid_OPFFeas];
        V_Hybrid_List = [V_Hybrid_List; OPFHybrid_converged.bus(:,8)];
        TotQG_ExclSlack_Hybrid = sum(OPFHybrid_converged.gen(2:end,3)); % except the slack node

    else
        % If OPF does not converge, then the best option to keep LFMA
        PFHybrid = PF_QContrRevFlow;
        TotdP_Hybrid_OPFInfeas = sum(real(get_losses(PFHybrid)));
        TotdP_Hybrid = TotdP_Hybrid_OPFInfeas;
        TotdP_Hybrid_OPFInfeas_List = [TotdP_Hybrid_OPFInfeas_List; TotdP_Hybrid_OPFInfeas];
        V_Hybrid_List = [V_Hybrid_List; PFHybrid.bus(:,8)];
        TotQG_ExclSlack_Hybrid = sum(PFHybrid.gen(2:end,3)); % except the slack node
    end    

    TotdP_Hybrid_List = [TotdP_Hybrid_List; TotdP_Hybrid];
end

