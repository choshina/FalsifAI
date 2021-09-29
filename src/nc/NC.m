function [NC_value,NC_activated_neurons] = NC(hiddenOut, activation_threshold)
% compute basic neuron coverage

% Input:
% hiddenOut: the results of hidden layers 
% activation_threshold: activation threshold
% Output:
% NC_value: basic neuron coverage
% NC_activated_neurons: a cell array recording the activated times of each neuron

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% record the activated neurons of each layer
NC_activated_neurons = cell(1, c_size);
% total number of neurons
neuron_num = 0;

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    NC_activated_neurons{1,i} = zeros(sz); 
end

% count the length of continuous activated interval for each neuron
tempHiddenOut = NC_activated_neurons;

% for each input 
for i = 1:r_size
    for j = 1:c_size
%         k = numel(hiddenOut{i,j});
%         eval(['layer_',num2str(j), '_activated_neuron', '=',  'zeros(', num2str(k), ', 1)']);
%         eval(['activated_neurons{1,', num2str(j), '} = layer_', num2str(j), '_activated_neuron' ]);
        tempHiddenOut{1,j}((hiddenOut{i,j} > activation_threshold)) = 1; 
        NC_activated_neurons{1,j} =  NC_activated_neurons{1,j} + tempHiddenOut{1,j};
        tempHiddenOut{1,j} = zeros(size(tempHiddenOut{1,j}));
    end
end

NC_value = sum(sum(cell2mat(NC_activated_neurons') > 0)) /neuron_num;

end
% activated_neurons_num = zeros(1,c_size);
% 
% for i = 1:c_size
%     activated_neurons_num(1,i) = sum(activated_neurons{1,i} >= 1);
% end
% 
% NC_value = sum(activated_neurons_num)/neuron_num;
