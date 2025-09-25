function url = eventWebPath(ev)
%KMTEVENTURL Build KMTNet ULENS event URL from event code.
%   URL = KMTEVENTURL(EV) returns the URL for event code EV, where EV has
%   the form xx#### (e.g., 210087 => year 2021, event 0087).
%
%   Example:
%     kmtEventUrl(210087)
%     % -> https://kmtnet.kasi.re.kr/ulens/event/2021/view.php?event=KMT-2021-BLG-0087

    % Normalize the event code to a 6-digit string
    if isnumeric(ev)
        evStr = sprintf('%06d', ev);
    elseif isstring(ev) || ischar(ev)
        evStr = char(ev);
        evStr = regexprep(evStr, '\s+', '');
    else
        error('EV must be numeric, char, or string.');
    end

    % Extract year and event number
    yy   = evStr(1:2);                 % '21'
    year = 2000 + str2double(yy);      % 2021
    num4 = evStr(3:6);                 % '0087'

    % Construct URL (always uses BLG)
    url = sprintf('https://kmtnet.kasi.re.kr/ulens/event/%d/view.php?event=KMT-%d-BLG-%s', ...
                  year, year, num4);
end