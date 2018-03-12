#ifndef MACROS_INC_
#define MACROS_INC_

#define phy_reg_read(addr, target)  \
    mov addr, r33                           \
    calls   L52                             \
    or  SPR_Ext_IHR_Data, 0x0, target

#define phy_reg_read_to_shm(addr, target)   \
    mov addr, r33                           \
    calls   L52                             \
    or  SPR_Ext_IHR_Data, 0x0, [target]

#define phy_reg_read_to_shm_off(addr, base, offset) \
    mov addr, r33                                   \
    calls   L52                                     \
    or  SPR_Ext_IHR_Data, 0x0, [base, offset]

#define phy_reg_write(addr, value)          \
    mov addr, r33                           \
    mov value, r34                          \
    calls   L54

#define phy_reg_or(addr, value)             \
    mov addr, r33                           \
    calls   L52                             \
    mov value, r34                          \
    or  SPR_Ext_IHR_Data, r34, r34          \
    calls   L54

#define phy_reg_and(addr, value)            \
    mov addr, r33                           \
    calls   L52                             \
    mov value, r34                          \
    and SPR_Ext_IHR_Data, r34, r34          \
    calls   L54

#define phy_table_write_word(id, offset, data)      \
    phy_reg_write(ACPHY_TableID(rev), id)           \
    phy_reg_write(ACPHY_TableOffset(rev), offset)   \
    phy_reg_write(ACPHY_TableDataLo(rev), data)

#endif /* MACROS_INC_ */
