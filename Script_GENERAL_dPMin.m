clear; clear all; clc; close all;

%% All parameters to change

% 1. Case Data
% A. PAPER TEST CASES
CaseOrig = case33_200600Invs_5DG_100MVA; PV_idx = [2:5]; Wind_idx = 6;

% 2. Modify generation: randomly place PVs in the amount NSendGen
GM = 0;  
% IF GM = 1, THEN settings of NSendGen of and Niter get activated

% 2a. Number of sender generators (used only if GM = 1)
NSendGen = 100; 

% 2b. Number of random locations of generators (used only if GM = 1)
Niter = 1; % If Niter>1, then set TV=1

% 3. Percentage PVs produce from their rated capacity
Pg_coef_det = 0.8; % 1 means PVs produce at their rated capacity, so no Q-control available
% 0.5 for 30-bus case; 0.8 for other cases

% 4. Load modification
LM = 0; % 1 - make load modification
CosFiLoad = 0.97; % assumed power factor across all loads

% 4.5 % Scaling RES and inverter capacity (if any)
k_Inv = 1;

% 4.6 Scaling Load (if any)
k_Load = 1;

% 4.7 Scaling line parameters
k_RX = 1; % More than 1 - increasing, less than 1 - decreasing 

% 5. Power factor: lagging to leading limits
CosFiLimInv = 0.8;
TgFiLimInv = sqrt(1/CosFiLimInv^2-1); % tangent 

% 6. Defining amount of Q reserve for voltage control
Q_coeff = 0; % 
Q_avail = 1 - Q_coeff; % available limit for loss minimization purpose

% 7. Time-variying PV generation and load
TV = 0; % 1 means that pattern of time-varying PV generation and load will be used for SYSLAB data.
% Tv = 1 and Sc = 1 are self-exclusive, but both of them can be zero at the
% same time 

% Simulation should be done only for one random location of PVs: Niter = 1
% 7a. IF TV = 1, THEN choose the period of simulation 12 hours or a whole year
Period = 1; % 1 - for test purpose; 12 - means 12 hours; 24 - 03:00-19:30 at the first day in Garima's forecasting;
% 25 - 00:00-23:59 at the first day in Garima's forecasting; 365 - means a whole year, 
% 7b. For case Period == 24,25 we can have night hours on (GridOfNigHour == 1) or off (GridOfNigHour == 0). For all
% other scenarios, GridOfNigHour == 0.
GridOfNigHour = 0;

% 7.5 Scenario check for RTDS
Sc = 0; % if 1, then work with designed PV, wind, demand scenarios file
% TV = 1 and Sc = 1 are self-exclusive, but both of them can be zero at the
% same time
% 7.6 Choose scenario number (line, not-counting header)
Sc_case = 1; % array/integer of the case(s)=line(s) to run; [1:991]'
% 7.7 Forecasting used or not
Sc_fct = 1; % if 1, then forecasting data is used

% 8. Cost of MWh in Money
MWh2Money = 258; %MWh2Euro = 258; MWh2DKK = 1983

% 9. Inputs for topology change: 
% For 33-bus system, the lines are provided, so I switched them on manually 
% Buses below correspond to 33-bus system
TopCh = 0; 
% 9a. IF 1, THEN topology changes as below
FDB = 19; % first disconnected bus. Nodes for .. system. 33-bus: 19,13,14. Akirkeby: 162,3207,941. 141-bus: 5,15,76.
SDB = 20; % second disconnected bus. Nodes for .. system. 33-bus: 20,14,32. Akirkeby: 3200,3214,3203. 141-bus: 6,118,78.
FCB = 8; % first connected bus. Nodes for .. system. 33-bus: 8,9,18. Akirkeby: 167,36,414. 141-bus: 7,17,45.
SCB = 21; % second connected bus. Nodes for .. system. 33-bus: 21,15,33. Akirkeby: 3179,3206,3151. 141-bus: 34,130,82.

% 10. Save a boxplot comparing Turitsyn and proposed algorithm as a TEX file
BP = 0; % if BP = 1, then save a TEX file
% modify tikz output file at the end of the script

% 11. Settigs for the Hybrid algorithm
% 11a. Do we select number of centrally controlled inverters (1) or let it be defined by NNonZerdQ (0)
SelectNCenInv = 0; 

% 11b. Number of centrally controlled inverters (active only if SelectNCenInv = 1)
NCenInv_user = 4; 

% 12. Make a plot
Plotting = 0; % if 1, the script makes plots

% 13. Show output of (optimal) power flow
pfPrint = 0; % if 0 then print amount is defined by mpopt below
             % if 1, then full runpf/runopf output is printed

% Total supression of print:
mpopt = mpoption('verbose',0,'out.all', 0);

% Printing the convergence and solver only:
% mpopt = mpoption('out.all', 0);

% 14. Iteration progress
ProgrPrint = 1; % if 1 then print progress over all number of simulations

%% List of data for the loops
% Losses acrooss different methods
TotdP_OPF_List = []; TotdP_OPF_Feas_List = []; TotdP_OPF_Infeas_List = [];

TotdP_base_kW_List = []; TotdP_OnlySlackGen_kW_List = [];
TotdP_QMax_kW_List = []; TotdP_Tur_kW_List = []; TotdP_NoCom_kW_List = [];

% For time-varyiing solar generation and demand
TotPG_List = []; TotPL_List = []; TotQL_List = [];

% total reactive power generation except the slack node
TotQG_ExclSlack_base_List = []; TotQG_ExclSlack_OnlySlackGen_List = [];
TotQG_ExclSlack_OPF_List = []; TotQG_ExclSlack_QMax_List = [];
TotQG_ExclSlack_Tur_List = []; TotQG_ExclSlack_NoCom_List = []; 
TotPG_ExclSlack_OPF_List = [];

% All voltage magnitudes in various algorithms
V_base_List = []; V_Tur_List = []; V_NoCom_List = [];
V_OPF_List = []; V_QMax_List = []; V_CaseOnlySlackGen_List = [];

% Loss improvements of Turitsyn and our approaches comparing to the base case
dLos_Tur_base_List = []; dLos_NoCom_base_List = [];

% Number of cases when our approach and Turitsyn
NdPTurLowOur = 0; % number of cases when Turitsin provided lower losses than our
NdPTurEqOur = 0; % ..equal
NdPTurHigOur = 0; % ..higher

% Number of infeasible simulations for each approach
NInf_base = 0; NInf_OnlySlackGen = 0; NInf_OPF = 0;
NInf_QMax = 0; NInf_Tur = 0; NInf_CaseAlgIA = 0;
NInf_QContrPasFlow = 0; NInf_QContrRevFlow = 0; NInf_Hybrid = 0;
NInf_HybridLLMA = 0; NInf_HybridLFMA = 0;

% Creating lists for a hybrid (LLMA and LFMA) algorithms
NNonZerdQLLMA_List = []; % list of number of zero dQs
TotdP_HybridLLMA_OPFFeas_List = [];
TotdP_HybridLLMA_OPFInfeas_List = [];
TotdP_HybridLLMA_List = [];
V_HybridLLMA_List = [];
CenInv_Iter_array_tab_LLMA = [];

NNonZerdQLFMA_List = []; % list of number of zero dQs
TotdP_HybridLFMA_OPFFeas_List = [];
TotdP_HybridLFMA_OPFInfeas_List = [];
TotdP_HybridLFMA_List = [];
V_HybridLFMA_List = [];
CenInv_Iter_array_tab_LFMA = [];

if SelectNCenInv == 1
    % anonimoys function as NTimePoints,NPV are defined further in cycle.
    % We will define the CenInv_Iter array line by line
    CenInv_Iter_array = @(NTimePoints,NPV) zeros(1,NCenInv_user);
else 
    % if centrally controlled inverters are defined via
    % NNonZerdQ, then their number will vary. To overcome
    % it, let's define the maximum number of NNonZerdQ as
    % NPV, which indeed cannot be exceeded.
     CenInv_Iter_array = @(NTimePoints,NPV) zeros(1,NPV);
end 

%% Loop start
for iter = 1:Niter
    if GM == 1
        rng(iter) %for random placement of PVs (does not influence to a original case)
    end
    CaseA = CaseOrig;
    % Scaling RES and inverter capacity (if any)
    CaseA.gen(:,[4,5,9])=k_Inv*CaseA.gen(:,[4,5,9]);
    % Scaling Load (if any)
    CaseA.bus(:,[3,4])=k_Load*CaseA.bus(:,[3,4]);
    % Scaling line parameters (if any)
    CaseA.branch(:,[3,4])=k_RX*CaseA.branch(:,[3,4]);
    
    NBus = size(CaseA.bus,1);

    %% FUNCTION: Topology Processing
    [CaseTopProc,NLine,G] = fTopolProc(CaseA,TopCh,FDB,SDB,FCB,SCB);

    %% FUNCTION: Load Processing
    [CaseLoadProc,INL,NNL,PL,QL] = fLoadProc(CaseTopProc,LM,CosFiLoad);

    %% FUNCTION: Generation Processing
    [CaseGenProc,ISG,NGen,NPV] = fGenProc(CaseLoadProc,GM,NSendGen,INL,PL,NBus);
    
    % Assigning PV_idx and Wind_idx
    if GM == 1
        PV_idx = 1:NSendGen; % only for 141-bus system, it has only PVs..
        Wind_idx = []; % .. but no wind turbines
    end
    
    if TV == 1
        PV_idx = 1:size(ISG,1); % only for Danish system, it has only PVs..
        Wind_idx = []; % .. but no wind turbines
    end

    %% FUNCTION: Time-varying solar generation and load
    [PV_coef_TV,Wind_coef_TV,Load_coef_TV,NTimePoints,PV_coef_forecast,PV_coef_current,...
    Wind_coef_forecast,Wind_coef_current,P_load_coef,Q_load_coef] = fTimeVarPvLoad(TV,Period,Sc,Sc_case,Sc_fct);

    %% Start a loop over time-varying solar generation and demand
    for iPoint = 1:NTimePoints % cycle of varying Pg and load
        
        %% FUNCTION: Deriving PL,QL values, Pg, Qg limits for both deterministic and time-varying cases
        [CaseA0] = fPgCoef(CaseGenProc,NTimePoints,Pg_coef_det,PV_coef_TV,Wind_coef_TV,Load_coef_TV,...
            iPoint,Q_avail,TgFiLimInv,NGen,PV_idx,Wind_idx,PV_coef_forecast,PV_coef_current,...
            Wind_coef_forecast,Wind_coef_current,P_load_coef,Q_load_coef,Sc,GridOfNigHour);

        %% ############  SIMULATIONS OF VARIOUS ALGORITHMS ################
        %% FUNCTION: Power flow for a case with preserved distributed generation and Qg = 0
        [CaseQgZero,PF_base,TotdP_base,TotPG,TotPL,TotQL,TotQG_ExclSlack_base,V_base_List] = fQgZeroPF(CaseA0,NBus,V_base_List,pfPrint,mpopt);

        %% FUNCTION: Power flow in a system with only one gen which is on a slack bus
        [CaseOnlySlackGen,PF_OnlySlackGen,TotdP_OnlySlackGen,TotQG_ExclSlack_OnlySlackGen,...
        V_CaseOnlySlackGen_List] = fOnlySlackGenPF(CaseA0,V_CaseOnlySlackGen_List,pfPrint,mpopt);

        %% FUNCTION: AC OPF (Pg is fixed to PV output; Qg,Va,Vm are control variables)
        [CaseA_OPF,OPF,TotdP_OPF_Feas_List,TotdP_OPF_Infeas_List,...
        TotdP_OPF_List,V_OPF_List,TotQG_ExclSlack_OPF,TotPG_ExclSlack_OPF] = fOpfPgFixed(CaseA0,...
        TotdP_OPF_Feas_List,TotdP_OPF_Infeas_List,TotdP_OPF_List,V_OPF_List,NBus,pfPrint,mpopt);

        %% FUNCTION: QgMax (setting the maximum Qg allowed by limits)
        [CaseQMax,PF_QMax,TotQG_ExclSlack_QMax,TotdP_QMax,V_QMax_List] = fQMaxPF(CaseA0,NBus,V_QMax_List,pfPrint,mpopt);

        %% FUNCTION: Local Load Measuring Algorithm (Turitsyn approach)
        [CaseTur,PF_Tur,TotQG_ExclSlack_Tur,TotdP_Tur,V_Tur_List] = fLLMA(CaseA0,NBus,NGen,V_Tur_List,pfPrint,mpopt);
        
        %% ### Local Flow Measuring Algorithm ###
        %% FUNCTION: (Step 1) Determine sender nodes
        % Step I of Local Flow Measuring Algorithm is exactly the same as Local Load Measuring Algorithm. 
        [CaseAlgI,Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,NS] = fDetSendNode(CaseTur,NGen,NBus);

        if NS > 0 % check if there is at least one sender node

            %% FUNCTION: (Step 1) Checkout-table
            [send_Tur_all,send_Tur_all_Tab] = fAfterStep1(Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,PF_Tur,NLine,G,NS);

            %% FUNCTION: (Step 1-A) determining the direction of a slack node/incoming flow by decreasing inverters' generation by 10%
            [CaseAlgIA,PF_CaseAlgIA,Sender_SlackDir] = fDetSlackDir(CaseAlgI,send_Tur_all_Tab,NS,NBus,NLine,pfPrint,mpopt);

            %% FUNCTION: (Step 2) increase of generation in sender nodes detecting passing flows (it comes from the slack node)
            [CaseQContrPasFlow,PF_QContrPasFlow,send_QContrPasFlow_all,send_QContrPasFlow_all_Tab] = fStep2(CaseTur,...
            NS,send_Tur_all_Tab,Send_Gen_Ind_List,Send_BusGen_ID_List,Send_Bus_Ind_List,NBus,NLine,G,pfPrint,mpopt);

            %% FUNCTION: (Step 3) changing generation for the nodes which detected reverse flows to slack nodes
            [CaseQContrRevFlow,PF_QContrRevFlow,V_NoCom_List,TotQG_ExclSlack_NoCom,TotdP_NoCom] = fStep3(CaseQContrPasFlow,...
            NS,send_QContrPasFlow_all_Tab,send_Tur_all_Tab,V_NoCom_List,NBus,pfPrint,mpopt);
               
            %% Hybrid LLMA (selectively running some inverters by centralized OPF after LLMA)      
            [CaseHybridLLMA,OPFHybridLLMA,GenID_dQ_DecrOrd_LLMA,CenInv_Iter_array_tab_LLMA,NNonZerdQLLMA_List,...
            TotdP_HybridLLMA_OPFFeas_List,TotdP_HybridLLMA_OPFInfeas_List,TotdP_HybridLLMA_List,V_HybridLLMA_List,...
            TotQG_ExclSlack_HybridLLMA] = fHybrid(CaseTur,PF_Tur,SelectNCenInv,NNonZerdQLLMA_List,...
            TotdP_HybridLLMA_OPFFeas_List,TotdP_HybridLLMA_OPFInfeas_List,TotdP_HybridLLMA_List,V_HybridLLMA_List,...
            NCenInv_user,NGen,NPV,NTimePoints,iter,iPoint,CenInv_Iter_array,CenInv_Iter_array_tab_LLMA,pfPrint,mpopt);
        
            %% Hybrid LFMA (selectively running some inverters by centralized OPF after LFMA)      
            [CaseHybridLFMA,OPFHybridLFMA,GenID_dQ_DecrOrd_LFMA,CenInv_Iter_array_tab_LFMA,NNonZerdQLFMA_List,...
            TotdP_HybridLFMA_OPFFeas_List,TotdP_HybridLFMA_OPFInfeas_List,TotdP_HybridLFMA_List,V_HybridLFMA_List,...
            TotQG_ExclSlack_HybridLFMA] = fHybrid(CaseQContrRevFlow,PF_QContrRevFlow,SelectNCenInv,NNonZerdQLFMA_List,...
            TotdP_HybridLFMA_OPFFeas_List,TotdP_HybridLFMA_OPFInfeas_List,TotdP_HybridLFMA_List,V_HybridLFMA_List,...
            NCenInv_user,NGen,NPV,NTimePoints,iter,iPoint,CenInv_Iter_array,CenInv_Iter_array_tab_LFMA,pfPrint,mpopt);

        else
            % if NS = 0, then Turitsyn is the best we can do
            TotdP_NoCom = TotdP_Tur; 
            TotQG_ExclSlack_NoCom = TotQG_ExclSlack_Tur;
            V_NoCom_List = [V_NoCom_List; PF_Tur.bus(:,8)];
        end

        %% Postprocessing calculated power losses
        % Convert p.u. to kW
        TotdP_base_kW = 1000*TotdP_base;
        TotdP_OnlySlackGen_kW = 1000*TotdP_OnlySlackGen;
        TotdP_OPF_Feas_kW_List = 1000*TotdP_OPF_Feas_List;
        TotdP_OPF_Infeas_kW_List = 1000*TotdP_OPF_Infeas_List;
        TotdP_OPF_kW_List = 1000*TotdP_OPF_List;
        TotdP_QMax_kW = 1000*TotdP_QMax;
        TotdP_Tur_kW = 1000*TotdP_Tur;
        TotdP_NoCom_kW = 1000*TotdP_NoCom;
        
        TotdP_HybridLLMA_OPFFeas_kW_List = 1000*TotdP_HybridLLMA_OPFFeas_List;
        TotdP_HybridLLMA_OPFInfeas_kW_List = 1000*TotdP_HybridLLMA_OPFInfeas_List;
        TotdP_HybridLLMA_kW_List = 1000*TotdP_HybridLLMA_List;
        
        TotdP_HybridLFMA_OPFFeas_kW_List = 1000*TotdP_HybridLFMA_OPFFeas_List;
        TotdP_HybridLFMA_OPFInfeas_kW_List = 1000*TotdP_HybridLFMA_OPFInfeas_List;
        TotdP_HybridLFMA_kW_List = 1000*TotdP_HybridLFMA_List;

        % Filling up the lists
        TotdP_base_kW_List = [TotdP_base_kW_List; TotdP_base_kW];
        TotdP_OnlySlackGen_kW_List = [TotdP_OnlySlackGen_kW_List; TotdP_OnlySlackGen_kW];
        TotdP_QMax_kW_List = [TotdP_QMax_kW_List; TotdP_QMax_kW];
        TotdP_Tur_kW_List = [TotdP_Tur_kW_List; TotdP_Tur_kW];
        TotdP_NoCom_kW_List = [TotdP_NoCom_kW_List; TotdP_NoCom_kW];

        %% Postprocessing calculated total active generation and load
        TotPG_List = [TotPG_List; TotPG];  % total active geneation
        TotPL_List = [TotPL_List; TotPL]; % total active load

        %% Postprocessing calculated total reactive generation and load   
        TotQL_List = [TotQL_List; TotQL]; % total reactive load

        TotQG_ExclSlack_base_List = [TotQG_ExclSlack_base_List; TotQG_ExclSlack_base];
        TotQG_ExclSlack_OnlySlackGen_List = [TotQG_ExclSlack_OnlySlackGen_List; TotQG_ExclSlack_OnlySlackGen];
        TotQG_ExclSlack_OPF_List = [TotQG_ExclSlack_OPF_List; TotQG_ExclSlack_OPF];
        TotPG_ExclSlack_OPF_List = [TotPG_ExclSlack_OPF_List; TotPG_ExclSlack_OPF];
        TotQG_ExclSlack_QMax_List = [TotQG_ExclSlack_QMax_List; TotQG_ExclSlack_QMax];
        TotQG_ExclSlack_Tur_List = [TotQG_ExclSlack_Tur_List; TotQG_ExclSlack_Tur]; 
        TotQG_ExclSlack_NoCom_List = [TotQG_ExclSlack_NoCom_List; TotQG_ExclSlack_NoCom];

        %% Number of cases when Turitsyn..
        if TotdP_Tur_kW < TotdP_NoCom_kW
            NdPTurLowOur = NdPTurLowOur + 1; % provided lower losses than Local Flow Measuring Algorithm
        elseif TotdP_Tur_kW == TotdP_NoCom_kW
            NdPTurEqOur = NdPTurEqOur + 1; % ..equal
        else
            NdPTurHigOur = NdPTurHigOur + 1; % ..higher
        end
        
        %% Number of infeasible simulations for each approach    
        if PF_base.success == 0
            NInf_base = NInf_base + 1;
        end
        
        if PF_OnlySlackGen.success == 0
            NInf_OnlySlackGen = NInf_OnlySlackGen + 1;
        end
        
        if OPF.success == 0
            NInf_OPF = NInf_OPF + 1;
        end
        
        if PF_QMax.success == 0
            NInf_QMax = NInf_QMax + 1;
        end
        
        if PF_Tur.success == 0
            NInf_Tur = NInf_Tur + 1;
        end
        
        if PF_CaseAlgIA.success == 0
            NInf_CaseAlgIA = NInf_CaseAlgIA + 1;
        end
        
        if PF_QContrPasFlow.success == 0
            NInf_QContrPasFlow = NInf_QContrPasFlow + 1;  
        end
        
        if PF_QContrRevFlow.success == 0
            NInf_QContrRevFlow = NInf_QContrRevFlow + 1;  
        end
        
        if OPFHybridLLMA.success == 0 
            NInf_HybridLLMA = NInf_HybridLLMA + 1; 
        end
        
        if OPFHybridLFMA.success == 0 
            NInf_HybridLFMA = NInf_HybridLFMA + 1; 
        end
        
        % Printing the iterative progress
        if ProgrPrint == 1
            disp([num2str(iter*iPoint),' / ',num2str(Niter*NTimePoints)])
        end
        
    end

    dLos_Tur_base = 100*(TotdP_base_kW - TotdP_Tur_kW)/TotdP_base_kW;
    dLos_NoCom_base = 100*(TotdP_base_kW - TotdP_NoCom_kW)/TotdP_base_kW;

    dLos_Tur_base_List = [dLos_Tur_base_List; dLos_Tur_base];
    dLos_NoCom_base_List = [dLos_NoCom_base_List; dLos_NoCom_base];

end 

%% Reporting results
% clc
disp('1. NETWORK AND SIMULATION DATA')
disp(['Number of PV placements: ',num2str(Niter)])
disp(['Number of Generators: ',num2str(NGen)])
disp(['Number of PVs: ',num2str(NPV)])
fprintf('\n') 

disp('2. NUMBER OF CASES WHEN ACTIVE POWER LOSSES IN TURITSYN APPROACH ARE..')
disp(['Lower: ',num2str(NdPTurLowOur)])
disp(['The same: ',num2str(NdPTurEqOur)])
disp(['Higher: ',num2str(NdPTurHigOur)])
disp('..THAN IN OUR LOCAL FLOW MEASURING ALGORITHM')
fprintf('\n') 

disp('3. LOSS COMPARISON ACROSS DIFFERENT METHODS, [kW]')
disp(['A. (BASE CASE) Case with preserved distributed generation and Qg = 0. MEAN: ',num2str(mean(TotdP_base_kW_List)),'; STD: ',num2str(std(TotdP_base_kW_List))])
disp(['B. Case with only one generator which is on a slack bus. MEAN: ',num2str(mean(TotdP_OnlySlackGen_kW_List)),'; STD: ',num2str(std(TotdP_OnlySlackGen_kW_List))])
disp(['C. Case with AC OPF (Pg is fixed to PV output; Qg,Va,Vm are control variables). MEAN: ',num2str(mean(TotdP_OPF_kW_List)),'; STD: ',num2str(std(TotdP_OPF_kW_List))])
disp(['D. Case with QgMax (setting the maximum Qg allowed by limits). MEAN: ',num2str(mean(TotdP_QMax_kW_List)),'; STD: ',num2str(std(TotdP_QMax_kW_List))])
disp(['E. Case with Local Load Measuring Algorithm (Turitsyn approach). MEAN: ',num2str(mean(TotdP_Tur_kW_List)),'; STD: ',num2str(std(TotdP_Tur_kW_List))])
disp(['F. Case with Local Flow Measuring Algorithm. MEAN: ',num2str(mean(TotdP_NoCom_kW_List)),'; STD: ',num2str(std(TotdP_NoCom_kW_List))])
fprintf('\n') 

disp('4. LOSS IMPROVEMENTS OF ..')
disp(['Turitsyn algorithm. MEAN: ',num2str(mean(dLos_Tur_base_List)),'; STD: ',num2str(std(dLos_Tur_base_List))])
disp(['Local Flow Measuring Algorithm. MEAN: ',num2str(mean(dLos_NoCom_base_List)),'; STD: ',num2str(std(dLos_NoCom_base_List))])
disp('.. COMPARED TO THE BASE CASE')
fprintf('\n') 

disp('5. CASE WHEN LOCAL FLOW MEASURING ALGORITHM IS THE MOST EFFICIENT THAN TURITSYNS APPROACH')
TotdP_dif_NoCom_Tur = abs(TotdP_Tur_kW_List - TotdP_NoCom_kW_List); % difference between Turitsyn and NoCom algorithm
[Val_MaxDif, Ind_MaxDif] = max(TotdP_dif_NoCom_Tur);
TotdP_Tur_MaxDif = TotdP_Tur_kW_List(Ind_MaxDif);
TotdP_NoCom_MaxDif = TotdP_NoCom_kW_List(Ind_MaxDif);
TotdP_base_MaxDif = TotdP_base_kW_List(Ind_MaxDif);
dLos_Tur_base_MaxDif = 100*(TotdP_base_MaxDif - TotdP_Tur_MaxDif)/TotdP_base_MaxDif;
dLos_NoCom_base_MaxDif = 100*(TotdP_base_MaxDif -TotdP_NoCom_MaxDif)/TotdP_base_MaxDif;
disp(['Power loss decrease by TURITSYN compared with a base case: ',num2str(dLos_Tur_base_MaxDif)])
disp(['Power loss decrease by LOCAL FLOW MEASURING ALGORITHM compared with a base case: ',num2str(dLos_NoCom_base_MaxDif)])
fprintf('\n') 

disp('6. NUMBER OF UNIQUE ACTIVE POWER LOSSES IN')
disp(['A. (BASE CASE) Case with preserved distributed generation and Qg = 0: ',num2str(size(unique(TotdP_base_kW_List),1))])
disp(['B. Case with only one generator which is on a slack bus: ',num2str(size(unique(TotdP_OnlySlackGen_kW_List),1))])
disp(['C. Case with AC OPF (Pg is fixed to PV output; Qg,Va,Vm are control variables): ',num2str(size(unique(TotdP_OPF_kW_List),1))])
disp(['D. Case with QgMax (setting the maximum Qg allowed by limits): ',num2str(size(unique(TotdP_QMax_kW_List),1))])
disp(['E. Case with Local Load Measuring Algorithm (Turitsyn approach): ',num2str(size(unique(TotdP_Tur_kW_List),1))])
disp(['F. Case with Local Flow Measuring Algorithm: ',num2str(size(unique(TotdP_NoCom_kW_List),1))])
fprintf('\n') 

disp('7. NUMBER OF INFEASIBLE SIMULATION RESULTS IN ..')
disp(['A. (BASE CASE) Case with preserved distributed generation and Qg = 0: ',num2str(NInf_base)])
disp(['B. Case with only one generator which is on a slack bus: ',num2str(NInf_OnlySlackGen)])
disp(['C. Case with AC OPF (Pg is fixed to PV output; Qg,Va,Vm are control variables): ',num2str(NInf_OPF)])
disp(['D. Case with QgMax (setting the maximum Qg allowed by limits): ',num2str(NInf_QMax)])
disp(['E. Case with Local Load Measuring Algorithm (Turitsyn approach): ',num2str(NInf_Tur)])
disp(['F. Step 1-A of Local Flow Measuring Algorithm (determine direction of a slack node: ',num2str(NInf_CaseAlgIA)])
disp(['G. Step 2 of Local Flow Measuring Algorithm: ',num2str(NInf_QContrPasFlow)])
disp(['H. Step 3 of Local Flow Measuring Algorithm: ',num2str(NInf_QContrRevFlow)])
fprintf('\n') 

disp('8. ENERGY AND MONETARY SAVINGS (Valid results only if TV=1)')
% Further, we 
% - divide by 1000 to convert from kW to MW. 
% - divide by 60 to convert from minute to hour
% - multiply by DataGran to find area under the power graph

% Data granularity (for TV=1) in min
DataGran = 1; % = 1 if data is minute-wise; = 5, if data is 5-min

% Keep in kWh or MWh
KeepInKWh = 1000; % If want to report in kWh, then KeepInKWh = 1000

% Compute losses
EnergyLosses_base_MWh = KeepInKWh*DataGran*sum(TotdP_base_kW_List)/1000/60; % 
EnergyLosses_OPF_MWh = KeepInKWh*DataGran*sum(TotdP_OPF_kW_List)/1000/60;
EnergyLosses_OPF_Feas_MWh = KeepInKWh*DataGran*sum(TotdP_OPF_Feas_kW_List)/1000/60;
EnergyLosses_OPF_Infeas_MWh = KeepInKWh*DataGran*sum(TotdP_OPF_Infeas_kW_List)/1000/60;
EnergyLosses_Tur_MWh = KeepInKWh*DataGran*sum(TotdP_Tur_kW_List)/1000/60;
EnergyLosses_NoCom_MWh = KeepInKWh*DataGran*sum(TotdP_NoCom_kW_List)/1000/60;
EnergyLosses_HybridLLMA_MWh = KeepInKWh*DataGran*sum(TotdP_HybridLLMA_kW_List)/1000/60;
EnergyLosses_HybridLFMA_MWh = KeepInKWh*DataGran*sum(TotdP_HybridLFMA_kW_List)/1000/60;

EnergyLosses_base_Money = MWh2Money*EnergyLosses_base_MWh; 
EnergyLosses_OPF_Money = MWh2Money*EnergyLosses_OPF_MWh;
EnergyLosses_OPF_Feas_Money = MWh2Money*EnergyLosses_OPF_Feas_MWh;
EnergyLosses_OPF_Infeas_Money = MWh2Money*EnergyLosses_OPF_Infeas_MWh;
EnergyLosses_Tur_Money = MWh2Money*EnergyLosses_Tur_MWh;
EnergyLosses_NoCom_Money = MWh2Money*EnergyLosses_NoCom_MWh;
EnergyLosses_HybridLLMA_Money = MWh2Money*EnergyLosses_HybridLLMA_MWh;
EnergyLosses_HybridLFMA_Money = MWh2Money*EnergyLosses_HybridLFMA_MWh;

disp(['A. (BASE CASE) Case with preserved distributed generation and Qg = 0. MWH: ',...
    num2str(EnergyLosses_base_MWh),'; MONETARY: ',num2str(EnergyLosses_base_Money)])
disp(['B. Case with AC OPF (Pg is fixed to PV output; Qg,Va,Vm are control variables). MWH: ',...
    num2str(EnergyLosses_OPF_MWh),'; MONETARY: ',num2str(EnergyLosses_OPF_Money),'; Savings MONETARY: ',...
    num2str(EnergyLosses_base_Money-EnergyLosses_OPF_Money)])
disp(['C. Case with AC OPF.. (Feasible cases). MWH: ',num2str(EnergyLosses_OPF_Feas_MWh),'; MONETARY: ',...
    num2str(EnergyLosses_OPF_Feas_Money)])
disp(['D. Case with AC OPF.. (Unfeasible cases -> power flow executed). MWH: ',...
    num2str(EnergyLosses_OPF_Infeas_MWh),'; MONETARY: ',num2str(EnergyLosses_OPF_Infeas_Money)])
disp(['E. Case with Local Load Measuring Algorithm (Turitsyn approach). MWH: ',...
    num2str(EnergyLosses_Tur_MWh),'; MONETARY: ',num2str(EnergyLosses_Tur_Money),'; Savings MONETARY: ',...
    num2str(EnergyLosses_base_Money-EnergyLosses_Tur_Money)])
disp(['F. Case with Local Flow Measuring Algorithm. MWH: ',...
    num2str(EnergyLosses_NoCom_MWh),'; MONETARY: ',num2str(EnergyLosses_NoCom_Money),'; Savings MONETARY: ',...
    num2str(EnergyLosses_base_Money-EnergyLosses_NoCom_Money)])
fprintf('\n') 






