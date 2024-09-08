function  [Asx,Asy]   = generateSourceDesignMat(SA,Args)

arguments
    SA;
    Args.Plx = true;
end
JDbar_years = (SA.JD-SA.JD0)./365.25;
if Args.Plx
   % Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1),IF.PlxTerms(:,1)];
   % Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,IF.PlxTerms(:,2)];
   Asx = [ones([numel(SA.JD)],1),zeros(numel(SA.JD),1),JDbar_years,zeros(numel(SA.JD),1),SA.PlxTerms(:,1)];
   Asy = [zeros(numel(SA.JD),1),ones(numel(SA.JD),1),zeros(numel(SA.JD),1),JDbar_years,SA.PlxTerms(:,2)];
else
    % Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1)];
    % Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0];
    Asx = [ones(numel(SA.JD),1),zeros(numel(SA.JD),1),JDbar_years,zeros(numel(SA.JD),1)];
    Asy = [zeros(numel(SA.JD),1),ones(numel(SA.JD),1),zeros(numel(SA.JD),1),JDbar_years];
end

end