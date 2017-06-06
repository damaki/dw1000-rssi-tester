# DW1000 RSSI Tool

This project implements a program to measure the received signal strength
indication (RSSI) for the [https://decawave.com/products/dw1000](DecaWave DW1000)
ultra-wideband (UWB) transceiver. The purpose of this tool is to provide a way
for users to find the limits on communication range, and areas of low signal
strength and reliability in environments utilizing the DecaWave DW1000.

## Hardware

This tool is designed to run on the DecaWave EVB1000 evaluation boards,
utilizing the DW1000 UWB transceiver.

## Using the tool

There are two programs which must be built and loaded onto the EVB1000 boards.
One program continuously transmits packets, and the other program receives those
packets and measures the RSSI and packet loss relative to the transmitter.

### Dependencies

The following prerequisites are required before building the software:
  * GNAT GPL 2016 for ARM ELF (available at [https://libre.adacore.com/download/](libre.adacore.com)).
  * The ravenscar-full-evb1000 runtime (available on [https://github.com/damaki/ravenscar-full-evb1000](GitHub)).

### Building the programs

There are two programs, a transmitter and a receiver. To build the transmitter
run the following command in the `transmitter` directory:

```
gprbuild --target=arm-eabi -Pdw1000_rssi_scan_tx.gpr
```

To build the receiver program run the following command in the `receiver`
directory:

```
gprbuild --target-arm-eabi -Pdw1000_rssi_scan_rx.gpr
```

### Programming the EVB1000

The output of the build process described above are two executables:
`transmitter/bin/dw1000_rssi_scan_tx.elf` and 
`receiver/bin/dw1000_rssi_scan_rx.elf`. These instructions to program the
STM32 microcontroller on the EVB1000 with these executables are based on the
[http://www.st.com/en/development-tools/st-link-v2.html](ST-LINK/V2) by
ST Microelectronics.

To program the executable onto the target, use the following instructions
(this example programs the transmitter executable, but the process is the same
for both executables, just with different file names, of course):
  1. Convert the ELF file to a binary (.bin) file using the following command:
     ```arm-eabi-objcopy -Obinary dw1000_rssi_scan_tx.elf dw1000_rssi_scan_tx.bin```
  2. Connect the ST-LINK/V2 to the target EVB1000 and apply power to the board.
  3. Run the following command:
     ```st-flash write dw1000_rssi_scan_tx.bin 0x08000000```
     
### Running the executables

Once the executables have been programmed, you can use them to measure the signal
strength in your environment simply by powering on the programmed EVB1000 boards.
You will need to program one EVB1000 board with the transmitter executable, and
one (or more) other EVB1000 boards with the receiver executable.

The basic premise is that the transmitter transmits a continuous stream of packets
using the configured channel, data rate, and PRF. The receiver(s) listens for these
transmitted packets and measures the average signal strength and percentage of
packets correctly received. As you move the receiver around in your environment,
the signal strength and percentage of packets received will vary, allowing you
to find the limits on range of the EVB1000 in your environment.

### Configuring the EVB1000

The transmitter and receiver must be configured to use the same settings
(channel, data rate, and PRF). They are configured using the S1 switches
at the top of the EVB1000 (to the left of the four LEDs).

Switches 3 and 4 configure the data rate:
|  3  |  4  | Data Rate |
|:---:|:---:|:---------:|
| Off | Off | 110 kbps  |
| Off | On  | 850 kbps  |
| On  | Off | 6.81 Mbps |
| On  | On  | 6.81 Mbps |

Switch 5 configures the PRF:
|  5  |  PRF   |
|:---:|:------:|
| Off | 16 MHz |
| On  | 64 MHz |

Switches 6, 7, and 8 configure the channel (frequency):
|  6  |  7  |  8  | Channel |
|:---:|:---:|:---:|:-------:|
| Off | Off | Off | 1       |
| Off | Off | On  | 2       |
| Off | On  | Off | 3       |
| Off | On  | On  | 4       |
| On  | Off | Off | 5       |
| On  | Off | On  | 7       |
| On  | On  | Off | 7       |
| On  | On  | On  | 7       |

### LCD

The LCD displays the current configuration on the top line, and the percentage
of packets received and the average RSSI on the bottom line. An example of the
information displayed is shown below:
```
Ch1 16MHz 110kbps
 94% -93 dBm
```

With the above example, 94% of packets were received over the last second, and
the average estimated signal strength of the received packets was -93 dBm.

If the receiver is out of range of the transmitter (or the transmitter is off,
or using a different configuration), then the bottom line of the display shows
dashes. For example:
```
Ch1 16MHz 110kbps
 ---% ---- dBm
```


The display is updated at a rate of 1 Hz, and the measurements are calculated 
over the previous 1 second of received packets.

### LEDs

Three of the LEDs on the EVB1000 are used also relay information. The behaviour
of the LEDs (1 to 4, left to right) are as follows:
  1. Toggled every time the LCD is updated (at a rate of 1 Hz).
  2. Not used.
  3. Toggled each time a receiver error occurs (e.g. bad packet or demodulation
     error, etc...)
  4. Toggled each time a packet is received.
