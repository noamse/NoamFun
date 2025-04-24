function  [Aax,Aay]   = generateAnnualDesignMat(IF,Args)

arguments
    IF;
    Args.FakePlx = false;
end
%JDbase = (IF.JD - 2457388.5)./365.25;
%JDbar_years = (IF.JD-IF.JD0)./365.25;
dt = datetime(IF.JD, 'convertfrom', 'juliandate');
yearD = year(dt); % Get the year
year_start = juliandate(datetime(yearD,1,1));  % JD at the start of the year
year_end = juliandate(datetime(yearD+1,1,1));  % JD at the start of next year
JDphase = (IF.JD - year_start) ./ (year_end - year_start);
JDphase=JDphase-0.5;
%Aax = [mod(JDbase,1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1)];
%Aay = [zeros([IF.Nepoch],1),mod(JDbase,1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years)];
%Aax = [sin(2*pi.*JDphase).^2,cos(2*pi.*JDphase).^2,sin(2*pi.*JDphase),cos(2*pi.*JDphase),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1)];
%Aay = [zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),sin(2*pi.*JDphase),cos(2*pi.*JDphase),sin(2*pi.*JDphase).^2,cos(2*pi.*JDphase).^2];
Aax = [ones(size(JDphase)),JDphase,JDphase.^2,JDphase.^3,JDphase.^4,zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase))];
Aay = [zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase)),zeros(size(JDphase)),ones(size(JDphase)),JDphase,JDphase.^2,JDphase.^3,JDphase.^4];


end