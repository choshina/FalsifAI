import sys

model = []
algorithm = '' 
optimization = []
phi_str = []
controlpoints = []
input_name = []
input_range = []
parameters = []
timespan = ''
loadfile = ''

status = 0
arg = ''
linenum = 0

budget_local = 0
scalar = 0

algopath = ''
trials = ''
timeout = ''
max_sim = ''
addpath = []

#nn = ''
nn_in = []
guidance = ''
qs_size = ''
cov_metric = []


with open(sys.argv[1],'r') as conf:
	for line in conf.readlines():
		argu = line.strip().split()
		if status == 0:
			status = 1
			arg = argu[0]
			linenum = int(argu[1])
		elif status == 1:
			linenum = linenum - 1
			if arg == 'model':
				model.append([argu[0], argu[1]])

			elif arg == 'optimization':
				optimization.append(argu[0])
			elif arg == 'phi':
				complete_phi = argu[0]+';'+argu[1]
				for a in argu[2:]:
					complete_phi = complete_phi + ' '+ a
				phi_str.append(complete_phi)
			elif arg == 'controlpoints':
				controlpoints.append(int(argu[0]))
			elif arg == 'input_name':
				input_name.append(argu[0])
			elif arg == 'input_range':
				input_range.append([float(argu[0]),float(argu[1])])
			elif arg == 'parameters':
				parameters.append(argu[0])	
			elif arg == 'timespan':
				timespan = argu[0]
			elif arg == 'trials':
				trials = argu[0]
			elif arg == 'timeout':
				timeout = argu[0]
			elif arg == 'max_sim':
				max_sim  = argu[0]
			elif arg == 'addpath':
				addpath.append(argu[0])
			elif arg == 'loadfile':
				loadfile = argu[0]
			elif arg == 'budget_local':
				budget_local = int(argu[0])
			elif arg == 'nn':
				nn = argu[0]
			elif arg == 'nn_in':
				nn_in.append(argu[0])
			elif arg == 'guidance':
				guidance = argu[0]
			elif arg == 'qs_size':
				qs_size = int(argu[0])
			elif arg == 'cov_metric':
				if len(argu) == 3:
					cov_metric.append([argu[0], argu[1], argu[2]])
				else:
					cov_metric.append([argu[0], argu[1]])
#			elif arg == 'cov_param':
#				cov_param.append(float(argu[0]))
			else:
				continue
			if linenum == 0:
				status = 0


for ph in phi_str:
	for cp in controlpoints:
		for opt in optimization:
			for mod in model:
				for covm in cov_metric:
					property = ph.split(';')
					filename = mod[0] + '_AI_' + property[0]  + '_'  +  str(qs_size) + '_' + str(budget_local) + '_' + opt + '_' + guidance + '_' + '_'.join(covm)
					param = '\n'.join(parameters)
					with open('benchmarks/'+filename,'w') as bm:
						bm.write('#!/bin/sh\n')
						bm.write('csv=$1\n')
						bm.write('matlab -nodesktop -nosplash <<EOF\n')
						bm.write('clear;\n')
						for ap in addpath:
							bm.write('addpath(genpath(\'' + ap + '\'));\n')
						if loadfile!= '':
							bm.write('load ' + loadfile + '\n')
						bm.write('InitBreach;\n\n')
						bm.write(param + '\n')
						bm.write('mdl = \''+ mod[0] + '\';\n')
						bm.write('Br = BreachSimulinkSystem(mdl);\n')
						bm.write('br = Br.copy();\n')
						bm.write('controlpoints = ' + str(cp) + ';\n')
						bm.write('br.Sys.tspan = ' + timespan + ';\n')
						bm.write('input_gen.type = \'UniStep\';\n')
						bm.write('input_gen.cp = controlpoints;\n')
						bm.write('br.SetInputGen(input_gen);\n')

						bm.write('budget_t = ' + str(timeout) + ';\n')
						bm.write('budget_local = ' + str(budget_local) + ';\n')
						bm.write('input_name = {\'' + input_name[0] + '\'')
						for iname in input_name[1:]:
							bm.write(',')
							bm.write('\'' + iname + '\'')
						bm.write('};\n')

						bm.write('input_range = [[' + str(input_range[0][0]) + ' ' + str(input_range[0][1]) + ']')
						for ir in input_range[1:]:
							bm.write(';[' + str(ir[0]) + ' ' + str(ir[1]) + ']')
						bm.write('];\n')

						bm.write('spec = \''+ property[1]+'\';\n')
						bm.write('phi = STL_Formula(\'phi\',spec);\n')

						bm.write('for cpi = 0:controlpoints -1\n')
						bm.write('\tfor ini = 0:numel(input_name) - 1\n')
						bm.write('\t\tin = input_name(ini + 1);\n')
						bm.write('\t\tbr.SetParamRanges({strcat(in, \'_u\', num2str(cpi))}, input_range(ini + 1, :));\n')
						bm.write('\tend\n')
						bm.write('end\n')

						bm.write('nn = \'' + mod[1] + '\';\n')
						bm.write('nn_in = {\'' + nn_in[0] + '\'')
						for nnin in nn_in[1:]:
							bm.write(',')
							bm.write('\'' + nnin + '\'')
						bm.write('};\n')

						bm.write('guidance = \'' + guidance + '\';\n')
						bm.write('qs_size = ' + str(qs_size) + ';\n')
						bm.write('cov_metric = \'' + covm[0] + '\';\n')
				
						bm.write('cov_param = [' + covm[1] +  ' ')
						for covp in covm[2:]:
							bm.write(' ' + covp)
						bm.write('];\n')

						bm.write('solver = \'' + opt + '\';\n')
			    
		
						bm.write('trials = ' + trials + ';\n')	
						bm.write('filename = \''+filename+'\';\n')
						bm.write('falsified = [];\n')
						bm.write('coverage = [];\n')
						bm.write('obj_bests = [];\n')
						bm.write('time = [];\n')
						bm.write('num_sim = [];\n')
						bm.write('num_sim2 = [];\n')
		
						bm.write('for n = 1:trials\n')
						bm.write('\ttg = TestGen(br, phi, nn, nn_in, guidance, qs_size, cov_metric, cov_param, solver,  budget_t, budget_local);\n')
						bm.write('\ttg.run();\n')
						bm.write('\tfalsified = [falsified; tg.falsified];\n')
						bm.write('\tobj_bests = [obj_bests; tg.obj_best];\n')
						bm.write('\tcoverage = [coverage;tg.cov_curr];\n')
				#		bm.write('\tnum_sim = [num_sim;tg.num_sim];\n')		
						bm.write('\tnum_sim2 = [num_sim2; tg.num_sim2];\n')
						bm.write('\ttime = [time;tg.time_cost];\n')
	
						bm.write('end\n')

						bm.write('budget_locals = ones(trials, 1)*budget_local;\n')
						bm.write('spec = {spec')
						n_trials = int(trials)
						for j in range(1,n_trials):
							bm.write(';spec')
						bm.write('};\n')

						bm.write('filename = {filename')
						for j in range(1,n_trials):
							bm.write(';filename')
						bm.write('};\n')

						bm.write('cov_metrics = {cov_metric')
						for j in range(1, n_trials):
							bm.write(';cov_metric')
						bm.write('};\n')

						bm.write('result = table(filename, spec, cov_metrics, budget_locals, falsified, time, num_sim2, coverage, obj_bests);\n')
				
						bm.write('writetable(result,\'$csv\',\'Delimiter\',\';\');\n')
						bm.write('quit force\n')
						bm.write('EOF\n')
