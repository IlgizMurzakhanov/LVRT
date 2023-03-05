function [CaseA,ISG,NGen,NPV] = fGenProc(CaseA,GM,NSendGen,INL,PL,NBus)
% Processing generation. 

% Two cases: modifying the case file by randomly placing PVs or not.
if GM == 1 % if randomly place PVs, then ..
    % Deleting all generators and their costs except a slack bus (assume it goes first)
    CaseA.gen(2:end,:) = [];
    CaseA.gencost(2:end,:) = [];
    
    % duplicating the slack generator data to the rest sender generators
    for i = 2:NSendGen+1 % the generator of a slack node should stay
        CaseA.gen(i,:) = CaseA.gen(1,:);
    end

    % Random choice of generators
    INL_copy = INL; % created copy, cause repeated elements are deletec
    for i = 1:NSendGen
       ind = randperm(numel(INL_copy), 1); % select one element out of numel(x) elements, with the probability of occurrence of the element in x
       r(i) = INL_copy(ind);
       INL_copy(INL_copy==r(i)) = []; % delete this element from the sample, such that the picked elements are unique
    end

    % Changing generation on randomly chosen nodes
    ISG = transpose(r); % index of sender generators

    Pg_SG = sum(PL)/NSendGen; % sum of all P loads
    Sg_SG = Pg_SG;
%     Qg_max_SG = sqrt(Sg_SG^2 - Pg_SG^2);

    for i = 1:NSendGen 
        id_SG = ISG(i); % value from ISG
        id_SG_gen = find(CaseA.gen(:,1) == id_SG); % corresponding line in gen
        CaseA.gen(i,1) = id_SG; % Correct ID of gens
        CaseA.gen(i,2) = Pg_SG; % Pg of bus
        CaseA.gen(i,9) = Pg_SG; % Pg_max
        CaseA.gen(i,10) = Pg_SG; % Pg_min
        CaseA.gen(i,4) = Pg_SG; % Qg_max
        CaseA.gen(i,5) = -Pg_SG; % Qg_min
    end

    % Setting all costs equal to the provided one => dP minimimization 
    for i = 2:NSendGen+1 % the generator of reference node should stay
        CaseA.gencost(i,:) = CaseA.gencost(1,:);
    end

    % Changing type of a bus in CaseA.bus
    for i = 2:NBus % assuming bus 1 is slack
        if ismember(i,ISG) % checking if the specific bus ID is in ISG list 
            CaseA.bus(i,2) = 2; % if yes, mark it as type 2 - PV bus
        else
            CaseA.bus(i,2) = 1; % otherwise, type 1 - PQ bus
        end
    end
    
    % Flipping CaseA upside down so that slack node is in the first line.
    % This is needed only for GM=1 case
    CaseA.gen = flipud(CaseA.gen);
    
else % we operate within the original case
    ISG = CaseA.gen(2:end,1);
    CaseA.gen(2:end,2) = CaseA.gen(2:end,4); % setting Pg to Pg_max
end

NGen = size(CaseA.gen,1); % number of generators including slack bus
NPV = NGen - 1; % number of PVs. Assume there are no conventional gens

% Checking Pg and Qg limits, and re-assigning Pg limits if they are lower
% than Qg (this is a case for original Akirkeby system)
for i = 2:NGen
    if CaseA.gen(i,4) > CaseA.gen(i,9)  % if Qg_max > Pg_max
        CaseA.gen(i,9) = CaseA.gen(i,4); % then Pg_max = Qg_max
    end
end

end

