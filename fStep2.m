function [CaseQContrPasFlow,PF_QContrPasFlow,send_QContrPasFlow_all,send_QContrPasFlow_all_Tab] = fStep2(CaseTur,...
    NS,send_Tur_all_Tab,Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,NBus,NLine,G,pfPrint,mpopt)
% Step 2: increase of generation in sender nodes detecting passing flows (it comes from the slack node)

CaseQContrPasFlow = CaseTur; % start from Turitsyn approach
    
for i = 1:NS
    send_ind = table2array(send_Tur_all_Tab(i,1)); % i is line number, Send_Gen_Ind is index of line in gen structure
    if table2array(send_Tur_all_Tab(i,10)) == 1 % if flag for passing Q flow from slack node is 1
        Qg_increase = table2array(send_Tur_all_Tab(i,6)); % generation should be increased by the value of incoming flow
        Qg_pas_upd = CaseQContrPasFlow.gen(send_ind,3) + Qg_increase; % adding Qg_increase value
        
%         We divide Pg_max value by /Pg_coef_det to obtain Sg_max 
%         CaseQContrPasFlow.gen(send_ind,3) = min([Qg_pas_upd, ...
%         CaseQContrPasFlow.gen(send_ind,2)*TgFiLimInv*Q_avail, ... 
%         Q_avail*sqrt((CaseQContrPasFlow.gen(send_ind,9)/Pg_coef_det)^2-(CaseQContrPasFlow.gen(send_ind,2))^2)]); % compact equivalent form

        CaseQContrPasFlow.gen(send_ind,3) = min([Qg_pas_upd, CaseQContrPasFlow.gen(send_ind,4)]); % compact equivalent form
%         CaseQContrPasFlow.gen(send_ind,4) = CaseQContrPasFlow.gen(send_ind,3); % enforcing limits
%         CaseQContrPasFlow.gen(send_ind,5) = CaseQContrPasFlow.gen(send_ind,3); % enforcing limits
    end
end
    
CaseQContrPasFlow.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses
% running power flow with updated generaiton vaiues

if pfPrint == 0
    PF_QContrPasFlow = runpf(CaseQContrPasFlow,mpopt);
elseif pfPrint == 1
    PF_QContrPasFlow = runpf(CaseQContrPasFlow);
end
    
% Updating the table for new power flow
for j = 1:NS

    Send_Gen_Ind = Send_Gen_Ind_List(j);
    Send_BusGen_ID = Send_BusGen_ID_List(j);
    Send_Bus_Ind = Send_Bus_Ind_List(j);

    % saving Q_gen 
    if PF_QContrPasFlow.gen(Send_Gen_Ind,1) == Send_BusGen_ID 
        Qg_id = PF_QContrPasFlow.gen(Send_Gen_Ind,3);
    end

    % saving QL
    if PF_QContrPasFlow.bus(Send_Bus_Ind,1) == Send_BusGen_ID
        QL_id = PF_QContrPasFlow.bus(Send_Bus_Ind,4);
    end

    % List of all neighbor nodes.  
    Neig_all = [];
    for i = 1:NLine
        if PF_QContrPasFlow.branch(i,1) == Send_BusGen_ID
            Neig_all = [Neig_all; PF_QContrPasFlow.branch(i,2)];
        elseif PF_QContrPasFlow.branch(i,2) == Send_BusGen_ID
            Neig_all = [Neig_all; PF_QContrPasFlow.branch(i,1)];
        end
    end

    % Finding parent and children neighbors
    Shortest_path = shortestpath(G,Send_BusGen_ID,1); % Bus 1 is a slack node 
    Neig_in = Shortest_path(2); % first is source, last is target (slack) node
    Neig_out_list = setdiff(Neig_all, Neig_in); %So, it is
    % straighforward to define the outcoming, chidren, nodes.
    NNeig_out = length(Neig_out_list); % number of outcoming neighbors

    % Finding incoming flow (always only 1)
    for i = 1:NLine
        if PF_QContrPasFlow.branch(i,1) == Neig_in && PF_QContrPasFlow.branch(i,2) == Send_BusGen_ID %From - neigbor incoming, To - current node
            QFlow_in = -PF_QContrPasFlow.branch(i,17); % Incoming flow is To flow (current node), where default sign is -
        elseif PF_QContrPasFlow.branch(i,2) == Neig_in && PF_QContrPasFlow.branch(i,1) == Send_BusGen_ID % To - neigbor incoming, From - current node
            QFlow_in = -PF_QContrPasFlow.branch(i,15); % Incoming flow is From flow (current node), where default sign is +
        end
    end

    % Finding sum of outcoming flows (might be several outcoming flows)
    QFlow_out_tot = 0;

    if NNeig_out > 0 % if there is at least on outcoming neighbor
        for k = 1:NNeig_out % cycle over each outcoming neighbor
            Neig_out = Neig_out_list(k); % that specific outcoming neighbor
            for i = 1:NLine
                if PF_QContrPasFlow.branch(i,1) == Neig_out && PF_QContrPasFlow.branch(i,2) == Send_BusGen_ID %From - neigbor outcoming, To - current node
                    QFlow_out = PF_QContrPasFlow.branch(i,17); % Outcoming flow is To flow (current node), where default sign is -
                elseif PF_QContrPasFlow.branch(i,2) == Neig_out && PF_QContrPasFlow.branch(i,1) == Send_BusGen_ID % To - neigbor incoming, From - current node
                    QFlow_out = PF_QContrPasFlow.branch(i,15); % Outcoming flow is From flow (current node), where default sign is +
                end
            end
            QFlow_out_tot = QFlow_out_tot + QFlow_out; % this works if there are no parallel lines. Otherwise, in the previous 
            %cycle one more sum should be
        end
    end

    % Calculating the disbalance
    Q_disb = QFlow_out_tot - QFlow_in - (Qg_id - QL_id);

    % Putting flag for passing flow from the slack node
    if NNeig_out > 0 && abs(Q_disb) < 1e-5 % 1st condition: non-leaf node, 2nd condition: presicion 
    %         if NNeig_out > 0 % 1st condition: non-leaf node 
        flag_FlowFrSlack = 1;
    else
        flag_FlowFrSlack = 0;
    end

    % Flag for the reverse flow to the slack node
    if table2array(send_Tur_all_Tab(j,6))*QFlow_in < 0 % the size of table is the same. < means it changed the sign
       flag_ReversToSlack = 1; % the flag for reverse flow to slack node is 1
    else
       flag_ReversToSlack = 0; % in Turitsyn's approach no reverse flows to the slack node
    end

    % Initializing and Filling the struct
    send_QContrPasFlow_i = struct('Sender_Generator_Index',Send_Gen_Ind,'Sender_BusGen_ID',Send_BusGen_ID,'Sender_Bus_Index',Send_Bus_Ind,...
        'Q_gen',Qg_id,'Q_load',QL_id,'Incoming_Q_flow',QFlow_in,'Total_outcoming_Q_flow',QFlow_out_tot,'Disbalance_of_Q',Q_disb,...
        'Number_of_neighbors_out',NNeig_out,'Passing_Q_flow_from_slack_node',flag_FlowFrSlack,'Reverse_flow_to_slack',flag_ReversToSlack);

    % Total incoming flow for all recepient nodes is positive, what is
    % correct.
    if j == 1
        send_QContrPasFlow_all = send_QContrPasFlow_i;
    else
        send_QContrPasFlow_all = [send_QContrPasFlow_all; send_QContrPasFlow_i];
    end

end  

    % The table presentation
    send_QContrPasFlow_all_Tab = struct2table(send_QContrPasFlow_all); % the system state after increasing generation by the value of passing flow from slack node

end

