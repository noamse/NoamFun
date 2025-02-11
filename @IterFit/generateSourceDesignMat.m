function  [Asx,Asy]   = generateSourceDesignMat(IF,Args)

arguments
    IF;
    Args.Plx = true;
    Args.FakePlx = false;
end
JDbar_years = (IF.JD-IF.JD0)./365.25;
if Args.Plx
    %Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1),IF.PlxTerms(:,1)];
    %Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),JDbar_years,IF.PlxTerms(:,2)];
    Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1),IF.PlxTerms(:,1)];
    Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,IF.PlxTerms(:,2)];
    if Args.FakePlx 
        Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1),IF.PlxTerms(:,1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1)];
        Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,IF.PlxTerms(:,2),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years)];
    end
elseif Args.FakePlx 
  
   Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years),zeros([IF.Nepoch],1),zeros([IF.Nepoch],1)];
   Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1),zeros([IF.Nepoch],1),sin(2*pi.*JDbar_years),cos(2*pi.*JDbar_years)];

else
    %Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1)];
    %Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0];
    Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years,zeros([IF.Nepoch],1)];
    Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),JDbar_years];
end

end