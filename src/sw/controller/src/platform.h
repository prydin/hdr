/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

#ifndef __PLATFORM_H_
#define __PLATFORM_H_

#ifndef SDT
#include "platform_config.h"
#endif

#include "xiic.h"

void init_platform();
void cleanup_platform();
XIic* get_iic();
#endif
