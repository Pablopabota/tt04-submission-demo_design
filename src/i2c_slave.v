//Website:https://dlbeer.co.nz/articles/i2c.html
//------------------jcyuan change------------------------
//-------------------------------------------------------
//-------------------------------------------------------
//----------------------USAGE----------------------------
//-------------------------------------------------------
//-------------------------------------------------------
//FOR WRITE----------------------------------------------

/*START
Master-to-slave: device address, R/W# = 0 (0xAA)
Master-to-slave: register index (0x03)
Master-to-slave: register data (0x57)
STOP*/

//FOR READ-----------------------------------------------

/*START
Master-to-slave: device address, R/W# = 0 (0xAA)
Master-to-slave: register index (0x03)
RESTART
Master-to-slave: device address, R/W# = 1 (0xAB)
Slave-to-master (not acked): register data (0x57)
STOP*/

//-------------------------------------------------------
//-------------------------------------------------------
//-------------------------------------------------------
//-------------------------------------------------------
module i2c_slave (
    input scl,
    inout sda,
    input i2c_rst
    );

parameter [2:0] STATE_IDLE      = 3'h0,//idle
                STATE_DEV_ADDR  = 3'h1,//the slave addr match
                STATE_READ      = 3'h2,//the op=read 
                STATE_IDX_PTR   = 3'h3,//get the index of inner-register
                STATE_WRITE     = 3'h4;//write the data in the reg 

reg             start_detect;
reg             start_resetter;

reg             stop_detect;
reg             stop_resetter;

reg [3:0]       bit_counter;//(from 0 to 8)9counters-> one byte=8bits and one ack=1bit
reg [7:0]       input_shift;
reg             master_ack;
reg [2:0]       state;
reg [7:0]       reg_00,reg_01,reg_02,reg_03;//slave_reg
reg [7:0]       output_shift;
reg             output_control;
reg [7:0]       index_pointer;

parameter [6:0] device_address = 7'h55;
wire            start_rst = i2c_rst | start_resetter;//detect the START for one cycle
wire            stop_rst = i2c_rst | stop_resetter;//detect the STOP for one cycle
wire            lsb_bit = (bit_counter == 4'h7) && !start_detect;//the 8bits one byte data
wire            ack_bit = (bit_counter == 4'h8) && !start_detect;//the 9bites ack 
wire            address_detect = (input_shift[7:1] == device_address);//the input address match the slave
wire            read_write_bit = input_shift[0];// the write or read operation 0=write and 1=read
wire            write_strobe = (state == STATE_WRITE) && ack_bit;//write state and finish one byte=8bits
assign          sda = output_control ? 1'bz : 1'b0;

//---------------------------------------------
//---------------detect the start--------------
//---------------------------------------------
always @ (posedge start_rst or negedge sda) begin
    if (start_rst)
        start_detect <= 1'b0;
    else
        start_detect <= scl;
end

always @ (posedge i2c_rst or posedge scl) begin
    if (i2c_rst)
        start_resetter <= 1'b0;
    else
        start_resetter <= start_detect;
end
//the START just last for one cycle of scl

//---------------------------------------------
//---------------detect the stop---------------
//---------------------------------------------
always @ (posedge stop_rst or posedge sda) begin   
    if (stop_rst)
        stop_detect <= 1'b0;
    else
        stop_detect <= scl;
end

always @ (posedge i2c_rst or posedge scl) begin   
    if (i2c_rst)
        stop_resetter <= 1'b0;
    else
        stop_resetter <= stop_detect;
end
//the STOP just last for one cycle of scl
//don't need to check the RESTART,due to: a START before it is STOP,it's START; 
//                                        a START before it is START,it's RESTART;
//the RESET and START combine can be recognise the RESTART,but it's doesn't matter

//---------------------------------------------
//---------------latch the data---------------
//---------------------------------------------
always @ (negedge scl) begin
    if (ack_bit || start_detect)
        bit_counter <= 4'h0;
    else
        bit_counter <= bit_counter + 4'h1;
end
//counter to 9(from 0 to 8), one byte=8bits and one ack 
always @ (posedge scl) begin
    if (!ack_bit)
        input_shift <= {input_shift[6:0], sda};
end
//at posedge scl the data is stable,the input_shift get one byte=8bits

//---------------------------------------------
//------------slave-to-master transfer---------
//---------------------------------------------
always @ (posedge scl) begin
    if (ack_bit)
        master_ack <= ~sda;//the ack sda is low
end
//the 9th bits= ack if the sda=1'b0 it's a ACK, 

//---------------------------------------------
//------------state machine--------------------
//---------------------------------------------
always @ (posedge i2c_rst or negedge scl) begin
    if (i2c_rst)
        state <= STATE_IDLE;
    else if (start_detect)
        state <= STATE_DEV_ADDR;
    else if (ack_bit) begin//at the 9th cycle and change the state by ACK
        case (state)
            STATE_IDLE: begin
                state <= STATE_IDLE;
            end
            STATE_DEV_ADDR: begin
                if (!address_detect)//addr don't match
                    state <= STATE_IDLE;
                else if (read_write_bit)// addr match and operation is read
                    state <= STATE_READ;
                else//addr match and operation is write
                    state <= STATE_IDX_PTR;
            end
            STATE_READ: begin
                if (master_ack)//get the master ack 
                    state <= STATE_READ;
                else//no master ack ready to STOP
                    state <= STATE_IDLE;
            end
            STATE_IDX_PTR: begin
                state <= STATE_WRITE;//get the index and ready to write 
            end
            STATE_WRITE: begin
                state <= STATE_WRITE;//when the state is write the state
            end
        endcase
    end
    //if don't write and master send a stop,need to jump idle
    //the stop_detect is the next cycle of ACK
    else if(stop_detect)//jcyuan add  
            state <= STATE_IDLE;//jcyuan add
end

//---------------------------------------------
//------------Register transfers---------------
//---------------------------------------------

//-------------------for index----------------
always @ (posedge i2c_rst or negedge scl) begin
    if (i2c_rst)
        index_pointer <= 8'h00;
    else if (stop_detect)
        index_pointer <= 8'h00;
    else if (ack_bit) begin //at the 9th bit -ack, the input_shift has one bytes
        if (state == STATE_IDX_PTR) //at the state get the inner-register index
            index_pointer <= input_shift;
        else //ready for next read/write;bulk transfer of a block of data 
            index_pointer <= index_pointer + 8'h01;
    end
end

//----------------for write---------------------------
//we only define 4 registers for operation
always @ (posedge i2c_rst or negedge scl) begin
    if (i2c_rst) begin
        reg_00 <= 8'h00;
        reg_01 <= 8'h00;
        reg_02 <= 8'h00;
        reg_03 <= 8'h00;
    end //the moment the input_shift has one byte=8bits
    else if (write_strobe && (index_pointer == 8'h00))
        reg_00 <= input_shift;
    else if (write_strobe && (index_pointer == 8'h01))
        reg_01 <= input_shift;
    else if (write_strobe && (index_pointer == 8'h02))
        reg_02 <= input_shift;
    else if (write_strobe && (index_pointer == 8'h03))
        reg_03 <= input_shift;
end

//------------------------for read-----------------------
always @ (negedge scl) begin   
    if (lsb_bit) begin //at one byte that can be load the output_shift
        case (index_pointer)
            8'h00: output_shift <= reg_00;
            8'h01: output_shift <= reg_01;
            8'h02: output_shift <= reg_02;
            8'h03: output_shift <= reg_03;
            // ... and so on ...
        endcase
    end
    else begin
        output_shift <= {output_shift[6:0], 1'b0};
        //once the shift it,after 8 times the output_shift=8'b0
        //the 9th bit is 0 for the RESTART for address match slave ACK 
    end
end

//---------------------------------------------
//------------Output driver--------------------
//---------------------------------------------

always @ (posedge i2c_rst or negedge scl) begin   
    if (i2c_rst)
        output_control <= 1'b1;
    else if (start_detect)
        output_control <= 1'b1;
    else if (lsb_bit) begin   
        output_control <= !(((state == STATE_DEV_ADDR) && address_detect) || 
        (state == STATE_IDX_PTR) || (state == STATE_WRITE)); 
        //when operation is wirte 
        //addr match gen ACK,the index get gen ACK,and write data gen ACK
    end
    else if (ack_bit) begin
        // Deliver the first bit of the next slave-to-master
        // transfer, if applicable.
        if (((state == STATE_READ) && master_ack) || ((state == STATE_DEV_ADDR) && address_detect && read_write_bit))
            output_control <= output_shift[7];
            //for the RESTART and send the addr ACK for 1'b0
            //for the read and master ack both slave is pull down
        else
            output_control <= 1'b1;
    end
    else if (state == STATE_READ)//for read send output shift to sda
        output_control <= output_shift[7];
    else
        output_control <= 1'b1;
end

endmodule
