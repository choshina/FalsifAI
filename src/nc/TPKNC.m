function [TPKNC_value, TPKNC_activated_neurons] = TPKNC(hiddenOut, K)
% compute top-k neuron coverage

% Input:
% hiddenOut: the results of hidden layers
% K: Top-K neurons of each layer 
% Output:
% TPKNC_value: top-k neuron coverage
% TPKNC_activated_neurons: a cell array recording the activated times of each neuron

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% total number of neurons
neuron_num = 0;

% record the top-k activated neurons of each layer
TPKNC_activated_neurons = cell(1, c_size);

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    TPKNC_activated_neurons{1,i} = zeros(sz);
end

tempHiddenOut = TPKNC_activated_neurons;

% for each input
for i = 1:r_size
    for j = 1:c_size
        layerHiddenOutArray = cell2mat(hiddenOut(i,j)');
        layerHiddenOutArray = sort(layerHiddenOutArray,'descend');
        kth = layerHiddenOutArray(K,1);
        tempHiddenOut{1,j}(hiddenOut{i,j} >= kth) = 1;
        TPKNC_activated_neurons{1,j} = TPKNC_activated_neurons{1,j} + tempHiddenOut{1,j};
        tempHiddenOut{1,j} = zeros(size(tempHiddenOut{1,j}));
    end
end

TPKNC_value =sum(sum(cell2mat(TPKNC_activated_neurons') > 0)) /neuron_num;

end
% activated_neurons_num = zeros(1,c_size);
% 
% for i = 1:c_size
%     activated_neurons_num(1,i) = sum(TPKNC_activated_neurons{1,i} >= 1);
% end
% 
% NC_value = sum(activated_neurons_num)/neuron_num;

