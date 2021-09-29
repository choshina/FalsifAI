function [MDNC_value,MDNC_activated_neurons] = MDNC(hiddenOut, t_interval)
% compute monotonic decrease neuron coverage

% Input:
% hiddenOut: the results of hidden layers 
% t_interval: time interval
% Output:
% MDNC_value: monotonic decrease neuron coverage
% MDNC_activated_neurons: a cell array recording the activated times of each neuron

% r_size: the number of inputs; c_size: the number of layers
[r_size, c_size] = size(hiddenOut);

% record the activated neurons of each layer
MDNC_activated_neurons = cell(1, c_size);

% total number of neurons
neuron_num = 0;

for i = 1:c_size
    sz = size(hiddenOut{1,i});
    neuron_num = neuron_num + sz(1,1);
    MDNC_activated_neurons{1,i} = zeros(sz);
end

% count the length of continuous activated interval for each neuron
MD_tempHiddenOut = MDNC_activated_neurons;

% if r_size is less than t_interval, there is no MDNC
if r_size < t_interval
    MDNC_value = 0;
    return;
end

% input squence
for i = 2:r_size
    for j = 1:c_size
        good_position = (hiddenOut{i,j} <= hiddenOut{i-1,j});
        MD_tempHiddenOut{1,j}(good_position) = MD_tempHiddenOut{1,j}(good_position) + 1;
        
        if i == r_size &  MD_tempHiddenOut{1,j}(good_position) > t_interval
            MDNC_activated_neurons{1,j}(good_position) = MDNC_activated_neurons{1,j}(good_position) + 1;
        end
       
%        bad_postion = (hiddenOut{i,j} > hiddenOut{i-1,j});
%        if MD_tempHiddenOut{1,j}(bad_postion) > t_interval
%            MDNC_activated_neurons{1,j}(bad_postion) = MDNC_activated_neurons{1,j}(bad_postion) + 1;
%        end

		bad_position = (hiddenOut{i,j} > hiddenOut{i-1,j});
		for index = 1: numel(bad_position)
			if bad_position(index, 1) == 1 & MD_tempHiddenOut{1,j}(index) > t_interval
				MDNC_activated_neurons{1,j}(index, 1) = MDNC_activated_neurons{1,j}(index, 1) + 1;
			end
		end
        MD_tempHiddenOut{1,j}(bad_position) = 0;
    end
end

MDNC_value = sum(cell2mat(MDNC_activated_neurons') > 0)/neuron_num;

end

