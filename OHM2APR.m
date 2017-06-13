function OHM2APR(inputname,outputname,measnums)
% OHM2APR(inputname,outputname,measnums)
%
% Takes a .ohm file and transforms the measurements given in measnums 
% into a .srv file that can be read by pseudosection.sh
%
% Do not mix different types of arrays. The result will look ugly  
%
% INPUT:
%
% inputname    filename for the .ohm file
% outputname   filename for the .apr file
% measnums     measurement numbers that you want to include  
%
% Last modified by plattner-at-alumni.ethz.ch, 6/13/2017

widthfact=0.5;  
heightfact=0.2;

fin=fopen(inputname,'r');
fout=fopen(outputname,'w');

% Read in number of electrodes
strin=fgets(fin);
red=sscanf(strin,'%d%s');

% Create electrode location matrix
nelec=red(1);
electrodes=nan(nelec,3);

% Skip the next line in the input file
strin=fgetl(fin);

% Read all the electrodes
for counter=1:nelec
    strin=fgets(fin);
    red=sscanf(strin,'%f %f %f');
    electrodes(counter,1)=red(1);
    electrodes(counter,2)=red(2);
    electrodes(counter,3)=red(3);
end

% Now the measurements
strin=fgets(fin);
red=sscanf(strin,'%d%s');
nmeas=red(1);

% Skip a line in the input file
strin=fgetl(fin);

% Create measurements matrix
measurements=nan(nmeas,6);

% measurements:
% A B M N V/I G
% G is the geometry factor

for counter=1:nmeas    
    strin=fgets(fin);
    red=sscanf(strin,'%d %d %d %d %f %f');
    measurements(counter,1:5)=red(1:5);
    AM=norm(electrodes(measurements(counter,1),:) - electrodes(measurements(counter,3),:));
    BM=norm(electrodes(measurements(counter,2),:) - electrodes(measurements(counter,3),:));
    AN=norm(electrodes(measurements(counter,1),:) - electrodes(measurements(counter,4),:));
    BN=norm(electrodes(measurements(counter,2),:) - electrodes(measurements(counter,4),:));
    measurements(counter,6) = (1/AM - 1/BM - 1/AN + 1/BN)/(2*pi); 
    % Apparent resistivity will be V/I * 1/G = V/(I*G)
end    

% Only keep the desired measurement numbers
if nargin>2
  measurements=measurements(measnums,:);
end

% Now prepare writing the boxes
% Comparing injection electrodes with potential electrodes
%AB=sqrt(electrodes(:,1).^2 - electrodes(:,2).^2);
%MN=norm(electrodes(:,3).^2 - electrodes(:,4).^2);
AB=abs(measurements(:,1)-measurements(:,2));
MN=abs(measurements(:,3)-measurements(:,4));
AM=abs(measurements(:,1)-measurements(:,3));
BN=abs(measurements(:,2)-measurements(:,4));
% If injection electrodes further apart, then it's Schlumberger or Wenner
% If they are the same apart, then it's dipole dipole.
% In other case, I'm not sure what to do
% For Schlumberger/Wenner, put it at midpoint between M and N
% For dipole dipole, put it at midpoint between A and N
xpos= (AB > MN).*(measurements(:,3)+measurements(:,4))/2 + ...
      (AB == MN).*((measurements(:,1)+measurements(:,2))/2 + (measurements(:,3)+measurements(:,4))/2)/2;

% For Wenner, the depth is M-N (put the M-N=1 case in Schlumberger)
ypos = (AB>MN & MN>1).*MN + ...
% for Schlumberger, the depth is (AB-1)/2       
       (AB>MN & MN==1).*(AB-1)/2 + ...
% for dipole-dipole, the depth is (A+B/2-M+N/2)-1       
       (AB == MN).*(abs((measurements(:,1)+measurements(:,2))/2 - (measurements(:,3)+measurements(:,4))/2) -1); 

% box width is electrode spacing. Let's do x-axis = electrode number
boxwidths=widthfact*ones(size(measurements,1),1);
boxheights=heightfact*ones(size(measurements,1),1);


dlmwrite(outputname,[xpos,ypos,measurements(:,5)./measurements(:,6),boxwidths,boxheights],'\t')


