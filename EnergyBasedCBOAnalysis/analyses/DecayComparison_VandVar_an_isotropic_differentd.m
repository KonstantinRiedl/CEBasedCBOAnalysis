% Comparison of isotropic CBO in different dimensions
%
% This script compares the decay behavior of our functional V for isotropic
% or anisotropic CBO with the theoretically expected rates in different
% dimensions.
%

%%
clear; clc; close all;

co = set_color();
co = co([1,2,3,5,6],:);


%% Settings for Easy Handling and Notes
% 
% use pre-set CBO setting (overrides manually chosen parameters)
pre_setparameters = 0;

% save plot
pdfexport = 0;

% plot settings
semilogy_plot = 0; % show decays in semilogy plot
normalized = 1; % normalize energy functional V


%% Energy Function E

% % dimension of the ambient space
d = [4,8,12,16];


%% Parameters of CBO Algorithm

% time horizon
T = 4;

% discrete time size
dt = 0.01;
 
% number of particles
N = 320000;

% lambda (parameter of consensus drift term)
lambda = 1;
% gamma (parameter of gradient drift term)
gamma = 0;
learning_rate = 0.01;
% anisotropic diffusion
anisotropic = 1;
% sigma (parameter of exploration term)
sigma = 0.32;

% alpha (weight in Gibbs measure for consensus point computation)
alpha = 10^15;

 
%% Initialization
V0mean_radial = 0.5;
V0mean_type = 2; % 1,2,3,4 % not all different for small d
% type 1: V0mean_radial*[1,0,0,0,0,0,0,0]
% type 2: V0mean_radial*[1,1,1,1,0,0,0,0]/normalization_of_direction
% type 3: V0mean_radial*[2,2,1,1,0,0,0,0]/normalization_of_direction
% type 4: V0mean_radial*[1,1,1,1,1,1,1,1]/normalization_of_direction
V0std = 32;


%% Error Metrics

% % Functional V (called Vstar)
Vstar = NaN(length(d),1+T/dt);

for i = 1:length(d)
    
    % global minimizer
    vstar = zeros(d(i),1);
    
    % % energy function E
    % (E is a function mapping columnwise from R^{d\times N} to R^N)
    objectivefunction = 'Rastrigin';
    [E, grad_E, parametersE, ~, ~] = objective_function(objectivefunction, d(i), 'CBO');
    
    % % Initialization
    % V0mean types % 1,2,3,4 % not all different for small d
    % type 1: V0mean_radial*[1,0,0,0,0,0,0,0]
    % type 2: V0mean_radial*[1,1,1,1,0,0,0,0]/normalization_of_direction
    % type 3: V0mean_radial*[2,2,1,1,0,0,0,0]/normalization_of_direction
    % type 4: V0mean_radial*[1,1,1,1,1,1,1,1]/normalization_of_direction
    if V0mean_type == 1
        V0mean = zeros(d(i),1);
        V0mean(1) = 1;
    elseif V0mean_type == 2
        V0mean_1 = ones(round(d(i)/2),1);
        V0mean_2 = zeros(d(i)-round(d(i)/2),1);
        V0mean = [V0mean_1; V0mean_2]/2;
    elseif V0mean_type == 3
        V0mean_1 = 2*ones(round(d(i)/4),1);
        V0mean_2 = ones(round(d(i)/4),1);
        V0mean_3 = zeros(d(i)-2*round(d(i)/4),1);
        V0mean = [V0mean_1; V0mean_2; V0mean_3]/sqrt(10);
    elseif V0mean_type == 4
        V0mean = ones(d(i),1)/sqrt(8);
    else
        error('V0mean type not known')
    end
    V0mean = V0mean_radial*V0mean/norm(V0mean);
    V0 = V0mean+sqrt(V0std)*randn(d(i),N);
    
    % normalization of error metrics
    if normalized
        normal_Variance_isotropic = 1/2*sum(vecnorm(V0-vstar).^2)/N;
        normal_Variance_anisotropic = 1/2*sum(vecnorm(V0-vstar).^2)/N;
    end
    
    % % Initialization of error metrics
    Vstar(i,1) = normal_Variance_isotropic;
    if normalized
        Vstar(i,1) = Vstar(i,1)/normal_Variance_isotropic;
    end
    
    parametersCBO = containers.Map({'T', 'dt', 'N', 'alpha', 'lambda', 'gamma', 'learning_rate', 'anisotropic', 'sigma'},...
                                   { T,   dt,   N,   alpha,   lambda,   gamma,   learning_rate,   anisotropic,   sigma});
    V = V0;
    for k = 1:T/dt
        
        % % CBO iteration
        % compute current consensus point v_alpha
        v_alpha = compute_valpha(E, alpha, V);

        % position updates of one iteration of CBO
        V = CBO_update(E, grad_E, parametersCBO, v_alpha, V);

        % % Computation of Error Metrics
        % Energy Functional V
        Vstar(i,k+1) = 1/2*sum(vecnorm(V-vstar,2,1).^2)/N;
        
        if normalized
            Vstar(i,k+1) = Vstar(i,k+1)/normal_Variance_isotropic;
        end

    end

end

%% Plotting of Error Metrics

set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaulttextinterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');

f = figure('Position', [1700 800 600 400]);
for i = 1:length(d)
    if ~normalized
        label_V_isotropic = ['$\mathcal{V}(\widehat\rho^N_t)$, $d=\,$',num2str(d(i))];
    else
        label_V_isotropic = ['$\mathcal{V}(\widehat\rho^N_t)/\mathcal{V}(\rho_0)$, $d=\,$',num2str(d(i))];
    end
    if ~semilogy_plot
        errormetric_plot_isotropic = plot(0:dt:T,Vstar(i,:), "color", co(i,:), 'LineWidth', 2, 'LineStyle', '-','DisplayName',label_V_isotropic);
    else
        errormetric_plot_isotropic = semilogy(0:dt:T,Vstar(i,:), "color", co(i,:), 'LineWidth', 2, 'LineStyle', '-','DisplayName',label_V_isotropic);
    end
    hold on
end

xlim([0,T])
xticks([0 0.5 1 1.5 2 2.5 3 3.5 4])
if ~semilogy_plot
    % normal plot
    ylim([0,1])
    yticks([0 0.25 0.5 0.75 1])
else
    % semilogy plot
    %ylim([5*10^-3,1])
end

% rate of decay reference line (from theory)
if anisotropic
	label_rate = ['$\exp\!\big(\!-(2\lambda-\sigma^2)t\big)$'];
	if ~semilogy_plot
        rate_plot = plot(0:dt:T,exp(-(2*lambda-sigma^2)*[0:dt:T]), "color", 0.4*[1,1,1], 'LineWidth', 2, 'LineStyle', '-.','DisplayName',label_rate);
    else
        rate_plot = semilogy(0:dt:T,exp(-(2*lambda-dsigma^2)*[0:dt:T]), "color", 0.4*[1,1,1], 'LineWidth', 2, 'LineStyle', '-.','DisplayName',label_rate);
    end
else
    for i = 1:length(d)
        label_rate = ['$\exp\!\big(\!-(2\lambda-d\sigma^2)t\big)$'];
        if ~semilogy_plot
            rate_plot = plot(0:dt:T,exp(-(2*lambda-d(i)*sigma^2)*[0:dt:T]), "color", 0.4*[1,1,1], 'LineWidth', 2, 'LineStyle', ':','DisplayName',label_rate);
        else
            rate_plot = semilogy(0:dt:T,exp(-(2*lambda-d(i)*sigma^2)*[0:dt:T]), "color", 0.4*[1,1,1], 'LineWidth', 2, 'LineStyle', ':','DisplayName',label_rate);
        end
        if i>1
            rate_plot.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end
    end
end
    
ax = gca;
ax.FontSize = 13;

xlabel('$t$','Interpreter','latex','FontSize',15)
if ~semilogy_plot
    legend('Interpreter','latex','FontSize',15,'Location','northeast')
else
    legend('Interpreter','latex','FontSize',15,'Location','southwest')
end


%% Save Image
if pdfexport
    print(f,[main_folder(),'/EnergyBasedCBOAnalysis/images_videos/VforisotropicforVariousdim_',objectivefunction],'-dpdf');

    % save parameters
    save([main_folder(),'/EnergyBasedCBOAnalysis/images_videos/VforisotropicforVariousdim_',objectivefunction,'_param'], 'objectivefunction', 'E', 'vstar', 'd', 'T', 'dt', 'N', 'alpha', 'lambda', 'gamma', 'learning_rate', 'sigma', 'V0mean_radial', 'V0mean_type', 'V0std')
end

