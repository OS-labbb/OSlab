#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <pmm.h>

// 常量定义
#define SLUB_CACHE_NUM 8
#define SLUB_MAX_OBJ_SIZE 4096
#define PGSIZE 4096

// 对象头结构
typedef struct obj_header {
    struct kmem_cache *cache;
    size_t obj_size;
    struct slab_header *slab;
} obj_header_t;

// Slab头结构
typedef struct slab_header {
    struct kmem_cache *cache;
    int inuse;                    // 已使用对象数
    list_entry_t list;            // 链表节点
    char *objects_start;          // 对象起始位置
    void *freelist;               // 空闲对象链表
} slab_header_t;

// 缓存结构
typedef struct kmem_cache {
    char name[32];
    size_t obj_size;
    int objs_per_slab;
    int num_active;
    list_entry_t slabs_full;
    list_entry_t slabs_partial;
    list_entry_t slabs_free;
} kmem_cache_t;

// 链表转换宏
#define le2slab(le, member)              \
    to_struct((le), slab_header_t, member)

// 函数声明
void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *obj_data);
void *kmem_cache_alloc(kmem_cache_t *cache);
void kmem_cache_free(kmem_cache_t *cache, void *obj_data);
kmem_cache_t *slub_find_cache(size_t size);
void slub_stat(void);
void kmem_cache_destroy(kmem_cache_t *cache);

void run_slub_tests(void);
void test_basic_functionality(void);
void test_boundary_conditions(void);
void test_bulk_operations(void);

#endif /* __KERN_MM_SLUB_PMM_H__ */
