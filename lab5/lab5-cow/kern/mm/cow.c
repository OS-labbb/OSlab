/*
 * Copy-On-Write (COW) Implementation for ucore
 * 
 * This file implements the COW mechanism which allows parent and child processes
 * to share memory pages until one of them attempts to write to a shared page.
 * 
 * Key Features:
 * 1. Share pages on fork instead of copying
 * 2. Mark shared pages as read-only with COW flag
 * 3. Handle page faults on write attempts
 * 4. Copy page only when write occurs (lazy copy)
 */

#include <pmm.h>
#include <vmm.h>
#include <mmu.h>
#include <error.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

// Define true/false if not available
#ifndef true
#define true 1
#define false 0
#endif

/*
 * copy_range_cow - Copy-On-Write version of copy_range
 * 
 * Instead of copying the page content, this function:
 * 1. Shares the physical page between parent and child
 * 2. Marks both PTEs as read-only
 * 3. Sets the COW flag in both PTEs
 * 4. Increments the page reference count
 * 
 * @to:    destination page directory
 * @from:  source page directory
 * @start: start virtual address
 * @end:   end virtual address
 * @share: if true, use COW; if false, use traditional copy
 * 
 * Return: 0 on success, -E_NO_MEM on failure
 */
int copy_range_cow(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end, bool share)
{
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    
    // If not sharing, use traditional copy (not implemented here)
    if (!share) {
        cprintf("COW: Traditional copy not implemented in this function\n");
        return -E_INVAL;
    }
    
    do {
        // Get source PTE
        pte_t *ptep = get_pte(from, start, 0);
        pte_t *nptep;
        
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        
        // If PTE is valid, set up COW sharing
        if (*ptep & PTE_V) {
            // Get or create destination PTE
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            
            uint32_t perm = (*ptep & PTE_USER);
            struct Page *page = pte2page(*ptep);
            
            // Check if page already has COW flag
            bool already_cow = (*ptep & PTE_COW) ? true : false;
            
            if (!already_cow) {
                // First time sharing this page
                // Remove write permission and add COW flag to parent's PTE
                uint32_t new_perm = (perm & ~PTE_W) | PTE_COW;
                *ptep = pte_create(page2ppn(page), new_perm);
                
                // Flush TLB for parent's page
                tlb_invalidate(from, start);
                
                cprintf("COW: Page at VA 0x%x marked as COW in parent (ref=%d)\n", 
                        start, page_ref(page));
            }
            
            // Set up child's PTE with same COW settings
            uint32_t child_perm = (perm & ~PTE_W) | PTE_COW;
            
            // Share the page by incrementing reference count
            page_ref_inc(page);
            
            // Map the shared page to child with COW flag
            *nptep = pte_create(page2ppn(page), child_perm);
            
            cprintf("COW: Page at VA 0x%x shared with child (ref=%d)\n", 
                    start, page_ref(page));
        }
        
        start += PGSIZE;
    } while (start != 0 && start < end);
    
    return 0;
}

/*
 * do_cow_page_fault - Handle COW page fault
 * 
 * This function is called when a process tries to write to a COW page.
 * It performs the actual copy of the page and updates the page table.
 * 
 * Steps:
 * 1. Verify this is a COW page fault
 * 2. Allocate a new page
 * 3. Copy content from shared page to new page
 * 4. Update PTE to point to new page with write permission
 * 5. Decrement reference count of old page
 * 6. Flush TLB
 * 
 * @mm:   memory management structure
 * @addr: faulting address
 * 
 * Return: 0 on success, error code on failure
 */
int do_cow_page_fault(struct mm_struct *mm, uintptr_t addr)
{
    cprintf("COW: Page fault at address 0x%x\n", addr);
    
    if (mm == NULL) {
        cprintf("COW: Error - mm is NULL\n");
        return -E_INVAL;
    }
    
    // Get the PTE for the faulting address
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
    
    if (ptep == NULL || !(*ptep & PTE_V)) {
        cprintf("COW: Error - Invalid PTE\n");
        return -E_INVAL;
    }
    
    // Check if this is a COW page
    if (!(*ptep & PTE_COW)) {
        cprintf("COW: Error - Not a COW page\n");
        return -E_INVAL;
    }
    
    cprintf("COW: Confirmed COW page fault\n");
    
    // Get the old page
    struct Page *old_page = pte2page(*ptep);
    uint32_t perm = (*ptep & PTE_USER);
    
    cprintf("COW: Old page ref count = %d\n", page_ref(old_page));
    
    // Special case: if we're the only one using this page, just restore write permission
    if (page_ref(old_page) == 1) {
        cprintf("COW: Only one reference, restoring write permission\n");
        
        // Remove COW flag and restore write permission
        uint32_t new_perm = (perm & ~PTE_COW) | PTE_W;
        *ptep = pte_create(page2ppn(old_page), new_perm);
        
        // Flush TLB
        tlb_invalidate(mm->pgdir, addr);
        
        cprintf("COW: Write permission restored\n");
        return 0;
    }
    
    // Multiple references exist, need to copy the page
    cprintf("COW: Multiple references exist, copying page\n");
    
    // Allocate a new page
    struct Page *new_page = alloc_page();
    if (new_page == NULL) {
        cprintf("COW: Error - Failed to allocate new page\n");
        return -E_NO_MEM;
    }
    
    // Get kernel virtual addresses
    void *old_kva = page2kva(old_page);
    void *new_kva = page2kva(new_page);
    
    // Copy content from old page to new page
    memcpy(new_kva, old_kva, PGSIZE);
    
    cprintf("COW: Page content copied\n");
    
    // Decrement reference count of old page
    page_ref_dec(old_page);
    
    // Update PTE to point to new page with write permission
    uint32_t new_perm = (perm & ~PTE_COW) | PTE_W;
    
    // Round down address to page boundary
    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
    
    // Insert the new page with write permission
    int ret = page_insert(mm->pgdir, new_page, la, new_perm);
    if (ret != 0) {
        cprintf("COW: Error - Failed to insert new page\n");
        free_page(new_page);
        return ret;
    }
    
    cprintf("COW: New page mapped, old page ref count = %d\n", page_ref(old_page));
    
    return 0;
}

/*
 * is_cow_page_fault - Check if a page fault is a COW fault
 * 
 * A page fault is a COW fault if:
 * 1. The page is valid
 * 2. The page has the COW flag set
 * 3. The fault was caused by a write attempt
 * 
 * @mm:         memory management structure
 * @addr:       faulting address
 * @error_code: error code from trap frame (not used in RISC-V, check cause instead)
 * 
 * Return: true if COW fault, false otherwise
 */
bool is_cow_page_fault(struct mm_struct *mm, uintptr_t addr, uint32_t error_code)
{
    if (mm == NULL) {
        return false;
    }
    
    // Get the PTE
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
    
    if (ptep == NULL || !(*ptep & PTE_V)) {
        return false;
    }
    
    // Check COW flag
    if (*ptep & PTE_COW) {
        cprintf("COW: Detected COW page fault at 0x%x\n", addr);
        return true;
    }
    
    return false;
}

/*
 * Setup COW for a memory range during fork
 * This is a wrapper function that can be called from copy_mm
 */
int setup_cow_pages(struct mm_struct *to, struct mm_struct *from)
{
    if (to == NULL || from == NULL) {
        return -E_INVAL;
    }
    
    cprintf("COW: Setting up COW for memory range\n");
    
    list_entry_t *list = &(from->mmap_list);
    list_entry_t *le = list;
    
    // Iterate through all VMAs
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        
        // Set up COW for this VMA's range
        int ret = copy_range_cow(to->pgdir, from->pgdir, 
                                 vma->vm_start, vma->vm_end, true);
        if (ret != 0) {
            cprintf("COW: Failed to setup COW for VMA [0x%x, 0x%x)\n", 
                    vma->vm_start, vma->vm_end);
            return ret;
        }
        
        cprintf("COW: Setup COW for VMA [0x%x, 0x%x)\n", 
                vma->vm_start, vma->vm_end);
    }
    
    return 0;
}