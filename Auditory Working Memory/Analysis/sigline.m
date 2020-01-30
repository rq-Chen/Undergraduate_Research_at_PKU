function sigline(xs,h,nt,lbl)

if nargin==1
    h=gca;
    nt = '*';
    lbl=[];
elseif nargin==2
    nt = '*';
    lbl=[];
elseif nargin==3
    lbl=[];
end
if isnumeric(h)
    y = h;
else
    y = gety(h);
end
% Now plot the sig line on the current axis
hold on
xs=[xs(1);xs(2)];
plot(xs,[1;1]*y*1.1,'-k', 'LineWidth',1.5);%line
text(mean(xs), y*1.11, nt, 'HorizontalAlignment', 'center',...
    'FontSize', 16);% the sig star sign
if lbl
    text(mean(xs)*1.1, y*1.18, lbl)% the sig star sign
end
plot([1;1]*xs(1),[y*1.05,y*1.1],'-k', 'LineWidth',1.5);%left edge drop
plot([1;1]*xs(2),[y*1.05,y*1.1],'-k', 'LineWidth',1.5);%right edge drop
hold off
%--------------------------------------------------------------------------
% Helper function that Returns the largest single value of ydata in a given
% graphic handle. It returns the given value if it is not a graphics
% handle. 
function y=gety(h)
    %Returns the largest single value of ydata in a given graphic handle
    %h= figure,axes,line. Note that y=h if h is not a graphics
    if isgraphics(h) 
        switch(get(h,'type'))
            case {'line','hggroup','patch', 'bar'}
                y=max(get(h,'ydata'));
                return;
            otherwise
                ys=[];
                hs=get(h,'children');
                for n=1:length(hs)
                    ys=[ys,gety(hs(n))];
                end
                y=max(ys(:));
        end
    else
        y=h;
    end
end
end