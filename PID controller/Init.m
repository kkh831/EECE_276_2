clc;
clear;

%% Graphic Option
quadGraphics(1).diffuseColor =	[1.0 1.0 1.0];
quadGraphics(1).specularColer =	[0.7 0.7 0.7 1.0];
quadGraphics(1).ambientColor =	[0.5 0.5 0.5 1.0];
quadGraphics(1).emissiveColor =	[0.0 0.0 0.0 1.0];
quadGraphics(1).shininess =     100;

quadGraphics(2).diffuseColor =	[1.0 1.0 1.0];
quadGraphics(2).specularColer =	[0.7 0.7 0.7 1.0];
quadGraphics(2).ambientColor =	[0.5 0.5 0.5 1.0];
quadGraphics(2).emissiveColor =	[0.0 0.0 0.0 1.0];
quadGraphics(2).shininess =     100;

quadGraphics(3).diffuseColor =	[1.0 1.0 1.0];
quadGraphics(3).specularColer =	[0.7 0.7 0.7 1.0];
quadGraphics(3).ambientColor =	[0.5 0.5 0.5 1.0];
quadGraphics(3).emissiveColor =	[0.0 0.0 0.0 1.0];
quadGraphics(3).shininess =     100;

quadGraphics(4).diffuseColor =	[1.0 1.0 1.0];
quadGraphics(4).specularColer =	[0.7 0.7 0.7 1.0];
quadGraphics(4).ambientColor =	[0.5 0.5 0.5 1.0];
quadGraphics(4).emissiveColor =	[0.0 0.0 0.0 1.0];
quadGraphics(4).shininess =     100;


rotorColorOpacity =             0.0;
rotorGraphics(1).color =        [1.0 0.0 0.0];
rotorGraphics(1).opacity =      rotorColorOpacity;
rotorGraphics(2).color =        [1.0 0.5 0.0];
rotorGraphics(2).opacity =      rotorColorOpacity;
rotorGraphics(3).color =        [1.0 1.0 0.0];
rotorGraphics(3).opacity =      rotorColorOpacity;
rotorGraphics(4).color =        [0.0 1.0 0.0];
rotorGraphics(4).opacity =      rotorColorOpacity;


%% Initial Condition
quad(1).initialPosition = [0.0 0.0 0.0];
quad(2).initialPosition = [-0.8 0.0 0.0];
quad(3).initialPosition = [0.0 0.8 0.0];
quad(4).initialPosition = [0.0 -0.8 0.0];


%% Formation
formation(1,:) = [0.0; 0.0; 0.0];
formation(2,:) = [-1.0; 0.0; 0.0];
formation(3,:) = [cosd(60); sind(60); 0.0];
formation(4,:) = [cosd(60); -sind(60); 0.0];

formationGraphics.size =    18;
formationGraphics.color =   [0.8 0.0 1.0];
formationGraphics.opacity = 0.3;

actualGraphics.size =    18;
actualGraphics.color =   [1.0 0.2 0.2];
actualGraphics.opacity = 0.5;


%% Randomize
quadDefault.mass = 0.44;
quadDefault.inertia = [0.001421219 0.001560811 0.002674212];
quadDefault.actuator.p2r = [-0.006748, 20.71, 828.8];
quadDefault.actuator.sr = 0.05826;
quadDefault.actuator.sf = 0.07999;
quadDefault.actuator.kt = 9.168e-9;
quadDefault.actuator.kp = 1.166e-10;




SEED = 20191118;

rng(SEED);

for i = 1:4
    quad(i).mass = quadDefault.mass;% * normrnd(1, 0.01);
    quad(i).inertia = quadDefault.inertia;% .* normrnd(1, 0.01, 1, 3);

    for j = 1:4
        quad(i).actuator(j).p2r = quadDefault.actuator.p2r;% .* [normrnd(1, 0.0001) normrnd(1, 0.0001) normrnd(1, 0.01)];
        quad(i).actuator(j).sr = quadDefault.actuator.sr;% * normrnd(1, 0.03);
        quad(i).actuator(j).sf = quadDefault.actuator.sf;% * normrnd(1, 0.03);
        quad(i).actuator(j).kt = quadDefault.actuator.kt;% * normrnd(1, 0.03);
        quad(i).actuator(j).kp = quadDefault.actuator.kp;% * normrnd(1, 0.03);
    end
end



%% Path Generator
% time, x, y, z, psi

PIXEL2METER = 1/77;

load('Path_x');     % x_saved_buffer
load('Path_y');     % y_saved_buffer

Path_x = (x_saved_buffer - x_saved_buffer(1)) * PIXEL2METER;
Path_y = (y_saved_buffer - y_saved_buffer(1)) * PIXEL2METER;
[n, ~] = size(Path_x);

Z_stab_time = 0;
Yaw_stab_time = 5;
yaw_ang = 0;

path = zeros(1 + Z_stab_time*100 + n, 5);
path(1,:) = [0, 0, 0, 0.8, 0];
for k=2:(Z_stab_time*100 + 1)
    path(k,:) = [0.01*(k-1), 0, 0, 0.8, 0];
end

for k=(Z_stab_time*100 + 2):(Z_stab_time*100 + Yaw_stab_time*100 + 1)
%     yaw_ang = yaw_ang + 4*pi*0.01;
    path(k,:) = [0.01*(k-1), 0, 0, 0.8, yaw_ang];
end

for k=(Z_stab_time*100 + Yaw_stab_time*100 + 2):(Z_stab_time*100 + Yaw_stab_time*100 + 1 + n)
%     yaw_ang = yaw_ang + 4*pi*0.01;
    path(k,1) = 0.01*(k-1);
    path(k,2) = Path_x(k - (Z_stab_time*100 + Yaw_stab_time*100 + 1));
    path(k,3) = Path_y(k - (Z_stab_time*100 + Yaw_stab_time*100 + 1));
    path(k,4) = 0.8;
    path(k,5) = yaw_ang;
end

filteredPath(:,1) = path(:,1);
filteredPath(:,2) = doFilter(path(:,2));
filteredPath(:,3) = doFilter(path(:,3));
filteredPath(:,4) = doFilter(path(:,4));
filteredPath(:,5) = path(:,5);

filteredPath(1:500, 2:4) = [zeros(500, 2) 0.8*ones(500, 1)];
filteredPath = cat(1, filteredPath, filteredPath(end,:) + [3, 0, 0, -0.8, 0]);
