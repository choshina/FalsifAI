function [TimedNC_value,TimedNC_activated_neurons] = TimedNC(hiddenOut, t_interval,activation_threshold)
% compute timed neuron coverage

% Input:
% hiddenOut: the results of hidden layers 
% t_interval: time interval（the number of size of the ）
% activation_threshold: activation threshold
% Output:
% TimedNC_value: timed neuron coverage
% TimedNC_activated_neurons: a cell array recording the activated times of each neuron

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% record the activated neurons of each layer
TimedNC_activated_neurons = cell(1, c_size);

% total number of neurons
neuron_num = 0;

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    TimedNC_activated_neurons{1,i} = zeros(sz);
end

% count the length of continuous activated interval for each neuron
tempHiddenOut = TimedNC_activated_neurons;

% if r_size is less than t_interval, there is no TimedNC
if r_size < t_interval
    TimedNC_value = 0;
    return;
end

% input squence
for i = 1:r_size
    for j = 1:c_size
        % if one neuron is activated now,its corresponding time add 1
        position_activated = (hiddenOut{i,j} > activation_threshold);
        tempHiddenOut{1,j}(position_activated) = tempHiddenOut{1,j}(position_activated) + 1;
        % 这块可能有bug
        % tempHiddenOut >= t_interval and this neuron isn't activated at this time 
        position_true = (tempHiddenOut{1,j} >= t_interval & (hiddenOut{i,j} <= activation_threshold | i == r_size) );  
        TimedNC_activated_neurons{1,j}(position_true) =  TimedNC_activated_neurons{1,j}(position_true) + 1;
        tempHiddenOut{1,j}(position_true) = 0; 
        % tempHiddenOut < t_interval and this neuron isn't activated at this time 
        position_false = (tempHiddenOut{1,j} < t_interval & hiddenOut{i,j} <= activation_threshold);  
        tempHiddenOut{1,j}(position_false) = 0;    
    end
end

TimedNC_value =sum(sum(cell2mat(TimedNC_activated_neurons') > 0)) /neuron_num;

end
% activated_neurons_num = zeros(1,c_size);
% 
% for i = 1:c_size
%     activated_neurons_num(1,i) = sum(TimedNC_activated_neurons{1,i} >= 1);
% end
% 
% TimedNC_value = sum(activated_neurons_num)/neuron_num;
