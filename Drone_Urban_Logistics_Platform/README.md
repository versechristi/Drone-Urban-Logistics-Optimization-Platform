# 无人机城市物流优化平台 (Drone Urban Logistics Optimization Platform)

**版本:** 1.0.0
**最后更新:** 2025-05-24 
**作者:** (versechristi)

## 项目简介

本项目是一个基于MATLAB实现的仿真平台，旨在研究和优化城市环境下无人机物流配送的关键问题。平台集成了**用户交互界面**、**场景数据生成**、**配送中心（枢纽）选址与布局优化**、以及基于**模拟退火 (SA)** 和**蚁群优化 (ACO)** 算法的**多无人机路径规划**。此外，平台还提供了算法性能的**对比分析**和结果的**可视化**功能。

## 主要功能

* **参数化场景配置**: 用户可通过图形界面（WebApp）或配置文件定义仿真场景的各项参数，包括：
    * 地理中心位置（经纬度）
    * 客户数量与分布半径
    * 候选配送中心数量
    * 期望选择的配送中心数量
    * 无人机性能（载重、续航、单位成本）
    * 模拟退火和蚁群算法的特定参数
* **数据生成**: 自动生成客户点（含需求量）和候选配送中心点的位置。
* **枢纽选址与布局**: 根据客户分布和候选点，采用优化策略（当前实现为基于K-means聚类客户后指派最近候选点）选择最终的配送中心位置。
* **路径规划**:
    * **模拟退火 (SA)**: 实现多无人机、多配送中心的车辆路径问题 (MDVRP) 求解。
    * **蚁群优化 (ACO)**: 实现MDVRP的另一种启发式解法。
    * 两种算法均支持输出**中间迭代过程的快照**，便于观察算法收敛过程。
* **结果可视化**:
    * 枢纽选址结果图（候选点、最终选址点、客户分布、大致服务区域）。
    * 路径规划结果的地理路线图（支持KML导出，可在Google Earth等软件中查看）。
    * 算法收敛曲线图。
    * 中间迭代快照的路径图。
* **对比分析**:
    * SA与ACO算法的收敛曲线对比图。
    * SA与ACO算法的最终性能指标（如总成本、计算时间、路径数量、总飞行距离）的柱状图对比。
    * 生成详细的文本对比报告。
* **结果导出与记录**:
    * 每次运行的结果（参数、图表、KML文件、MAT数据文件、日志）均保存在带时间戳的独立文件夹中。
    * 控制台输出记录在日志文件中。

## 项目结构

Drone_Urban_Logistics_Platform/
│
├── +WebApp/                             # MATLAB App Designer 应用 (用户输入界面)
│   └── DroneLogisticsConfigurator.mlapp
│
├── +configurations/                     # 配置文件
│   ├── default_simulation_parameters.m # 默认仿真参数脚本
│   └── current_run_parameters.mat      # UI保存的当前运行参数
│
├── main_Orchestrator.m                 # 主控制脚本，运行整个仿真流程
│
├── +data_generation/                   # 包: 数据生成模块
│   ├── generate_Customers.m           
│   ├── generate_Candidate_Depots.m    
│   └── load_Drone_Specifications.m    
│
├── +hub_selection_layout/              # 包: 枢纽选址与布局优化模块
│   ├── optimize_Hub_Locations.m       
│   ├── evaluate_Hub_Layout_Fitness.m  
│   └── +visualizer/                    # 子包: 枢纽相关的可视化
│       ├── plot_Candidate_Vs_Selected_Hubs.m
│       ├── plot_Hub_Service_Areas.m   
│       └── export_Hub_Layout_Data.m   
│
├── +path_planning_algorithms/          # 包: 路径规划核心算法
│   ├── +simulated_annealing_vrp/       # 子包: 模拟退火解决VRP
│   │   ├── solve_SA_VRP.m             
│   │   ├── generate_Initial_Solution_SA.m
│   │   ├── generate_Neighbor_Solution_SA.m
│   │   └── calculate_Total_Cost_SA.m  
│   │
│   ├── +ant_colony_vrp/                # 子包: 蚁群优化解决VRP
│   │   ├── solve_ACO_VRP.m            
│   │   ├── ants_Construct_Solutions_ACO.m
│   │   ├── update_Pheromones_ACO.m    
│   │   ├── calculate_Total_Cost_ACO.m 
│   │   └── +visualizer_ACO/            # 子包: ACO相关的可视化 (隶属于ant_colony_vrp)
│   │       ├── plot_ACO_Route_Snapshot.m
│   │       └── plot_ACO_Convergence_Curve.m
│   │
│   └── +visualizer_SA/                 # 子包: SA相关的可视化 (隶属于path_planning_algorithms)
│       ├── plot_SA_Route_Snapshot.m   
│       └── plot_SA_Convergence_Curve.m
│
├── +comparative_analytics/             # 包: SA与ACO对比分析模块
│   ├── plot_SA_vs_ACO_Convergence.m   
│   ├── plot_Final_Performance_Bars.m  
│   └── generate_Comparative_Report.m  
│
├── +common_utilities/                  # 包: 通用辅助函数
│   ├── calculate_Haversine_Distance.m 
│   ├── convert_Matlab_to_KML_Colors.m 
│   ├── export_Routes_to_KML.m         
│   ├── save_Figure_Properly.m         
│   └── manage_Iteration_Checkpoints.m 
│
├── results_output/                     # 文件夹: 存储所有运行结果
│   └── ExperimentRun_yyyymmdd_HHMMSS/  # 每次运行的独立子文件夹
│       ├── inputs/                     # 输入参数子文件夹
│       │   └── parameters_used.mat     # 本次运行使用的参数
│       ├── hub_layout_results/        
│       ├── path_planning_sa/          
│       ├── path_planning_aco/         
│       ├── comparative_analysis_plots/
│       ├── simulation_log.txt          # 控制台日志
│       └── comparative_report.txt      # 对比分析报告
│
└── README.md                           # 本文件


## 环境要求

* **MATLAB R2021a 或更高版本** (因App Designer和某些函数语法)
* **Mapping Toolbox** (用于地理绘图和KML导出)
* **Statistics and Machine Learning Toolbox** (用于 `kmeans` 函数)
* **(可选) Parallel Computing Toolbox** (若 `parfor` 在ACO中被有效使用以加速蚂蚁并行构建解)

## 如何运行

1.  **启动MATLAB**。
2.  **设置路径**: 确保MATLAB的当前工作目录是项目根目录 (`Drone_Urban_Logistics_Platform/`)，或者将项目根目录及其所有子文件夹（特别是包文件夹）添加到MATLAB路径中。
    ```matlab
    % 在MATLAB命令行中，导航到项目根目录并执行：
    addpath(genpath(pwd)); %
    ```
    或者，`main_Orchestrator.m` 脚本在开始执行时会自动尝试将项目根目录及其子目录添加到路径中。
3.  **配置参数 (推荐方式)**:
    * 导航到 `WebApp/` 文件夹。
    * 在MATLAB中打开并运行 `DroneLogisticsConfigurator.mlapp`。
    * 在图形界面中设置您期望的仿真参数。
    * 点击界面中的 "Save Config & Prepare Run" 按钮。这将参数保存到 `configurations/current_run_parameters.mat`。
4.  **配置参数 (备选方式 - 手动或默认)**:
    * 如果您不使用WebApp，可以手动修改 `configurations/default_simulation_parameters.m` 文件中的默认值。
    * 或者，确保 `configurations/current_run_parameters.mat` 文件存在且包含有效的 `params` 结构体（可以先通过WebApp生成一次）。`main_Orchestrator.m` 在找不到此文件或文件无效时，会加载默认参数。
5.  **运行主程序**:
    * 在MATLAB编辑器中打开位于项目根目录的 `main_Orchestrator.m` 文件。
    * 点击编辑器中的 "运行" (Run) 按钮，或在MATLAB命令行中输入 `main_Orchestrator` 并按回车。
6.  **查看结果**:
    * 仿真运行期间，控制台会输出各个阶段的信息，并记录到 `results_output/ExperimentRun_yyyymmdd_HHMMSS/simulation_log.txt`。
    * 所有生成的图表、KML文件、数据文件和报告都将保存在对应的 `results_output/ExperimentRun_yyyymmdd_HHMMSS/` 子文件夹中。

## 注意事项

* KML文件的生成和部分地理绘图功能依赖MATLAB Mapping Toolbox。如果未安装，相关功能将被跳过或以基础绘图方式替代。
* 算法参数（尤其是SA和ACO的参数）对求解质量和计算时间有显著影响，可能需要根据具体问题规模进行调优。
* ACO算法的并行化 (`parfor`) 需要Parallel Computing Toolbox才能真正实现并行计算，否则将作为普通 `for` 循环串行执行。
* `main_Orchestrator.m` 脚本在启动时会尝试将当前脚本所在的目录（假定为项目根目录）及其所有子目录添加到 MATLAB 路径中，并刷新工具箱路径缓存。

## 未来展望与可扩展方向

* 集成更高级的枢纽选址算法（如p-中值模型、集合覆盖模型等）。
* 引入动态需求、时间窗约束等更复杂的VRP变种。
*
