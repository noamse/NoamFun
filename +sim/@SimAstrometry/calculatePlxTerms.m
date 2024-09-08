function    [PlxX,PlxY] = calculatePlxTerms(SA,Args)

arguments
    SA;
    Args.Coo = [4.6273,-0.4646];

end
    [Ecoo] = celestial.SolarSys.calc_vsop87(SA.JD, 'Earth', 'e', 'E');
   
    
    X = Ecoo(1,:)'; Y = Ecoo(2,:)'; Z = Ecoo(3,:)';
    
    RA = Args.Coo(1);
    Dec = Args.Coo(2);
    %PlxX= -1/400 * (X.*sin(RA)- Y.*cos(RA)); 
    %PlxY= 1/400 * (X.*cos(RA).*sin(RA) + Y.*sin(RA).*sin(Dec) - Z.*cos(Dec)); 
    PlxX= 1/SA.mas2pix * (X.*sin(RA)- Y.*cos(RA)); 
    PlxY= 1/SA.mas2pix * (-X.*cos(RA).*sin(RA) - Y.*sin(RA).*sin(Dec) + Z.*cos(Dec)); 
end
