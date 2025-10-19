#include <slub_pmm.h>
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <memlayout.h>
#include <assert.h>

// 使用你的内核中定义的宏来进行地址转换
#ifndef page2kva
#define page2kva(page) (KADDR(page2pa(page)))
#endif

#ifndef kva2page
#define kva2page(kva) (pa2page(PADDR(kva)))
#endif

// 全局缓存数组定义
kmem_cache_t slub_caches[SLUB_CACHE_NUM];
static size_t slub_size_classes[] = {32, 64, 128, 256, 512, 1024, 2048, 4096};

// 预定义的缓存名称
static const char *slub_cache_names[] = {
    "size-32", "size-64", "size-128", "size-256",
    "size-512", "size-1024", "size-2048", "size-4096"
};

// 调试配置
#ifdef DEBUG_SLUB
#define SLUB_DEBUG 1
#else
#define SLUB_DEBUG 0
#endif

#if SLUB_DEBUG
#define slub_debug(fmt, ...) cprintf("[SLUB] " fmt, ##__VA_ARGS__)
#else
#define slub_debug(fmt, ...) 
#endif

void slub_init(void) {
    slub_debug("初始化SLUB分配器\n");
    
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
        kmem_cache_t *cache = &slub_caches[i];
        
        // 设置缓存名称 - 使用预定义名称
        const char *predefined_name = slub_cache_names[i];
        char *dst = cache->name;
        const char *src = predefined_name;
        int j = 0;
        
        // 安全地复制名称
        while (*src && j < sizeof(cache->name) - 1) {
            *dst++ = *src++;
            j++;
        }
        *dst = '\0';
        
        cache->obj_size = slub_size_classes[i];
        
        // 计算每Slab对象数
        size_t total_obj_size = sizeof(obj_header_t) + cache->obj_size;
        cache->objs_per_slab = PGSIZE / total_obj_size;
        if (cache->objs_per_slab < 1) cache->objs_per_slab = 1;
        
        // 初始化链表
        list_init(&cache->slabs_full);
        list_init(&cache->slabs_partial);
        list_init(&cache->slabs_free);
        
        cache->num_active = 0;
        
        slub_debug("创建缓存: %s, 对象大小=%u, 每Slab对象数=%d\n", 
                   cache->name, (unsigned int)cache->obj_size, cache->objs_per_slab);
    }
    
    slub_debug("SLUB分配器初始化完成\n");
}

// 查找合适缓存
kmem_cache_t *slub_find_cache(size_t size) {
    cprintf("\n=== slub_find_cache: 查找适合 %u 字节的缓存 ===\n", (unsigned int)size);
    
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
        cprintf("  检查缓存[%d]: %s (大小: %u)\n", i, slub_cache_names[i], (unsigned int)slub_size_classes[i]);
        if (size <= slub_size_classes[i]) {
            cprintf("  ✓ 找到合适缓存: %s\n", slub_cache_names[i]);
            return &slub_caches[i];
        }
    }
    cprintf("  ✗ 未找到合适缓存\n");
    return NULL;
}

// 分配新Slab页 - 使用内核的alloc_pages
static slab_header_t *slub_alloc_slab_page(kmem_cache_t *cache) {
    cprintf("\n=== slub_alloc_slab_page: 为缓存 %s 分配新Slab ===\n", cache->name);
    
    // 使用物理页分配器分配1页
    cprintf("  调用 alloc_pages(1) 分配物理页...\n");
    struct Page *page = alloc_pages(1);
    if (page == NULL) {
        cprintf("  ✗ 分配Slab页失败\n");
        return NULL;
    }
    cprintf("  ✓ 物理页分配成功: page=%p\n", page);
    
    // 计算Slab大小
    size_t total_obj_size = sizeof(obj_header_t) + cache->obj_size;
    cprintf("  对象总大小: %u (头:%u + 数据:%u)\n", 
            (unsigned int)total_obj_size, (unsigned int)sizeof(obj_header_t), (unsigned int)cache->obj_size);
    
    // Slab头在页的开始处 - 使用page2kva
    slab_header_t *slab = (slab_header_t *)page2kva(page);
    cprintf("  Slab虚拟地址: %p\n", slab);
    
    slab->cache = cache;
    slab->inuse = 0;
    list_init(&slab->list);
    slab->objects_start = (char *)slab + sizeof(slab_header_t);
    slab->freelist = NULL;
    
    cprintf("  初始化Slab: inuse=0, objects_start=%p\n", slab->objects_start);
    
    // 初始化所有对象
    cprintf("  开始初始化 %d 个对象...\n", cache->objs_per_slab);
    for (int i = cache->objs_per_slab - 1; i >= 0; i--) {
        obj_header_t *header = (obj_header_t *)((char *)slab->objects_start + i * total_obj_size);
        
        header->cache = cache;
        header->obj_size = cache->obj_size;
        header->slab = slab;
        
        void *obj_data = (void *)(header + 1);
        
        // 构建freelist
        *(void **)obj_data = slab->freelist;
        slab->freelist = obj_data;
        
        if (i == cache->objs_per_slab - 1 || i == 0) {
            cprintf("    对象[%d]: header=%p, data=%p\n", i, header, obj_data);
        }
    }
    
    // 添加到free链表
    list_add(&(cache->slabs_free), &(slab->list));
    cprintf("  ✓ Slab添加到free链表\n");
    
    slub_debug("分配新Slab: cache=%s, 对象数=%d\n", cache->name, cache->objs_per_slab);
    return slab;
}

// 从缓存分配对象
void *kmem_cache_alloc(kmem_cache_t *cache) {
    cprintf("\n=== kmem_cache_alloc: 从缓存 %s 分配对象 ===\n", cache->name);
    
    if (!cache) {
        cprintf("  ✗ 缓存指针为空\n");
        return NULL;
    }
    
    slab_header_t *slab = NULL;
    list_entry_t *le = NULL;
    const char *source = "";
    
    // 1. 尝试从partial链表获取
    if (!list_empty(&cache->slabs_partial)) {
        le = list_next(&cache->slabs_partial);
        slab = le2slab(le, list);
        source = "partial链表";
        cprintf("  ✓ 从partial链表获取Slab\n");
    }
    // 2. 尝试从free链表获取
    else if (!list_empty(&cache->slabs_free)) {
        le = list_next(&cache->slabs_free);
        slab = le2slab(le, list);
        list_del_init(&slab->list);
        list_add(&(cache->slabs_partial), &(slab->list));
        source = "free链表";
        cprintf("  ✓ 从free链表获取Slab，移动到partial链表\n");
    }
    // 3. 分配新Slab
    else {
        cprintf("  partial和free链表都为空，分配新Slab...\n");
        slab = slub_alloc_slab_page(cache);
        if (!slab) return NULL;
        list_del_init(&slab->list);
        list_add(&(cache->slabs_partial), &(slab->list));
        source = "新建Slab";
        cprintf("  ✓ 新Slab添加到partial链表\n");
    }
    
    cprintf("  分配来源: %s, slab=%p\n", source, slab);
    
    // 从freelist分配对象
    void *obj_data = slab->freelist;
    if (!obj_data) {
        cprintf("  ✗ Slab的freelist为空\n");
        return NULL;
    }
    
    cprintf("  从freelist获取对象: %p\n", obj_data);
    
    slab->freelist = *(void **)obj_data;
    slab->inuse++;
    
    cprintf("  更新freelist: %p -> %p\n", obj_data, slab->freelist);
    cprintf("  Slab使用计数: %d -> %d\n", slab->inuse - 1, slab->inuse);
    
    // 更新Slab状态
    if (slab->inuse == cache->objs_per_slab) {
        list_del_init(&slab->list);
        list_add(&(cache->slabs_full), &(slab->list));
        cprintf("  ✓ Slab状态变化: partial -> full\n");
    }
    
    cache->num_active++;
    
    slub_debug("分配对象: cache=%s, slab使用数=%d/%d, 地址=%p\n", 
               cache->name, slab->inuse, cache->objs_per_slab, obj_data);
    
    cprintf("  ✓ 对象分配成功: %p\n", obj_data);
    return obj_data;
}

// 释放对象到缓存
void kmem_cache_free(kmem_cache_t *cache, void *obj_data) {
    cprintf("\n=== kmem_cache_free: 释放对象到缓存 %s ===\n", cache->name);
    cprintf("  释放对象: %p\n", obj_data);
    
    if (!cache || !obj_data) {
        cprintf("  ✗ 缓存或对象指针为空\n");
        return;
    }
    
    // 通过对象头找到Slab
    obj_header_t *header = (obj_header_t *)obj_data - 1;
    slab_header_t *slab = header->slab;
    
    cprintf("  对象头: %p, 所属Slab: %p\n", header, slab);
    
    // 验证一致性
    if (slab->cache != cache) {
        cprintf("  ✗ SLUB错误: 缓存不一致, obj=%p\n", obj_data);
        return;
    }
    
    if (slab->inuse == 0) {
        cprintf("  ✗ SLUB错误: slab使用计数为0但尝试释放对象 %p\n", obj_data);
        return;
    }
    
    cprintf("  Slab当前状态: inuse=%d/%d\n", slab->inuse, cache->objs_per_slab);
    
    // 将对象放回freelist
    void *old_freelist = slab->freelist;
    *(void **)obj_data = slab->freelist;
    slab->freelist = obj_data;
    slab->inuse--;
    
    cprintf("  对象放回freelist: %p -> %p\n", old_freelist, obj_data);
    cprintf("  Slab使用计数: %d -> %d\n", slab->inuse + 1, slab->inuse);
    
    // 从当前链表删除
    list_del_init(&slab->list);
    cprintf("  从当前链表移除Slab\n");
    
    // 根据inuse计数添加到合适的链表
    if (slab->inuse == 0) {
        list_add(&(cache->slabs_free), &(slab->list));
        cprintf("  ✓ Slab状态变化: -> free链表\n");
    } else {
        list_add(&(cache->slabs_partial), &(slab->list));
        cprintf("  ✓ Slab状态变化: -> partial链表\n");
    }
    
    cache->num_active--;
    
    slub_debug("释放对象: cache=%s, slab使用数=%d/%d, 地址=%p\n", 
               cache->name, slab->inuse, cache->objs_per_slab, obj_data);
    
    cprintf("  ✓ 对象释放完成\n");
}

// 用户分配接口
void *kmalloc(size_t size) {
    cprintf("\n=== kmalloc请求: %u 字节 ===\n", (unsigned int)size);
    
    if (size == 0) {
        cprintf("  请求大小为0，返回NULL\n");
        return NULL;
    }
    
    if (size > SLUB_MAX_OBJ_SIZE) {
        cprintf("  大对象分配，使用物理页分配器\n");
        // 大对象：使用物理页分配器
        size_t total_size = sizeof(obj_header_t) + size;
        size_t page_count = (total_size + PGSIZE - 1) / PGSIZE;
        cprintf("  计算所需页数: %u 页 (总大小: %u)\n", 
               (unsigned int)page_count, (unsigned int)total_size);
        
        struct Page *page = alloc_pages(page_count);
        if (!page) {
            cprintf("  ✗ 大对象分配失败: size=%u\n", (unsigned int)size);
            return NULL;
        }
        void *addr = page2kva(page);
        
        // 为大对象创建对象头
        obj_header_t *header = (obj_header_t *)addr;
        header->cache = NULL;  // 关键：大对象的cache设为NULL
        header->obj_size = size;
        header->slab = NULL;   // 关键：大对象的slab设为NULL
        
        void *obj_data = header + 1;
        cprintf("  ✓ 大对象分配成功: size=%u, pages=%u, header=%p, data=%p\n", 
               (unsigned int)size, (unsigned int)page_count, header, obj_data);
        return obj_data;
    } else {
        cprintf("  小对象分配，查找合适缓存...\n");
        kmem_cache_t *cache = slub_find_cache(size);
        if (!cache) {
            cprintf("  ✗ 找不到合适缓存: size=%u\n", (unsigned int)size);
            return NULL;
        }
        cprintf("  使用缓存: %s\n", cache->name);
        return kmem_cache_alloc(cache);
    }
}

// 用户释放接口
void kfree(void *obj_data) {
    cprintf("\n=== kfree请求: 释放对象 %p ===\n", obj_data);
    
    if (!obj_data) {
        cprintf("  对象指针为NULL，忽略\n");
        return;
    }
    
    // 通过对象头找到对象信息
    obj_header_t *header = (obj_header_t *)obj_data - 1;
    
    cprintf("  对象头信息: cache=%p, slab=%p, obj_size=%u\n",
           header->cache, header->slab, (unsigned int)header->obj_size);
    
    // 检查是否为大对象：大对象的cache和slab都为NULL
    if (header->cache == NULL && header->slab == NULL) {
        cprintf("  大对象释放\n");
        
        // 计算大对象实际占用的页数
        size_t total_size = sizeof(obj_header_t) + header->obj_size;
        size_t page_count = (total_size + PGSIZE - 1) / PGSIZE;
        
        cprintf("  大对象信息: 总大小=%u, 页数=%u\n", 
               (unsigned int)total_size, (unsigned int)page_count);
        
        // 使用header的地址来查找物理页（不是obj_data！）
        struct Page *page = kva2page(header);
        if (page) {
            cprintf("  找到对应物理页: %p, 释放 %u 页\n", 
                   page, (unsigned int)page_count);
            free_pages(page, page_count);
            cprintf("  ✓ 大对象释放完成\n");
        } else {
            cprintf("  ✗ 大对象释放失败: 无法找到对应的物理页\n");
        }
        return;
    }
    
    cprintf("  SLUB对象释放\n");
    // SLUB对象：通过对象头找到缓存
    if (header->cache != NULL) {
        cprintf("  找到所属缓存: %s\n", header->cache->name);
        kmem_cache_free(header->cache, obj_data);
    } else {
        cprintf("  ✗ SLUB警告: 无法释放未知对象 %p\n", obj_data);
    }
}
// ==================== 测试函数 ====================

// 辅助函数：打印分隔符
static void print_separator(const char *title) {
    cprintf("\n");
    for (int i = 0; i < 60; i++) cprintf("=");
    cprintf("\n%s\n", title);
    for (int i = 0; i < 60; i++) cprintf("=");
    cprintf("\n");
}

void test_basic_functionality(void) {
    print_separator("测试1: 基本功能测试");
    
    cprintf("\n1. 分配32字节对象:\n");
    void *ptr1 = kmalloc(32);
    assert(ptr1 != NULL);
    
    cprintf("\n2. 分配64字节对象:\n");
    void *ptr2 = kmalloc(64);
    assert(ptr2 != NULL);
    
    cprintf("\n3. 分配128字节对象:\n");
    void *ptr3 = kmalloc(128);
    assert(ptr3 != NULL);
    
    cprintf("\n4. 释放对象:\n");
    kfree(ptr1);
    kfree(ptr2);
    kfree(ptr3);
    
    cprintf("基本功能测试通过\n");
}

void test_boundary_conditions(void) {
    print_separator("测试2: 边界条件测试");
    
    cprintf("\n1. 测试极小对象(1B, 8B):\n");
    void *tiny1 = kmalloc(1);
    void *tiny2 = kmalloc(8);
    kfree(tiny1);
    kfree(tiny2);
    
    cprintf("\n2. 测试边界大小(1023B, 1024B, 1025B):\n");
    void *b1 = kmalloc(1023);
    void *b2 = kmalloc(1024);
    void *b3 = kmalloc(1025);
    kfree(b1);
    kfree(b2);
    kfree(b3);
    
    cprintf("边界条件测试通过\n");
}

void test_bulk_operations(void) {
    print_separator("测试3: 批量操作测试");
    
    cprintf("\n1. 批量相同大小对象:\n");
    const int NUM_OBJECTS = 10;  // 减少数量以便观察
    void *objects[NUM_OBJECTS];
    
    for (int i = 0; i < NUM_OBJECTS; i++) {
        cprintf("\n--- 分配第%d个对象 ---\n", i + 1);
        objects[i] = kmalloc(64);
        assert(objects[i] != NULL);
    }
    
    cprintf("\n2. 批量释放对象:\n");
    for (int i = 0; i < NUM_OBJECTS; i++) {
        cprintf("\n--- 释放第%d个对象 ---\n", i + 1);
        kfree(objects[i]);
    }
    
    cprintf("批量操作测试通过\n");
}

// 主测试函数
void run_slub_tests(void) {
    cprintf("\n\n");
    print_separator("开始 SLUB 分配器测试");
    // 运行各个测试
    test_basic_functionality();
    test_boundary_conditions();
    test_bulk_operations();
    
    print_separator("所有 SLUB 测试完成");
}
