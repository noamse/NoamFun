function Res = convertRes(ResSt, IndSt, epsSTrackField, epsETrackField)
% convertRes Extracts data from a specified element of the ResSt structure array.
%
%   Res1 = convertRes(ResSt, IndSt, epsSTrackField, epsETrackField) creates a
%   structure Res1 that contains data extracted from ResSt(IndSt). The function
%   processes the following fields:
%
%       - RMSTrack       (unchanged)
%       - epsSTrackField (specified by the user, e.g., 'epsSTrack1' or 'epsSTrack2')
%       - epsETrackField (specified by the user, e.g., 'epsETrack1' or 'epsETrack2')
%
%   The output structure Res1 will have the fields:
%       RMSAll, X0track, Y0track, Xpmtrack, Ypmtrack, a1, a2, a3, a4, a5, a6.
%
% Example:
%   IndSt = 7;
%   Res1 = convertRes(ResSt, IndSt, 'epsSTrack1', 'epsETrack1');
%
%   This will extract the data from ResSt(7).RMSTrack, ResSt(7).epsSTrack1, and
%   ResSt(7).epsETrack1.
%

    % Validate the index
    if IndSt < 1 || IndSt > numel(ResSt)
        error('IndSt is out of bounds.');
    end

    % Process the RMSTrack field (assuming each cell contains at least one column)
    %Res1.RMSAll = cell2mat(cellfun(@(x) x(:,1), ResSt(IndSt).RMSTrack, 'UniformOutput', false));
    
    % Process the epsSTrack field using the user-specified field name
    Res.X0track  = cell2mat(cellfun(@(x) x(1,:)', ResSt(IndSt).(epsSTrackField), 'UniformOutput', false));
    Res.Y0track  = cell2mat(cellfun(@(x) x(2,:)', ResSt(IndSt).(epsSTrackField), 'UniformOutput', false));
    Res.Xpmtrack = cell2mat(cellfun(@(x) x(3,:)', ResSt(IndSt).(epsSTrackField), 'UniformOutput', false));
    Res.Ypmtrack = cell2mat(cellfun(@(x) x(4,:)', ResSt(IndSt).(epsSTrackField), 'UniformOutput', false));

    % Process the epsETrack field using the user-specified field name
    Res.a1 = cell2mat(cellfun(@(x) x(1,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
    Res.a2 = cell2mat(cellfun(@(x) x(2,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
    Res.a3 = cell2mat(cellfun(@(x) x(3,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
    Res.a4 = cell2mat(cellfun(@(x) x(4,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
    Res.a5 = cell2mat(cellfun(@(x) x(5,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
    Res.a6 = cell2mat(cellfun(@(x) x(6,:)', ResSt(IndSt).(epsETrackField), 'UniformOutput', false));
end