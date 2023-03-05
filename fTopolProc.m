function [CaseA,NLine,G] = fTopolProc(CaseA,TopCh,FDB,SDB,FCB,SCB)
% This function units three blocks of the code found below

%% Re-configuring topology if and in the way defined by a user
NLine = size(CaseA.branch,1);

if TopCh == 1
    for i = 1:NLine
        bus_fr = CaseA.branch(i,1);
        bus_to = CaseA.branch(i,2);
        if bus_fr == FDB && bus_to == SDB
            CaseA.branch(NLine+1, :) = CaseA.branch(i,:); % copied everything including indexes
            CaseA.branch(NLine+1, 1) = FCB; % setting correct indexes for connected line
            CaseA.branch(NLine+1, 2) = SCB;
            CaseA.branch(i,:) = []; % deleting the disconnected line
        end
    end
end

%% Deleting the switched off lines as they "confuse" local flow measuring algorithm
OnLines_Ind_List = []; % same as keeping only "on" lines

for i = 1:NLine
    if CaseA.branch(i,11) == 1
        OnLines_Ind_List = [OnLines_Ind_List; i];
    end
end

CaseA.branch = CaseA.branch(OnLines_Ind_List,:);
NLine = size(CaseA.branch,1);

%% Creating graph for the system
% Create external graph
FrBus = transpose(CaseA.branch(:,1));
ToBus = transpose(CaseA.branch(:,2));
G = graph(FrBus, ToBus);

% % Visualize the internal graph: not used but can be kept as proto-code
% CaseA_Int = ext2int(CaseA); % internalize the bus indices
% FrBus_Int = transpose(CaseA_Int.branch(:,1));
% ToBus_Int = transpose(CaseA_Int.branch(:,2));
% G_Int = graph(FrBus_Int, ToBus_Int);
% figure(1) %hide plot for speed
% h = plot(G_Int);
% h = plot(G,'NodeLabel',CaseA_Int.bus(:,1)); 
% 
% % Mapping from internal to external
% [i2e, busExt, genExt, branchExt] = ext2int(CaseA_Int.bus, CaseA_Int.gen, CaseA_Int.branch);
% % And then compare pair-wise i2e and CaseA.bus(:,1)

end

