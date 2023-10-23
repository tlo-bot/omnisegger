function info = cellprops5( mask, props )
% cellprops5 : Calculates the shape properties of a region or 'cell'.
% This are used later to calculate the score of a region.
%
% INPUT :
%       mask : cell / region mask
%       props : properties generated by regionprops

% OUTPUT :
%         info = [L1 : long axis of the region
%             L2mean : mean of the short axis
%             Lneck : neck width
%             L2max : short axis max
%             L2v : variance of the short axis
%             s1 : <width sin pi s/S >
%             s2 : <width sin pi 2s/S >
%             s3 : <width sin pi 3s/S >
%             RoundIndOver :
%             RoundIndUnder,
%             Area,
%             stm1 : max dtheta^2
%             sa1 : <theta sin pi s/2S >
%             sa2 : <theta sin pi s/S >
%             sa3 : <theta sin pi 3s/2S >
%             sa4 : <theta sin pi 2s/S >
%             1/L1 : 1 / long axis
%             1/L2mean : 1 / mean of short axis
%             minWidthEnd : Min End Width 
%             sqmin : round end min
%             sqmax : round end max];
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

debug = false;

% Calculate cell thickness and length by rotating the
% region based on the angle of the majorAxis.
Orientation = props.Orientation;

imRot = imrotate( mask, -Orientation+90);
ss = size(imRot);

if debug
    figure(2);
    clf;
    imshow(cat(3,ag(imRot)+0.5*ag(~imRot),ag(imRot),ag(imRot)),'InitialMagnification','fit');
    hold on;
end

width = sum(double(imRot),2); % array of long axis length, per y direction
ymask = (width>=1); % 0 if no cell along x-dimension, 1 if there is
widthWindow = ([0;width(1:end-1)] + width + [width(2:end);0] )/3;
% width in y-before + width in current y + width in y after /3

L1          = sum(ymask);
L2max       = max(widthWindow);
L2v         = var(widthWindow);

ymin = find(ymask,1,'first');
ymax = find(ymask,1,'last');


ind = (ymin):(ymax);
L2mean = mean(width(ind));
if L2mean<1
    L2mean=1;
end

% Sine Cosine Idea
nn = (numel(ind)-1);
s  = 2*pi*(0:nn)/nn;

s1 = mean(width(ind)'.*sin(s*0.5));
s2 = mean(width(ind)'.*sin(s));
s3 = mean(width(ind)'.*sin(s*1.5));


% Calculate the neck width
if numel(widthWindow) > 6;
    ww       = widthWindow';
    v        = ww(3:end)-ww(1:end-2);
    s_change = logical([0, sign(v(2:end))-sign(v(1:end-1)),0,0]);
    s_change(2:end) = logical(s_change(2:end)+s_change(1:end-1));
    ind = find(s_change);
    ind_ = ind(logical((ind>3).*(ind<(numel(ww)-2))));
    
    if isempty(ind_)
        Lneck = L2mean;
        pos = mean([ymin,ymax]);
    else
        [Lneck,pos] = min( ww(ind_) );
        pos = ind_(pos);
    end
else
    Lneck = L2mean;
    pos = mean([ymin,ymax]);
end

if Lneck > L2mean
    Lneck = L2mean;
    pos = mean([ymin,ymax]);
end

if debug
    xx = 1:numel(ww);    
    figure(1);
    clf;
    plot( xx, ww, '.-' );
    hold on;
    plot( pos+0*x,x, 'r:' );
    plot( xx(ind_), ww(ind_), 'g.' );
    figure(2)
end

% make stuff w/o rotating
if abs(tan( props.Orientation*pi/180 )) > 1
    yunr = sum(mask,2)';
else
    yunr = sum(mask);
end

ip = find( logical(yunr), 1, 'last' );
im = find( logical(yunr), 1, 'first' );


% thin ends
im = find( logical(yunr), 1, 'first' );
ip = find( logical(yunr), 1, 'last' );

if ip-im >= 3
    m1 = mean( yunr(im+[ 0, 1]) );
    m4 = mean( yunr(ip+[-1, 0]) );
    minWidthEnd = min(m1,m4);
else
    minWidthEnd = L2mean;
end



% Square ends
if ip-im >= 7
    m2 = mean( yunr(im+[ 2, 3]) );
    m3 = mean( yunr(ip+[-3,-2]) );
    
    sq1 = m2-m1;
    sq2 = m3-m4;
    
    sqmax = max(sq1,sq2);
    sqmin = min(sq1,sq2);
else
    sqmax = 0;
    sqmin = 0;
end



% Calculate the maximum bend angle.
dr  = 3;
dr2 = 3;
yy = (ymin+dr):dr2:(ymax-dr);

if numel(yy) > 4
    tmp = imRot(yy,:);
    x = 1:ss(2);    
    [X,Y] = meshgrid(x,yy);
    
    xx = sum( X.*tmp,2 )./sum(tmp,2);   
    d1 = [xx(1:end-2)-xx(3:end),yy(1:end-2)'-yy(3:end)'];    
    dangle = ((d1(1:end-2,1).*d1(3:end,2)...
        -d1(1:end-2,2).*d1(3:end,1))./...
        (norm2(d1(1:end-2,:)).*norm2(d1(3:end,:))));
    
    stm1 = max( dangle.^2 );    
    angle = cumsum(dangle)';
    na = numel(angle)-1;
    
    s = (0:na)/na*pi/2;
    
    try
        sa1 = mean( angle.*sin(s  ) );
        sa2 = mean( angle.*sin(s*2) );
        sa3 = mean( angle.*sin(s*3) );
        sa4 = mean( angle.*sin(s*4) );
    catch ME
        printError(ME)
    end
    
    
    if debug
        ss_ = size(d1);
        for ii = 1:ss_(1)
            plot( xx(ii)+[0,-d1(ii,1)], yy(ii)+[0,-d1(ii,2)], 'c.' );
        end
    end
    
    
    % Calculate the end score
    yy = [(ymin+dr),(ymax-dr)];
    xx = widthWindow(round(yy));
    r = ((xx)/2);
    r(r<1)=1;
    
    yyd = [(ymin+r(1)+[-1,0,1]),(ymax-r(2)+[-1,0,1])];
    yy  = round(yyd);
    
    [X] = meshgrid(x,yy);
    
    tmp = imRot(yy,:);
    xx = sum( X.*tmp,2 )./sum(tmp,2);
    xx = [mean(xx(1:3)),mean(xx(4:6))];
    yyd = yyd([2,5]);
    
    
    if debug
        phi = 0:.1:2*pi;
        
        plot(xx,yyd,'go');
        xxx = r(1)*cos(phi);
        yyy = r(1)*sin(phi);
        plot(xx(1)+xxx,yy(1)+yyy,'g:')
        
        xxx = r(2)*cos(phi);
        yyy = r(2)*sin(phi);
        plot(xx(2)+xxx,yyd(2)+yyy,'g:')
        
        plot( [1,ss(2)],[ymax,ymax],':r')
        plot( [1,ss(2)],[ymin,ymin],':r')
        
    end
    
    xcen = xx;
    ycen = yyd;
    
    x0 = xcen(1);
    y0 = ycen(1);
    r0 = r(1);
    
    yy = max(1,round(y0-r0-2)):min(round(y0+r0+2),ss(1));
    xx = max(1,round(x0-r0-2)):min(round(x0+r0+2),ss(2));
    
    [X,Y] = meshgrid(xx,yy);
    tmp = imRot(yy,xx);
    
    R2 = (X-x0).^2 + (Y-y0).^2 - r0^2;
    
    ind_over = find( ((R2 > 0).*tmp).*(d1(1,1)*(X-x0) + d1(1,2)*(Y-y0) > 0));
    ind_under = find( ((R2 < 0).*(tmp<1)).*(d1(1,1)*(X-x0) + d1(1,2)*(Y-y0) > 0));
    
    
    if debug
        plot(X(ind_over),Y(ind_over),'r.');
        plot(X(ind_under),Y(ind_under),'b.');
    end
    
    RoundIndOverTop  = sum( tmp(ind_over).*R2(ind_over))/r0^4;
    RoundIndUnderTop = sum( (1-tmp(ind_under)).*abs(R2(ind_under)))/r0^4;
    
    x0 = xcen(2);
    y0 = ycen(2);
    r0 = r(2);
    
    yy = max(1,round(y0-r0-2)):min(round(y0+r0+2),ss(1));
    xx = max(1,round(x0-r0-2)):min(round(x0+r0+2),ss(2));
    
    [X,Y] = meshgrid(xx,yy);
    tmp = imRot(yy,xx);
    
    R2 = (X-x0).^2 + (Y-y0).^2 - r0^2;
    
    ind_over = find( ((R2 > 0).*tmp).*(d1(1,1)*(X-x0) + d1(1,2)*(Y-y0) < 0));
    ind_under = find( ((R2 < 0).*(tmp<1)).*(d1(1,1)*(X-x0) + d1(1,2)*(Y-y0) < 0));
    
    if debug
        plot(X(ind_over),Y(ind_over),'r.');
        plot(X(ind_under),Y(ind_under),'b.');
    end
    
    
    RoundIndOverBot  = sum( tmp(ind_over).*R2(ind_over))/r0^4;
    RoundIndUnderBot = sum( (1-tmp(ind_under)).*abs(R2(ind_under)))/r0^4;
    
else
    %'fail'
    stm1 = 0;
    sa1 = 0;
    sa2 = 0;
    sa3 = 0;
    sa4 = 0;
    RoundIndOverTop  = 0;
    RoundIndUnderTop = 0;
    RoundIndOverBot  = 0;
    RoundIndUnderBot = 0;
end

RoundIndOver  = RoundIndOverTop  + RoundIndOverBot;
RoundIndUnder = RoundIndUnderTop + RoundIndUnderBot;

if L1 < 1
    L1 = 1;
end


info = [L1, ...
    L2mean, ...
    Lneck, ...
    L2max, ...
    L2v, ...
    s1, ...
    s2, ...
    s3, ...
    RoundIndOver, ...
    RoundIndUnder, ...
    props.Area, ....
    stm1, ...
    sa1, ...
    sa2, ...
    sa3, ...
    sa4, ...
    1/L1, ...
    1/L2mean,...
    minWidthEnd,...
    sqmin,...
    sqmax];

info(isnan(info)) = 0;

if debug
    drawnow;
    keyboard;
end

end

function tmp = norm2( dd )

tmp = sqrt(sum(dd.*dd,2));

end