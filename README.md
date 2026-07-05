# Hybrid AI Scheduler for Heterogeneous HPC Environments

Este repositório apresenta uma arquitetura híbrida para escalonamento inteligente de tarefas em ambientes de Computação de Alto Desempenho (HPC). A abordagem combina otimização offline baseada em NSGA-II (Non-dominated Sorting Genetic Algorithm II) e Simulated Annealing (SA) com adaptação online por meio de Q-Learning.

A arquitetura foi implementada no simulador SimGrid e comparada com algoritmos clássicos e baseados em Inteligência Artificial, incluindo FCFS, EDF, Min-Min, GA_Pure e RL_Pure.

## Principais características

- Escalonamento multiobjetivo.
- Minimização de makespan.
- Redução do consumo energético.
- Minimização de violações de deadlines.
- Adaptação dinâmica via aprendizado por reforço.
- Execução em plataformas HPC heterogêneas.

## Tecnologias

- C++
- SimGrid
- NSGA-II
- Simulated Annealing
- Q-Learning


## Instructions

### Prerequisites

This project was developed and tested using **SimGrid 4.1**. Before running the project, install SimGrid by following the official installation guide:

https://simgrid.org/

After installation, the project structure should be organized as follows:

```text
<root_directory>/
├── simgrid/                  # SimGrid 4.1 installation
├── create_project.sh         # Project generation script
```

The `create_project.sh` script must be placed in the **same root directory** as the SimGrid installation and executed from there.

### 1. Make the script executable

```bash
chmod +x create_project.sh
```

### 2. Generate the project

```bash
./create_project.sh
```

This command creates the `tarefa3_fia_hpc` project directory, including all source files, scheduler implementations, build configuration, and execution scripts.

### 3. Compile and run the simulations

```bash
cd tarefa3_fia_hpc
bash scripts/run_all.sh
```

### Output

After execution, the project generates one directory for each scheduling algorithm:

```text
fcfs/
edf/
minmin/
ga_pure/
rl_pure/
adaptive/
```

Each directory contains the corresponding simulation outputs. The main results for each scheduler are stored in a file named:

```text
results.csv
```

These CSV files contain the performance metrics collected during the simulations and can be used for analysis, comparison, and visualization of the scheduling algorithms.



## Resultados

Os experimentos mostram que o algoritmo GA_Pure obteve o menor makespan e consumo energético, enquanto a arquitetura híbrida NSGA2_SA_RL apresentou o menor número de violações de deadlines, mantendo desempenho competitivo nas demais métricas. Os resultados demonstram que a combinação de otimização evolutiva com aprendizado por reforço é uma estratégia promissora para o escalonamento inteligente em ambientes HPC heterogêneos.
