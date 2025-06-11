#include <stdint.h>
#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xtmrctr.h"
#include "xparameters.h"
#include "target_config.h"
#include "xil_io.h"

#define AXI_DPE_BASE_ADDR 0x30000
#define DPE_X_NUM_BYTES 128

// Number of 32-bit writes on axi-dpe intended to store in BRAM as vector x
uint32_t num_writes = DPE_X_NUM_BYTES;
int32_t buffer[DPE_X_NUM_BYTES] = {
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000,
   0x3f800000,  0x3f800000,  0x3f800000, 0x3f800000, 0x3f800000,  0x3f800000, 0x3f800000,  0x3f800000
};
 

XTmrCtr TimerCounter;
static inline u32 get_timer_val(void)
{
    // Returns the current 32-bit value from the AXI timer
    return XTmrCtr_GetValue(&TimerCounter, 0);
}

typedef struct sdc_reg
{
	volatile uint32_t ctrl;
	volatile uint32_t stat;
	volatile uint32_t dstaddr;
	volatile uint32_t startsector;
	volatile uint32_t sectornum;
	volatile uint32_t progress;
	volatile uint32_t reset;
}sdc_reg_t;

static volatile sdc_reg_t *sdc = (volatile sdc_reg_t *)XPAR_SD_CONTROLLER_WRAPPER_0_BASEADDR;

typedef struct mem_setter
{
    volatile uint32_t source_addr;  // 0x800
    volatile uint32_t target_addr;  // 0x804
    volatile uint32_t length;       // 0x808
    volatile uint32_t control;      // 0x80C
    volatile uint32_t status;       // 0x810
    volatile uint32_t no_access;
} mem_setter_t;

static volatile mem_setter_t *m_setter = (volatile mem_setter_t *)(XPAR_AXI_DPE_0_BASEADDR + 0x800);

void sdcard_reset()
{
	sdc->reset = 0x01;
}

int sdcard_is_busy()
{
    u32 s = sdc->stat;
    return s & 0x01;
}

void wait_sdcard_ready()
{
	u32 cur_time = get_timer_val();
	uint32_t last_progress = sdc->progress;

	while(sdcard_is_busy())
	{
		if(sdc->progress != last_progress)
		{
			last_progress = sdc->progress;
			cur_time = get_timer_val();
		}
		else if((get_timer_val() - cur_time) > 5e6)
		{
			xil_printf("Retrying\r\n");
			sdcard_reset();
			while(sdcard_is_busy());
			cur_time = get_timer_val();
			last_progress = sdc->progress;
			sdc->ctrl = 1;
		}
	}
}

void sdcard_read(uint32_t dstaddr, uint32_t offset, uint32_t size)
{
    wait_sdcard_ready();
	while(sdcard_is_busy());
    sdc->dstaddr = dstaddr;
    sdc->startsector = offset;
    sdc->sectornum = size;
    sdc->ctrl = 1;
}

uint32_t sdcard_get_progress()
{
    return sdc->progress;
}

#if defined(alinx)
    #define BASE_ADDR XPAR_MIG_0_BASEADDRESS
#elif defined(puzhi)
   // #define BASE_ADDR XPAR_LMB_BRAM_0_BASEADDRESS
   #define BASE_ADDR XPAR_DDR4_0_BASEADDRESS
    
#endif

static volatile uint16_t *block_ram = (volatile uint16_t *)(BASE_ADDR);
    static volatile uint32_t *block_ram_32bit = (volatile uint32_t *)(BASE_ADDR);
    static volatile uint8_t *block_ram_8bit = (volatile uint8_t *)(BASE_ADDR);
int main()
{
    init_platform();

    // 1) Initialize the AXI Timer
    XTmrCtr_Initialize(&TimerCounter, XPAR_XTMRCTR_0_BASEADDR);

    // Optionally set auto-reload, but for simple timing we don't necessarily need it
    XTmrCtr_SetOptions(&TimerCounter, 0, XTC_AUTO_RELOAD_OPTION);

    // Reset
    XTmrCtr_Reset(&TimerCounter, 0);

    // Start
    XTmrCtr_Start(&TimerCounter, 0);

    // Sd card reset
	sdcard_reset();

    while((sdc->stat & 0x18) != 0x18);

    xil_printf("Start DMA\r\n");

    sdcard_read(block_ram, 0, 1024*500*2); // 500MB test

    while(sdcard_is_busy());
 
    xil_printf("Transferred %ld bytes\r\n", sdcard_get_progress());

    // uint16_t v = 0x0;
    // for (int i=0; i < 1024*1*512; i++)
    //      if  (v++ != block_ram[i])
    //          xil_printf("err block_ram[%d]: %x\r\n", i, block_ram[i]);

    for (int i = 0; i < 16; i++)
         xil_printf("block_ram[%d]: %x\r\n", i, block_ram_8bit[i]);

    xil_printf("First 16!\r\n");

    for (int i = 0; i < 16; i++)
         xil_printf("block_ram[%d]: %x\r\n", i, block_ram_8bit[512 + i]);

    xil_printf("Fitst 16 after 512!\r\n");
 
    m_setter->source_addr = block_ram;
    m_setter->target_addr = block_ram + 8192;
    m_setter->length = 1024;
    m_setter->control = 0x0;
    
    for (int i = 0; i < DPE_X_NUM_BYTES;  i++){
    	Xil_Out32(AXI_DPE_BASE_ADDR + (i * 4), (u32)buffer[i]);
    	u32 val = Xil_In32(AXI_DPE_BASE_ADDR + (i * 4));
    	xil_printf("Addr 0x%08X = 0x%08X\r\n", AXI_DPE_BASE_ADDR + (i * 4), val);
    }

    while(!(m_setter->status & 0x2))
    {
        xil_printf("status in while loop %x!\r\n", m_setter->status);
    }
    xil_printf("source_addr %x!\r\n", m_setter->source_addr);
    xil_printf("target_addr %x!\r\n", m_setter->target_addr);
    xil_printf("length %x!\r\n", m_setter->length);
    xil_printf("control %x!\r\n", m_setter->control);
    xil_printf("status %x!\r\n", m_setter->status);
    xil_printf("no access %x!\r\n", m_setter->no_access);
    // xil_printf("start %x!\r\n", m_setter->start);
    // xil_printf("value %x!\r\n", m_setter->value);
    // xil_printf("len %x!\r\n", m_setter->len);
    // xil_printf("addr %x!\r\n", m_setter->start_addr);
    // xil_printf("no access %x!\r\n", m_setter->no_access);
    
    // xil_printf("Done memset!\r\n");

    for (int i = 0; i < 1024; i++)
         xil_printf("block_ram[%d]: %x\r\n", i, block_ram[8192 + i]);


    cleanup_platform();
    return 0;
}
