function [NDNC_value, NDNC_activated_neurons] = NDNC(hiddenOut,  t_interval, activation_threshold)
% compute negative differential neuron coverage

% Input:
% hiddenOut: the results of hidden layers
% activation_threshold: activation threshold
% t_interval: time interval
% Output:
% NDNC_value: negative differential neuron coverage
% NDNC_activated_neurons: a cell array recording the activated times of each neuron(NDNC)

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% record the activated neurons of each layer
NDNC_activated_neurons = cell(1, c_size);
% total number of neurons
neuron_num = 0;

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    NDNC_activated_neurons{1,i} = zeros(sz);
end

NDNC_activated_neurons_array = zeros(1,neuron_num);

% if r_size is less than t_interval, there is no NDNC
if r_size < t_interval
    NDNC_value = 0;
    error("r_size is 1, there is no NDNC");
    return;
end

for i = 1 : r_size
    for j = 1: c_size
        newHiddenOut{i,j} = hiddenOut{i,j}';
    end
end

% transform cell to matrix 
newHiddenOutMat = cell2mat(newHiddenOut);

% input squence
for i = t_interval + 1 : r_size
    for j = 1: neuron_num
        tempHiddenOutMat = newHiddenOutMat(i - t_interval : i,:);
        [maxArray, maxArray_index] = max(tempHiddenOutMat);
        [minArray, minArray_index] = min(tempHiddenOutMat);
        good_position = (maxArray - minArray > activation_threshold) & (maxArray_index < minArray_index);
        NDNC_activated_neurons_array(good_position) = NDNC_activated_neurons_array(good_position) + 1;
    end
end

index = 0;
for i = 1 : c_size
    layer_neuron_num = numel(NDNC_activated_neurons{1,i});
    NDNC_activated_neurons{1,i} = NDNC_activated_neurons_array(1,index + 1 : index + layer_neuron_num)';
    index = index + layer_neuron_num;
end

NDNC_value = sum(cell2mat(NDNC_activated_neurons') > 0) /neuron_num;

end