/*
 * Copy-On-Write (COW) Header File
 * 
 * This header provides the interface for COW functionality in ucore
 */

#ifndef __KERN_MM_COW_H__
#define __KERN_MM_COW_H__

#include <defs.h>
#include <mmu.h>

// Forward declarations
struct mm_struct;

/*
 * Copy memory range with COW optimization
 * This is the main function used during fork()
 */
int copy_range_cow(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share);

/*
 * Handle COW page fault
 * Called from trap handler when a write to COW page is detected
 */
int do_cow_page_fault(struct mm_struct *mm, uintptr_t addr);

/*
 * Check if a page fault is a COW fault
 */
bool is_cow_page_fault(struct mm_struct *mm, uintptr_t addr, uint32_t error_code);

/*
 * Setup COW for all pages in a memory management structure
 * Used during process fork
 */
int setup_cow_pages(struct mm_struct *to, struct mm_struct *from);

#endif /* !__KERN_MM_COW_H__ */