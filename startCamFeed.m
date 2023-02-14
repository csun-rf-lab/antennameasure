function [anechoicCam,cam] = startCamFeed(app)    
    anechoicCam = ipcam('rtsp://anechoic.csun.edu:554/streaming/channels/3', 'admin', 'CSUNanechoic','Timeout',60);
    hImage = image(app.UIAxes,zeros(360,640,3));
    app.UIAxes.XLim = [0,640];
    app.UIAxes.YLim = [0,360];
    app.UIAxes.XTick = [];
    app.UIAxes.YTick = [];
    pbaspect(app.UIAxes,[640,360,1]);
    app.UIAxes.Position = [0 0 640 360];
    cam = preview(anechoicCam,hImage);
    pause(3600)
end