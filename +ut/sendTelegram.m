function sendTelegram(msg)
    bot_token = '8133686636:AAHUEuL9g_G1_UIdGRY2MFWBhK9cH8GhoWg'; % MOVE TO ENV VARS ASAP
    chat_id   = '7700572066';

    url = sprintf('https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s', ...
        bot_token, chat_id, urlencode(msg));

    opts = weboptions('Timeout', 30);   % was 5
    try
        webread(url, opts);
    catch ME
        warning('sendTelegram failed (ignored): %s', ME.message);
    end
end
