#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>
#include <stdio.h>

#define USE_SKEW_HEAP 1

/* You should define the BigStride constant here*/
/* LAB6 CHALLENGE 1: 2312711 2314003 2314081 */
#define BIG_STRIDE 0x7FFFFFFF  /* 2^31 - 1 = 2147483647 */
/* you should give a value, and is ??? */

/* The compare function for two skew_heap_node_t's and the
 * corresponding procs*/
static int
proc_stride_comp_f(void *a, void *b)
{
     struct proc_struct *p = le2proc(a, lab6_run_pool);
     struct proc_struct *q = le2proc(b, lab6_run_pool);
     int32_t c = p->lab6_stride - q->lab6_stride;
     if (c > 0)
          return 1;
     else if (c == 0)
          return 0;
     else
          return -1;
}

/*
 * stride_init initializes the run-queue rq with correct assignment for
 * member variables, including:
 *
 *   - run_list: should be a empty list after initialization.
 *   - lab6_run_pool: NULL
 *   - proc_num: 0
 *   - max_time_slice: no need here, the variable would be assigned by the caller.
 *
 * hint: see libs/list.h for routines of the list structures.
 */
static void
stride_init(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2312711 2314003 2314081
      * (1) init the ready process list: rq->run_list
      * (2) init the run pool: rq->lab6_run_pool
      * (3) set number of process: rq->proc_num to 0
      */
      /* (1) 初始化双向链表（用于链表实现）
      * list_init 将链表初始化为空，即 head->next = head->prev = head
      */
     list_init(&(rq->run_list));
     
     /* (2) 初始化 Skew Heap 为空（用于堆实现）*/
     rq->lab6_run_pool = NULL;
     
     /* (3) 初始化进程计数为 0 */
     rq->proc_num = 0;
}

/*
 * stride_enqueue inserts the process ``proc'' into the run-queue
 * ``rq''. The procedure should verify/initialize the relevant members
 * of ``proc'', and then put the ``lab6_run_pool'' node into the
 * queue(since we use priority queue here). The procedure should also
 * update the meta date in ``rq'' structure.
 *
 * proc->time_slice denotes the time slices allocation for the
 * process, which should set to rq->max_time_slice.
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 */
static void
stride_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2312711 2314003 2314081
      * (1) insert the proc into rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_insert: insert a entry into skew_heap
      *         list_add_before: insert  a entry into the last of list
      * (2) recalculate proc->time_slice
      * (3) set proc->rq pointer to rq
      * (4) increase rq->proc_num
      */
      #if USE_SKEW_HEAP
     /* 
      * 使用 Skew Heap 实现
      * 
      * skew_heap_insert 函数：
      * - 将新节点插入堆中，保持堆的性质（父节点 stride <= 子节点 stride）
      * - 返回新的堆根节点（可能发生变化）
      * - 时间复杂度：O(log n) 平均
      */
     rq->lab6_run_pool = skew_heap_insert(
          rq->lab6_run_pool,           /* 当前堆根 */
          &(proc->lab6_run_pool),      /* 新节点 */
          proc_stride_comp_f           /* 比较函数 */
     );
#else
     /* 
      * 使用链表实现
      * 
      * list_add_before(&rq->run_list, ...) 将节点加入链表尾部
      * 因为 run_list 是哨兵节点，在它之前就是队尾
      */
     list_add_before(&(rq->run_list), &(proc->run_link));
#endif

     /* 
      * 时间片重置逻辑
      * 
      * 场景1：time_slice == 0
      *   新进程或时间片刚用完的进程，需要分配新时间片
      * 
      * 场景2：time_slice > max_time_slice
      *   防止配置错误或恶意设置，强制修正
      * 
      * 场景3：0 < time_slice <= max_time_slice
      *   进程被高优先级进程抢占，保留剩余时间片
      */
     if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
          proc->time_slice = rq->max_time_slice;
     }
     
     /* 设置进程所属的运行队列 */
     proc->rq = rq;
     
     /* 更新队列中的进程计数 */
     rq->proc_num++;
}

/*
 * stride_dequeue removes the process ``proc'' from the run-queue
 * ``rq'', the operation would be finished by the skew_heap_remove
 * operations. Remember to update the ``rq'' structure.
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 */
static void
stride_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2312711 2314003 2314081
      * (1) remove the proc from rq correctly
      * NOTICE: you can use skew_heap or list. Important functions
      *         skew_heap_remove: remove a entry from skew_heap
      *         list_del_init: remove a entry from the  list
      */
#if USE_SKEW_HEAP
     /* 
      * 使用 Skew Heap 实现
      * 
      * skew_heap_remove 函数：
      * - 从堆中删除指定节点
      * - 重新调整堆结构，保持堆的性质
      * - 返回新的堆根节点
      * - 时间复杂度：O(log n) 平均
      */
     rq->lab6_run_pool = skew_heap_remove(
          rq->lab6_run_pool,           /* 当前堆根 */
          &(proc->lab6_run_pool),      /* 要删除的节点 */
          proc_stride_comp_f           /* 比较函数 */
     );
#else
     /* 
      * 使用链表实现
      * 
      * list_del_init：从链表删除节点，并重新初始化该节点
      * assert 确保链表非空（防止错误调用）
      */
     assert(!list_empty(&(proc->run_link)));
     list_del_init(&(proc->run_link));
#endif

     /* 更新队列中的进程计数 */
     rq->proc_num--;
}
/*
 * stride_pick_next pick the element from the ``run-queue'', with the
 * minimum value of stride, and returns the corresponding process
 * pointer. The process pointer would be calculated by macro le2proc,
 * see kern/process/proc.h for definition. Return NULL if
 * there is no process in the queue.
 *
 * When one proc structure is selected, remember to update the stride
 * property of the proc. (stride += BIG_STRIDE / priority)
 *
 * hint: see libs/skew_heap.h for routines of the priority
 * queue structures.
 */
static struct proc_struct *
stride_pick_next(struct run_queue *rq)
{
     /* LAB6 CHALLENGE 1: 2312711 2314003 2314081
      * (1) get a  proc_struct pointer p  with the minimum value of stride
             (1.1) If using skew_heap, we can use le2proc get the p from rq->lab6_run_pol
             (1.2) If using list, we have to search list to find the p with minimum stride value
      * (2) update p;s stride value: p->lab6_stride
      * (3) return p
      */
#if USE_SKEW_HEAP
     /* 
      * Skew Heap 实现：堆顶就是 stride 最小的进程
      * 时间复杂度：O(1)
      */
     if (rq->lab6_run_pool == NULL) {
          return NULL;  /* 队列为空 */
     }
     
     /* 从堆顶节点获取进程结构体 */
     struct proc_struct *p = le2proc(rq->lab6_run_pool, lab6_run_pool);
#else
     /* 
      * 链表实现：需要遍历整个链表找到 stride 最小的进程
      * 时间复杂度：O(n)
      */
     list_entry_t *le = list_next(&(rq->run_list));
     
     /* 队列为空检查 */
     if (le == &(rq->run_list)) {
          return NULL;
     }
     
     /* 初始化：假设第一个进程是最小的 */
     struct proc_struct *p = le2proc(le, run_link);
     le = list_next(le);
     
     /* 遍历链表，寻找 stride 更小的进程 */
     while (le != &(rq->run_list)) {
          struct proc_struct *q = le2proc(le, run_link);
          
          /* 使用有符号差值比较（处理溢出）*/
          if ((int32_t)(q->lab6_stride - p->lab6_stride) < 0) {
               p = q;  /* q 的 stride 更小，更新最小值 */
          }
          le = list_next(le);
     }
#endif

     /* 
      * 更新被选中进程的 stride
      * 
      * pass = BIG_STRIDE / priority
      * 
      * 注意：priority 为 0 时按 1 处理，避免除零错误
      * 实际系统中应确保 priority >= 1
      */
     if (p->lab6_priority == 0) {
          p->lab6_stride += BIG_STRIDE;  /* 等同于 priority = 1 */
     } else {
          p->lab6_stride += BIG_STRIDE / p->lab6_priority;
     }
     
     return p;
}

/*
 * stride_proc_tick works with the tick event of current process. You
 * should check whether the time slices for current process is
 * exhausted and update the proc struct ``proc''. proc->time_slice
 * denotes the time slices left for current
 * process. proc->need_resched is the flag variable for process
 * switching.
 */
static void
stride_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
     /* LAB6 CHALLENGE 1: 2312711 2314003 2314081 */
     /* 如果还有剩余时间片，减 1 */
     if (proc->time_slice > 0) {
          proc->time_slice--;
     }
     
     /* 时间片用完，设置重调度标志 */
     if (proc->time_slice == 0) {
          proc->need_resched = 1;
     }
}

struct sched_class stride_sched_class = {
    .name = "stride_scheduler",
    .init = stride_init,
    .enqueue = stride_enqueue,
    .dequeue = stride_dequeue,
    .pick_next = stride_pick_next,
    .proc_tick = stride_proc_tick,
};
