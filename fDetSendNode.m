function [CaseAlgI,Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,NS] = fDetSendNode(CaseTur,NGen,NBus)
% Determine all the information regarding sender nodes. Recipient nodes are
% not used in the algorithm anymore.
CaseAlgI = CaseTur;

% 1) Nodes identify if they are sender (donor) or recipient
Send_Gen_Ind_List = []; % List of Senders Generator Index (line)
Send_BusGen_ID_List = [];  % List of Senders Bus=Generator ID 
Send_Bus_Ind_List = []; % List of Senders Bus Index (line)

% Rec_Gen_Ind_List = []; % List of Receivers Generator Index (line)
% Rec_BusGen_ID_List = [];  % List of Receivers Bus=Generator ID 
% Rec_Bus_Ind_List = []; % List of Receivers Bus Index (line)

for i = 1:NGen % except the slack bus, slack bus assumed to be #1
    BusID = CaseAlgI.gen(i,1); % on which bus is generator
    for j = 1:NBus
        if CaseAlgI.bus(j,1) == BusID
            QL = CaseAlgI.bus(j,4);
            if  CaseAlgI.gen(i,1) > 1 % check if Qg >= QL, then it is potential sender. Also check if it is not a slack node
                % Gen in CaseAlgI should be compared with Qmax in CaseA, as limits
                % are changed in CaseAlgI for enforcement
                Send_Gen_Ind = i; 
                Send_BusGen_ID = CaseAlgI.gen(i,1); 
                Send_Bus_Ind = find(CaseAlgI.bus(:,1)==Send_BusGen_ID); 

                Send_Gen_Ind_List = [Send_Gen_Ind_List; Send_Gen_Ind]; 
                Send_BusGen_ID_List = [Send_BusGen_ID_List; Send_BusGen_ID];  
                Send_Bus_Ind_List = [Send_Bus_Ind_List; Send_Bus_Ind]; 
        
%             else
%                 % initial recipient node: Qmax should be greater than zero
%                 Rec_Gen_Ind = i; 
%                 Rec_BusGen_ID = CaseAlgI.gen(i,1); 
%                 Rec_Bus_Ind = find(CaseAlgI.bus(:,1)==Rec_BusGen_ID); 
% 
%                 Rec_Gen_Ind_List = [Rec_Gen_Ind_List; Rec_Gen_Ind]; 
%                 Rec_BusGen_ID_List = [Rec_BusGen_ID_List; Rec_BusGen_ID];  
%                 Rec_Bus_Ind_List = [Rec_Bus_Ind_List; Rec_Bus_Ind]; 
            
            end 
        end
    end
end

% % Displaying donor and recipient buses on the graph: before any check
% highlight(h, transpose(Send_BusGen_ID_List), 'NodeColor', 'r') % donor generators
% highlight(h, transpose(Rec_BusGen_ID_List), 'NodeColor', 'g') % recipient generators

NS = size(Send_BusGen_ID_List,1); % number of sender nodes
% NR = size(Rec_BusGen_ID_List,1) % number of recipient nodes

end

