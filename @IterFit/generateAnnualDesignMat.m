function  [Aax,Aay]   = generateAnnualDesignMat(IF,Args)

arguments
    IF;
    Args.FakePlx = false;
end
JDbase = (IF.JD - 2457388.5)./365.25;
JDbar_years = (IF.JD-IF.JD0)./365.25;
Aax = [mod(JDbase,1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1)];
Aay = [zeros([IF.Nepoch],1),mod(JDbase,1),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years)];
end