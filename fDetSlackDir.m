function [CaseAlgIA,PF_CaseAlgIA,Sender_SlackDir] = fDetSlackDir(CaseAlgI,send_Tur_all_Tab,NS,NBus,NLine,pfPrint,mpopt)
% Determining the direction of a slack node/incoming flow by decreasing inverters' generation by 10%
CaseAlgIA = CaseAlgI;
% Let's use inverters' indixes, IDs, and number of neighbours from send_Tur_all_Tab
% as inverters physically can get this data in decentralized manner

send_NonLeaf_GenInd_List = []; % see Gen_Ind below
send_NonLeaf_BusGenID_List = []; % see BusGen_ID below

send_Tur_all_Arr = table2array(send_Tur_all_Tab); % converting to array
for i = 1:NS
    if send_Tur_all_Arr(i,9)>0 % if number of outgoing neighbors more than 0
        
        Gen_Ind = send_Tur_all_Arr(i,1); % index of the sender gen with multiplie lines
        BusGen_ID = send_Tur_all_Arr(i,2); % ID of the sender gen with multiplie lines
        
        send_NonLeaf_GenInd_List = [send_NonLeaf_GenInd_List;Gen_Ind];
        send_NonLeaf_BusGenID_List = [send_NonLeaf_BusGenID_List;BusGen_ID];
        
        CaseAlgIA.gen(Gen_Ind,3) = 0.9*CaseAlgIA.gen(Gen_Ind,3); % decrease Qg by 10%
    end
end

CaseAlgIA.bus(2:NBus,2) = 1; % changing type of PVs from PV to PQ buses

if pfPrint == 0
    PF_CaseAlgIA = runpf(CaseAlgIA,mpopt);
elseif pfPrint == 1
    PF_CaseAlgIA = runpf(CaseAlgIA);
end

NSNL = size(send_NonLeaf_BusGenID_List,1); % number of non-leaf sender nodes

% Next, for each gen with decreased Qg, we aim to find a line with the
% biggest absolute value of reactive power flow: columns 15, 17 
BusID_max_Qfl_List = []; % list of the buses with maximum flows

for i = 1:NSNL
    Send_NonLeaf_BusGenID = send_NonLeaf_BusGenID_List(i);
    BusID_AllNeig_List = [];
    QFlow_List = [];
    for j = 1:NLine % going over all lines for each non-leaf sender node
        if PF_CaseAlgIA.branch(j,1) == Send_NonLeaf_BusGenID
            BusID_AllNeig_List = [BusID_AllNeig_List; PF_CaseAlgIA.branch(j,2)]; %save bus ID
            QFlow_List = [QFlow_List; abs(PF_CaseAlgIA.branch(j,17))]; % save flow
        elseif PF_CaseAlgIA.branch(j,2) == Send_NonLeaf_BusGenID
            BusID_AllNeig_List = [BusID_AllNeig_List; PF_CaseAlgIA.branch(j,1)]; %save bus ID
            QFlow_List = [QFlow_List; abs(PF_CaseAlgIA.branch(j,15))]; % save flow
        end
    end
    [max_QFlow_val, max_QFlow_ind] = max(QFlow_List);
    BusID_max_Qfl = BusID_AllNeig_List(max_QFlow_ind); % the neighbor bus with max flow
    BusID_max_Qfl_List = [BusID_max_Qfl_List; BusID_max_Qfl];
end

% line-pair-wise: Sender non-leaf node and its neighbor towards slack node
Sender_SlackDir = horzcat(send_NonLeaf_BusGenID_List, BusID_max_Qfl_List); 
% for 33-bus system obtained results are correct

end

