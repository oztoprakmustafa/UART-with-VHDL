# UART-with-VHDL
Designing of UART Communication Protocol Using VHDL
Throughout my internship period, I have taken many tasks individually. 
One of them is understanding of basic conseps of Uart communication protocol and testing it using FPGA. This project consists of two parts;
One part is sending data from computer to FPGA to blink led.
The other part is sending data from FPGA to computer to see in serial monitor.

#Information about UART
What is UART?
“UART” stands for Universal Asynchronous receiver-transmitter. It is a peripheral that is present inside a microcontroller.
The function of UART is to convert the incoming and outgoing data into the serial binary stream. An 8-bit serial data received 
from the peripheral device is converted into the parallel form using serial to parallel conversion and parallel data received 
from the CPU is converted using serial to parallel conversion.

Block Diagram
The UART consists of the following core components. They are the transmitter and receiver. 
The transmitter consists of the Transmit hold register, Transmit shift register, and control logic.
Similarly, the receiver consists of a Receive hold register, Receiver shift register, and control logic. 
In common, both the transmitter and receiver are provided with baud rate generator.
The baud rate generator generates the speed at which the transmitter and receiver have to send/receive the data.
The Transmit hold register contains the data byte to be transmitted. 
The transmit shift register and receiver shift register shift the bits to the left or right until a byte of data is sent/received.

![UART-Block-Diagram](https://user-images.githubusercontent.com/34604921/152719711-3d5f61dc-6756-40ef-88f6-3c9d8ad442f4.png)

How UART works?
To know the working of UART, you need to understand the basic functionality of serial communication. 
In short, transmitter and receiver use start bit, stop bit and timing parameters to synchronize with each other. 
The original data is in the parallel form. For example, we have 4-bit data, to convert it into the serial form,
we need a parallel to serial converter.
![UART-Interface](https://user-images.githubusercontent.com/34604921/152719734-1959b6fd-1918-488f-84c1-e97320cab91c.png)
