# Pipeline RISC-V Processor
The design was ranked 3rd place during the competition SP22. Note that the project is in a form of 3 people while the competition code is fully implemented by me alone. 

## Performance Numbers (100 MHz)
| | Comp1 | Comp2  | Comp3  |
| :---   | -: | -: | -: |
| Delay | 531555ns | 295405ns |669745ns |
| Power | 684.8mW | 567.1mW |614.4mW |
| FMax | 106.5Mhz |

## Implementation List
- Basic Pipeline with data hazard handling
- M-extension
- Branch Target Table & Return Address Stack
- Multi-way Cache
- Instruction Prefetch
