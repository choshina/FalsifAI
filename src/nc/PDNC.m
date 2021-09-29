function [PDNC_value, PDNC_activated_neurons] = PDNC(hiddenOut,  t_interval, diff_threshold)
% compute positive differential neuron coverage

% Input:
% hiddenOut: the results of hidden layers
% diff_threshold: differential threshold
% t_interval: time interval
% Output:
% PDNC_value: postive differential neuron coverage
% PDNC_activated_neurons: a cell array recording the activated times of each neuron(PDNC)

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% record the activated neurons of each layer
PDNC_activated_neurons = cell(1, c_size);
% total number of neurons
neuron_num = 0;

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    PDNC_activated_neurons{1,i} = zeros(sz);
end

PDNC_activated_neurons_array = zeros(1,neuron_num);

% if r_size is less than t_interval, there is no PDNC
if r_size < t_interval
    PDNC_value = 0;
    error("r_size is 1, there is no PDNC");
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
    tempHiddenOutMat = newHiddenOutMat(i - t_interval : i, :);
    [maxArray, maxArray_index] = max(tempHiddenOutMat);
    [minArray, minArray_index] = min(tempHiddenOutMat);
    good_position = (maxArray - minArray > diff_threshold) & (maxArray_index > minArray_index);
    PDNC_activated_neurons_array(good_position) = PDNC_activated_neurons_array(good_position) + 1;
end

index = 0;
for i = 1 : c_size
    layer_neuron_num = numel(PDNC_activated_neurons{1,i});
    PDNC_activated_neurons{1,i} = PDNC_activated_neurons_array(1,index + 1 : index + layer_neuron_num)';
    index = index + layer_neuron_num;
end

PDNC_value = sum(cell2mat(PDNC_activated_neurons') > 0) /neuron_num;

end