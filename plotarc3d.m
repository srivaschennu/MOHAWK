function line_h = plotarc3d(pts,ht,color,linewidth)

% Copyright (C) 2018 Srivas Chennu, University of Kent and University of Cambrige,
% srivas@gmail.com
% 
% 
% plots arc from vertex p(1) to vertex p(2) at height h, in the specified
% colour and at the specified width.
% 
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.



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