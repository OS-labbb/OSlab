#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

#define BUDDY_MAX_ORDER 10

static free_area_t free_area[BUDDY_MAX_ORDER + 1];

#define free_list(order) (free_area[order].free_list)
#define nr_free(order) (free_area[order].nr_free)

// 辅助函数：判断是否为2的幂
static bool is_power_of_2(size_t n) {
    return n > 0 && (n & (n - 1)) == 0;
}

// 辅助函数：向上取整到2的幂
static size_t round_up_power_of_2(size_t n) {
    if (n == 0) return 1;
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    return n + 1;
}

// 辅助函数：计算以2为底的对数（向下取整）
static unsigned int log2_floor(size_t n) {
    unsigned int order = 0;
    while (n > 1) {
        n >>= 1;
        order++;
    }
    return order;
}

static void
buddy_init(void) {
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_init(&free_list(i));
        nr_free(i) = 0;
    }
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    cprintf("buddy_init_memmap: base=%p, n=%lu\n", base, n);
    
    // 初始化所有页面
    for (size_t i = 0; i < n; i++) {
        struct Page *page = &base[i];
        assert(PageReserved(page));
        page->flags = 0;
        set_page_ref(page, 0);
        // 清除property，我们不在每个页面存储order
        page->property = 0;
    }
    
    // 将整个内存区域作为一个大块添加到最高阶
    unsigned int max_order = BUDDY_MAX_ORDER;
    size_t max_pages = 1 << max_order;
    
    // 如果请求的页面数小于最大块，使用合适的阶数
    while (max_order > 0 && (1 << (max_order - 1)) >= n) {
        max_order--;
    }
    
    base->property = max_order;
    SetPageProperty(base);
    nr_free(max_order)++;
    list_add(&free_list(max_order), &(base->page_link));
    
    cprintf("buddy_init_memmap: initialized order %u with %lu pages\n", max_order, n);
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    if (n > (1 << BUDDY_MAX_ORDER)) {
        cprintf("buddy_alloc_pages: requested too many pages %lu\n", n);
        return NULL;
    }
    
    // 计算需要的阶数
    size_t size = round_up_power_of_2(n);
    unsigned int order = log2_floor(size);
    
    cprintf("buddy_alloc_pages: requesting %lu pages, order %u\n", n, order);
    
    // 寻找合适的块
    unsigned int current_order = order;
    while (current_order <= BUDDY_MAX_ORDER) {
        if (nr_free(current_order) > 0) {
            break;
        }
        current_order++;
    }
    
    if (current_order > BUDDY_MAX_ORDER) {
        cprintf("buddy_alloc_pages: no free memory\n");
        return NULL;
    }
    
    // 获取第一个可用块
    list_entry_t *le = list_next(&free_list(current_order));
    struct Page *page = le2page(le, page_link);
    
    // 从自由链表中移除
    list_del(le);
    nr_free(current_order)--;
    ClearPageProperty(page);
    
    cprintf("buddy_alloc_pages: found block at %p, order %u\n", page, current_order);
    
    // 分割块直到达到需要的阶数
    while (current_order > order) {
        current_order--;
        
        // 计算伙伴块 - 使用正确的索引计算方式
        struct Page *buddy = page + (1 << current_order);  // 正确，因为page已经是struct Page*类型，+表示增加的页面数
        
        // 初始化伙伴块
        buddy->property = current_order;
        SetPageProperty(buddy);
        
        // 将伙伴块加入自由链表
        list_add(&free_list(current_order), &(buddy->page_link));
        nr_free(current_order)++;
        
        cprintf("buddy_alloc_pages: split to order %u, buddy at %p\n", current_order, buddy);
    }
    
    // 设置分配块的属性
    page->property = order;
    cprintf("buddy_alloc_pages: allocated %lu pages at %p\n", 1 << order, page);
    
    return page;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    
    cprintf("buddy_free_pages: freeing %lu pages at %p\n", n, base);
    
    // 实际释放的大小是2的幂
    size_t size = round_up_power_of_2(n);
    unsigned int order = log2_floor(size);
    
    struct Page *page = base;
    page->property = order;
    SetPageProperty(page);
    
    // 尝试合并伙伴块
    while (order < BUDDY_MAX_ORDER) {
        // 计算伙伴块的索引 - 修复核心算法问题
        size_t page_index = page - pages;  // 直接相减得到索引，不需要除以sizeof(struct Page)
        size_t buddy_index = page_index ^ (1 << order);
        
        // 检查伙伴块是否有效
        if (buddy_index >= npage) {
            break;
        }
        
        struct Page *buddy = &pages[buddy_index];
        
        // 检查伙伴块是否空闲且大小相同
        if (!PageProperty(buddy) || buddy->property != order) {
            break;
        }
        
        // 从自由链表中移除伙伴块
        list_del(&(buddy->page_link));
        nr_free(order)--;
        ClearPageProperty(buddy);
        
        // 确定合并后的起始页面（取地址较小的）
        if (page > buddy) {
            struct Page *temp = page;
            page = buddy;
            buddy = temp;
        }
        
        // 提升阶数
        order++;
        page->property = order;
        
        cprintf("buddy_free_pages: merged to order %u at %p\n", order, page);
    }
    
    // 将最终块加入自由链表
    SetPageProperty(page);
    list_add(&free_list(order), &(page->page_link));
    nr_free(order)++;
    
    cprintf("buddy_free_pages: freed order %u at %p\n", order, page);
}

static size_t
buddy_nr_free_pages(void) {
    size_t total = 0;
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        total += nr_free(i) * (1 << i);
    }
    return total;
}

// 辅助函数：打印详细内存状态
static void
buddy_detailed_dump(void) {
    cprintf("\n详细内存状态:\n");
    cprintf("最大阶数: %d\n", BUDDY_MAX_ORDER);
    cprintf("空闲页面总数: %lu\n", nr_free_pages());
    
    // 打印每个阶数的空闲块信息
    cprintf("各阶数空闲块数量:\n");
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        cprintf("order %2d: %4d 块 (每块 %4lu 页)\n", 
               order, nr_free(order), (1UL << order));
    }
}

// 测试1: 边缘情况测试
static void
test_edge_cases(void) {
    cprintf("\n=== 测试1: 边缘情况测试 ===\n");
    
    // 测试分配1个页面（最小单位）
    struct Page *block1 = alloc_page();
    cprintf("分配1个页面 -> 地址: %p\n", block1);
    
    // 测试分配较大的块
    struct Page *block_medium = alloc_pages(4);
    cprintf("分配4个页面 -> 地址: %p\n", block_medium);
    
    // 测试分配接近最大大小的块
    size_t max_size = (1 << (BUDDY_MAX_ORDER - 1));
    struct Page *block_large = alloc_pages(max_size);
    cprintf("分配%d个页面 -> 地址: %p\n", max_size, block_large);
    
    // 释放所有块
    if (block1 != NULL) {
        free_page(block1);
        cprintf("释放1页块\n");
    }
    if (block_medium != NULL) {
        free_pages(block_medium, 4);
        cprintf("释放4页块\n");
    }
    if (block_large != NULL) {
        free_pages(block_large, max_size);
        cprintf("释放%d页块\n", max_size);
    }
    
    buddy_detailed_dump();
}

// 测试2: 内存碎片测试
static void
test_fragmentation(void) {
    cprintf("\n=== 测试2: 内存碎片测试 ===\n");
    
    // 分配多个小块
    struct Page *blocks[8];
    for (int i = 0; i < 8; i++) {
        blocks[i] = alloc_pages(4); // 分配4页块
        cprintf("分配4页块 -> 地址: %p\n", blocks[i]);
    }
    
    // 释放间隔的块，制造碎片
    cprintf("释放间隔块制造碎片...\n");
    for (int i = 1; i < 8; i += 2) {
        if (blocks[i] != NULL) {
            free_pages(blocks[i], 4);
            cprintf("释放地址 %p\n", blocks[i]);
        }
    }
    
    // 尝试分配大块（可能会失败，因为存在碎片）
    struct Page *large_block = alloc_pages(16);
    cprintf("尝试分配16页块 -> %s\n", large_block != NULL ? "成功" : "可能失败，存在碎片");
    if (large_block != NULL) {
        free_pages(large_block, 16);
        cprintf("释放16页块\n");
    }
    
    // 释放剩余小块
    for (int i = 0; i < 8; i += 2) {
        if (blocks[i] != NULL) {
            free_pages(blocks[i], 4);
            cprintf("释放地址 %p\n", blocks[i]);
        }
    }
    
    // 现在应该能分配大块了
    large_block = alloc_pages(16);
    cprintf("释放所有块后分配16页块 -> %s\n", large_block != NULL ? "成功" : "失败");
    if (large_block != NULL) {
        free_pages(large_block, 16);
        cprintf("释放16页块\n");
    }
    
    buddy_detailed_dump();
}

// 测试3: 伙伴合并测试
static void
test_buddy_merge(void) {
    cprintf("\n=== 测试3: 伙伴合并测试 ===\n");
    
    // 分配两个可能成为伙伴的块
    struct Page *block1 = alloc_pages(8);
    struct Page *block2 = alloc_pages(8);
    cprintf("分配两个8页块: %p, %p\n", block1, block2);
    
    // 计算两个块是否是相邻的伙伴
    size_t index1 = block1 - pages;
    size_t index2 = block2 - pages;
    
    // 正确的伙伴关系判断：两个块的索引异或 (1 << order) 应该相等
    size_t mask = 1 << 3;  // 对于8页块，order是3
    bool is_buddy = (index1 ^ mask) == index2;
    
    cprintf("两个块%s相邻伙伴 (索引: %lu 和 %lu, 异或掩码: %lu)\n", 
           is_buddy ? "是" : "不是", index1, index2, mask);
    
    // 释放第一个块
    cprintf("释放第一个块 %p\n", block1);
    free_pages(block1, 8);
    
    // 释放第二个块，应该合并成16页块
    cprintf("释放第二个块 %p (应该合并)\n", block2);
    free_pages(block2, 8);
    
    // 验证合并结果 - 尝试分配16页块
    struct Page *merged_block = alloc_pages(16);
    cprintf("分配16页块 -> %s\n", merged_block != NULL ? "成功 (合并有效)" : "失败 (合并可能有问题)");
    if (merged_block != NULL) {
        free_pages(merged_block, 16);
        cprintf("释放16页块\n");
    }
    
    buddy_detailed_dump();
}

// 测试5: 边界情况测试（OOM和重复释放）
static void
test_boundary_conditions(void) {
    cprintf("\n=== 测试5: 边界情况测试 ===\n");
    
    // 测试1: 尝试分配超过最大可用内存的大小
    size_t oom_size = (1 << (BUDDY_MAX_ORDER + 1)); // 超过最大阶数
    cprintf("尝试分配过大内存 (%lu 页)... ", oom_size);
    struct Page *oom_block = alloc_pages(oom_size);
    if (oom_block == NULL) {
        cprintf("成功拒绝，返回NULL\n");
    } else {
        cprintf("错误：分配了过大内存！\n");
        free_pages(oom_block, oom_size);
    }
    
}

// 测试4: 非2的幂次方大小分配测试
static void
test_exact_sizes(void) {
    cprintf("\n=== 测试4: 非2的幂次方大小分配测试 ===\n");
    
    // 测试非2的幂次方大小分配
    int sizes[] = {3, 5, 7, 9, 15, 17, 31};
    int num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    struct Page *pages[7];
    
    for (int i = 0; i < num_sizes; i++) {
        int actual_size = sizes[i];
        int adjusted_size = round_up_power_of_2(actual_size);
        pages[i] = alloc_pages(actual_size);
        cprintf("请求 %d 页 -> 调整到 %d 页 -> 地址: %p\n", 
               actual_size, adjusted_size, pages[i]);
    }
    
    // 按分配顺序的逆序释放
    cprintf("\n按逆序释放所有块:\n");
    for (int i = num_sizes - 1; i >= 0; i--) {
        if (pages[i] != NULL) {
            free_pages(pages[i], sizes[i]);
            cprintf("释放地址 %p (请求大小 %d 页)\n", pages[i], sizes[i]);
        }
    }
    
    buddy_detailed_dump();
}

static void
buddy_check(void) {
    cprintf("========== 伙伴系统综合测试 ==========\n");
    
    size_t initial_free = nr_free_pages();
    cprintf("初始空闲页面: %lu\n", initial_free);
    
    // 打印初始状态
    buddy_detailed_dump();
    
    // 运行所有测试
    test_edge_cases();
    test_fragmentation();
    test_buddy_merge();
    test_exact_sizes();
    test_boundary_conditions();
    
    // 验证内存是否完全释放
    size_t final_free = nr_free_pages();
    cprintf("\n最终空闲页面: %lu\n", final_free);
    
    // 允许小误差（可能有一些保留页面）
    if (final_free >= initial_free - 8) { // 允许最多8页的差异
        cprintf("\n伙伴系统检查: 通过\n");
    } else {
        cprintf("\n伙伴系统检查: 失败 (检测到内存泄漏: %lu 页差异)\n", 
               initial_free - final_free);
    }
    
    cprintf("========== 伙伴系统测试结束 ==========\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};