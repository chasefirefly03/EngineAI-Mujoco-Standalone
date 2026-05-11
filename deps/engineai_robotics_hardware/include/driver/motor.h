#ifndef __MOTOR_DRIVER__
#define __MOTOR_DRIVER__

#ifdef __cplusplus 
extern "C" {
#endif

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <linux/types.h>

typedef struct {
  int dimension;
  float *q;
  float *qd;
  float *tau;
} motor_data_t;

typedef struct {
  int dimension;
  float *q_des;
  float *qd_des;
  float *kp;
  float *kd;
  float *tau_ff;
} motor_command_t;

typedef struct {
  int dimension;
  bool *disable;
  bool *offline;
  bool* over_temperature_warning;
  bool* over_temperature_error;
  bool* under_voltage_error;
  bool* over_voltage_error;
  bool* phase_a_over_current_error;
  bool* phase_b_over_current_error;
  bool* phase_c_over_current_error;
  bool* over_heat_error;
  bool* over_torque_error;
  bool* motor_encoder_validation_error;
  bool* joint_encoder_validation_error;
  bool* self_check_error;
  bool* over_speed_error;
} motor_error_t;

typedef struct {
  int dimension;
  float *tau_cmd;
  float *mos_temperature;
  float *motor_temperature;
  unsigned short *run_time;
  unsigned short *last_run_time;
  unsigned short *error_code;
  unsigned short *voltage;
  unsigned short *current;
} motor_debug_t;

typedef struct {
  bool enable;
  float percentage;
  float voltage;
  float current;
  float current_limit;
  unsigned int error_code;
} motor_power_t;

typedef struct {
  int dimension;
  char *model;
  char *ver;
} motor_ver_info_t;

typedef enum {
  kOverTemperatureErrorWarning = 0,
  kUnderVoltageError,
  kOverVoltageError,
  kPhaseABCOverCurrentError,
  kOverHeatError,
  kOverTorqueError,
  kOverSpeedError,
} MotorError_t;

/* set_powerboard_led() */
typedef enum {
  BLINK_RED = 0x1,
  BLINK_GREEN = 0x2,
  BLINK_BLUE = 0x3,
  BLINK_WHITE = 0x4,
  CONSTANT_ON_WHITE = 0x5,
  CONSTANT_ON_GREEN = 0x6,
  BREATHE_WHITE = 0x7,
  WATER_WHITE = 0x8,
  BREATHE_RED = 0x9,
  BLINK_ORANGE = 0xa,
  CONSTANT_ON_ORANGE = 0xb,
};

extern int set_motor_product_cfg(char *str);
extern int motor_init(void);
extern void motor_destroy(void);

extern motor_command_t *get_motor_cmd(void);
extern motor_data_t *get_motor_data(void);

extern int set_motor_cmd(motor_command_t *cmd);
extern int set_motor_enable(int *buff, int length);
extern int set_motor_zero(int index);
extern int set_motor_bias_zero(int index);
extern int set_powerboard_led(uint8_t led_color);
extern int set_powerboard_led_state(char *str);
extern int set_upgrade_firmware_type(uint8_t type);

extern motor_error_t *get_motor_error(void);
extern motor_debug_t *get_motor_debug(void);
extern motor_power_t *get_motor_power(void);
extern motor_ver_info_t *get_motor_ver_info(void);

extern void motor_debug_out_set(int enable);
extern char *get_product_model(void);
extern int get_product_motor_num(void);

extern int get_motor_ver(void);
extern int set_get_motor_ver(void);
extern int set_get_motor_hardware_ver(void);
extern char *get_motor_hal_version(void);
extern char *get_motor_model(int index);
extern int modify_motor_params(void *t_data, void *r_data, int parm_index, int motor_index, char *mode);
extern bool is_motor_bus_connected(void);
extern int update_motor_fw(char *file, int motor_index);
extern bool enable_or_disable_motor_error(MotorError_t motor_error, bool enable);

#ifdef __cplusplus 
};
#endif

#endif //__MOTOR_DRIVER__