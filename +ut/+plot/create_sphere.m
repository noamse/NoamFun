function [fig,h] = create_sphere(n,r)
% Plot transparent sphere and return the axes.
% 
%     Input:  n- number of faces to plot
%             
%             r- sphere radius
%             
%             
% call : [ax] = ut.plot.create_sphere(20,1)

[x,y,z] = sphere(n);
fig=figure;
h= surfl(x.*r, y.*r, z.*r);
set(h, 'FaceAlpha', 0.0,'LineStyle','--','EdgeAlpha',0.2,'AlphaData',0.2,'MarkerEdgeColor',[0.9,0.9,0.9])
%shading interp
end