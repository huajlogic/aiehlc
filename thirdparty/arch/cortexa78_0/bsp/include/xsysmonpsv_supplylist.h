#ifndef XSYSMONPSV_SUPPLYLIST
#define XSYSMONPSV_SUPPLYLIST

#define XPAR_XSYSMONPSV_0_NO_MEAS       255

/*
* The supply configuration table for sysmon
*/
typedef enum {
	EndList,
	NO_SUPPLIES_CONFIGURED = XPAR_XSYSMONPSV_0_NO_MEAS,
} XSysMonPsv_Supply;

#endif