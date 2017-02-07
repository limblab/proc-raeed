function nmcb = read_nmcb(varargin)
%nmcb = read_nmcb(filename) reads the Neuromechanic model FILENAME into the
%structure NMCB:
%       cu: cuves - struct array of (name, curve)
%       vw: views - struct array of viewpoint (see manual)
%       pa: parameters - integration and reporting parameters
%      bod: bodies - struct array of (name, parentbody, location, mass,
%                         centerofmass, inertia, tDOF, rDOF, marker)
%       en: environment - GV (gravity Vector), pe (perturbation struct)
%       ms: muscles - struct array of (name, model, max_force, oiv,
%                         oivsegment, gaussrender, activation,
%                         optimal_fiber_length, tendon_slack_length,
%                         damping, pennation, timescale, hillparameters,
%                         state, activeforcelength, passiveforcelength,
%                         tendonforcelength, motorneuron)
%     nuin: []
%       nu: neurons - struct array of (name, type, synapses, bound)
%       eq: equilibration - struct of (Q, C, LBMIN,LB,UBMAX,UB,XOTAR,XO)
%
%nmcb = read_nmcb(filename,fid) reads from file descriptor FID, rather than
%opening FILENAME

body_file = varargin{1};
if nargin == 1
    fid = fopen(body_file,'r');
    if (fid<0)
        error(['Unknown file: ',body_file]);
    end
    nmcb = BodyFileReader(fid);
    fclose(fid);
else
    fid = varargin{2};
    nmcb = BodyFileReader(fid);
end
if ~isempty(nmcb)
    nmcb.pa.body_file = body_file;
end


%% BodyFileReader =======================================================
function nmcb = BodyFileReader(fid)
     nmcb = [];
%     isokk = 1;
    name = fscanf(fid,'%s',1);
    outflags = {'DegreesOfFreedom_pos' 'DegreesOfFreedom_vel' 'DegreesOfFreedom_acc' ...
        'Inertia' 'Gravity' 'Coriolis' 'External_Forces' 'Constraints' 'CoM' ...
        'Energy' 'Momentum' 'MomentArms' 'MusculotendonLen' 'MusculotendonVel' ...
        'MuscleForce' 'NeuronOutput' 'Muscle_States' 'Neuron_States'};


    while (strcmpi(name,'endbodyfileinput')==0);
        switch lower(strtok(name))
            case 'beginview'
                nmcb = ReadView(fid,nmcb);
            case 'beginparameters'
                nmcb = ReadParameters(fid,nmcb,outflags);
            case 'beginsplines'
                nmcb = ReadSplines(fid,nmcb);
            case 'beginrigidbodies'
                nmcb = readrigidbodies(fid,nmcb);
            case 'beginattach'
                nmcb = ReadAttach(fid,nmcb);
            case 'beginmuscles'
                nmcb = ReadMuscles(fid,nmcb);
            case 'beginneurons'
                nmcb = ReadNeurons(fid,nmcb);
            case 'beginenvironment'
                nmcb = ReadEnvironment(fid,nmcb);
            case 'beginequilibrate'
                nmcb = ReadEquilibrate(fid,nmcb);
            case 'beginlocomotion'
                if exist('nmcb_lcmt','file')==2
                    nmcb = nmcb_lcmt(fid,0,nmcb);
                end
            otherwise   %comment or unrecognized symbol
        end
        if feof(fid)==1; break; end
        name = fscanf(fid,'%s',1);
    end

% BodyFileReader =======================================================
%% ReadView =======================================================
function nmcb = ReadView(fid,nmcb)
%Reads the view element into NMCB. 
    name = ' ';
    %Valid view elements:
    nms = {'view' 'spline' 'eye' 'center' 'up' 'znf' 'fovy' 'ortholim' 'orthorot'};
    %data type for each element
    nmtyp = {'%i' '%s' '%e' '%e' '%e' '%e' '%e' '%e' '%e'};
    %number of data expected for each element
    nmid = [1 1 3 3 3 2 1 6 16];
    nmcb.vw = [];
    while (strcmpi(name,'endview')==0);
        %The view element may contain either a single set of parameters
        %named as in nms...
        idx = find(strcmpi(nms,name));
        if ~isempty(idx)
            nmcb.vw.(name) = fscanf(fid,nmtyp{idx},nmid(idx));
        end
        %Or multiple sets with each distinguished by a single char (ie:
        %(view1, eye1, center1, up1)
        idx = find(strcmpi(nms,name(1:end-1)));
        if ~isempty(find(strcmpi(nms,name(1:end-1)),1))
            nmcb.vw.(name) = fscanf(fid,nmtyp{idx},nmid(idx));
        end
        
        name = fscanf(fid,'%s',1);         
    end
    
% ReadView =======================================================
%% ReadParameters =======================================================
function nmcb = ReadParameters(fid,nmcb,outflags)
%ReadParameters reads the parameters block.  This has the form
%   beginparameters
%       [parametername] [optionalvalue]
%   endparameters

    name = fscanf(fid,'%s',1);
    if name(1)=='-'  %separator at the end of beginparameters
        name=fscanf(fid, '%s', 1);
    end
    nmcb.pa.out = [];
    while (strcmpi(name,'endparameters')==0);
        
        % If the input line matches a parameterless outflag, set the flag
        idx = find(strcmpi(outflags,name));
        if idx
            nmcb.pa.out.(outflags{idx}) = 1;
        
        elseif strcmpi(name, 'numint') %numint method requires string value
            nmcb.pa.(name) = fscanf(fid, '%s', 1);
        else
        %All other parameters have to read a value from the file
            nmcb.pa.(name) = fscanf(fid, '%e', 1);
        end
        name = fscanf(fid,'%s',1); 
    end
% ReadParameters =======================================================
%% ReadSplines =======================================================
function nmcb = ReadSplines(fid,nmcb)
%ReadSplines reads curve data from the nmcb. This section has the form
% beginsplines
%    beginspline splinename  splinedimension
%           x-data y-data
%           ...
%    endspline
%    beginspline...
% endsplines

    name = fscanf(fid,'%s',1);
    count = 0;
    while (strcmpi(name,'endsplines')==0);
        if strcmpi(name,'beginspline')
            count = count+1;
            nmcb.cu(count).name = fscanf(fid,'%s',1);
            num = fscanf(fid,'%i',1);%number of independent variables
            nmcb.cu(count).curve = [];
%            L = strtrim(fgetl(fid));
            L=fscanf(fid, '%s', 1);
            while (strcmpi(L, 'endspline')==0)
                switch lower(L)
                    case 'splinetype'
%                        nmcb.cu(count).type = sscanf(name(11:end),'%i');
                        nmcb.cu(count).type = fscanf(fid,'%i', 1);
                    case {'constraint1', 'constraint2'}
%                         nmcb.cu(count).(lower(strtok(L))) = sscanf(L(12:end),'%e',num);
                         nmcb.cu(count).(lower(L)) = fscanf(fid,'%e',num);
                    case 'alpha'
%                        nmcb.cu(count).alpha = sscanf(L(6:end),'%e',10);
                        nmcb.cu(count).alpha = fscanf(fid,'%e',10);
                    otherwise
%                        [a, numread] = sscanf(L, '%e', num+1);
                        a=str2double(L);
                            a = [a fscanf(fid, '%e', num)];
%                        if (numread == num+1)
                            nmcb.cu(count).curve = [nmcb.cu(count).curve; a];
%                        end
                end %switch lower(strtok(L))
%                L = strtrim(fgetl(fid));
                L=fscanf(fid, '%s', 1);
            end %while (strcmpi(strtok(L), 'endspline')==0)
        end  %if strcmpi(name,'beginspline')
        name = fscanf(fid,'%s',1); 
    end  %while (strcmpi(name,'endsplines')==0);
% ReadSplines =======================================================
% ReadAttach =======================================================
function nmcb = ReadAttach(fid,nmcb)
%Reads geometry/surface attachments
    name = ' ';
    ip = 0;
    while (strcmpi(name,'endattach')==0);
        if strcmpi(name,  'beginpolygons');
            ip = ip + 1;
            nmcb.at.poly(ip).name = fscanf(fid,'%s',1);
            while (strcmpi(name,'endpolygons')==0);
                switch lower(name)
                    case 'body'
                        nmcb.at.poly(ip).body = fscanf(fid,'%s',1);
                    case  'file'
                        nmcb.at.poly(ip).file = fgetl(fid);
                    case  'align'
                        nmcb.at.poly(ip).align = fscanf(fid,'%e',6);
                end
                name = fscanf(fid,'%s',1); 
            end  %while ~endpolygons
        end  %if  'beginpolygons'

        name = fscanf(fid,'%s',1); 
        if ~ischar(name); break; end%seems useless
        
    end    
% ReadAttach =======================================================
% ReadMuscles =======================================================
function nmcb = ReadMuscles(fid,nmcb)
%read ms module.  These look like
%         beginmuscle [name] [type]
%              max_force  [P0] 
%              beginattachments
%                     [x] [y] [z] [segment]
%              endattachments
%              gaussrender  [p1] [p2] [p3] 
%              activation  [p1] [p2] 
%              optimal_fiber_length  [Lo]
%              tendon_slack_length  [Lt]
%              damping  [p1] 
%              pennation  [q] 
%              timescale  [p1]
%              hillparameters  [p1] [p2] [p3]
%              state  [p1] ... [pn depending on type]
%              activeforce-length [curve.name]
%              passiveforce-length [curve.name]
%              tendonforce-length [curve.name]
%              motorneuron [nu.name]
%         endmuscle [optional name]

    name = lower(fscanf(fid,'%s',1));
    ii = 0;
    iw = 0;
    while (strcmpi(name,'endmuscles')==0);
        if strcmpi(name,  'beginwrap');
            iw = iw + 1;
            nmcb.wr(iw).name = fscanf(fid,'%s',1);
            nmcb.wr(iw).type = fscanf(fid,'%s',1);
            nmcb.wr(iw).bod = fscanf(fid,'%s',1);
            while (strcmpi(name,'endwrap')==0);
                nmcb.wr(iw).(lower(name)) = fscanf(fid,'%e',3);
                name = fscanf(fid,'%s',1); 
            end
        elseif strcmpi(name,  'beginmuscle');
            ii = ii + 1;
            nmcb.ms(ii).name = fscanf(fid,'%s',1);
            nmcb.ms(ii).model = fscanf(fid,'%s',1);
            while (strcmpi(name,'endmuscle')==0);
                switch name
                    case {'max_force',  'optimal_fiber_length',  'tendon_slack_length',...
                            'damping',  'pennation',  'sheath',  'torque_output',...
                            'timescale'}
                        nmcb.ms(ii).(name) = fscanf(fid,'%e',1);
                    case 'activation'
                        nmcb.ms(ii).activation = fscanf(fid,'%e',2);
                    case {'gaussrender',  'hillparameters'}
                        nmcb.ms(ii).(name) = fscanf(fid,'%e',3);
                    case  'state'
                        switch lower(nmcb.ms(ii).model)
                            case 'zajacnoact'
                                
                            case {'zajac','schuttenoact','schuttenoactspline'}
                                nmcb.ms(ii).state = fscanf(fid,'%e',1);
                            case {'schutte','schuttespline'}
                                nmcb.ms(ii).state = fscanf(fid,'%e',2);
                        end
                    case 'beginattachments'
                        jj = 0;
                        name = fscanf(fid,'%e',1);
                        while ~isempty(name);
                            jj = jj+1;
                            nmcb.ms(ii).oiv(jj,1) = name;
                            nmcb.ms(ii).oiv(jj,2:3) = fscanf(fid,'%e',2);
                            nmcb.ms(ii).oivsegment{jj} = fscanf(fid,'%s',1);
                            name = fscanf(fid,'%e',1);
                        end
                    case 'motorneuron'
                        nmcb.ms(ii).motorneuron = fscanf(fid,'%s',1);
                    case {'functions',  'activeforce-length',  'passiveforce-length',...
                            'force-velocity',  'velocity-force',  'tendonforce-length'}
                        nmcb.ms(ii).(name(name>='a' & name<='z')) = strtrim(fgetl(fid));
                end
                name = lower(fscanf(fid,'%s',1)); 
            end
        end
    name = fscanf(fid,'%s',1); 
    end    
% ReadMuscles =======================================================
% ReadNeurons =======================================================
function nmcb = ReadNeurons(fid,nmcb)
%Read the neuron structure.  These look like
% beginneurons
% beginneuron [name] [type]
%      beginsynapses
%           [type:constant/fiberlength/etc] [name] [parameterlist] 
%      endsynapses
%      bound  [lower] [upper]
%      [state]  [value]
%      [controlstate]   [value]
% endneuron
 
    ii = 0;
    name = fscanf(fid,'%s',1);
    nmcb.nuin = [];
    while (strcmpi(name,'endneurons')==0);
        switch lower(name)
            case 'circuitinput'
                nmcb.nuin{end+1} = ['     circuitinput ' fgetl(fid)];
            case 'circuitpoint'
                nmcb.nuin{end+1} = ['     circuitpoint ' fgetl(fid)];
            case 'beginneuron'
                ii = ii + 1;
                nmcb.nu(ii).name = fscanf(fid,'%s',1);
                nmcb.nu(ii).type = fscanf(fid,'%s',1);
                name = fscanf(fid,'%s',1);
                while (strcmpi(name,'endneuron')==0);
                    switch lower(name)
                        case 'controlstate'
                            nmcb.nu(ii).controlstate = fscanf(fid,'%i');
                        case  'state'
                            nmcb.nu(ii).state = fscanf(fid,'%e');
                        case 'bound'
                            nmcb.nu(ii).bound = fscanf(fid,'%e',2);
                        case 'beginsynapses'
                            jj = 0;
                            type = fscanf(fid,'%s',1);
                            while (strcmpi(type,'endsynapses')==0);
                                jj = jj +1;
                                nmcb.nu(ii).synapses(jj).type = type;
                                LINE = fgetl(fid);
                                if (isempty(LINE))
                                    nmcb.nu(ii).synapses(jj).name = [];
                                    nmcb.nu(ii).synapses(jj).parms = [];
                                else
                                    [synname, val] = strtok(LINE);
                                    nmcb.nu(ii).synapses(jj).name = synname;
                                    nmcb.nu(ii).synapses(jj).parms = str2num(val);
                                end
                                type = fscanf(fid,'%s',1);
                            end %while endsynapses
                    end %switch (endneuron)
                    name = fscanf(fid,'%s',1);
                end %while endneuron
        end
        name = fscanf(fid,'%s',1);
    end %while endneurons
% ReadNeurons =======================================================
%% ReadEnvironment =======================================================
function nmcb = ReadEnvironment(fid,nmcb)
    ii = 0;
    kk = 0;
    name = ' ';
    while (strcmpi(name,'endenvironment')==0);
        switch lower(name)
            case  'contactmodel'
                nmcb.en.contactmodel = fscanf(fid,'%s',1);
            case {'frictioncoef',  'stiffness',  'viscosity',  'impulsetau'}
                nmcb.en.(name) = fscanf(fid,'%e',1)';
            case 'gravity_vector'
                nmcb.en.GV = fscanf(fid,'%e',3)';
            
            case 'beginperturbation'
                ii = ii + 1;
                nmcb.en.pe(ii).name = fscanf(fid,'%s',1);
                nmcb.en.pe(ii).type = [fscanf(fid,'%s',1) ' ' fscanf(fid,'%s',1)];
                while (strcmpi(name,'endperturbation')==0);
                    if strcmpi(name,  'dimension');
                        bcdm = fscanf(fid,'%e',1);

                        if bcdm == 3
                            nmcb.en.pe(ii).dimension = eye(3);
                        else
                            nmcb.en.pe(ii).dimension(1:bcdm,1:3) = 0;
                            for jj = 1:bcdm
                                nmcb.en.pe(ii).dimension(jj,1:3) = fscanf(fid,'%e',3)';
                            end
                        end

                    elseif strcmpi(name,  'location');
                        nmcb.en.pe(ii).poi = fscanf(fid,'%e',3)';
                        body2 = fgetl(fid);
                        [~,n] = sscanf(body2,'%s',5);
                        [nmcb.en.pe(ii).body] = sscanf(body2,'%s',1);
                        if n>1
                            body2idx = strfind(body2,nmcb.en.pe(ii).body) ...
                                + length(nmcb.en.pe(ii).body);
                            [nmcb.en.pe(ii).body2] = ...
                                sscanf(body2(body2idx+1:end),'%s',1);
                        end
                    elseif strcmpi(name,  'lock');
                        nmcb.en.pe(ii).lock = strtrim(fgetl(fid));
                    elseif strcmpi(name,  'wrench');
                        nmcb.en.pe(ii).wrench = fscanf(fid,'%e',3)';
                    elseif strcmpi(name,  'spline');
                        nmcb.en.pe(ii).spline = fscanf(fid,'%s',1);
                        nmcb.en.pe(ii).direction_FOR = fscanf(fid,'%s',1);
                        LINE = strtrim(fgetl(fid)); % READ REST OF LINE
                        nmcb.en.pe(ii).splineparams = sscanf(LINE,'%e')';
                    elseif strcmpi(name,  'beginparameters');
                        strtrim(fgetl(fid)); % READ REST OF LINE
                        fscanf(fid,'%s',1);
                        nmcb.en.pe(ii).direction = fscanf(fid,'%e',3)';
                        nmcb.en.pe(ii).direction_FOR = fscanf(fid,'%s',1);
                        strtrim(fgetl(fid)); % READ REST OF LINE

                        jj = 0;
                        while 1;
                            jj = jj +1;
                            LINE = fscanf(fid,'%e',3);
                            if isempty(LINE); break; end
                            nmcb.en.pe(ii).params(jj,:) = LINE;
                            strtrim(fgetl(fid)); % READ REST OF LINE
                        end
                    end
                    name = fscanf(fid,'%s',1);
                end %while endperturbation

            case 'begincontacts'   %This is ugly, but I don't have a contact file to validate fixes
                while (1);
                    kk = kk + 1;
                    name = fscanf(fid,'%s',1);
                    if (strcmpi(name,'endcontacts')); break; end;
                    nmcb.en.co(kk).type = name;
                    nmcb.en.co(kk).body = fscanf(fid,'%s',1);
                    nmcb.en.co(kk).name = fscanf(fid,'%s',1);
                    name = strtrim(fgetl(fid)); % READ REST OF LINE
                    if ~ischar(name); break; end
                    lngth = length(nmcb.en.co(kk).name);
                    nmcb.en.co(kk).ellps = [];
                    if (length(name)~=lngth)
                        nmcb.en.co(kk).ellps = sscanf(strtrim(name),'%e',9);
                    end;
                end

        end %switch (name)
        
        name = fscanf(fid,'%s',1); 
        if ~ischar(name); break; end  %This line appears frequently, and
                                      %seems to serve no purpose. ie: 
                                      %ischar(fscanf( ,'%s', )) is always true
                
    end

% ReadEnvironment =======================================================
%% ReadEquilibrate =======================================================
function nmcb = ReadEquilibrate(fid,nmcb)
    
    if isfield(nmcb,'ms')
        nmus = size(nmcb.ms,2);
    else
        nmus = 0;
    end
    name = ' ';
    while (strcmpi(name,'endequilibrate')==0);
            
        if strcmpi(name,  'Q')
            eqtype = fscanf(fid,'%s',1);
            switch upper(eqtype)
                case 'EYE'
                    nmcb.eq.Q = eye(nmus);
                case '-EYE'
                    nmcb.eq.Q = -eye(nmus);
                case {'FMAX','-FMAX','FMAX2','-FMAX2'}
                    nmcb.eq.Q =upper(name);
                otherwise
                    jj = str2num(eqtype);
                    if (jj == 1)
                        nmcb.eq.Q = ones(nmus);
                        val=  fscanf(fid,'%e',1);
                    else
                        nmcb.eq.Q = reshape(fscanf(fid,'%e',jj*jj),jj,jj);
                    end
            end %switch eqtype

        elseif strcmpi(name,  'C')
            jj = fscanf(fid,'%i',1);
            if (jj == 1);                     val=  fscanf(fid,'%e',1); 
                nmcb.eq.C = val*ones(nmus,1);
            else
                nmcb.eq.C = fscanf(fid,'%e',jj);
            end

        elseif strcmpi(name,  'LB')
            eqtype = fscanf(fid,'%s',1);
            if (strcmpi(eqtype,'EXCITATION'))
                nmcb.eq.LBMIN = 'EXCITATION';
            elseif (strcmpi(eqtype,'FORCE'))
                nmcb.eq.LBMIN = 'FORCE';
            else
                warning('Unable to interpret BEGINEQUILIBRATE section (LB)');
            end
            jj = fscanf(fid,'%i',1);
            if (jj == 1);                     val=  fscanf(fid,'%e',1); 
                nmcb.eq.LB = val*ones(nmus,1);
            else
                nmcb.eq.LB = fscanf(fid,'%e',jj);
            end

        elseif strcmpi(name,  'UB')
            eqtype = fscanf(fid,'%s',1);
            if (strcmpi(eqtype,'EXCITATION'))
                nmcb.eq.UBMAX = 'EXCITATION';
            elseif (strcmpi(eqtype,'FORCE'))
                nmcb.eq.UBMAX = 'FORCE';
            else
                warning('Unable to interpret BEGINEQUILIBRATE section (UB)');
            end
            jj = fscanf(fid,'%i',1);
            if (jj == 1);
                val=  fscanf(fid,'%e',1); 
                nmcb.eq.UB = val*ones(nmus,1);
            else
                nmcb.eq.UB = fscanf(fid,'%e',jj);
            end 

        elseif strcmpi(name,  'X0')
            eqtype = fscanf(fid,'%s',1);
            if (strcmpi(eqtype,'EXCITATION'))
                nmcb.eq.X0TAR = 'EXCITATION';
            elseif (strcmpi(eqtype,'FORCE'))
                nmcb.eq.X0TAR = 'FORCE';
            else
                warning('Unable to interpret BEGINEQUILIBRATE section (X0)');
            end
            jj = fscanf(fid,'%i',1);
            if (jj == 1);                     val=  fscanf(fid,'%e',1); 
                nmcb.eq.X0 = val*ones(nmus,1);
            else
                nmcb.eq.X0 = fscanf(fid,'%e',jj);
            end 
        end
        name = fscanf(fid,'%s',1); 
        
    end
% ReadEquilibrate =======================================================
%% ReadRigidBodies =======================================================
function nmcb = readrigidbodies(fid,nmcb)
    ii = 0;
    name = fscanf(fid,'%s',1);    
    while (strcmpi(name,'endrigidbodies')==0);
        if (strcmpi(name, 'beginbody'));
            tj = 0;
            rj = 0;
            ii = ii + 1;
            nmcb.bod(ii).name = fscanf(fid,'%s',1);
            name = fscanf(fid,'%s',1);
            while (strcmpi(name,'endbody')==0);
                switch lower(name)
                    case {'parentbody',  'limbtype'}
                        nmcb.bod(ii).(name) = fscanf(fid,'%s',1);
                    case 'mass'
                        nmcb.bod(ii).mass = fscanf(fid,'%e',1);
                    case {'centerofmass',  'location'}
                        nmcb.bod(ii).(name) = fscanf(fid,'%e',3)';
                    case 'polygons'
                        nmcb.bod(ii).polygons = strtrim(fgetl(fid));
                    case {'polygonalign',  'inertia'}
                        nmcb.bod(ii).(name) = fscanf(fid,'%e',6);
                    case  'begin_tdof'
                        tj = tj + 1;
                        np = 0;
                        nmcb.bod(ii).tDOF(tj).name = fscanf(fid,'%s',1);
                        while (strcmpi(name,'end_DOF')==0);
                            switch lower(name)
                                case 'axis'
                                    nmcb.bod(ii).tDOF(tj).axis = fscanf(fid,'%e',3)';
    %                         elseif (strcmpi(name, 'range');
    %                             nmcb.bod(ii).tDOF(tj).range = fscanf(fid,'%e',2);
                                case 'state'
                                    nmcb.bod(ii).tDOF(tj).state = fscanf(fid,'%e',2);
                                case {'pullratio', 'locked'}
                                    nmcb.bod(ii).tDOF(tj).(name) = fscanf(fid,'%s',1);
                                case 'posture'
                                    np = np + 1;
                                    nmcb.bod(ii).tDOF(tj).posture(np).name = fscanf(fid,'%s',1);
                                    nmcb.bod(ii).tDOF(tj).posture(np).state = fscanf(fid,'%e',2);
                            end %swtich tDOF
                            name = fscanf(fid,'%s',1); 
                        end %while end_DOF (tDOF)
                    case 'begin_rdof'
                        rj = rj + 1;
                        np = 0;
                        nmcb.bod(ii).rDOF(rj).name = fscanf(fid,'%s',1);
                        while (strcmpi(name,'end_DOF')==0);
                            if (strcmpi(name, 'axis'));
                                nmcb.bod(ii).rDOF(rj).axis = fscanf(fid,'%e',3)';
                            elseif (strcmpi(name, 'state'));
                                nmcb.bod(ii).rDOF(rj).state = fscanf(fid,'%e',2);
    %                         elseif (strcmpi(name, 'range'));
    %                             nmcb.bod(ii).rDOF(rj).range = fscanf(fid,'%e',2);
                            elseif (strcmpi(name, 'pullratio'));
                                nmcb.bod(ii).rDOF(rj).pullratio = fscanf(fid,'%e',1);
                            elseif (strcmpi(name, 'locked'));
                                nmcb.bod(ii).rDOF(rj).locked = fscanf(fid,'%s',1);
                            elseif (strcmpi(name, 'posture'));
                                np = np + 1;
                                nmcb.bod(ii).rDOF(rj).posture(np).name = fscanf(fid,'%s',1);
                                nmcb.bod(ii).rDOF(rj).posture(np).state = fscanf(fid,'%e',2);
                            end
                            name = fscanf(fid,'%s',1); 
                        end
                
                    case 'marker'
                        LINE = strtrim(fgetl(fid));
                        if ~isfield(nmcb.bod(ii),'marker');
                            nmcb.bod(ii).marker = [];
                        end
                        jj = length(nmcb.bod(ii).marker) + 1;
                        markername = strtrim(sscanf(LINE,'%s',1));
                        LINE = LINE(length(markername)+1:end);
                        nmcb.bod(ii).marker(jj).name = markername;
                        nmcb.bod(ii).marker(jj).location = str2num(LINE);
                    
                end
                name = fscanf(fid,'%s',1);
            end
        end
        name = fscanf(fid,'%s',1);
    end
% ReadRigidBodies =======================================================
