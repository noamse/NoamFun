function  [Asx,Asy]   = generateSourceDesignMat(IF,Args)

arguments
    IF;
    Args.Plx = true;
end

if Args.Plx
%      Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1),IF.PlxTerms(:,1)];
%      Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,IF.PlxTerms(:,2)];
   Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1),IF.PlxTerms(:,1)];
   Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),IF.JD-IF.JD0,IF.PlxTerms(:,2)];
else
%     Asx = [ones([IF.Nepoch],1)+ IF.ParE(1,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1)];
%     Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1) + IF.ParE(5,:)',zeros([IF.Nepoch],1),IF.JD-IF.JD0];
    Asx = [ones([IF.Nepoch],1),zeros([IF.Nepoch],1),IF.JD-IF.JD0,zeros([IF.Nepoch],1)];
    Asy = [zeros([IF.Nepoch],1),ones([IF.Nepoch],1),zeros([IF.Nepoch],1),IF.JD-IF.JD0];
end

end