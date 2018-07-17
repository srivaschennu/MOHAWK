function line_h = plotarc3d(pts,ht,color,linewidth)
%plots arc from p(1) to p(2) at height h

pts = cat(1,mean(pts([1 2],:),1), pts);
pts(1,:) = pts(1,:) .* ht;

% hobbysplines({pts(1,:),pts(2,:),pts(3,:)},'linestyle',{'linewidth',linewidth},'color',color,'tension',2)
% scatter3(pts(:,1),pts(:,2),pts(:,3),50,'filled');
% line_h = [];

t = pts(3,:)-pts(1,:); u = pts(2,:)-pts(1,:); v = pts(2,:)-pts(3,:);
w = cross(t,u);
t2 = sum(t.^2); u2 = sum(u.^2); w2 = sum(w.^2);
c = pts(1,:)+(t2*sum(u.*v)*u-u2*sum(t.*v)*t)/(2*w2); % <-- The center
r = 1/2*sqrt(t2*u2*sum(v.^2)/w2); % <-- The radius
a = pts(2,:)-c; a = a/norm(a);
b = cross(w,a); b = b/norm(b);
n = 100;
ang = linspace(0,mod(atan2(dot(pts(3,:)-c,b),dot(pts(3,:)-c,a)),2*pi),n).';
T = bsxfun(@plus,r*(cos(ang)*a+sin(ang)*b),c);

% The plot of the circular arc from p(2) to p(3)
line_h = plot3(T(:,1),T(:,2),T(:,3));

set(line_h,'Color',color,'LineWidth',linewidth);