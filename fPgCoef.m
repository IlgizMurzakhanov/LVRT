function [CaseA0] = fPgCoef(CaseA,NTimePoints,Pg_coef_det,PV_coef_TV,Wind_coef_TV,Load_coef_TV,...
            iPoint,Q_avail,TgFiLimInv,NGen,PV_idx,Wind_idx,PV_coef_forecast,PV_coef_current,...
            Wind_coef_forecast,Wind_coef_current,P_load_coef,Q_load_coef,Sc,GridOfNigHour)
        
% Deriving PL,QL values, Pg, Qg limits for both deterministic and
% time-varying cases

CaseA0 = CaseA; % each time taking "preserved" CaseA 

%% All Sc==0 / Sc==1 parts combined
if Sc == 0
    
    % Define Pg_coef
    if NTimePoints == 1 % if it is a deterministic case
        PV_coef = Pg_coef_det; % then we use Pg_coef_det coefficient
        Wind_coef = Pg_coef_det;
    else % if it is a time-varying case
        Wind_coef = Wind_coef_TV(iPoint);
        PV_coef = PV_coef_TV(iPoint);
        if GridOfNigHour == 1
%             if iPoint < 184 % if it is night hour (between 03:00-06:00 for Garima's dataset)
            if iPoint < 300 || iPoint > 1200 % if it is night hour (between 20:00-05:00 for Garima's full day dataset)
                PV_coef = 0; % then no generation in PV: Pg=0, Qg=0
            end
        end
    end
    
    % Defining Qg limits for PV
    CaseA0.gen(PV_idx,4) = Q_avail*CaseA0.gen(PV_idx,9)*min(PV_coef*TgFiLimInv, sqrt(1-PV_coef^2));
    % Defining Qg limits for Wind turbine
    if Wind_coef <= 0.4
        Wind_QgMax = 1;
    elseif (0.4 < Wind_coef) && (Wind_coef < 1)
        Wind_QgMax = -5/6*Wind_coef + 4/3;
    elseif Wind_coef == 1
        Wind_QgMax = 0.5;
    end
    
    CaseA0.gen(Wind_idx,4) = Q_avail*CaseA0.gen(Wind_idx,9)*Wind_QgMax;
    
    % Pg limits AFTER applying PV_coef and Wind_coef for all gens EXCEPT slack bus
    CaseA0.gen(PV_idx,2) = PV_coef*CaseA0.gen(PV_idx,9); %PV
    CaseA0.gen(Wind_idx,2) = Wind_coef*CaseA0.gen(Wind_idx,9); %PV
    
    % Time varying load
    CaseA0.bus(:,3) = Load_coef_TV(iPoint)*CaseA.bus(:,3);  %PL
    CaseA0.bus(:,4) = Load_coef_TV(iPoint)*CaseA.bus(:,4);  %QL
    
elseif Sc == 1
    
    % Defining Qg limits for forecasted and current PV_Pg_coef
    PV_QgMax_forecast = Q_avail*CaseA0.gen(PV_idx,9)*min(PV_coef_forecast*TgFiLimInv, sqrt(1-PV_coef_forecast^2));
    PV_QgMax_current = Q_avail*CaseA0.gen(PV_idx,9)*min(PV_coef_current*TgFiLimInv, sqrt(1-PV_coef_current^2));
    % We take maximum Qg: if forecast is greater, then move to it.
    % Otherwise stick to current
    CaseA0.gen(PV_idx,4) = max(PV_QgMax_forecast, PV_QgMax_current); 
    
    % For Wind turbine, we follow a specific PQ diagram with approximation.
    % Forecast
    if Wind_coef_forecast <= 0.4
        Wind_QgMax_forecast = 1;
    elseif (0.4 < Wind_coef_forecast) && ( Wind_coef_forecast < 1)
        Wind_QgMax_forecast = -5/6*Wind_coef_forecast + 4/3;
    elseif Wind_coef_forecast == 1
        Wind_QgMax_forecast = 0.5;
    end
    
    % Current
    if Wind_coef_current <= 0.4
        Wind_QgMax_current = 1;
    elseif (0.4 < Wind_coef_current) && (Wind_coef_current < 1)
        Wind_QgMax_current = -5/6*Wind_coef_current + 4/3;
    elseif Wind_coef_current == 1
        Wind_QgMax_current = 0.5;
    end
    
    % Choosing the maximum value
    CaseA0.gen(Wind_idx,4) = Q_avail*CaseA0.gen(Wind_idx,9)*max(Wind_QgMax_forecast, Wind_QgMax_current);
    
    % Time varying load
    CaseA0.bus(:,3) = P_load_coef(iPoint)*CaseA.bus(:,3);  %PL
    CaseA0.bus(:,4) = Q_load_coef(iPoint)*CaseA.bus(:,4);  %QL
    
    % Pg limits AFTER applying Pg_coef for all gens EXCEPT slack bus
    CaseA0.gen(PV_idx,2) = PV_coef_current*CaseA0.gen(PV_idx,9); %Pg PV
    CaseA0.gen(Wind_idx,2) = Wind_coef_current*CaseA0.gen(Wind_idx,9); %Pg wind
end  
    
% Common for any type: Qg_min = - Qg_max
CaseA0.gen(:,5) = -CaseA0.gen(:,4);
% Qg = 0 (default value)
CaseA0.gen(:,3) = 0;

% With below two lines commented, gen columns 9 and 10 display Pg_max limits 
% WITHOUT multiplication by Pg_coef, or same as S_inverter_max. So Pg^2 +
% Qg^2 <= column 9
CaseA0.gen(2:NGen,9) = CaseA0.gen(2:NGen,2); %Pg_max 
CaseA0.gen(2:NGen,10) = CaseA0.gen(2:NGen,2); %Pg_min. We assume that don't curtail it

end

