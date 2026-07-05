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

## Resultados

Os experimentos mostram que o algoritmo GA_Pure obteve o menor makespan e consumo energético, enquanto a arquitetura híbrida NSGA2_SA_RL apresentou o menor número de violações de deadlines, mantendo desempenho competitivo nas demais métricas. Os resultados demonstram que a combinação de otimização evolutiva com aprendizado por reforço é uma estratégia promissora para o escalonamento inteligente em ambientes HPC heterogêneos.
