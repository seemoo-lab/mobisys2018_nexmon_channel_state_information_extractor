/***************************************************************************
 *                                                                         *
 *          ###########   ###########   ##########    ##########           *
 *         ############  ############  ############  ############          *
 *         ##            ##            ##   ##   ##  ##        ##          *
 *         ##            ##            ##   ##   ##  ##        ##          *
 *         ###########   ####  ######  ##   ##   ##  ##    ######          *
 *          ###########  ####  #       ##   ##   ##  ##    #    #          *
 *                   ##  ##    ######  ##   ##   ##  ##    #    #          *
 *                   ##  ##    #       ##   ##   ##  ##    #    #          *
 *         ############  ##### ######  ##   ##   ##  ##### ######          *
 *         ###########    ###########  ##   ##   ##   ##########           *
 *                                                                         *
 *            S E C U R E   M O B I L E   N E T W O R K I N G              *
 *                                                                         *
 * This file is part of NexMon.                                            *
 *                                                                         *
 * Copyright (c) 2016 NexMon Team                                          *
 *                                                                         *
 * NexMon is free software: you can redistribute it and/or modify          *
 * it under the terms of the GNU General Public License as published by    *
 * the Free Software Foundation, either version 3 of the License, or       *
 * (at your option) any later version.                                     *
 *                                                                         *
 * NexMon is distributed in the hope that it will be useful,               *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 * GNU General Public License for more details.                            *
 *                                                                         *
 * You should have received a copy of the GNU General Public License       *
 * along with NexMon. If not, see <http://www.gnu.org/licenses/>.          *
 *                                                                         *
 **************************************************************************/

#pragma NEXMON targetregion "patch"

#include <firmware_version.h>   // definition of firmware version macros
#include <debug.h>              // contains macros to access the debug hardware
#include <wrapper.h>            // wrapper definitions for functions that already exist in the firmware
#include <structs.h>            // structures that are used by the code in the firmware
#include <helper.h>             // useful helper functions
#include <patcher.h>            // macros used to craete patches such as BLPatch, BPatch, ...
#include <rates.h>              // rates used to build the ratespec for frame injection
#include <nexioctls.h>          // ioctls added in the nexmon patch
#include <version.h>            // version information
#include <argprintf.h>          // allows to execute argprintf to print into the arg buffer
#include <channels.h>

#define SHM_CSI_COLLECT         0x8b0
#define SHM_CSI_COPIED          0x8b1
#define CMP_FRM_CTRL_FLD        0x8b2
#define CMP_DURATION            0x8b3
#define CMP_DST_MAC_0           0x8b4
#define CMP_DST_MAC_1           0x8b5
#define CMP_DST_MAC_2           0x8b6
#define CMP_SRC_MAC_0           0x8b7
#define CMP_SRC_MAC_1           0x8b8
#define CMP_SRC_MAC_2           0x8b9

int 
wlc_ioctl_hook(struct wlc_info *wlc, int cmd, char *arg, int len, void *wlc_if)
{
    int ret = IOCTL_ERROR;
    argprintf_init(arg, len);

    switch(cmd) {
        case 500: // set csi_collect
        {
            struct params {
                uint16 chanspec;
                uint16 csi_collect;
                uint16 cmp_frm_ctrl_fld;
                uint16 cmp_duration;
                uint16 cmp_dst_mac_0;
                uint16 cmp_dst_mac_1;
                uint16 cmp_dst_mac_2;
                uint16 cmp_src_mac_0;
                uint16 cmp_src_mac_1;
                uint16 cmp_src_mac_2;
            };

            struct params *params = (struct params *) arg;

            // deactivate scanning
            set_scansuppress(wlc, 1);
            
            // deactivate minimum power consumption
            set_mpc(wlc, 0);

            // set the channel
            set_chanspec(wlc, params->chanspec);

            if (wlc->hw->up && len > 1) {
                wlc_bmac_write_shm(wlc->hw, SHM_CSI_COLLECT * 2, params->csi_collect);
                wlc_bmac_write_shm(wlc->hw, CMP_FRM_CTRL_FLD * 2, params->cmp_frm_ctrl_fld);
                wlc_bmac_write_shm(wlc->hw, CMP_DURATION * 2, params->cmp_duration);
                wlc_bmac_write_shm(wlc->hw, CMP_DST_MAC_0 * 2, params->cmp_dst_mac_0);
                wlc_bmac_write_shm(wlc->hw, CMP_DST_MAC_1 * 2, params->cmp_dst_mac_1);
                wlc_bmac_write_shm(wlc->hw, CMP_DST_MAC_2 * 2, params->cmp_dst_mac_2);
                wlc_bmac_write_shm(wlc->hw, CMP_SRC_MAC_0 * 2, params->cmp_src_mac_0);
                wlc_bmac_write_shm(wlc->hw, CMP_SRC_MAC_1 * 2, params->cmp_src_mac_1);
                wlc_bmac_write_shm(wlc->hw, CMP_SRC_MAC_2 * 2, params->cmp_src_mac_2);
                ret = IOCTL_SUCCESS;
            }
            break;
        }

        case 501: // get csi_collect
        {
            if (wlc->hw->up && len > 1) {
                *(uint16 *) arg = wlc_bmac_read_shm(wlc->hw, SHM_CSI_COLLECT * 2);
                ret = IOCTL_SUCCESS;
            }
            break;
        }

        default:
            ret = wlc_ioctl(wlc, cmd, arg, len, wlc_if);
    }

    return ret;
}

__attribute__((at(0x1F3488, "", CHIP_VER_BCM4339, FW_VER_6_37_32_RC23_34_43_r639704)))
GenericPatch4(wlc_ioctl_hook, wlc_ioctl_hook + 1);
