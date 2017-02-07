function NMCO = read_nmco(output_file)

fid = fopen(output_file,'r');
if (fid<0)
    error(['Unknown file: ',output_file]);
end

NMCO.nmcb = read_nmcb(output_file,fid);
if isempty(NMCO.nmcb); return; end

nWe = 0;
nWc = 0;
nWt = 0;
NMCO.nCTRL = 0;
NMCO.ncon = 0;

n =  round((NMCO.nmcb.pa.end_time - ...
    NMCO.nmcb.pa.start_time)/NMCO.nmcb.pa.reporting_interval)+1;
unexpectedquit = 0;
%NEURON NUMBER
if (isfield(NMCO.nmcb,'nu'));
    nneu = length(NMCO.nmcb.nu);
end

name = fscanf(fid,'%s',1);

while (strcmp(name,'endoutput')==0);
    if feof(fid)==1; break; end
    switch(name)
        case 'beginsummary';        

            name = fscanf(fid,'%s',1);
            while (strcmp(name,'endsummary')==0);
                switch(name)
                    case 'nDegreesOfFreedom';       ndof = fscanf(fid,'%g',1);  NMCO.ndof = ndof;
                    case 'nBodies';                 nbod = fscanf(fid,'%g',1);  NMCO.nbod = nbod;
                    case 'nActuators';              nmus = fscanf(fid,'%g',1);  NMCO.nmus = nmus;
                    case 'nLockedDOFS';             nlck = fscanf(fid,'%g',1);  NMCO.nlck = nlck;
                    case 'nConstraints';            ncon = fscanf(fid,'%g',1);  NMCO.ncon = ncon;
                    case 'nPointsOfInterest';       npoi = fscanf(fid,'%g',1);  NMCO.npoi = npoi;
                    case 'nStates';                 nst8 = fscanf(fid,'%g',1);  NMCO.nst8 = nst8;
                    case 'nControls';               nCTRL = fscanf(fid,'%g',1); NMCO.nCTRL = nCTRL;
                    case 'nRigidBodyStates';        nrst8 = fscanf(fid,'%g',1); NMCO.nrst8 = nrst8;
                    case 'nRigidBodyControls';      nrCTRL = fscanf(fid,'%g',1);NMCO.nrCTRL = nrCTRL;
                    case 'nActuatorStates';         nmst8 = fscanf(fid,'%g',1); NMCO.nmst8 = nmst8;
                    case 'nActuatorControls';       nmCTRL = fscanf(fid,'%g',1);NMCO.nmCTRL = nmCTRL;
                    case 'nEnvironmentStates';      nest8 = fscanf(fid,'%g',1); NMCO.nest8 = nest8;
                    case 'nEnvironmentControls';    neCTRL = fscanf(fid,'%g',1);NMCO.neCTRL = neCTRL;
                    case 'nNeuronStates';           nnst8 = fscanf(fid,'%g',1); NMCO.nnst8 = nnst8;
                    case 'nNeuronControls';         nnCTRL = fscanf(fid,'%g',1);NMCO.nnCTRL = nnCTRL;
                    case 'DegreesOfFreedom'; 
                        for ii = 1:ndof
                            NMCO.DOF_names{ii} = fscanf(fid,'%s',1);
                        end
                    case 'Actuators';
                        for ii = 1:nmus
                            NMCO.ACTUATOR_names{ii} = fscanf(fid,'%s',1);
                        end
                end
                name = fscanf(fid,'%s',1);
            end

        case 'begindetail';

            name = fscanf(fid,'%s',1);
            iter = 0;
            while (strcmp(name,'enddetail')==0);
                switch(name)
                    case 'Time'; 
                        iter = iter+1;
                        nWc = 0;
                        nWe = 0;
                        nWt = 0;
                        NMCO.time(iter,1) = fscanf(fid,'%e',1);
                    case 'DegreesOfFreedom_pos';
                        NMCO.DOF_position(iter,:) = fscanf(fid,'%e',ndof);
                    case 'DegreesOfFreedom_vel';
                        NMCO.DOF_velocity(iter,:) = fscanf(fid,'%e',ndof);
                    case 'DegreesOfFreedom_acc';
                        NMCO.DOF_acceleration(iter,:) = fscanf(fid,'%e',ndof);
                    case 'Inertia';
                        NMCO.Inertia(iter,:,:) = reshape(fscanf(fid,'%e',ndof*ndof),ndof,ndof);
                    case 'Gravity';
                        NMCO.Gravity(iter,:) = fscanf(fid,'%e',ndof);
                    case 'Coriolis';
                        NMCO.Coriolis(iter,:) = fscanf(fid,'%e',ndof);


                    % READ EXTERNAL FORCES
                    case 'EXJacobian';
                        nWe = nWe +1;
                        NMCO.EXname{iter,nWe}= fscanf(fid,'%s',1);
                        NMCO.EXJacobian{iter,nWe}= reshape(fscanf(fid,'%e',6*ndof),6,ndof);
                    case 'EXJdotQdot';
                        NMCO.EXJdotQdot{iter,nWe}= fscanf(fid,'%e',6);
                    case 'EXWrench';
                        NMCO.EXWrench{iter,nWe}= fscanf(fid,'%e',6);
                    case 'EXPointPosition';
                        NMCO.EXPointPosition{iter,nWe}= fscanf(fid,'%e',3);
                    case 'EXPointVelocity';
                        NMCO.EXPointVelocity{iter,nWe}= fscanf(fid,'%e',3);


                    % READ CONTACTS
                    case 'ContactJacobian';
                        nWt = nWt + 1;
                        NMCO.CTname{iter,nWt}= fscanf(fid,'%s',1);
                        NMCO.CTid{iter,nWt} = fscanf(fid,'%i',4);
                        siz = fscanf(fid,'%i',1);
                        NMCO.CTJacobian{iter,nWt}= reshape(fscanf(fid,'%e',siz*ndof),siz,ndof);
                    case 'ContactJdQdXdd';
                        NMCO.CTJdQdXdd{iter,nWt}= fscanf(fid,'%e',3);
                    case 'ContactForce';
                        NMCO.CTForce{iter,nWt}= fscanf(fid,'%e',3);
                    case 'ContactVelocity';
                        NMCO.CTPointVelocity{iter,nWt}= fscanf(fid,'%e',3);
                    case 'ContactPosition';
                        NMCO.CTPointPosition{iter,nWt}= fscanf(fid,'%e',3);
                    case 'Contact';
                        NMCO.CTTorque{iter,1} = fscanf(fid,'%e',ndof-nlck+ncon);

                    % READ CONSTRAINTS
                    case 'ConstraintJacobian';
                        nWc = nWc +1;
                        NMCO.COname{iter,nWc}= fscanf(fid,'%s',1);
                        siz = fscanf(fid,'%i',1);
                        NMCO.COJacobian{iter,nWc}= reshape(fscanf(fid,'%e',siz*ndof),siz,ndof);
                    case 'ConstraintJdQdXdd';
                        siz = fscanf(fid,'%i',1);
                        NMCO.COJdQdXdd{iter,nWc}= fscanf(fid,'%e',siz);
                    case 'CONPointPosition';
                        NMCO.COPointPosition{iter,nWc}= fscanf(fid,'%e',3);
                    case 'CONPointVelocity';
                        NMCO.COPointVelocity{iter,nWc}= fscanf(fid,'%e',3);
                    case 'CONPointAcceleration';
                        NMCO.COPointAcceleration{iter,nWc}= fscanf(fid,'%e',3);
                    case 'ConstraintWrenches';
                        siz = 0;
                        for ii = 1:nWc
                            siz = siz + length(NMCO.COJdQdXdd{iter,ii});
                        end
%Added next because replay was writing ConstraintWrenches before ConstraintJabobian, where nWc is calculated
                        siz=3;
                        NMCO.COWrench(iter,:) = fscanf(fid,'%e',siz);


                    case 'Mass';
                        NMCO.TotalMass(iter,1)= fscanf(fid,'%e',1);
                    case 'CoMp';
                        NMCO.CoMp(iter,:)= fscanf(fid,'%e',3);
                    case 'CoMv';
                        NMCO.CoMv(iter,:)= fscanf(fid,'%e',3);
                    case 'CoMi';
                        NMCO.CoMi(iter,:)= fscanf(fid,'%e',6);
                    case 'Energy';
                        NMCO.TotalEnergy(iter,1)= fscanf(fid,'%e',1);
                    case 'LinearMomentum';
                        NMCO.LinearMomentum(iter,:)= fscanf(fid,'%e',3);
                    case 'AngularMomentum';
                        NMCO.AngularMomentum(iter,:)= fscanf(fid,'%e',3);

                    case 'MomentArms';
                        if (nmus~=0)
                        NMCO.MomentArms(iter,:,:)= reshape(fscanf(fid,'%e',nmus*ndof),ndof,nmus);
                        end
                    case 'MusculotendonLen';
                        if (nmus~=0)
                        NMCO.MTL(iter,:)= fscanf(fid,'%e',nmus);
                        end
                    case 'MusculotendonVel';
                        if (nmus~=0)
                        NMCO.MTV(iter,:)= fscanf(fid,'%e',nmus);
                        end
                    case 'MuscleForce';
                        if (nmus~=0)
                        NMCO.MuscleForces(iter,:)= fscanf(fid,'%e',nmus);
                        end
                    case 'NeuronOutput';
                        if (nneu~=0)
                        NMCO.NeuronOutput(iter,:)= fscanf(fid,'%e',nneu);
                        end
                    case 'UnlockedDOFS';
                        NMCO.unlockedDOFS(iter,:)= fscanf(fid,'%e',ndof-nlck);
                    case 'Neuron_States';
                        if (nnst8 ~= 0)
                            NMCO.Neuron_States(iter,:) = fscanf(fid,'%e',nnst8);
                        end
                    case 'DNeuron_StatesDT';
                        if (nnst8 ~= 0)
                            NMCO.DNeuron_StatesDT(iter,:)= fscanf(fid,'%e',nnst8);
                        end
                    case 'Muscle_States';
                        if (nmst8 ~= 0)
                            NMCO.Muscle_States(iter,:) = fscanf(fid,'%e',nmst8);
                        end
                    case 'DMuscle_StatesDT';
                        if (nmst8 ~= 0)
                            NMCO.DMuscle_StatesDT(iter,:)= fscanf(fid,'%e',nmst8);
                        end
                    
                    % Linearized part of state matrix
                    case 'DInertiaDQ';
                        NMCO.DInertiaDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^3),ndof-nlck,ndof-nlck,ndof-nlck);
                    case 'DExternalWrenchDQ';
                        NMCO.DExternalWrenchesDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DGravityTorquesDQ';
                        NMCO.DGravityTorquesDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DCoriolisTorquesDQ';
                        NMCO.DCoriolisTorquesDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DCoriolisTorquesDW';
                        NMCO.DCoriolisTorquesDW{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DMomentArmsDQ';
                        NMCO.DMomentArmsDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)*nmus*(ndof-nlck)),ndof-nlck,nmus,ndof-nlck);
                    case 'DMuscleTorquesDQ';
                        NMCO.DMuscleTorquesDQ{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DMuscleTorquesDW';
                        NMCO.DMuscleTorquesDW{iter} = reshape(fscanf(fid,'%e', ...
                            (ndof-nlck)^2),ndof-nlck,ndof-nlck);
                    case 'DConstraintJacobianDQ';
                        NMCO.DCOJacobianDQ{iter} = reshape(fscanf(fid,'%e', ...
                            ncon*(ndof-nlck)^2),ncon,ndof-nlck,ndof-nlck);
                    case 'DConstraintWrenchesDQ';
                        NMCO.DCCOWrenchesDQ{iter} = reshape(fscanf(fid,'%e', ...
                            ncon*(ndof-nlck)),ncon,ndof-nlck);
                    case 'DConstraintWrenchesDW';
                        NMCO.DCOWrenchesDW{iter} = reshape(fscanf(fid,'%e', ...
                            ncon*(ndof-nlck)),ncon,ndof-nlck);
                    case 'beginstatematrix';
                        fscanf(fid,'%s',1);
                        for ii = 1:(nst8-2*nlck)
                            NMCO.StateMatrix(iter,ii,:) = fscanf(fid,'%e',(nst8-2*nlck));
                        end
                end
                [name,readcount] = fscanf(fid,'%s',1);
                if (readcount == 0);     break;    end
            end

        case 'beginsimulationstates';     name = fscanf(fid,'%s',1);
            countstates = 0;
            while 1
                LINE = fgetl(fid);
                if ~ischar(LINE);
                    unexpectedquit = 1;
                    break;
                end
                if strfind(LINE,'endsimulationstates'); break; end
                if strfind(LINE,'CONTACT'); 
                    if ~isfield(NMCO,'contactids')
                        NMCO.contactids = [];
                    end
                    idx = strfind(LINE,'CONTACT')+7;
                    contactids = sscanf(LINE(idx:end),'%e',10)';
                    if length(contactids)==10
                    elseif length(contactids)==7
                        warning('CONTACT read incomplete! Possibly missing vimp, setting vimp to 0')
                        contactids = [contactids 0 0 0];
                    else
                        error(['CONTACT read incomplete! Read "' contactids '"'])
                    end
                    NMCO.contactids = [NMCO.contactids;contactids];
                elseif strfind(LINE,'PAUSE SIMULATION'); 
                    
                end
                states = str2num(LINE);
                if isempty(states); continue; end
                countstates = countstates+1;
                NMCO.time(countstates,1) = states(1);
                NMCO.states(countstates,:) = states(2:1+nst8);
                if nCTRL ~= 0
                    NMCO.controls(countstates,:) = states(2+nst8:end);
                end
            end
    end
    if (unexpectedquit); break; end
    [name,readcount] = fscanf(fid,'%s',1);
    if (readcount == 0);     break;    end
end
fclose(fid);

% if  ( isfield(NMCO,'CTJacobian') )
%     if (size(NMCO.CTJacobian,1) < size(NMCO.time,1))
%         for ii = size(NMCO.CTJacobian,1):size(NMCO.time,1)
%             for jj = 1:size(NMCO.CTJacobian,2)
%                 NMCO.CTJacobian{ii,jj} = [];
%                 NMCO.CTJdotQdotminusXdotdot{ii} = [];
%                 NMCO.CTPointPosition{ii,jj} = [];
%                 NMCO.CTWrenches{ii,jj} = [];
%             end
%         end
%     end
% end

% save([output_file(1:end-5) '.mat'],'NMCO')

