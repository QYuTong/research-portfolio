# Voltage Control Coordination in UK Distribution Networks

This repository provides the simulation codes, data, and analysis scripts
supporting a paper submitted to *Electric Power Systems Research (ENSP)*.

The study investigates a lightweight coordination strategy between
on-load tap changers (OLTCs) and inverter-based resources for voltage
regulation in UK-style medium-voltage distribution networks, with an
emphasis on deployability under limited communication and legacy
infrastructure constraints.

---

## Repository Structure

- `/code`
  - `run_simulation.m`  
    Main time-series simulation script.  
    Used to generate the voltage trajectories and operational states
    reported in Figures **2**, **4**, and **5**.

  - `init_IEEE33.m`  
    Initialisation of the modified IEEE 33-bus test feeder with UK-style
    parameters.

  - `IEEE33_data.m`  
    System and network data file for the IEEE 33-bus feeder.

  - `init_voltage_control.m`  
    Initialisation of inverter Q(U) droop control and OLTC coordination
    logic corresponding to **Figure 1**.

  - `analyze_results.m`  
    Post-processing and visualisation of simulation outputs.  
    Used to generate Figures **2** (voltage heat-maps),
    **4** (communication delay and outage scenarios),
    and **5** (unbalanced operation analysis).

  - `sensitivity_analysis.m`  
    Sensitivity analysis of PV penetration levels.  
    Used to generate **Figure 3**.

  - `example_power_flow.m`  
    Example steady-state power flow calculation for the test feeder.

  - `load_REFIT_data.m`  
    Load and PV profile data derived from the publicly available REFIT
    dataset.

- `/papers`
  - Research papers and working manuscripts.

- `/data`
  - Public or simulated datasets (no confidential or proprietary data).

---

## Reproducibility

The main results reported in the paper can be reproduced as follows:

1. Run `init_IEEE33.m` to initialise the distribution network model.
2. Execute `load_REFIT_data.m` to load demand and PV profiles.
3. Run `init_voltage_control.m` to initialise inverter and OLTC control
   parameters (Figure **1**).
4. Execute `run_simulation.m` to perform the time-series simulations
   (Figures **2**, **4**, and **5**).
5. Run `analyze_results.m` and `sensitivity_analysis.m` to reproduce all
   figures reported in the paper (Figures **2–5**).

All simulations were tested using **MATLAB R2022b**.

---

## Notes

The code is provided for research and reproducibility purposes.
Some scripts may be refined in future work.

---

## Contact

GitHub: https://github.com/QYuTong
