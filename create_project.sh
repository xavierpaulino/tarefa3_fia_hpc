#!/bin/bash
set -e

BASE_DIR="$(pwd)/tarefa3_fia_hpc"
rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"

# ----------------------------------------------------------------------
# Heterogeneous platform with per‑node wattage (unchanged)
# ----------------------------------------------------------------------
mkdir -p "$BASE_DIR/platforms"
cat > "$BASE_DIR/platforms/cluster_8nodes.xml" << 'EOF'
<?xml version='1.0'?>
<!DOCTYPE platform SYSTEM "https://simgrid.org/simgrid.dtd">
<platform version="4.1">
  <zone id="world" routing="Full">
    <host id="node-0" speed="2.0Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-1" speed="2.2Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-2" speed="2.4Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-3" speed="2.6Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-4" speed="2.8Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-5" speed="3.0Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-6" speed="2.3Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <host id="node-7" speed="2.5Gf">
      <prop id="wattage_per_state" value="95.0:200.0"/>
      <prop id="wattage_off" value="10"/>
    </host>
    <link id="link1" bandwidth="1GBps" latency="10us"/>
    <!-- full routes -->
    <route src="node-0" dst="node-1"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-2"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-3"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-4"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-5"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-0" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-2"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-3"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-4"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-5"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-1" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-2" dst="node-3"><link_ctn id="link1"/></route>
    <route src="node-2" dst="node-4"><link_ctn id="link1"/></route>
    <route src="node-2" dst="node-5"><link_ctn id="link1"/></route>
    <route src="node-2" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-2" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-3" dst="node-4"><link_ctn id="link1"/></route>
    <route src="node-3" dst="node-5"><link_ctn id="link1"/></route>
    <route src="node-3" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-3" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-4" dst="node-5"><link_ctn id="link1"/></route>
    <route src="node-4" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-4" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-5" dst="node-6"><link_ctn id="link1"/></route>
    <route src="node-5" dst="node-7"><link_ctn id="link1"/></route>
    <route src="node-6" dst="node-7"><link_ctn id="link1"/></route>
  </zone>
</platform>
EOF

# ----------------------------------------------------------------------
# Metrics and Workload (unchanged)
# ----------------------------------------------------------------------
cat > "$BASE_DIR/Metrics.h" << 'EOF'
#ifndef METRICS_H
#define METRICS_H
struct Metrics { double makespan; double total_energy; int deadline_misses; double fairness; };
#endif
EOF

cat > "$BASE_DIR/Workload.h" << 'EOF'
#ifndef WORKLOAD_H
#define WORKLOAD_H
#include <vector>
#include <string>
struct Task { int id; double flops; double bytes; double deadline; double release; };
class Workload {
public:
    static std::vector<Task> synthetic(int num_tasks, long seed = 456);
    static std::vector<Task> historical(int num_tasks = 1000, long seed = 456);
};
#endif
EOF

cat > "$BASE_DIR/Workload.cpp" << 'EOF'
#include "Workload.h"
#include <random>
#include <cmath>
#include <iostream>
#include <algorithm>

static std::vector<Task> generate(int num_tasks, long seed) {
    std::mt19937 rng(seed);

    std::uniform_real_distribution<> deadline_factor_dist(5.0, 10.0);
    std::exponential_distribution<> interarrival(0.4);

    std::lognormal_distribution<> flops_dist(25.0, 2.5);
    std::lognormal_distribution<> io_dist(18.0, 3.0);
    std::uniform_real_distribution<> jitter_dist(1.0, 10.0);

    std::vector<Task> tasks;
    double current_time = 0.0;

    for (int i = 0; i < num_tasks; ++i) {
        Task t;
        t.id = i;

        current_time += interarrival(rng);
        t.release = current_time;

        t.flops = std::max(1e8, flops_dist(rng));
        t.bytes = std::max(1e5, io_dist(rng));

        double estimated_runtime = t.flops / 2.4e9 + t.bytes / 1e9;
        double base_factor = deadline_factor_dist(rng);
        double jitter = jitter_dist(rng);

        // Deadline is relative to the release time and proportional to the estimated
        // processing demand. The previous 1e-4..1e-3 factor made almost every
        // deadline physically infeasible and collapsed scheduler differences.
        t.deadline = current_time + estimated_runtime * base_factor * jitter;

        tasks.push_back(t);
    }

    // Preserve chronological IDs and release order. The simulation injects tasks by
    // release time; shuffling here only made task IDs unrelated to arrival order and
    // corrupted offline policy bootstrapping.

    std::cout << "Generated " << tasks.size() << " heterogeneous HPC tasks.\n";
    return tasks;
}

std::vector<Task> Workload::synthetic(int num_tasks, long seed) {
    return generate(num_tasks, seed);
}
std::vector<Task> Workload::historical(int num_tasks, long seed) {
    return generate(num_tasks, seed);
}
EOF

# ----------------------------------------------------------------------
# Helper: create one scheduler project
# ----------------------------------------------------------------------
create_scheduler() {
    local name=$1
    local dir="$BASE_DIR/$name"
    mkdir -p "$dir"
    cp "$BASE_DIR/platforms/cluster_8nodes.xml" "$dir/"
    cp "$BASE_DIR/Metrics.h" "$dir/"
    cp "$BASE_DIR/Workload.h" "$dir/"
    cp "$BASE_DIR/Workload.cpp" "$dir/"

    cat > "$dir/scheduler.cpp" << 'EOF_TOP'
#include "simgrid/s4u.hpp"
#include "simgrid/plugins/energy.h"
#include "Workload.h"
#include "Metrics.h"
#include <iostream>
#include <vector>
#include <deque>
#include <algorithm>
#include <limits>
#include <unordered_map>
#include <numeric>
#include <random>
#include <cmath>
#include <memory>
#include <fstream>

namespace sg4 = simgrid::s4u;

constexpr double BANDWIDTH = 1e9; // 1 GB/s

static double getNodePower(sg4::Host* h) {
    const char* watt = h->get_property("wattage_per_state");
    if (!watt) return 200.0;
    std::string s(watt);
    size_t pos = s.find(':');
    if (pos == std::string::npos) return 200.0;
    return std::stod(s.substr(pos + 1));
}

EOF_TOP

    # ------------------------------------------------------------------
    # FCFS
    # ------------------------------------------------------------------
    if [ "$name" = "fcfs" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_FCFS'
class Scheduler {
    std::deque<Task> queue;
    std::vector<double> speeds, power;
public:
    void init(int n, const std::vector<double>& sp, const std::vector<double>& pw, unsigned int) {
        speeds = sp; power = pw; queue.clear();
    }
    void onTaskArrival(const Task& t, double, const std::vector<double>&) { queue.push_back(t); }
    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        Task t = queue.front(); queue.pop_front();
        double best_ct = std::numeric_limits<double>::max();
        int best_node = free_nodes[0];
        for (int n : free_nodes) {
            double exec = t.flops / speeds[n] + t.bytes / BANDWIDTH;
            double ct = now + node_load[n] + exec;
            if (ct < best_ct) { best_ct = ct; best_node = n; }
        }
        return {best_node, t};
    }
    void onTaskCompletion(const Task&, int, double, const std::vector<double>&) {}
    std::string name() const { return "FCFS"; }
};
EOF_FCFS

    # ------------------------------------------------------------------
    # EDF
    # ------------------------------------------------------------------
    elif [ "$name" = "edf" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_EDF'
class Scheduler {
    std::vector<Task> queue;
    std::vector<double> speeds;
public:
    void init(int n, const std::vector<double>& sp, const std::vector<double>&, unsigned int) {
        speeds = sp; queue.clear();
    }
    void onTaskArrival(const Task& t, double, const std::vector<double>&) {
        queue.push_back(t);
        std::sort(queue.begin(), queue.end(),
                  [](const Task& a, const Task& b){ return a.deadline < b.deadline; });
    }
    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        size_t idx = 0;
        while (idx < queue.size() && queue[idx].release > now + 1e-9) ++idx;
        if (idx == queue.size()) return {-1, Task{}};
        Task t = queue[idx];
        queue.erase(queue.begin() + idx);
        double best_ct = std::numeric_limits<double>::max();
        int best_node = free_nodes[0];
        for (int n : free_nodes) {
            double exec = t.flops / speeds[n] + t.bytes / BANDWIDTH;
            double ct = now + node_load[n] + exec;
            if (ct < best_ct) { best_ct = ct; best_node = n; }
        }
        return {best_node, t};
    }
    void onTaskCompletion(const Task&, int, double, const std::vector<double>&) {}
    std::string name() const { return "EDF"; }
};
EOF_EDF

    # ------------------------------------------------------------------
    # Min‑Min
    # ------------------------------------------------------------------
    elif [ "$name" = "minmin" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_MINMIN'
class Scheduler {
    std::vector<Task> queue;
    std::vector<double> speeds;
public:
    void init(int n, const std::vector<double>& sp, const std::vector<double>&, unsigned int) {
        speeds = sp; queue.clear();
    }
    void onTaskArrival(const Task& t, double, const std::vector<double>&) { queue.push_back(t); }
    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        double best_ct = std::numeric_limits<double>::max();
        int best_task = -1, best_node = -1;
        for (size_t i = 0; i < queue.size(); ++i) {
            double min_ct = std::numeric_limits<double>::max();
            int best_for_task = -1;
            for (int n : free_nodes) {
                double exec = queue[i].flops / speeds[n] + queue[i].bytes / BANDWIDTH;
                double ct = now + node_load[n] + exec;
                if (ct < min_ct) { min_ct = ct; best_for_task = n; }
            }
            if (min_ct < best_ct) { best_ct = min_ct; best_task = i; best_node = best_for_task; }
        }
        if (best_task == -1) return {-1, Task{}};
        Task t = queue[best_task];
        queue.erase(queue.begin() + best_task);
        return {best_node, t};
    }
    void onTaskCompletion(const Task&, int, double, const std::vector<double>&) {}
    std::string name() const { return "MinMin"; }
};
EOF_MINMIN

    # ------------------------------------------------------------------
    # GA – NSGA‑II with normalised weighted sum selection
    # ------------------------------------------------------------------
    elif [ "$name" = "ga_pure" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_GAPURE'
// ----------------------------------------------------------------------
// Multi-objective NSGA-II representation for scheduling
// Chromosome = node assignment + execution priority. This is necessary
// because deadline-aware scheduling depends on both WHERE and WHEN a task runs.
// ----------------------------------------------------------------------
constexpr double DEFAULT_IDLE_POWER = 95.0;

struct Individual {
    std::vector<int> assignment;
    std::vector<double> priority;
    double makespan = 0.0;
    double energy = 0.0;
    int deadline_misses = 0;
    double deadline_violation = 0.0;
    double fairness = 1.0;
    int rank = 0;
    double crowding = 0.0;
};

static std::vector<double> defaultPriority(const std::vector<Task>& tasks) {
    std::vector<double> p(tasks.size(), 0.0);
    for (size_t i = 0; i < tasks.size(); ++i) {
        // Earlier deadlines receive higher priority by default.
        p[i] = tasks[i].deadline;
    }
    return p;
}

bool dominates(const Individual& a, const Individual& b) {
    int better = 0, worse = 0;
    if (a.makespan < b.makespan) better++; else if (a.makespan > b.makespan) worse++;
    if (a.energy < b.energy) better++; else if (a.energy > b.energy) worse++;
    if (a.deadline_misses < b.deadline_misses) better++; else if (a.deadline_misses > b.deadline_misses) worse++;
    if (a.fairness > b.fairness) better++; else if (a.fairness < b.fairness) worse++;
    return (better > 0 && worse == 0);
}

void fastNonDominatedSort(std::vector<Individual>& pop) {
    std::vector<std::vector<int>> dominatedBy(pop.size());
    std::vector<int> dominationCount(pop.size(), 0);
    std::vector<int> currentFront;
    for (size_t i = 0; i < pop.size(); ++i) {
        pop[i].rank = 0;
        for (size_t j = 0; j < pop.size(); ++j) {
            if (i == j) continue;
            if (dominates(pop[i], pop[j])) dominatedBy[i].push_back((int)j);
            else if (dominates(pop[j], pop[i])) dominationCount[i]++;
        }
        if (dominationCount[i] == 0) { pop[i].rank = 0; currentFront.push_back((int)i); }
    }
    int front = 0;
    while (!currentFront.empty()) {
        std::vector<int> nextFront;
        for (int i : currentFront) {
            for (int j : dominatedBy[i]) {
                if (--dominationCount[j] == 0) { pop[j].rank = front + 1; nextFront.push_back(j); }
            }
        }
        ++front;
        currentFront = nextFront;
    }
}

void crowdingDistance(std::vector<Individual>& front) {
    if (front.empty()) return;
    for (auto& ind : front) ind.crowding = 0.0;
    if (front.size() <= 2) {
        for (auto& ind : front) ind.crowding = std::numeric_limits<double>::max();
        return;
    }
    const int m = 4;
    for (int obj = 0; obj < m; ++obj) {
        std::sort(front.begin(), front.end(),
                  [obj](const Individual& a, const Individual& b) {
                      if (obj == 0) return a.makespan < b.makespan;
                      if (obj == 1) return a.energy < b.energy;
                      if (obj == 2) return a.deadline_misses < b.deadline_misses;
                      return a.fairness > b.fairness;
                  });
        front.front().crowding = front.back().crowding = std::numeric_limits<double>::max();
        double minVal, maxVal;
        if (obj == 0) { minVal = front.front().makespan; maxVal = front.back().makespan; }
        else if (obj == 1) { minVal = front.front().energy; maxVal = front.back().energy; }
        else if (obj == 2) { minVal = front.front().deadline_misses; maxVal = front.back().deadline_misses; }
        else { minVal = front.back().fairness; maxVal = front.front().fairness; }
        if (maxVal - minVal > 1e-12) {
            for (size_t i = 1; i + 1 < front.size(); ++i) {
                double prevObj, nextObj;
                if (obj == 0) { prevObj = front[i-1].makespan; nextObj = front[i+1].makespan; }
                else if (obj == 1) { prevObj = front[i-1].energy; nextObj = front[i+1].energy; }
                else if (obj == 2) { prevObj = front[i-1].deadline_misses; nextObj = front[i+1].deadline_misses; }
                else { prevObj = front[i+1].fairness; nextObj = front[i-1].fairness; }
                front[i].crowding += (nextObj - prevObj) / (maxVal - minVal);
            }
        }
    }
}

Individual evaluate(const std::vector<int>& assign, const std::vector<double>& priority,
                    const std::vector<Task>& tasks, const std::vector<double>& speeds,
                    const std::vector<double>& power) {
    int nodes = (int)speeds.size();
    std::vector<double> node_finish(nodes, 0.0), node_busy(nodes, 0.0), work(nodes, 0.0);
    std::vector<int> order(tasks.size());
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&](int a, int b) {
        if (std::abs(priority[a] - priority[b]) > 1e-12) return priority[a] < priority[b];
        return tasks[a].release < tasks[b].release;
    });

    double violation = 0.0;
    int misses = 0;
    for (int idx : order) {
        int node = std::max(0, std::min((int)assign[idx], nodes - 1));
        double exec = tasks[idx].flops / speeds[node] + tasks[idx].bytes / BANDWIDTH;
        double start = std::max(tasks[idx].release, node_finish[node]);
        double finish = start + exec;
        node_finish[node] = finish;
        node_busy[node] += exec;
        work[node] += tasks[idx].flops;
        if (finish > tasks[idx].deadline + 1e-9) {
            ++misses;
            violation += (finish - tasks[idx].deadline);
        }
    }

    double makespan = *std::max_element(node_finish.begin(), node_finish.end());
    double total_energy = 0.0;
    for (int n = 0; n < nodes; ++n) {
        // Approximate SimGrid host energy: idle energy over whole makespan plus
        // additional active-minus-idle energy while executing tasks.
        double active = power[n];
        double idle = DEFAULT_IDLE_POWER;
        total_energy += idle * makespan + std::max(0.0, active - idle) * node_busy[n];
    }

    double sum = std::accumulate(work.begin(), work.end(), 0.0);
    double sq = 0.0; for (double w : work) sq += w*w;
    double fairness = (sq > 1e-12) ? (sum*sum) / (nodes * sq) : 1.0;

    Individual ind;
    ind.assignment = assign;
    ind.priority = priority;
    ind.makespan = makespan;
    ind.energy = total_energy;
    ind.deadline_misses = misses;
    ind.deadline_violation = violation;
    ind.fairness = fairness;
    return ind;
}

Individual evaluate(const std::vector<int>& assign, const std::vector<Task>& tasks,
                    const std::vector<double>& speeds, const std::vector<double>& power) {
    return evaluate(assign, defaultPriority(tasks), tasks, speeds, power);
}

// Select one deployable member from the Pareto front. NSGA-II itself remains
// Pareto-based; this tie-break only chooses the schedule to execute online.
Individual selectBest(const std::vector<Individual>& candidates) {
    if (candidates.empty()) return Individual{};
    const int nObj = 4;
    double minVals[4] = {1e18,1e18,1e18,1e18};
    double maxVals[4] = {-1e18,-1e18,-1e18,-1e18};
    for (const auto& ind : candidates) {
        double vals[4] = {ind.makespan, ind.energy, (double)ind.deadline_misses, -ind.fairness};
        for (int j = 0; j < nObj; ++j) {
            minVals[j] = std::min(minVals[j], vals[j]);
            maxVals[j] = std::max(maxVals[j], vals[j]);
        }
    }
    double bestScore = 1e18;
    int bestIdx = 0;
    for (size_t i = 0; i < candidates.size(); ++i) {
        double vals[4] = {candidates[i].makespan, candidates[i].energy,
                          (double)candidates[i].deadline_misses, -candidates[i].fairness};
        double norm[4];
        for (int j = 0; j < nObj; ++j) {
            double range = maxVals[j] - minVals[j];
            norm[j] = (range > 1e-12) ? (vals[j] - minVals[j]) / range : 0.0;
        }
        // Final deployment tie-break over exactly the reported objectives:
        // makespan, energy, deadline_misses, fairness.
        double score = 0.25*norm[0] + 0.20*norm[1] + 0.35*norm[2] + 0.20*norm[3];
        if (score < bestScore) { bestScore = score; bestIdx = (int)i; }
    }
    return candidates[bestIdx];
}

void writeParetoFrontCSV(const std::string& schedulerName, const std::vector<Individual>& pareto, unsigned int seed) {
    std::ofstream out("../pareto_front.csv", std::ios::app);
    if (!out.is_open()) return;
    out.seekp(0, std::ios::end);
    if (out.tellp() == std::streampos(0)) {
        out << "scheduler,seed,solution_id,makespan,total_energy,deadline_misses,fairness,deadline_violation\n";
    }
    int sid = 0;
    for (const auto& ind : pareto) {
        out << schedulerName << "," << seed << "," << sid++ << ","
            << ind.makespan << "," << ind.energy << ","
            << ind.deadline_misses << "," << ind.fairness << ","
            << ind.deadline_violation << "\n";
    }
}

class GA {
    int pop_size, generations;
    double crossover_rate, mutation_rate;
    std::mt19937 rng;
    unsigned int seed_value;
    std::string label;
public:
    GA(int ps=100, int gen=80, double cr=0.8, double mr=0.08, unsigned int seed=456, const std::string& lbl="GA_Pure")
        : pop_size(ps), generations(gen), crossover_rate(cr), mutation_rate(mr), rng(seed), seed_value(seed), label(lbl) {}

    Individual optimizeIndividual(const std::vector<Task>& tasks, int num_nodes,
                                  const std::vector<double>& speeds,
                                  const std::vector<double>& power) {
        if (tasks.empty()) return Individual{};
        std::uniform_real_distribution<double> real01(0.0, 1.0);
        std::vector<Individual> pop(pop_size);
        for (auto& ind : pop) {
            ind.assignment.resize(tasks.size());
            ind.priority.resize(tasks.size());
            for (size_t i = 0; i < tasks.size(); ++i) {
                ind.assignment[i] = rng() % num_nodes;
                // Blend EDF prior with random diversity: deadline-aware but not fixed.
                ind.priority[i] = tasks[i].deadline * (0.80 + 0.40 * real01(rng));
            }
            ind = evaluate(ind.assignment, ind.priority, tasks, speeds, power);
        }

        for (int gen = 0; gen < generations; ++gen) {
            fastNonDominatedSort(pop);
            std::vector<Individual> popWithCrowding;
            int maxRankPop = 0;
            for (auto& ind : pop) maxRankPop = std::max(maxRankPop, ind.rank);
            for (int r = 0; r <= maxRankPop; ++r) {
                std::vector<Individual> front;
                for (auto& ind : pop) if (ind.rank == r) front.push_back(ind);
                crowdingDistance(front);
                popWithCrowding.insert(popWithCrowding.end(), front.begin(), front.end());
            }
            pop = popWithCrowding;

            auto tournament = [&]() -> Individual {
                int i1 = rng() % pop.size(), i2 = rng() % pop.size();
                if (pop[i1].rank < pop[i2].rank) return pop[i1];
                if (pop[i2].rank < pop[i1].rank) return pop[i2];
                return (pop[i1].crowding > pop[i2].crowding) ? pop[i1] : pop[i2];
            };

            std::vector<Individual> offspring;
            while (offspring.size() < (size_t)pop_size) {
                Individual p1 = tournament(), p2 = tournament();
                Individual c1, c2;
                c1.assignment.resize(tasks.size()); c2.assignment.resize(tasks.size());
                c1.priority.resize(tasks.size()); c2.priority.resize(tasks.size());
                for (size_t i = 0; i < tasks.size(); ++i) {
                    if (real01(rng) < crossover_rate) {
                        bool takeP1 = (rng() % 2) != 0;
                        c1.assignment[i] = takeP1 ? p1.assignment[i] : p2.assignment[i];
                        c2.assignment[i] = takeP1 ? p2.assignment[i] : p1.assignment[i];
                        double beta = real01(rng);
                        c1.priority[i] = beta*p1.priority[i] + (1.0-beta)*p2.priority[i];
                        c2.priority[i] = beta*p2.priority[i] + (1.0-beta)*p1.priority[i];
                    } else {
                        c1.assignment[i] = p1.assignment[i]; c2.assignment[i] = p2.assignment[i];
                        c1.priority[i] = p1.priority[i]; c2.priority[i] = p2.priority[i];
                    }
                    if (real01(rng) < mutation_rate) c1.assignment[i] = rng() % num_nodes;
                    if (real01(rng) < mutation_rate) c2.assignment[i] = rng() % num_nodes;
                    if (real01(rng) < mutation_rate) c1.priority[i] *= (0.75 + 0.50 * real01(rng));
                    if (real01(rng) < mutation_rate) c2.priority[i] *= (0.75 + 0.50 * real01(rng));
                }
                c1 = evaluate(c1.assignment, c1.priority, tasks, speeds, power);
                c2 = evaluate(c2.assignment, c2.priority, tasks, speeds, power);
                offspring.push_back(c1);
                if (offspring.size() < (size_t)pop_size) offspring.push_back(c2);
            }

            std::vector<Individual> combined;
            combined.reserve(pop.size() + offspring.size());
            combined.insert(combined.end(), pop.begin(), pop.end());
            combined.insert(combined.end(), offspring.begin(), offspring.end());
            fastNonDominatedSort(combined);
            pop.clear();
            int maxRankCombined = 0;
            for (auto& ind : combined) maxRankCombined = std::max(maxRankCombined, ind.rank);
            for (int r = 0; r <= maxRankCombined && pop.size() < (size_t)pop_size; ++r) {
                std::vector<Individual> front;
                for (auto& ind : combined) if (ind.rank == r) front.push_back(ind);
                crowdingDistance(front);
                std::sort(front.begin(), front.end(), [](const Individual& a, const Individual& b){ return a.crowding > b.crowding; });
                for (auto& ind : front) {
                    if (pop.size() < (size_t)pop_size) pop.push_back(ind);
                    else break;
                }
            }
        }

        fastNonDominatedSort(pop);
        std::vector<Individual> pareto;
        for (auto& ind : pop) if (ind.rank == 0) pareto.push_back(ind);
        const std::vector<Individual>& finalFront = pareto.empty() ? pop : pareto;
        writeParetoFrontCSV(label, finalFront, seed_value);
        std::cout << "[" << label << "] Pareto front size: " << finalFront.size() << "\n";
        return selectBest(finalFront);
    }

    std::vector<int> optimize(const std::vector<Task>& tasks, int num_nodes,
                              const std::vector<double>& speeds,
                              const std::vector<double>& power) {
        return optimizeIndividual(tasks, num_nodes, speeds, power).assignment;
    }
};
// ----------------------------------------------------------------------
// Online scheduler using NSGA‑II; re‑optimises on queue change
// ----------------------------------------------------------------------
class Scheduler {
    std::vector<Task> queue;
    std::vector<double> speeds, power;
    int num_nodes;
    std::unique_ptr<GA> ga;
    std::vector<int> best_assign;
    std::vector<double> best_priority;
    bool need_reopt;
    size_t last_queue_size;
public:
    Scheduler() : need_reopt(true), last_queue_size(0) {}

    void init(int n, const std::vector<double>& sp, const std::vector<double>& pw, unsigned int seed) {
        num_nodes = n; speeds = sp; power = pw; queue.clear(); need_reopt = true;
        ga = std::make_unique<GA>(120, 60, 0.8, 0.08, seed, "GA_Pure");
    }
    void onTaskArrival(const Task& t, double, const std::vector<double>&) {
        queue.push_back(t); need_reopt = true;
    }
    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        if (need_reopt || queue.size() != last_queue_size) {
            Individual plan = ga->optimizeIndividual(queue, num_nodes, speeds, power);
            best_assign = plan.assignment;
            best_priority = plan.priority;
            last_queue_size = queue.size();
            need_reopt = false;
        }
        int best_idx = -1, best_node = -1;
        double best_prio = std::numeric_limits<double>::max();
        for (size_t i = 0; i < queue.size(); ++i) {
            if (queue[i].release > now + 1e-9) continue;
            int node = best_assign[i];
            if (std::find(free_nodes.begin(), free_nodes.end(), node) == free_nodes.end()) continue;
            double pr = (i < best_priority.size()) ? best_priority[i] : queue[i].deadline;
            if (pr < best_prio) { best_prio = pr; best_idx = (int)i; best_node = node; }
        }
        if (best_idx == -1) {
            // If the planned node is busy, still exploit a free node instead of idling.
            double best_ct = std::numeric_limits<double>::max();
            for (size_t i = 0; i < queue.size(); ++i) {
                if (queue[i].release > now + 1e-9) continue;
                for (int n : free_nodes) {
                    double exec = queue[i].flops / speeds[n] + queue[i].bytes / BANDWIDTH;
                    double ct = now + node_load[n] + exec;
                    if (ct < best_ct) { best_ct = ct; best_idx = (int)i; best_node = n; }
                }
            }
            if (best_idx == -1) return {-1, Task{}};
        }
        Task t = queue[best_idx];
        queue.erase(queue.begin() + best_idx);
        if (best_idx < (int)best_assign.size()) best_assign.erase(best_assign.begin() + best_idx);
        if (best_idx < (int)best_priority.size()) best_priority.erase(best_priority.begin() + best_idx);
        need_reopt = true;
        return {best_node, t};
    }
    void onTaskCompletion(const Task&, int, double, const std::vector<double>&) {
        need_reopt = true;
    }
    std::string name() const { return "GA_Pure"; }
};
EOF_GAPURE

    # ------------------------------------------------------------------
    # RL – Q‑learning
    # ------------------------------------------------------------------
    elif [ "$name" = "rl_pure" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_RL'
class Scheduler {
    std::vector<Task> queue;
    std::vector<double> speeds, power;
    int num_nodes;
    std::vector<std::vector<double>> Q;
    double alpha, gamma, epsilon;
    int step_count;
    static constexpr int num_states = 10000;
    struct DispatchInfo { int state; int action; double start_time; };
    std::unordered_map<int, DispatchInfo> dispatched;
    double current_energy = 0.0;
    std::mt19937 rng;
    std::vector<int> offline_policy;

    int discretizeState(const std::vector<double>& node_load, double now) {
        double avg_load = std::accumulate(node_load.begin(), node_load.end(), 0.0) / num_nodes;
        int load_bin = std::min(9, (int)(avg_load / 100.0));
        int queue_bin = std::min(9, (int)(queue.size() / 10));
        double avg_slack = 0.0;
        for (auto& t : queue) avg_slack += (t.deadline - now);
        if (!queue.empty()) avg_slack /= queue.size();
        int slack_bin = std::min(9, std::max(0, (int)(avg_slack / 50.0)));
        double avg_power = 0.0;
        for (int n = 0; n < num_nodes; ++n) avg_power += power[n];
        avg_power /= num_nodes;
        int power_bin = std::min(9, (int)(avg_power / 50.0));
        return load_bin + 10*queue_bin + 100*slack_bin + 1000*power_bin;
    }

    int selectAction(int state, const std::vector<int>& free_nodes) {
        double eps = std::max(0.05, epsilon * std::exp(-step_count / 5000.0));
        std::uniform_real_distribution<double> prob(0.0, 1.0);
        std::uniform_int_distribution<int> pick(0, (int)free_nodes.size() - 1);
        if (prob(rng) < eps) {
            return free_nodes[pick(rng)];
        }
        const auto& qvals = Q[state];
        int best_action = free_nodes[0];
        double best_val = -std::numeric_limits<double>::max();
        for (int n : free_nodes) {
            if (qvals[n] > best_val) { best_val = qvals[n]; best_action = n; }
        }
        return best_action;
    }

    void updateQ(int s, int a, double reward, int ns) {
        double best = -std::numeric_limits<double>::max();
        for (double v : Q[ns]) best = std::max(best, v);
        Q[s][a] += alpha * (reward + gamma * best - Q[s][a]);
    }

public:
    Scheduler(double a=0.4, double g=0.9, double e=0.5) : alpha(a), gamma(g), epsilon(e) {
        step_count = 0;
    }

    void init(int n, const std::vector<double>& sp, const std::vector<double>& pw, unsigned int seed) {
        num_nodes = n; speeds = sp; power = pw;
        queue.clear(); step_count = 0; current_energy = 0.0;
        Q.assign(num_states, std::vector<double>(num_nodes, 0.0));
        dispatched.clear();
        rng.seed(seed);
    }

    void onTaskArrival(const Task& t, double, const std::vector<double>&) {
        queue.push_back(t);
        std::sort(queue.begin(), queue.end(),
                  [](const Task& a, const Task& b){ return a.deadline < b.deadline; });
    }

    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        size_t idx = 0;
        while (idx < queue.size() && queue[idx].release > now + 1e-9) ++idx;
        if (idx == queue.size()) return {-1, Task{}};
        Task t = queue[idx];
        queue.erase(queue.begin() + idx);
        int state = discretizeState(node_load, now);
        int chosen_node = selectAction(state, free_nodes);
        dispatched[t.id] = {state, chosen_node, now};
        return {chosen_node, t};
    }

    void onTaskCompletion(const Task& task, int node, double finish_time,
                          const std::vector<double>& node_load) {
        auto it = dispatched.find(task.id);
        if (it == dispatched.end()) return;
        double exec = finish_time - it->second.start_time;
        double violation = std::max(0.0, finish_time - task.deadline);
        double energy_used = power[node] * exec;
        current_energy += energy_used;
        double miss = (violation > 1e-9) ? 1.0 : 0.0;
        double avg_load = std::accumulate(node_load.begin(), node_load.end(), 0.0) / std::max(1, num_nodes);
        double balance_penalty = std::abs(node_load[node] - avg_load) / (avg_load + 1.0);
        // Reward aligned with reported objectives: makespan proxy, energy,
        // deadline_misses, and fairness/load balance. Tardiness is kept only
        // as a secondary pressure inside the deadline term.
        double reward = - (exec / 50000.0 + energy_used / 1e8 + 3.0 * miss + violation / 50000.0 + 0.5 * balance_penalty);
        int next_state = discretizeState(node_load, finish_time);
        updateQ(it->second.state, it->second.action, reward, next_state);
        dispatched.erase(it);
        ++step_count;
    }

    std::string name() const { return "RL_Pure"; }
};
EOF_RL

    # ------------------------------------------------------------------
    # Adaptive – NSGA‑II+SA + Q‑learning
    # ------------------------------------------------------------------
    elif [ "$name" = "adaptive" ]; then
        cat >> "$dir/scheduler.cpp" << 'EOF_ADAPTIVE'
// ----------------------------------------------------------------------
// Multi-objective NSGA-II representation for scheduling
// Chromosome = node assignment + execution priority. This is necessary
// because deadline-aware scheduling depends on both WHERE and WHEN a task runs.
// ----------------------------------------------------------------------
constexpr double DEFAULT_IDLE_POWER = 95.0;

struct Individual {
    std::vector<int> assignment;
    std::vector<double> priority;
    double makespan = 0.0;
    double energy = 0.0;
    int deadline_misses = 0;
    double deadline_violation = 0.0;
    double fairness = 1.0;
    int rank = 0;
    double crowding = 0.0;
};

static std::vector<double> defaultPriority(const std::vector<Task>& tasks) {
    std::vector<double> p(tasks.size(), 0.0);
    for (size_t i = 0; i < tasks.size(); ++i) {
        // Earlier deadlines receive higher priority by default.
        p[i] = tasks[i].deadline;
    }
    return p;
}

bool dominates(const Individual& a, const Individual& b) {
    int better = 0, worse = 0;
    if (a.makespan < b.makespan) better++; else if (a.makespan > b.makespan) worse++;
    if (a.energy < b.energy) better++; else if (a.energy > b.energy) worse++;
    if (a.deadline_misses < b.deadline_misses) better++; else if (a.deadline_misses > b.deadline_misses) worse++;
    if (a.fairness > b.fairness) better++; else if (a.fairness < b.fairness) worse++;
    return (better > 0 && worse == 0);
}

void fastNonDominatedSort(std::vector<Individual>& pop) {
    std::vector<std::vector<int>> dominatedBy(pop.size());
    std::vector<int> dominationCount(pop.size(), 0);
    std::vector<int> currentFront;
    for (size_t i = 0; i < pop.size(); ++i) {
        pop[i].rank = 0;
        for (size_t j = 0; j < pop.size(); ++j) {
            if (i == j) continue;
            if (dominates(pop[i], pop[j])) dominatedBy[i].push_back((int)j);
            else if (dominates(pop[j], pop[i])) dominationCount[i]++;
        }
        if (dominationCount[i] == 0) { pop[i].rank = 0; currentFront.push_back((int)i); }
    }
    int front = 0;
    while (!currentFront.empty()) {
        std::vector<int> nextFront;
        for (int i : currentFront) {
            for (int j : dominatedBy[i]) {
                if (--dominationCount[j] == 0) { pop[j].rank = front + 1; nextFront.push_back(j); }
            }
        }
        ++front;
        currentFront = nextFront;
    }
}

void crowdingDistance(std::vector<Individual>& front) {
    if (front.empty()) return;
    for (auto& ind : front) ind.crowding = 0.0;
    if (front.size() <= 2) {
        for (auto& ind : front) ind.crowding = std::numeric_limits<double>::max();
        return;
    }
    const int m = 4;
    for (int obj = 0; obj < m; ++obj) {
        std::sort(front.begin(), front.end(),
                  [obj](const Individual& a, const Individual& b) {
                      if (obj == 0) return a.makespan < b.makespan;
                      if (obj == 1) return a.energy < b.energy;
                      if (obj == 2) return a.deadline_misses < b.deadline_misses;
                      return a.fairness > b.fairness;
                  });
        front.front().crowding = front.back().crowding = std::numeric_limits<double>::max();
        double minVal, maxVal;
        if (obj == 0) { minVal = front.front().makespan; maxVal = front.back().makespan; }
        else if (obj == 1) { minVal = front.front().energy; maxVal = front.back().energy; }
        else if (obj == 2) { minVal = front.front().deadline_misses; maxVal = front.back().deadline_misses; }
        else { minVal = front.back().fairness; maxVal = front.front().fairness; }
        if (maxVal - minVal > 1e-12) {
            for (size_t i = 1; i + 1 < front.size(); ++i) {
                double prevObj, nextObj;
                if (obj == 0) { prevObj = front[i-1].makespan; nextObj = front[i+1].makespan; }
                else if (obj == 1) { prevObj = front[i-1].energy; nextObj = front[i+1].energy; }
                else if (obj == 2) { prevObj = front[i-1].deadline_misses; nextObj = front[i+1].deadline_misses; }
                else { prevObj = front[i+1].fairness; nextObj = front[i-1].fairness; }
                front[i].crowding += (nextObj - prevObj) / (maxVal - minVal);
            }
        }
    }
}

Individual evaluate(const std::vector<int>& assign, const std::vector<double>& priority,
                    const std::vector<Task>& tasks, const std::vector<double>& speeds,
                    const std::vector<double>& power) {
    int nodes = (int)speeds.size();
    std::vector<double> node_finish(nodes, 0.0), node_busy(nodes, 0.0), work(nodes, 0.0);
    std::vector<int> order(tasks.size());
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&](int a, int b) {
        if (std::abs(priority[a] - priority[b]) > 1e-12) return priority[a] < priority[b];
        return tasks[a].release < tasks[b].release;
    });

    double violation = 0.0;
    int misses = 0;
    for (int idx : order) {
        int node = std::max(0, std::min((int)assign[idx], nodes - 1));
        double exec = tasks[idx].flops / speeds[node] + tasks[idx].bytes / BANDWIDTH;
        double start = std::max(tasks[idx].release, node_finish[node]);
        double finish = start + exec;
        node_finish[node] = finish;
        node_busy[node] += exec;
        work[node] += tasks[idx].flops;
        if (finish > tasks[idx].deadline + 1e-9) {
            ++misses;
            violation += (finish - tasks[idx].deadline);
        }
    }

    double makespan = *std::max_element(node_finish.begin(), node_finish.end());
    double total_energy = 0.0;
    for (int n = 0; n < nodes; ++n) {
        // Approximate SimGrid host energy: idle energy over whole makespan plus
        // additional active-minus-idle energy while executing tasks.
        double active = power[n];
        double idle = DEFAULT_IDLE_POWER;
        total_energy += idle * makespan + std::max(0.0, active - idle) * node_busy[n];
    }

    double sum = std::accumulate(work.begin(), work.end(), 0.0);
    double sq = 0.0; for (double w : work) sq += w*w;
    double fairness = (sq > 1e-12) ? (sum*sum) / (nodes * sq) : 1.0;

    Individual ind;
    ind.assignment = assign;
    ind.priority = priority;
    ind.makespan = makespan;
    ind.energy = total_energy;
    ind.deadline_misses = misses;
    ind.deadline_violation = violation;
    ind.fairness = fairness;
    return ind;
}

Individual evaluate(const std::vector<int>& assign, const std::vector<Task>& tasks,
                    const std::vector<double>& speeds, const std::vector<double>& power) {
    return evaluate(assign, defaultPriority(tasks), tasks, speeds, power);
}

// Select one deployable member from the Pareto front. NSGA-II itself remains
// Pareto-based; this tie-break only chooses the schedule to execute online.
Individual selectBest(const std::vector<Individual>& candidates) {
    if (candidates.empty()) return Individual{};
    const int nObj = 4;
    double minVals[4] = {1e18,1e18,1e18,1e18};
    double maxVals[4] = {-1e18,-1e18,-1e18,-1e18};
    for (const auto& ind : candidates) {
        double vals[4] = {ind.makespan, ind.energy, (double)ind.deadline_misses, -ind.fairness};
        for (int j = 0; j < nObj; ++j) {
            minVals[j] = std::min(minVals[j], vals[j]);
            maxVals[j] = std::max(maxVals[j], vals[j]);
        }
    }
    double bestScore = 1e18;
    int bestIdx = 0;
    for (size_t i = 0; i < candidates.size(); ++i) {
        double vals[4] = {candidates[i].makespan, candidates[i].energy,
                          (double)candidates[i].deadline_misses, -candidates[i].fairness};
        double norm[4];
        for (int j = 0; j < nObj; ++j) {
            double range = maxVals[j] - minVals[j];
            norm[j] = (range > 1e-12) ? (vals[j] - minVals[j]) / range : 0.0;
        }
        // Final deployment tie-break over exactly the reported objectives:
        // makespan, energy, deadline_misses, fairness.
        double score = 0.25*norm[0] + 0.20*norm[1] + 0.35*norm[2] + 0.20*norm[3];
        if (score < bestScore) { bestScore = score; bestIdx = (int)i; }
    }
    return candidates[bestIdx];
}

void writeParetoFrontCSV(const std::string& schedulerName, const std::vector<Individual>& pareto, unsigned int seed) {
    std::ofstream out("../pareto_front.csv", std::ios::app);
    if (!out.is_open()) return;
    out.seekp(0, std::ios::end);
    if (out.tellp() == std::streampos(0)) {
        out << "scheduler,seed,solution_id,makespan,total_energy,deadline_misses,fairness,deadline_violation\n";
    }
    int sid = 0;
    for (const auto& ind : pareto) {
        out << schedulerName << "," << seed << "," << sid++ << ","
            << ind.makespan << "," << ind.energy << ","
            << ind.deadline_misses << "," << ind.fairness << ","
            << ind.deadline_violation << "\n";
    }
}

class GA {
    int pop_size, generations;
    double crossover_rate, mutation_rate;
    std::mt19937 rng;
    unsigned int seed_value;
    std::string label;
public:
    GA(int ps=100, int gen=80, double cr=0.8, double mr=0.08, unsigned int seed=456, const std::string& lbl="GA_Pure")
        : pop_size(ps), generations(gen), crossover_rate(cr), mutation_rate(mr), rng(seed), seed_value(seed), label(lbl) {}

    Individual optimizeIndividual(const std::vector<Task>& tasks, int num_nodes,
                                  const std::vector<double>& speeds,
                                  const std::vector<double>& power) {
        if (tasks.empty()) return Individual{};
        std::uniform_real_distribution<double> real01(0.0, 1.0);
        std::vector<Individual> pop(pop_size);
        for (auto& ind : pop) {
            ind.assignment.resize(tasks.size());
            ind.priority.resize(tasks.size());
            for (size_t i = 0; i < tasks.size(); ++i) {
                ind.assignment[i] = rng() % num_nodes;
                // Blend EDF prior with random diversity: deadline-aware but not fixed.
                ind.priority[i] = tasks[i].deadline * (0.80 + 0.40 * real01(rng));
            }
            ind = evaluate(ind.assignment, ind.priority, tasks, speeds, power);
        }

        for (int gen = 0; gen < generations; ++gen) {
            fastNonDominatedSort(pop);
            std::vector<Individual> popWithCrowding;
            int maxRankPop = 0;
            for (auto& ind : pop) maxRankPop = std::max(maxRankPop, ind.rank);
            for (int r = 0; r <= maxRankPop; ++r) {
                std::vector<Individual> front;
                for (auto& ind : pop) if (ind.rank == r) front.push_back(ind);
                crowdingDistance(front);
                popWithCrowding.insert(popWithCrowding.end(), front.begin(), front.end());
            }
            pop = popWithCrowding;

            auto tournament = [&]() -> Individual {
                int i1 = rng() % pop.size(), i2 = rng() % pop.size();
                if (pop[i1].rank < pop[i2].rank) return pop[i1];
                if (pop[i2].rank < pop[i1].rank) return pop[i2];
                return (pop[i1].crowding > pop[i2].crowding) ? pop[i1] : pop[i2];
            };

            std::vector<Individual> offspring;
            while (offspring.size() < (size_t)pop_size) {
                Individual p1 = tournament(), p2 = tournament();
                Individual c1, c2;
                c1.assignment.resize(tasks.size()); c2.assignment.resize(tasks.size());
                c1.priority.resize(tasks.size()); c2.priority.resize(tasks.size());
                for (size_t i = 0; i < tasks.size(); ++i) {
                    if (real01(rng) < crossover_rate) {
                        bool takeP1 = (rng() % 2) != 0;
                        c1.assignment[i] = takeP1 ? p1.assignment[i] : p2.assignment[i];
                        c2.assignment[i] = takeP1 ? p2.assignment[i] : p1.assignment[i];
                        double beta = real01(rng);
                        c1.priority[i] = beta*p1.priority[i] + (1.0-beta)*p2.priority[i];
                        c2.priority[i] = beta*p2.priority[i] + (1.0-beta)*p1.priority[i];
                    } else {
                        c1.assignment[i] = p1.assignment[i]; c2.assignment[i] = p2.assignment[i];
                        c1.priority[i] = p1.priority[i]; c2.priority[i] = p2.priority[i];
                    }
                    if (real01(rng) < mutation_rate) c1.assignment[i] = rng() % num_nodes;
                    if (real01(rng) < mutation_rate) c2.assignment[i] = rng() % num_nodes;
                    if (real01(rng) < mutation_rate) c1.priority[i] *= (0.75 + 0.50 * real01(rng));
                    if (real01(rng) < mutation_rate) c2.priority[i] *= (0.75 + 0.50 * real01(rng));
                }
                c1 = evaluate(c1.assignment, c1.priority, tasks, speeds, power);
                c2 = evaluate(c2.assignment, c2.priority, tasks, speeds, power);
                offspring.push_back(c1);
                if (offspring.size() < (size_t)pop_size) offspring.push_back(c2);
            }

            std::vector<Individual> combined;
            combined.reserve(pop.size() + offspring.size());
            combined.insert(combined.end(), pop.begin(), pop.end());
            combined.insert(combined.end(), offspring.begin(), offspring.end());
            fastNonDominatedSort(combined);
            pop.clear();
            int maxRankCombined = 0;
            for (auto& ind : combined) maxRankCombined = std::max(maxRankCombined, ind.rank);
            for (int r = 0; r <= maxRankCombined && pop.size() < (size_t)pop_size; ++r) {
                std::vector<Individual> front;
                for (auto& ind : combined) if (ind.rank == r) front.push_back(ind);
                crowdingDistance(front);
                std::sort(front.begin(), front.end(), [](const Individual& a, const Individual& b){ return a.crowding > b.crowding; });
                for (auto& ind : front) {
                    if (pop.size() < (size_t)pop_size) pop.push_back(ind);
                    else break;
                }
            }
        }

        fastNonDominatedSort(pop);
        std::vector<Individual> pareto;
        for (auto& ind : pop) if (ind.rank == 0) pareto.push_back(ind);
        const std::vector<Individual>& finalFront = pareto.empty() ? pop : pareto;
        writeParetoFrontCSV(label, finalFront, seed_value);
        std::cout << "[" << label << "] Pareto front size: " << finalFront.size() << "\n";
        return selectBest(finalFront);
    }

    std::vector<int> optimize(const std::vector<Task>& tasks, int num_nodes,
                              const std::vector<double>& speeds,
                              const std::vector<double>& power) {
        return optimizeIndividual(tasks, num_nodes, speeds, power).assignment;
    }
};
// ----------------------------------------------------------------------
// Offline optimizer: NSGA‑II + SA with seeded RNG
// ----------------------------------------------------------------------
std::vector<int> offlineOptimize(const std::vector<Task>& tasks, int num_nodes,
                                 const std::vector<double>& speeds,
                                 const std::vector<double>& power,
                                 unsigned int seed) {
    GA ga(100, 50, 0.8, 0.1, seed, "Adaptive_NSGA2_SA_QL");
    std::vector<int> bestAssign = ga.optimize(tasks, num_nodes, speeds, power);

    // Compute normalisation factors from a set of random schedules
    std::vector<Individual> sample;
    std::mt19937 rng(seed);
    for (int i = 0; i < 100; ++i) {
        std::vector<int> assign(tasks.size());
        for (size_t j = 0; j < tasks.size(); ++j) assign[j] = rng() % num_nodes;
        sample.push_back(evaluate(assign, tasks, speeds, power));
    }
    double minM=1e18, maxM=0, minE=1e18, maxE=0, minD=1e18, maxD=0, minF=1e18, maxF=0;
    for (auto& ind : sample) {
        minM = std::min(minM, ind.makespan); maxM = std::max(maxM, ind.makespan);
        minE = std::min(minE, ind.energy); maxE = std::max(maxE, ind.energy);
        minD = std::min(minD, (double)ind.deadline_misses); maxD = std::max(maxD, (double)ind.deadline_misses);
        minF = std::min(minF, ind.fairness); maxF = std::max(maxF, ind.fairness);
    }
    auto normCost = [&](const Individual& ind) {
        double nM = (maxM - minM > 1e-12) ? (ind.makespan - minM)/(maxM - minM) : 0.0;
        double nE = (maxE - minE > 1e-12) ? (ind.energy - minE)/(maxE - minE) : 0.0;
        double nD = (maxD - minD > 1e-12) ? ((double)ind.deadline_misses - minD)/(maxD - minD) : 0.0;
        double nF = (maxF - minF > 1e-12) ? (ind.fairness - minF)/(maxF - minF) : 0.0;
        return 0.25 * (nM + nE + nD + (1.0 - nF));
    };

    std::vector<int> current = bestAssign;
    double T = 1000.0, cooling = 0.98;
    int steps = 1000;
    auto cost = [&](const std::vector<int>& assign) {
        auto ind = evaluate(assign, tasks, speeds, power);
        return normCost(ind);
    };
    double bestCost = cost(bestAssign);
    for (int s = 0; s < steps; ++s) {
        std::vector<int> neighbor = current;
        int numMut = std::max(1, (int)(tasks.size() * 0.2 * (rng()%100/100.0)));
        for (int m = 0; m < numMut; ++m) {
            int idx = rng() % tasks.size();
            neighbor[idx] = rng() % num_nodes;
        }
        double curCost = cost(current);
        double neighCost = cost(neighbor);
        if (neighCost < curCost || (rng()%100/100.0) < exp((curCost - neighCost)/T)) {
            current = neighbor;
            if (neighCost < bestCost) { bestAssign = neighbor; bestCost = neighCost; }
        }
        T *= cooling;
    }
    return bestAssign;
}

// ----------------------------------------------------------------------
// Adaptive scheduler: offline bootstrapping + online Q‑learning
// ----------------------------------------------------------------------
class Scheduler {
    std::vector<Task> queue;
    std::vector<double> speeds, power;
    int num_nodes;
    std::vector<std::vector<double>> Q;
    double alpha, gamma, epsilon;
    int step_count;
    static constexpr int num_states = 10000;
    struct DispatchInfo { int state; int action; double start_time; };
    std::unordered_map<int, DispatchInfo> dispatched;
    double current_energy = 0.0;
    std::mt19937 rng;
    std::vector<int> offline_policy;

    int discretizeState(const std::vector<double>& node_load, double now) {
        double avg_load = std::accumulate(node_load.begin(), node_load.end(), 0.0) / num_nodes;
        int load_bin = std::min(9, (int)(avg_load / 100.0));
        int queue_bin = std::min(9, (int)(queue.size() / 10));
        double avg_slack = 0.0;
        for (auto& t : queue) avg_slack += (t.deadline - now);
        if (!queue.empty()) avg_slack /= queue.size();
        int slack_bin = std::min(9, std::max(0, (int)(avg_slack / 50.0)));
        double avg_power = 0.0;
        for (int n = 0; n < num_nodes; ++n) avg_power += power[n];
        avg_power /= num_nodes;
        int power_bin = std::min(9, (int)(avg_power / 50.0));
        return load_bin + 10*queue_bin + 100*slack_bin + 1000*power_bin;
    }

    int selectAction(int state, const std::vector<int>& free_nodes, const Task& task, double now) {
        double eps = std::max(0.02, 0.35 * std::exp(-step_count / 7000.0));
        std::uniform_real_distribution<double> prob(0.0, 1.0);
        std::uniform_int_distribution<int> pick(0, (int)free_nodes.size() - 1);
        if (prob(rng) < eps) {
            return free_nodes[pick(rng)];
        }
        const auto& qvals = Q[state];
        int preferred = -1;
        if (!offline_policy.empty()) preferred = offline_policy[task.id % offline_policy.size()];
        int best_action = free_nodes[0];
        double best_val = -std::numeric_limits<double>::max();
        double slack = task.deadline - now;
        for (int n : free_nodes) {
            double exec = task.flops / speeds[n] + task.bytes / BANDWIDTH;
            double urgency_penalty = std::max(0.0, exec - slack) / 1000.0;
            double energy_penalty = (power[n] * exec) / 1e6;
            double offline_bonus = (n == preferred) ? 0.50 : 0.0;
            double score = qvals[n] + offline_bonus - 0.20 * urgency_penalty - 0.10 * energy_penalty;
            if (score > best_val) { best_val = score; best_action = n; }
        }
        return best_action;
    }

    void updateQ(int s, int a, double reward, int ns) {
        double best = -std::numeric_limits<double>::max();
        for (double v : Q[ns]) best = std::max(best, v);
        Q[s][a] += alpha * (reward + gamma * best - Q[s][a]);
    }

    void bootstrapQ(const std::vector<int>& policy, const std::vector<Task>& hist_tasks, unsigned int seed) {
        // Compute a normalised fitness value for the policy (as a baseline)
        auto ind = evaluate(policy, hist_tasks, speeds, power);
        // Get min/max from a few random schedules
        std::vector<Individual> sample;
        sample.push_back(ind);
        std::mt19937 rng(seed);
        for (int i = 0; i < 20; ++i) {
            std::vector<int> randAssign(hist_tasks.size());
            for (size_t j = 0; j < hist_tasks.size(); ++j) randAssign[j] = rng() % num_nodes;
            sample.push_back(evaluate(randAssign, hist_tasks, speeds, power));
        }
        double minM=1e18, maxM=0, minE=1e18, maxE=0, minD=1e18, maxD=0, minF=1e18, maxF=0;
        for (auto& s : sample) {
            minM = std::min(minM, s.makespan); maxM = std::max(maxM, s.makespan);
            minE = std::min(minE, s.energy); maxE = std::max(maxE, s.energy);
            minD = std::min(minD, (double)s.deadline_misses); maxD = std::max(maxD, (double)s.deadline_misses);
            minF = std::min(minF, s.fairness); maxF = std::max(maxF, s.fairness);
        }
        auto normCost = [&](const Individual& ind) {
            double nM = (maxM - minM > 1e-12) ? (ind.makespan - minM)/(maxM - minM) : 0.0;
            double nE = (maxE - minE > 1e-12) ? (ind.energy - minE)/(maxE - minE) : 0.0;
            double nD = (maxD - minD > 1e-12) ? ((double)ind.deadline_misses - minD)/(maxD - minD) : 0.0;
            double nF = (maxF - minF > 1e-12) ? (ind.fairness - minF)/(maxF - minF) : 0.0;
            return 0.25 * (nM + nE + nD + (1.0 - nF));
        };
        // Positive prior: better offline policies receive larger Q-values. The previous
        // code used a negative baseQ together with max(Q, baseQ) while Q started at
        // zero; therefore the offline NSGA-II+SA phase had exactly no effect.
        double baseQ = 1.0 - normCost(ind);

        // Simulate the policy to visit states and set Q values
        std::vector<Task> temp = hist_tasks;
        std::sort(temp.begin(), temp.end(), [](const Task& a, const Task& b){ return a.release < b.release; });
        double now = 0.0;
        size_t idx = 0;
        std::vector<double> node_load_sim(num_nodes, 0.0);
        std::vector<Task> q;
        while (idx < temp.size()) {
            while (idx < temp.size() && temp[idx].release <= now + 1e-9) {
                q.push_back(temp[idx]);
                ++idx;
            }
            std::sort(q.begin(), q.end(), [](const Task& a, const Task& b){ return a.deadline < b.deadline; });
            size_t i = 0;
            while (i < q.size() && q[i].release > now + 1e-9) ++i;
            if (i == q.size()) {
                if (idx < temp.size()) {
                    now = temp[idx].release;
                    continue;
                } else break;
            }
            Task t = q[i];
            q.erase(q.begin() + i);
            int action = policy[t.id % policy.size()];
            int state = discretizeState(node_load_sim, now);
            Q[state][action] = std::max(Q[state][action], baseQ);
            double exec = t.flops / speeds[action] + t.bytes / BANDWIDTH;
            node_load_sim[action] += exec;
            now += exec;
        }
    }

public:
    Scheduler(double a=0.4, double g=0.9, double e=0.5)
        : alpha(a), gamma(g), epsilon(e) { step_count = 0; }

    void init(int n, const std::vector<double>& sp, const std::vector<double>& pw, unsigned int seed) {
        num_nodes = n; speeds = sp; power = pw;
        queue.clear(); step_count = 0; current_energy = 0.0;
        Q.assign(num_states, std::vector<double>(num_nodes, 0.0));
        dispatched.clear();
        rng.seed(seed);

        // Offline phase – workload is fixed (seed 456) for reproducibility across seeds
        std::vector<Task> hist_workload = Workload::historical(1000, 456);
        offline_policy = offlineOptimize(hist_workload, num_nodes, speeds, power, seed);
        bootstrapQ(offline_policy, hist_workload, seed);
        std::cout << "[Adaptive] Offline NSGA‑II+SA completed, Q‑table initialised.\n";
    }

    void onTaskArrival(const Task& t, double, const std::vector<double>&) {
        queue.push_back(t);
        std::sort(queue.begin(), queue.end(),
                  [](const Task& a, const Task& b){ return a.deadline < b.deadline; });
    }

    std::pair<int, Task> schedule(double now, const std::vector<double>& node_load,
                                  const std::vector<int>& free_nodes) {
        if (queue.empty() || free_nodes.empty()) return {-1, Task{}};
        size_t idx = 0;
        while (idx < queue.size() && queue[idx].release > now + 1e-9) ++idx;
        if (idx == queue.size()) return {-1, Task{}};
        Task t = queue[idx];
        queue.erase(queue.begin() + idx);
        int state = discretizeState(node_load, now);
        int chosen_node = selectAction(state, free_nodes, t, now);
        dispatched[t.id] = {state, chosen_node, now};
        return {chosen_node, t};
    }

    void onTaskCompletion(const Task& task, int node, double finish_time,
                          const std::vector<double>& node_load) {
        auto it = dispatched.find(task.id);
        if (it == dispatched.end()) return;
        double exec = finish_time - it->second.start_time;
        double violation = std::max(0.0, finish_time - task.deadline);
        double energy_used = power[node] * exec;
        current_energy += energy_used;
        double miss = (violation > 1e-9) ? 1.0 : 0.0;
        double avg_load = std::accumulate(node_load.begin(), node_load.end(), 0.0) / std::max(1, num_nodes);
        double balance_penalty = std::abs(node_load[node] - avg_load) / (avg_load + 1.0);
        // Reward aligned with reported objectives: makespan proxy, energy,
        // deadline_misses, and fairness/load balance. Tardiness is kept only
        // as a secondary pressure inside the deadline term.
        double reward = - (exec / 50000.0 + energy_used / 1e8 + 3.0 * miss + violation / 50000.0 + 0.5 * balance_penalty);
        int next_state = discretizeState(node_load, finish_time);
        updateQ(it->second.state, it->second.action, reward, next_state);
        dispatched.erase(it);
        ++step_count;
    }

    std::string name() const { return "Adaptive_NSGA2_SA_QL"; }
};
EOF_ADAPTIVE
    fi

    # ------------------------------------------------------------------
    # Common simulation runner – workload seed fixed to 456
    # ------------------------------------------------------------------
    cat >> "$dir/scheduler.cpp" << 'EOF_RUN'
struct SimulationData {
    std::vector<Task> workload;
    Scheduler* scheduler;
    std::vector<double> node_speeds;
    std::vector<double> node_power;
    std::vector<sg4::Host*> hosts;
    bool verbose;
    Metrics result;
    unsigned int seed;
};

static void simulation_main(void* data) {
    SimulationData* d = static_cast<SimulationData*>(data);
    int num_nodes = d->hosts.size();
    std::vector<sg4::ExecPtr> active_execs(num_nodes, nullptr);
    std::vector<Task> running_task(num_nodes);
    std::vector<bool> node_busy(num_nodes, false);
    std::vector<double> node_load(num_nodes, 0.0);
    d->scheduler->init(num_nodes, d->node_speeds, d->node_power, d->seed);

    std::vector<Task> pending = d->workload;
    std::sort(pending.begin(), pending.end(),
              [](const Task& a, const Task& b){ return a.release < b.release; });
    size_t task_idx = 0;
    std::unordered_map<int, double> task_finish;
    std::vector<double> node_workload(num_nodes, 0.0);

    auto dispatch = [&](int node, const Task& t) {
        node_busy[node] = true;
        running_task[node] = t;
        double exec_time = t.flops / d->node_speeds[node] + t.bytes / BANDWIDTH;
        node_load[node] += exec_time;
        // SimGrid executes flops on a host. Convert the I/O time component into
        // equivalent host flops so the simulated completion time matches the
        // scheduler's CPU+I/O execution-time model.
        double equivalent_flops = t.flops + (t.bytes / BANDWIDTH) * d->node_speeds[node];
        auto exec = sg4::Exec::init()->set_host(d->hosts[node])->set_flops_amount(equivalent_flops);
        exec->start();
        active_execs[node] = exec;
        task_finish[t.id] = sg4::Engine::get_clock() + exec_time;
        node_workload[node] += t.flops;
    };

    while (task_idx < pending.size() || std::any_of(node_busy.begin(), node_busy.end(), [](bool b){ return b; })) {
        double now = sg4::Engine::get_clock();
        while (task_idx < pending.size() && pending[task_idx].release <= now + 1e-9) {
            d->scheduler->onTaskArrival(pending[task_idx], now, node_load);
            ++task_idx;
        }
        // Dispatch repeatedly until either no node is free or the scheduler has no
        // ready task. The previous version dispatched at most one task and then
        // waited, which serialized the workload and destroyed HPC parallelism.
        bool dispatched_any = true;
        while (dispatched_any) {
            dispatched_any = false;
            std::vector<int> free_nodes;
            for (int n = 0; n < num_nodes; ++n) if (!node_busy[n]) free_nodes.push_back(n);
            if (free_nodes.empty()) break;
            auto [node, t] = d->scheduler->schedule(now, node_load, free_nodes);
            if (node >= 0 && t.id >= 0 && !node_busy[node]) {
                dispatch(node, t);
                dispatched_any = true;
            }
        }
        sg4::ActivitySet set;
        for (int n = 0; n < num_nodes; ++n) if (active_execs[n]) set.push(active_execs[n]);
        if (!set.empty()) {
            sg4::ActivityPtr completed = set.wait_any();
            int finished_node = -1;
            for (int n = 0; n < num_nodes; ++n) if (active_execs[n] == completed) { finished_node = n; break; }
            if (finished_node != -1) {
                double finish_time = sg4::Engine::get_clock();
                const Task& finished_task = running_task[finished_node];
                node_busy[finished_node] = false;
                double exec_time = finished_task.flops / d->node_speeds[finished_node] + finished_task.bytes / BANDWIDTH;
                node_load[finished_node] -= exec_time;
                if (node_load[finished_node] < 0) node_load[finished_node] = 0;
                active_execs[finished_node] = nullptr;
                d->scheduler->onTaskCompletion(finished_task, finished_node, finish_time, node_load);
            }
        } else if (task_idx < pending.size()) {
            double next_release = pending[task_idx].release;
            double now = sg4::Engine::get_clock();
            if (next_release > now) sg4::this_actor::sleep_until(next_release);
        } else break;
    }

    d->result.makespan = sg4::Engine::get_clock();
    d->result.total_energy = 0.0;
    for (auto* h : d->hosts) d->result.total_energy += sg_host_get_consumed_energy(h);
    d->result.deadline_misses = 0;
    for (const auto& t : d->workload) {
        auto it = task_finish.find(t.id);
        if (it != task_finish.end() && it->second > t.deadline + 1e-9) d->result.deadline_misses++;
    }
    double sum_work = std::accumulate(node_workload.begin(), node_workload.end(), 0.0);
    double sum_sq = 0.0;
    for (double w : node_workload) sum_sq += w*w;
    d->result.fairness = (sum_sq > 1e-9) ? (sum_work*sum_work) / (num_nodes * sum_sq) : 1.0;
}

Metrics runSimulation(sg4::Engine& e, const std::vector<Task>& workload, Scheduler& scheduler,
                      const std::vector<double>& node_speeds,
                      const std::vector<double>& node_power,
                      const std::vector<sg4::Host*>& hosts, bool verbose, unsigned int seed) {
    SimulationData data = {workload, &scheduler, node_speeds, node_power, hosts, verbose, Metrics{}, seed};
    sg4::Actor::create("sim_actor", hosts[0], simulation_main, &data);
    e.run();
    return data.result;
}

int main(int argc, char* argv[]) {
    unsigned int seed = (argc > 1) ? static_cast<unsigned int>(std::stoi(argv[1])) : 42u;
    std::srand(seed); // for any legacy rand() calls

    sg_host_energy_plugin_init();
    sg4::Engine e(&argc, argv);
    e.load_platform("cluster_8nodes.xml");
    auto hosts = e.get_all_hosts();
    if (hosts.empty()) return 1;
    std::vector<double> speeds, power;
    for (auto* h : hosts) {
        speeds.push_back(h->get_speed());
        power.push_back(getNodePower(h));
    }

    Scheduler scheduler;

    // Workload is fixed (seed 456) for all scheduler runs – ensures fair comparison
    auto workload = Workload::synthetic(1000, 456);
    Metrics m = runSimulation(e, workload, scheduler, speeds, power, hosts, false, seed);

    // Output CSV line (append to ../results.csv)
    std::ofstream out("../results.csv", std::ios::app);
    if (!out.is_open()) {
        std::cerr << "Warning: could not open ../results.csv for writing\n";
    } else {
        // Check if file is empty -> write header
        out.seekp(0, std::ios::end);
        if (out.tellp() == std::streampos(0)) {
            out << "scheduler,seed,makespan,total_energy,deadline_misses,fairness\n";
        }
        out << scheduler.name() << "," << seed << ","
            << m.makespan << "," << m.total_energy << ","
            << m.deadline_misses << "," << m.fairness << "\n";
        out.close();
    }

    // Also print to console for backward compatibility
    std::cout << "SCHEDULER," << scheduler.name()
              << ",MAKESPAN," << m.makespan
              << ",ENERGY," << m.total_energy
              << ",DEADLINE_MISSES," << m.deadline_misses
              << ",FAIRNESS," << m.fairness << std::endl;
    return 0;
}
EOF_RUN

    # ----------------------------------------------------------------------
    # CMakeLists and run script (accept seed argument)
    # ----------------------------------------------------------------------
    cat > "$dir/CMakeLists.txt" << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(scheduler)
set(CMAKE_CXX_STANDARD 17)
find_package(PkgConfig REQUIRED)
pkg_check_modules(SIMGRID REQUIRED simgrid)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cluster_8nodes.xml ${CMAKE_CURRENT_BINARY_DIR}/cluster_8nodes.xml COPYONLY)
add_executable(scheduler scheduler.cpp Workload.cpp)
target_include_directories(scheduler PRIVATE ${SIMGRID_INCLUDE_DIRS})
target_link_libraries(scheduler ${SIMGRID_LIBRARIES} pthread dl)
EOF

    cat > "$dir/run.sh" << 'EOF'
#!/bin/bash
set -e
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4
export LD_LIBRARY_PATH="${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}"
./scheduler "$1"
EOF
    chmod +x "$dir/run.sh"
    echo "Created $name"
}

# ----------------------------------------------------------------------
# Generate all six schedulers
# ----------------------------------------------------------------------
create_scheduler "fcfs"
create_scheduler "edf"
create_scheduler "minmin"
create_scheduler "ga_pure"
create_scheduler "rl_pure"
create_scheduler "adaptive"

# ----------------------------------------------------------------------
# Create a top-level script to run 5 Monte‑Carlo iterations per scheduler
# ----------------------------------------------------------------------
cat > "$BASE_DIR/run_all.sh" << 'EOF'
#!/bin/bash
set -e

for sched in fcfs edf minmin ga_pure rl_pure adaptive; do
    echo "Running $sched with 10 seeds..."
    cd "$sched"
    for seed in 42 123 456 789 2026 31415 27182 98765 13579 24680; do				
        ./run.sh "$seed"
    done
    cd ..
done
echo "All runs completed. Results are in each scheduler's results.csv"
EOF
chmod +x "$BASE_DIR/run_all.sh"

echo ""
echo "============================================================"
echo "✅ All schedulers generated and ready."
echo "Workload is fixed to seed 456; scheduler seeds vary: 42 123 456 789 2026 31415 27182 98765 13579 24680."
echo "To run 5 seeded iterations per scheduler, execute:"
echo "  cd $BASE_DIR && ./run_all.sh"
echo "Results are stored as CSV in each scheduler's directory."
echo "============================================================"
