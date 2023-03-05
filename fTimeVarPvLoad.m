function [PV_coef_TV,Wind_coef_TV,Load_coef_TV,NTimePoints,PV_coef_forecast,PV_coef_current,...
    Wind_coef_forecast,Wind_coef_current,P_load_coef,Q_load_coef] = fTimeVarPvLoad(TV,Period,Sc,Sc_case,Sc_fct)
% Varying PV and load from SYSLAB system data && scenario file

% if TV == 1 && Sc == 0
if TV == 1
   % loading saved variables  
   PV_Load = load('Pgen_PL_pu_2019.mat');
   PV_coef_raw = PV_Load.PV_715_5min_pu_arr; % time-varying Pg
   Load_coef_raw = PV_Load.PL_715_5min_abs_pu_arr; % time-varying PL, QL(same coeff)
   
   PV_coef_forecast = 0;
   PV_coef_current = 0;
   Wind_coef_forecast = 0;
   Wind_coef_current = 0;
   
   P_load_coef = 0;
   Q_load_coef = 0;
   
   if Period == 1
       %% Choosing short period for test purposes
       PV_coef_TV = PV_coef_raw(52189:52190);
       Wind_coef_TV = PV_coef_TV; % for long scenarios (Transactions paper, assume all RES are PV)
       Load_coef_TV = Load_coef_raw(52189:52190);     
       NTimePoints = size(PV_coef_TV,1); % number of data points of changing Pg and load  
   end
   
   if Period == 12
       %% Choosing one day to display difference of algorithms' work
       % 16 June 04:00:00 - 16:00:00
%        Pg_coef_TV = PG_coef_raw(52189:52477);
%        Load_coef = Load_coef_raw(52189:52477);       
       PV_coef_TV = PV_coef_raw(52189:52289);
       Wind_coef_TV = PV_coef_TV; % for long scenarios (Transactions paper, assume all RES are PV)
       Load_coef_TV = Load_coef_raw(52189:52289);      
       NTimePoints = size(PV_coef_TV,1); % number of data points of changing Pg and load  
   end

   if Period == 24
       %% this the first day 03:00 - 19:30 in Garima's forecasting
       sc_data = readtable('pv_wind_demand_pu.csv'); 
       PV_coef_TV = sc_data{1:991,3}; 
       Wind_coef_TV = sc_data{1:991,5};
       Load_coef_TV = sc_data{1:991,6};
       NTimePoints = size(PV_coef_TV,1); % number of data points of changing Pg and load  
   end

   if Period == 25
       %% the first full day in Garima's forecasting
        pv_data = readtable('PvFullDayForecast.csv'); 
        wind_data = readtable('WindFullDayForecast.csv');
        demand_data = readtable('DemandFullDayForecast.csv');
        
        % PV: kW -> p.u.
        PV_kW = pv_data{1:1438,2}; 
        PV_kW_max = max(PV_kW);
        PV_pu = PV_kW/10; % capacity as reported by Garima
        PV_coef_TV = PV_pu;
        
        % Wind: kW -> p.u.
        Wind_kW = wind_data{1:1438,3};
        Wind_kW_max = max(Wind_kW);
        Wind_pu = Wind_kW/10; % capacity as reported by Garima
        Wind_coef_TV = Wind_pu;
        
        % Load: kW -> p.u.
        Load_kW = demand_data{332643:334080,9};
        Load_kW_abs = abs(Load_kW);
        Load_kW_max = max(Load_kW_abs);
        % Load_pu = Load_kW_abs/Load_kW_max;
        Load_pu = Load_kW_abs/0.7;
        Load_coef_TV = Load_pu;
        
        NTimePoints = size(PV_coef_TV,1); 
   end
   
   if Period == 365
       %% Choosing the whole year time interval
       % Let's first make Pg_coef_TV and Load_coef of the same size
       Length_min = min(length(PV_coef_raw),length(Load_coef_raw));
       % and then let's concatenate
       PV_Load_coef = horzcat(PV_coef_raw(1:Length_min),Load_coef_raw(1:Length_min));
       % Let's delete lines containing NaN for running of runpf
       PV_Load_coef(any(isnan(PV_Load_coef), 2), :) = [];
       % Let's delete lines with zero PV output
%        PG_Load_coef( ~any(PG_Load_coef(:,1),2), :) = [];
       % Finally let's assign generation and load coefficients
       PV_coef_TV = PV_Load_coef(:,1);
       Wind_coef_TV = PV_coef_TV; % for long scenarios (Transactions paper, assume all RES are PV)
       Load_coef_TV = PV_Load_coef(:,2);
       NTimePoints = size(PV_coef_TV,1); % number of data points of changing Pg and load  
   end
   
% elseif TV == 1 && Sc == 1
elseif Sc == 1
%     sc_data = readtable('pv_wind_demand_pu_8scenarios.csv');
%     sc_data = readtable('pv_wind_demand_pu_4scenarios.csv');
%     sc_data = readtable('pv_wind_demand_pu.csv'); 
    sc_data = readtable('pv_wind_demand_pu_WorkingScenario.csv');
    NTimePoints = size(Sc_case,1); % number of scenarios for check
    for i = 1:NTimePoints
        case_i = Sc_case(i,1);

        % Keep both forecast and current coefficients for PV and wind
        PV_coef_current = sc_data{case_i,3};
        Wind_coef_current = sc_data{case_i,5};
        
        if Sc_fct == 1
            PV_coef_forecast = sc_data{case_i,2};
            Wind_coef_forecast = sc_data{case_i,4};
        elseif Sc_fct == 0 % if don't use forecast, then keep coefficients from present
            PV_coef_forecast = sc_data{case_i,3};
            Wind_coef_forecast = sc_data{case_i,5};
        end
                
        P_load_coef = sc_data{case_i,6};
        Q_load_coef = sc_data{case_i,7};
    end 
        
    PV_coef_TV = 0; % for scenarios, we don't use Pg_coef_TV
    Wind_coef_TV = 0; 
    Load_coef_TV = 0; % for scenarios, we have P/Q loads, so don't use Load_coef
        
   
else % no time-variying Pg and load
   PV_coef_TV = 1; % not changing
   Wind_coef_TV = 1; 
   Load_coef_TV = 1; % not changing
   NTimePoints = 1; % just one time simulation
   
   PV_coef_forecast = 0;
   PV_coef_current = 0;
   Wind_coef_forecast = 0;
   Wind_coef_current =0;
   
   P_load_coef = 0;
   Q_load_coef = 0;
end

end

