classdef TestGen < handle
    properties
        br
        phi
        
        params
        lb
        rb
        tspan
        
        net_name
        net
        nn_input
        nn_input_num
        nn_tspan_num
        nn_num_neurons
        
        
        cov_curr
        act_curr
        
        budget
        budget_local
        
        guidance
        qseed_size
        qseed
        
        cov_metric
        cov_param
        
        solver
        solver_options
        
        objective
        obj_best
        x_best
        
        num_sim
        num_sim2
        time_cost
        
        falsified
    end
    
    methods
        
        function this = TestGen(br, phi, nn, nn_in, gd, qs_size, cov_metric, cov_param, solver, budget, budget_local)
            this.br = br;
            
            this.phi = phi;
            this.budget =  budget;
            this.budget_local = budget_local;
            
            this.tspan = br.Sys.tspan;
            
            this.params = br.GetSysVariables();
            rgs = br.GetParamRanges(this.params);
            this.lb = rgs(:, 1);
            this.rb = rgs(:, 2);
            
            this.net_name = nn;
            load(nn, 'net');
            this.net = net;
            this.nn_input = nn_in;
            this.nn_input_num = numel(nn_in);
            this.nn_tspan_num = numel(this.tspan);
            this.nn_num_neurons = 0;
            for i = 1: this.net.numLayers - 1
                this.nn_num_neurons = this.nn_num_neurons + this.net.layers{i}.dimensions;
            end
            
            this.cov_curr = 0;
            this.act_curr = cell(1, this.net.numLayers-1);
            for a = 1:numel(this.act_curr)
                %TODO init 0
                this.act_curr{a} = zeros(this.net.layers{a}.dimensions, 1);
            end
            
            this.guidance = gd;
            this.qseed_size = qs_size;
			this.qseed = CQueue();
            this.init_seed();
            
            this.cov_metric = cov_metric;
            this.cov_param = cov_param;
            
            
            this.solver = solver;
%             if strcmp(this.solver, 'sa')
%                 this.setup_sa();
%             elseif strcmp(this.solver, 'cmaes')
%                 this.setup_cmaes;
%             end
            switch this.solver
                case 'sa'
                    this.setup_sa();
                case 'cmaes'
                    this.setup_cmaes();
                case 'random'
                    this.setup_random();
                otherwise
            end
            
            this.objective = @(x)(objective_wrapper(this, x));
            
            this.obj_best = intmax;
            this.x_best = [];
            this.num_sim = 0;
            this.num_sim2 = 0;
            this.time_cost = 0;
            
            this.falsified = 0;
            
            rng('default');
            rng(round(rem(now, 1)*1000000));
        end
        
        function run(this)
            tic;
            while true
                if this.qseed.isempty()
                    this.init_seed();
                end
                u = this.qseed.pop();

                if strcmp(this.solver, 'sa')
                    
                    this.solver_options.MaxTime = this.budget_local;
                    [xb, objb, ~, output] = simulannealbnd(this.objective, u, this.lb, this.rb, this.solver_options);
                    
                    this.obj_best = objb;
                    this.x_best = xb;
                    this.num_sim = this.num_sim + output.funccount;
                    
                elseif strcmp(this.solver, 'cmaes')
                    this.solver_options.StopIter = this.budget_local;
                    [~, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, u, [], this.solver_options);
                    
                    this.obj_best = bestever.f;
                    this.x_best = bestever.x;
                    this.num_sim = this.num_sim + counteval;
                    
                elseif strcmp(this.solver, 'random')
                    [xb, fb] = random_sample(this.objective, u, this.lb, this.rb, this.budget_local);
                    this.obj_best = fb;
                    this.x_best = xb;
                end
                
                this.num_sim2
                time = toc;
                this.time_cost = time;
                
                if this.obj_best < 0
                    this.falsified = 1;
					this.x_best
                    break;
                end
                
               % if time > this.budget
			    if this.istimeout()
                    break;
                end
            end
        end
        
        function init_seed(this)
            
        %    this.qseed = CQueue();
            for j = 1:this.qseed_size
                x0 = [];
                lb__ = this.lb;
                ub__ = this.rb;
                num = numel(lb__);
                for i = 1: num
                    is__ = lb__(i) + rand()*(ub__(i) - lb__(i));
                    x0 = [x0 is__];
                end
                this.qseed.push(x0');
            end
        end
        
		function yes = istimeout(this)
			yes = (this.num_sim2 > this.budget);
		end

        function fval = objective_wrapper(this, x)
           time = toc;
           if this.obj_best < 0 || this.istimeout()
               fval = this.obj_best;
           else
               fval = this.obtain_robustness(x);
               
               this.num_sim2 = this.num_sim2 + 1;
               
               % maybe not work; 
               if fval < this.obj_best 
                   this.obj_best = fval;
                   this.x_best = x;
               end
                   
           end
        end
        
        function rob = obtain_robustness(this, x)
            this.br.SetParam(this.br.GetSysVariables(), x);
            this.br.Sim(this.tspan);
            rob = this.br.CheckSpec(this.phi);
            
            % make sure that in simulink, the corres. signal is output
            signal_list = this.br.GetSignalList();
            signals_origin = this.br.P.traj{1,1}.X;
            
            signals = [];
            for ni = this.nn_input
                
                for li = 1: numel(signal_list)
                    if strcmp(ni, signal_list(li))
                        if find(ismember(signal_list, 'in_Vref_True'))
                            signals = [signals; signals_origin(li, 1:300:180001)];
                        else
                            signals = [signals; signals_origin(li, :)];
                        end
                    end
                end
            end
            
            hidden_out = cell(this.nn_tspan_num, this.net.numLayers-1);
            output = cell(this.nn_tspan_num, 1);
            
            for j = 1: this.nn_tspan_num
                for i = 1: this.net.numLayers
                    if i == 1
                        activationFcn = this.net.layers{i}.transferFcn();
                        activationFcn = str2func(activationFcn);
                        hidden_out{j, i} = activationFcn(this.net.IW{1,1}*signals(:,j) + this.net.b{i});
                    elseif i > 1 && i <  this.net.numLayers
                        activationFcn = this.net.layers{i}.transferFcn();
                        activationFcn = str2func(activationFcn);
                        hidden_out{j, i} = activationFcn(this.net.LW{i, i-1}*hidden_out{j, i-1} + this.net.b{i});
                    else
                        transFcn = this.net.layers{this.net.numLayers}.transferFcn();
                        transFcn = str2func(transFcn);
                        output{j, 1} = transFcn(this.net.LW{i, i-1}*hidden_out{j, i-1} + this.net.b{i});
                    end
                end
            end
            
            % the way of updating qseed
            if strcmp(this.guidance, 'cov')
                [~, act_neurons] = this.coverage(hidden_out);
                [temp_cov, res_mat] = this.combineCovMat(act_neurons);
                if temp_cov > this.cov_curr
                    this.cov_curr = temp_cov;
                    this.act_curr = res_mat;
                    this.qseed.push(x);
                end
                
            elseif strcmp(this.guidance, 'rob')
                [temp_cov, res_mat] = this.combineCovMat(act_neurons);
                if rob < this.obj_best
                    this.act_curr = res_mat;
                    this.qseed.push(x);
                end
                
            elseif strcmp(this.guidance, 'both')
                [~, act_neurons] = this.coverage(hidden_out);
                [temp_cov, res_mat] = this.combineCovMat(act_neurons);
                if temp_cov > this.cov_curr
                    this.cov_curr = temp_cov;
                    this.act_curr = res_mat;
                    this.qseed.push(x);
                elseif rob< this.obj_best
                    this.act_curr = res_mat;
                    this.qseed.push(x);
                end
            elseif strcmp(this.guidance, 'rand')
                if this.qseed.isempty()
                    x0 = [];
                    lb__ = this.lb;
                    ub__ = this.rb;
                    num = numel(lb__);
                    for i = 1: num
                        is__ = lb__(i) + rand()*(ub__(i) - lb__(i));
                        x0 = [x0 is__];
                    end
                    this.qseed.push(x0');
                end
            end
            
        end
        
        function [temp_cov, res_mat] = combineCovMat(this, an)
            res_mat = this.act_curr;
            for kk = 1: this.net.numLayers -1
                res_mat{kk} = res_mat{kk} + an{kk};
            end
            
            temp_cov = sum(cell2mat(res_mat') > 0)/this.nn_num_neurons;
        end
        
        function [v, a_neurons] = coverage(this, hidden_out)
            switch this.cov_metric
                case 'nc'
                    [v, a_neurons] = NC(hidden_out, this.cov_param);
                    
                case 'tkc'
                    [v, a_neurons] = TPKNC(hidden_out, this.cov_param);
                    
                case 'tnc'
                    [v, a_neurons] = TimedNC(hidden_out, this.cov_param(1), this.cov_param(2)); % (1): t_interval. (2) threshold
                
                case 'ttk'
                    [v, a_neurons] = TTK(hidden_out, this.cov_param(1), this.cov_param(2)); % (1): t_interval. (2) K
                    
                case 'pd'
                    [v, a_neurons] = PDNC(hidden_out, this.cov_param(1), this.cov_param(2));
                    
                case 'nd'
                    [v, a_neurons] = NDNC(hidden_out, this.cov_param(1), this.cov_param(2));
                    
                case 'mi'
                    [v, a_neurons] = MINC(hidden_out, this.cov_param);
                    
                case 'md'
                    [v, a_neurons] = MDNC(hidden_out, this.cov_param); 
                
                otherwise
            end
        end
        
        
        function setup_sa(this)
            solver_opt = optimset('Display', 'iter');
            this.solver_options = solver_opt;
        end
        
        function setup_cmaes(this)
            this.solver_options = cmaes();
            this.solver_options.LBounds = this.lb;
            this.solver_options.UBounds = this.rb;
        end
        function setup_random(this)
%             this.solver_options = cmaes();
%             this.solver_options.LBounds = this.lb;
%             this.solver_options.UBounds = this.rb;
        end
        
    end
    
end
