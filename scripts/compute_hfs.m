function [accuracy] = compute_hfs(graph_type, graph_thresh)

%%%%%%%%%%%% the number of samples to generate
num_samples = 100;

%%%%%%%%%%%% the sample distribution function with the options necessary for the
%%%%%%%%%%%% distribuion


sample_dist = @two_moons;
dist_options = [1, 0.02, 0]; % two moons: radius of the moons,
                          %        variance of the moons
                          %        number of mislabeled nodes

plot_results = 0;

if nargin < 1

    plot_results = 1;

    %%%%%%%%%%%% the type of the graph to build and the respective threshold

    graph_type = 'knn';
    graph_thresh = 7; % the number of neighbours for the graph

%    graph_type = 'eps';
 %   graph_thresh = 0.30; % the epsilon threshold

end

%%%%%%%%%%%% similarity function
similarity_function = @exponential_euclidean;

%%%%%%%%%%%% similarity options
similarity_options = [0.5]; % exponential_euclidean: sigma

[X, Y] = get_samples(sample_dist, num_samples, dist_options);

%%%%%%%%%%%% automatically infer number of labels from samples
num_classes = length(unique(Y));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% randomly sample six labels                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% labels = zeros(num_samples);
% for i = 1:num_samples
%     labels(i) = randi(6);
% end

% select 6 random labels and their idxes
[Y_l, l_list] = datasample(Y, 20)%, 'Replace', false);
u_list = setdiff(1:num_samples, l_list);

%label vs unlabeled X
X_l = X(l_list, :);
X_u = X(u_list, :);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use the build_similarity_graph function to build the graph W  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

W = build_similarity_graph(graph_type, graph_thresh, X, similarity_function, similarity_options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% build the laplacian                                          %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D = zeros(size(W));
for i=1:length(W)
    D(i,i) = sum(W(i,:));
end 
L = D - W ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute hfs solution                                      %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

l_idx = l_list; 
u_idx = u_list; 

%Yl = zeros(length(l_idx),2);    
Yl = zeros(length(l_idx),2);
Yl(:,1) = Y_l==1;
Yl(:,2) = Y_l==2;
%Yl = Y_l %oneHot(Y_l);

Yu = inv(L(u_idx,u_idx)) * (W(u_idx,l_idx) * Yl) ;

    
% Soft Version
SYl = zeros(length(Y),2);
SYl(l_idx, :) = Yl; %oneHot(Y_l);

c_l = 5;
c_u = 0.5;

C = zeros(num_samples,1);
C(l_idx) = c_l;
C(u_idx) = c_u;

C = diag(C);

gamma = 0.01;
Q = L + gamma*eye(num_samples);

SYu = inv((inv(C)*Q +eye(num_samples))) * SYl;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute the labels assignment from the HFS solution       %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~,label] = max(Yu, [], 2);
[~,soft_label] = max(SYu, [], 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


final_label = Y;
final_label(u_idx) = label;

if plot_results
    plot_classification(X,Y,W,final_label, soft_label);
end
accuracy=sum(final_label==Y)/length(Y);
soft_accu=sum(soft_label==Y)/length(Y);
accuracy=max(accuracy,1-accuracy);
soft_accu=max(soft_accu,1-soft_accu);
fprintf('accuracy = %1.4f ; soft labeling accuracy = %1.4f \n',accuracy,soft_accu);

