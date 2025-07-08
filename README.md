# RISC-V Processor
# Author : Praveen Saravanan

A comprehensive, single-file implementation of a 32-bit RISC-V processor in SystemVerilog. This project contains all processor modules integrated into one file for easy compilation and testing.

## Features

### Processor Capabilities
- **32-bit RISC-V single-cycle processor**
- **Harvard architecture** (separate instruction and data memory)
- **32 general-purpose registers** (x0-x31, where x0 is hardwired to 0)
- **Comprehensive instruction support** (R-type, I-type, Load/Store, Branch, Jump)
- **Full ALU** with arithmetic, logical, and shift operations
- **Branch prediction** (simple taken/not-taken)
- **Memory-mapped I/O ready**

### Design Benefits
- **Single-file implementation** - Easy to compile and share
- **Modular design** - Clean separation of concerns
- **Proper MUX usage** - Demonstrates hierarchical design
- **Comprehensive testbench** - Thorough verification
- **Educational focus** - Well-commented and documented
- **Synthesis-ready** - Can be implemented on FPGA

## 🏗️ Architecture

┌─────────────────────────────────────────────────────────────────┐
│                    RISC-V Processor Architecture                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │    PC    │────│ Instruction │────│   Control   │             │
│  │          │    │   Memory    │    │    Unit     │             │
│  └──────────┘    └─────────────┘    └─────────────┘             │
│       │                                    │                    │
│       │          ┌─────────────┐           │                    │
│       └──────────│   Branch    │───────────┘                    │
│                  │    Unit     │                                │
│                  └─────────────┘                                │
│                                                                 │
│  ┌─────────────┐    ┌─────────┐    ┌─────────────┐             │
│  │  Register   │────│   ALU   │────│    Data     │             │
│  │    File     │    │         │    │   Memory    │             │
│  └─────────────┘    └─────────┘    └─────────────┘             │
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐                            │
│  │ Immediate   │    │   MUX4/MUX2 │                            │
│  │ Generator   │    │  (Routing)  │                            │
│  └─────────────┘    └─────────────┘                            │
└─────────────────────────────────────────────────────────────────┘


### Key Components
- **Program Counter (PC)**: Tracks current instruction address
- **Instruction Memory**: Stores the program (ROM-like)
- **Register File**: 32 x 32-bit general-purpose registers
- **ALU**: Performs arithmetic and logical operations
- **Control Unit**: Generates control signals from instruction opcode
- **Branch Unit**: Evaluates branch conditions
- **Data Memory**: Load/store data (RAM-like)
- **Immediate Generator**: Extracts and sign-extends immediate values
- **MUX Networks**: Route data between components


### Prerequisites
- **SystemVerilog simulator** (ModelSim, Vivado, Verilator, etc.)
- **Basic RISC-V knowledge** (helpful but not required)


## 🔧 Module Descriptions

### Core Modules

#### 1. **processor_complete** (Top Module)
- **Purpose**: Integrates all components
- **Interfaces**: Clock, reset, debug outputs
- **Key Features**: Proper MUX usage, clean signal routing

#### 2. **alu** (Arithmetic Logic Unit)
- **Operations**: ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, SRA
- **Flags**: Zero, overflow, negative
- **Width**: Parameterizable (default 32-bit)

#### 3. **register_file** (Register Bank)
- **Registers**: 32 x 32-bit (x0 hardwired to 0)
- **Ports**: Dual read, single write
- **Features**: Synchronous write, asynchronous read

#### 4. **control_unit** (Instruction Decoder)
- **Input**: Opcode, funct3, funct7
- **Output**: All control signals
- **Supported**: All major RISC-V instruction types

#### 5. **branch_unit** (Branch Logic)
- **Comparisons**: EQ, NE, LT, GE, LTU, GEU
- **Types**: Conditional branches, unconditional jumps
- **Output**: Branch taken signal

### Utility Modules

#### 6. **mux2** / **mux4** (Multiplexers)
- **Purpose**: Data path routing
- **Usage**: PC selection, ALU inputs, register write data
- **Features**: Parameterizable width

#### 7. **immediate_generator** (Immediate Extraction)
- **Formats**: I, S, B, U, J type immediates
- **Features**: Proper sign extension
- **Compliance**: RISC-V specification

#### 8. **program_counter** (PC Logic)
- **Features**: Reset, stall, branch support
- **Inputs**: Branch target, take branch signal
- **Output**: Current PC, PC+4

### Memory Modules

#### 9. **instruction_memory** (Program Storage)
- **Type**: ROM-like (initialized with test program)
- **Interface**: Address in, instruction out
- **Features**: Word-aligned access

#### 10. **data_memory** (Data Storage)
- **Type**: RAM with byte/halfword/word access
- **Operations**: Load/store with different sizes
- **Features**: Little-endian, sign extension

##  Instruction Set

### Supported Instructions

#### R-Type (Register-Register)
| Instruction | Description | Example |
|-------------|-------------|---------|
| ADD | Addition | `ADD x3, x1, x2` |
| SUB | Subtraction | `SUB x3, x1, x2` |
| AND | Bitwise AND | `AND x3, x1, x2` |
| OR | Bitwise OR | `OR x3, x1, x2` |
| XOR | Bitwise XOR | `XOR x3, x1, x2` |
| SLT | Set Less Than | `SLT x3, x1, x2` |
| SLTU | Set Less Than Unsigned | `SLTU x3, x1, x2` |
| SLL | Shift Left Logical | `SLL x3, x1, x2` |
| SRL | Shift Right Logical | `SRL x3, x1, x2` |
| SRA | Shift Right Arithmetic | `SRA x3, x1, x2` |

#### I-Type (Immediate)
| Instruction | Description | Example |
|-------------|-------------|---------|
| ADDI | Add Immediate | `ADDI x1, x0, 5` |
| ANDI | AND Immediate | `ANDI x1, x2, 0xFF` |
| ORI | OR Immediate | `ORI x1, x2, 0xFF` |
| XORI | XOR Immediate | `XORI x1, x2, 0xFF` |
| SLTI | Set Less Than Immediate | `SLTI x1, x2, 10` |
| SLTIU | Set Less Than Immediate Unsigned | `SLTIU x1, x2, 10` |

#### Load/Store
| Instruction | Description | Example |
|-------------|-------------|---------|
| LB | Load Byte | `LB x1, 0(x2)` |
| LH | Load Halfword | `LH x1, 0(x2)` |
| LW | Load Word | `LW x1, 0(x2)` |
| LBU | Load Byte Unsigned | `LBU x1, 0(x2)` |
| LHU | Load Halfword Unsigned | `LHU x1, 0(x2)` |
| SB | Store Byte | `SB x1, 0(x2)` |
| SH | Store Halfword | `SH x1, 0(x2)` |
| SW | Store Word | `SW x1, 0(x2)` |

#### Branch Instructions
| Instruction | Description | Example |
|-------------|-------------|---------|
| BEQ | Branch if Equal | `BEQ x1, x2, label` |
| BNE | Branch if Not Equal | `BNE x1, x2, label` |
| BLT | Branch if Less Than | `BLT x1, x2, label` |
| BGE | Branch if Greater/Equal | `BGE x1, x2, label` |
| BLTU | Branch if Less Than Unsigned | `BLTU x1, x2, label` |
| BGEU | Branch if Greater/Equal Unsigned | `BGEU x1, x2, label` |

#### Jump Instructions
| Instruction | Description | Example |
|-------------|-------------|---------|
| JAL | Jump and Link | `JAL x1, label` |
| JALR | Jump and Link Register | `JALR x1, 0(x2)` |

#### Upper Immediate
| Instruction | Description | Example |
|-------------|-------------|---------|
| LUI | Load Upper Immediate | `LUI x1, 0x12345` |
| AUIPC | Add Upper Immediate to PC | `AUIPC x1, 0x12345` |


### Performance Metrics
- **Clock Period**: 10ns (100MHz)
- **Instructions**: 8 arithmetic + 2 NOPs
- **Execution Time**: ~100ns (10 cycles)
- **Throughput**: 1 instruction per cycle (single-cycle design)


### Pipeline Implementation

To convert to pipelined:
1. Add pipeline registers between stages
2. Implement hazard detection
3. Add forwarding logic
4. Update control for pipeline stalls


##  References

- [RISC-V Instruction Set Manual](https://riscv.org/specifications/)
- [Computer Organization and Design (Patterson & Hennessy)](https://www.elsevier.com/books/computer-organization-and-design-risc-v-edition/patterson/978-0-12-812275-4)
- [SystemVerilog IEEE 1800 Standard](https://ieeexplore.ieee.org/document/8299595)

