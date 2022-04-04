# FalsifAI

This repository is for the artifact evaluation of the paper "FalsifAI: Falsification of AI-Enabled Hybrid Control Systems Guided by Time-Aware Coverage Criteria".

## System requirement


- Operating system: Linux or MacOS;

- Matlab (Simulink/Stateflow) version: >= 2020a. (Matlab license needed)

- Python version: >= 3.3

- MATLAB toolboxes dependency: 
  1. [Model Predictive Control Toolbox](https://www.mathworks.com/help/mpc/index.html) for ACC benchmark
  2. [Stateflow](https://www.mathworks.com/products/stateflow.html)
  3. [Deep Learning Toolbox](https://www.mathworks.com/products/deep-learning.html)

## Folder Structure Conventions

```
.
├── Makefile
├── README.md
├── benchmarks
│   ├── train
│   │   ├── ACC
│   │   │   ├── ACC_config.txt
│   │   │   ├── ACC_falsification.m
│   │   │   ├── ACC_falsify.m
│   │   │   └── ACC_trainController.m
│   │   ├── AFC
│   │   │   ├── AFC_config.txt
│   │   │   ├── AFC_falsification.m
│   │   │   ├── AFC_falsify.m
│   │   │   └── AFC_trainController.m
│   │   └── DPC
│   │       ├── buck_config.txt
│   │       ├── buck_falsification.m
│   │       ├── buck_falsify.m
│   │       └── buck_trainController.m
│   ├── ACC
│   │   ├── dataset
│   │   │   └── ACC_trainset.mat
│   │   ├── model
│   │   │   ├── mpcACCsystem.slx
│   │   │   └── nncACCsystem.slx
│   │   ├── nnconfig
│   │   └── nncontroller
│   ├── AFC
│   │   ├── dataset
│   │   │   └── AFC_trainset.mat
│   │   ├── model
│   │   │   ├── fuel_control.slx
│   │   │   └── nn_fuel_control.slx
│   │   ├── nnconfig
│   │   └── nncontroller
│   └── DPC
│       ├── dataset
│       │   └── buck_trainset.mat
│       ├── model
│       │   ├── my_buck_pid.slx
│       │   └── buck_nn.slx
│       ├── nnconfig
│       └── nncontroller
├── log/
├── results/
├── run
├── robustness_calculator.m(relied on Breach)
├── src
│   ├── TestGen.m
│   ├── main.m
│   ├── nc
│   │   ├── NC.m
│   │   ├── TKC.m
│   │   ├── TNC.m
│   │   ├── TTK.m
│   │   ├── PD.m
│   │   ├── ND.m
│   │   ├── MI.m
│   │   └── MD.m
│   └── util
│       └── CQueue.m
└── test
│   ├── falsifai_test.py
│   ├── breach_test.py
│   ├── scripts
│   └── config
│       ├── AI
│       │   ├── acc.conf
│       │   ├── afc.conf
│       │   └── dpc.conf
│       └── breach
│           ├── acc.conf
│           ├── afc.conf
│           └── dpc.conf
└── analyses
    ├── results.txt
    └── statTest.R

```

## Installation

- Clone the repository `git clone https://github.com/lyudeyun/FalsifAI.git`

- Install [Breach](https://github.com/decyphir/breach)
  1. start matlab, set up a C/C++ compiler using the command `mex -setup`. (Refer to [here](https://www.mathworks.com/help/matlab/matlabexternal/changing-default-compiler.html) for more details.)
  2. navigate to `breach/` in Matlab commandline, and run `InstallBreach`

 ## Usage

 To reproduce the experimental results, users should follow the steps below:

 - The user-specified configuration files are stored in the directory `test/config/`. Replace the paths of `FalsifAI` and `breach` in user-specified file under the line `addpath 2` with their own paths. Users can also specify other configurations, such as model, input ranges, optimization methods, and etc. 
 - Navigate to the directory `test/`. Run the command `python [type]_test.py config/[user-specified configuration file]`. Users can generate the testing scripts by `ai_test.py` or `breach_test.py`.
 - Now the executable scripts have been generated under the directory `test/benchmarks/`. Users need to edit the executable scripts permission using the command `chmod -R 777 *`.
 - Navigate to the root directory `falsifAI/` and run the command `make`. The automatically generated .csv experimental results will be stored in directory `results/`.
 - The corresponding log will be stored under directory `output/`.


