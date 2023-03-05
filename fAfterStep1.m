function [send_Tur_all,send_Tur_all_Tab] = fAfterStep1(Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,PF_Tur,NLine,G,NS)
% Creating checkout-table after Step I

for j = 1:NS 
       
    Send_Gen_Ind = Send_Gen_Ind_List(j);
    Send_BusGen_ID = Send_BusGen_ID_List(j);
    Send_Bus_Ind = Send_Bus_Ind_List(j);

    % saving Q_gen 
    Qg_id = PF_Tur.gen(Send_Gen_Ind,3);

    % saving QL
    QL_id = PF_Tur.bus(Send_Bus_Ind,4);

    % List of all neighbor nodes.  
    Neig_all = [];
    for i = 1:NLine
        if PF_Tur.branch(i,1) == Send_BusGen_ID
            Neig_all = [Neig_all; PF_Tur.branch(i,2)];
        elseif PF_Tur.branch(i,2) == Send_BusGen_ID
            Neig_all = [Neig_all; PF_Tur.branch(i,1)];
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
        if PF_Tur.branch(i,1) == Neig_in && PF_Tur.branch(i,2) == Send_BusGen_ID %From - neigbor incoming, To - current node
            QFlow_in = -PF_Tur.branch(i,17); % Incoming flow is To flow (current node), where default sign is -
        elseif PF_Tur.branch(i,2) == Neig_in && PF_Tur.branch(i,1) == Send_BusGen_ID % To - neigbor incoming, From - current node
            QFlow_in = -PF_Tur.branch(i,15); % Incoming flow is From flow (current node), where default sign is +
        end
    end

    % Finding sum of outcoming flows (might be several outcoming flows)
    QFlow_out_tot = 0;

    if NNeig_out > 0 % if there is at least on outcoming neighbor
        for k = 1:NNeig_out % cycle over each outcoming neighbor
            Neig_out = Neig_out_list(k); % that specific outcoming neighbor
            for i = 1:NLine
                if PF_Tur.branch(i,1) == Neig_out && PF_Tur.branch(i,2) == Send_BusGen_ID %From - neigbor outcoming, To - current node
                    QFlow_out = PF_Tur.branch(i,17); % Outcoming flow is To flow (current node), where default sign is -
                elseif PF_Tur.branch(i,2) == Neig_out && PF_Tur.branch(i,1) == Send_BusGen_ID % To - neigbor incoming, From - current node
                    QFlow_out = PF_Tur.branch(i,15); % Outcoming flow is From flow (current node), where default sign is +
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
        flag_FlowFrSlack = 1;
    else
        flag_FlowFrSlack = 0;
    end

    % Flag for the reverse flow to the slack node
    flag_ReversToSlack = 0; % in Turitsyn's approach no reverse flows to the slack node

    % Initializing and Filling the struct
    send_Tur_i = struct('Sender_Generator_Index',Send_Gen_Ind,'Sender_BusGen_ID',Send_BusGen_ID,'Sender_Bus_Index',Send_Bus_Ind,...
                'Q_gen',Qg_id,'Q_load',QL_id,'Incoming_Q_flow',QFlow_in,'Total_outcoming_Q_flow',QFlow_out_tot,'Disbalance_of_Q',Q_disb,...
                'Number_of_neighbors_out',NNeig_out,'Passing_Q_flow_from_slack_node',flag_FlowFrSlack,'Reverse_flow_to_slack',flag_ReversToSlack);

    % Total incoming flow for all recepient nodes is positive, what is correct.
    if j == 1
        send_Tur_all = send_Tur_i;
    else
        send_Tur_all = [send_Tur_all; send_Tur_i];
    end

end  
   
% The table presentation
send_Tur_all_Tab = struct2table(send_Tur_all); % the system state after Turitsyn approach

end

