# Serial Communication System (TX/RX) with Integrated FIFO Buffer

## Overview
This repository contains the RTL design, architecture, and functional verification of a complete digital serial communication system (Transmitter, Receiver, and FIFO buffer) implemented in **Verilog HDL** as a final project for the Digital Systems Design course (Grade: 95/100).

The system handles serial data transmission from a ROM-based Transmitter (`TX`) through a buffering `FIFO` stage into a RAM-based Receiver (`RX`), managed by dedicated Finite State Machines (FSMs) and verified using **ModelSim**.

---

## System Architecture

The top-level module (`TOP_System.v`) integrates three main subsystems:

1. **Transmitter (`TX_block`)**
   * **`TX_FSM.v`**: Controls the transmission sequence, handshaking, and FIFO write-enable (`wr_enable`) signaling.
   * **`TX_ROM.v` & `tx_data.txt`**: Stores the source data bytes to be transmitted.
   * **`TX_adrs_reg.v`**: Address counter/register for sequential ROM reading.
   * **`TX_TBUF.v`**: Shift register/buffer for parallel-to-serial conversion.

2. **FIFO Buffer (`FIFO.v`)**
   * Bridges the TX and RX domains to prevent data loss during continuous or burst transfers.
   * Implements full/empty flag logic and pointer management to regulate read (`rd_enable`) and write (`wr_enable`) operations.

3. **Receiver (`RX_block`)**
   * **`RX_FSM.v`**: Monitors FIFO status, manages data sampling, and controls memory write cycles.
   * **`RX_RBUF.v`**: Shift register/buffer for serial-to-parallel conversion.
   * **`RX_adrs_reg.v`**: Address counter/register for sequential RAM writing.
   * **`RX_RAM.v`**: Stores the successfully received data bytes.

---

## Verification & Simulation
All modules were individually and jointly verified using self-checking/waveform testbenches in **ModelSim**:
* **Unit Testing:** `tb_TX_block.v`, `tb_RX_block.v`, and `tb_FIFO.v` (verifying edge cases such as FIFO full/empty conditions, boundary pointers, and continuous read/write).
* **Integration Testing:** `tb_TX_RX.v` (direct TX-to-RX link) and `tb_TOP_System.v` (full end-to-end system verification with FIFO).

### How to Run Simulation (ModelSim)
1. Create a new project in ModelSim and add all `.v` files from `src/` and `tb/`.
2. Ensure `tx_data.txt` is placed in the active simulation working directory.
3. Compile all files.
4. Start simulation on `tb_TOP_System` (or any unit testbench) and inspect the waveforms.

---

## Repository Structure
* `src/` – Synthesizable Verilog RTL source files (`TOP_System`, `FIFO`, `TX`, `RX`).
* `tb/` – Verilog testbenches for unit and system-level verification.
* `docs/` – Full architectural documentation, FSM diagrams, and simulation waveforms (`Final_Project_Report.pdf`, `Project_Presentation.pdf`).

---

## Tools & Technologies
* **HDL:** Verilog
* **Simulation & Verification:** ModelSim

## Authors
* **Noam Ifergan**
* **Yarden Sagiv**