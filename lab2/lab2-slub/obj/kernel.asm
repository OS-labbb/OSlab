
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	16c50513          	addi	a0,a0,364 # ffffffffc02021b8 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	17650513          	addi	a0,a0,374 # ffffffffc02021d8 <etext+0x24>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	14658593          	addi	a1,a1,326 # ffffffffc02021b4 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	18250513          	addi	a0,a0,386 # ffffffffc02021f8 <etext+0x44>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <free_area>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	18e50513          	addi	a0,a0,398 # ffffffffc0202218 <etext+0x64>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00007597          	auipc	a1,0x7
ffffffffc020009a:	2e258593          	addi	a1,a1,738 # ffffffffc0207378 <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	19a50513          	addi	a0,a0,410 # ffffffffc0202238 <etext+0x84>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00007597          	auipc	a1,0x7
ffffffffc02000ae:	6cd58593          	addi	a1,a1,1741 # ffffffffc0207777 <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	18c50513          	addi	a0,a0,396 # ffffffffc0202258 <etext+0xa4>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <free_area>
ffffffffc02000e0:	00007617          	auipc	a2,0x7
ffffffffc02000e4:	29860613          	addi	a2,a2,664 # ffffffffc0207378 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	0b2020ef          	jal	ra,ffffffffc02021a2 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	18c50513          	addi	a0,a0,396 # ffffffffc0202288 <etext+0xd4>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	6eb000ef          	jal	ra,ffffffffc0200ff6 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	44d010ef          	jal	ra,ffffffffc0201d8c <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	417010ef          	jal	ra,ffffffffc0201d8c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00007317          	auipc	t1,0x7
ffffffffc02001c6:	16e30313          	addi	t1,t1,366 # ffffffffc0207330 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00002517          	auipc	a0,0x2
ffffffffc02001f6:	0b650513          	addi	a0,a0,182 # ffffffffc02022a8 <etext+0xf4>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	07850513          	addi	a0,a0,120 # ffffffffc0202280 <etext+0xcc>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	6f30106f          	j	ffffffffc020210e <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	0a650513          	addi	a0,a0,166 # ffffffffc02022c8 <etext+0x114>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00007597          	auipc	a1,0x7
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200250:	00002517          	auipc	a0,0x2
ffffffffc0200254:	08850513          	addi	a0,a0,136 # ffffffffc02022d8 <etext+0x124>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00007417          	auipc	s0,0x7
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0207008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	08250513          	addi	a0,a0,130 # ffffffffc02022e8 <etext+0x134>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00002517          	auipc	a0,0x2
ffffffffc020027a:	08a50513          	addi	a0,a0,138 # ffffffffc0202300 <etext+0x14c>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8b75>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00002917          	auipc	s2,0x2
ffffffffc0200334:	02090913          	addi	s2,s2,32 # ffffffffc0202350 <etext+0x19c>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00002497          	auipc	s1,0x2
ffffffffc0200342:	00a48493          	addi	s1,s1,10 # ffffffffc0202348 <etext+0x194>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00002517          	auipc	a0,0x2
ffffffffc0200396:	03650513          	addi	a0,a0,54 # ffffffffc02023c8 <etext+0x214>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00002517          	auipc	a0,0x2
ffffffffc02003a2:	06250513          	addi	a0,a0,98 # ffffffffc0202400 <etext+0x24c>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00002517          	auipc	a0,0x2
ffffffffc02003e2:	f4250513          	addi	a0,a0,-190 # ffffffffc0202320 <etext+0x16c>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	53d010ef          	jal	ra,ffffffffc0202128 <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	583010ef          	jal	ra,ffffffffc020217c <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	4cf010ef          	jal	ra,ffffffffc020215e <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00002517          	auipc	a0,0x2
ffffffffc02004a8:	eb450513          	addi	a0,a0,-332 # ffffffffc0202358 <etext+0x1a4>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00002517          	auipc	a0,0x2
ffffffffc0200576:	e0650513          	addi	a0,a0,-506 # ffffffffc0202378 <etext+0x1c4>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00002517          	auipc	a0,0x2
ffffffffc0200588:	e0c50513          	addi	a0,a0,-500 # ffffffffc0202390 <etext+0x1dc>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	e1a50513          	addi	a0,a0,-486 # ffffffffc02023b0 <etext+0x1fc>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00002517          	auipc	a0,0x2
ffffffffc02005a6:	e5e50513          	addi	a0,a0,-418 # ffffffffc0202400 <etext+0x24c>
        memory_base = mem_base;
ffffffffc02005aa:	00007797          	auipc	a5,0x7
ffffffffc02005ae:	d887b723          	sd	s0,-626(a5) # ffffffffc0207338 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00007797          	auipc	a5,0x7
ffffffffc02005b6:	d967b723          	sd	s6,-626(a5) # ffffffffc0207340 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00007517          	auipc	a0,0x7
ffffffffc02005c0:	d7c53503          	ld	a0,-644(a0) # ffffffffc0207338 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00007517          	auipc	a0,0x7
ffffffffc02005ca:	d7a53503          	ld	a0,-646(a0) # ffffffffc0207340 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	00007797          	auipc	a5,0x7
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc0207018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	00007517          	auipc	a0,0x7
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc0207028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005ec:	cd49                	beqz	a0,ffffffffc0200686 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005ee:	00007617          	auipc	a2,0x7
ffffffffc02005f2:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0207018 <free_area>
ffffffffc02005f6:	01062803          	lw	a6,16(a2)
ffffffffc02005fa:	86aa                	mv	a3,a0
ffffffffc02005fc:	02081793          	slli	a5,a6,0x20
ffffffffc0200600:	9381                	srli	a5,a5,0x20
ffffffffc0200602:	08a7e063          	bltu	a5,a0,ffffffffc0200682 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200606:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200608:	0018059b          	addiw	a1,a6,1
ffffffffc020060c:	1582                	slli	a1,a1,0x20
ffffffffc020060e:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200610:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200612:	06c78763          	beq	a5,a2,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (p->property >= n && p->property < min_size) {
ffffffffc0200616:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020061a:	00d76763          	bltu	a4,a3,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
ffffffffc020061e:	00b77563          	bgeu	a4,a1,ffffffffc0200628 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200622:	fe878513          	addi	a0,a5,-24
ffffffffc0200626:	85ba                	mv	a1,a4
ffffffffc0200628:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020062a:	fec796e3          	bne	a5,a2,ffffffffc0200616 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc020062e:	c929                	beqz	a0,ffffffffc0200680 <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200630:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200634:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200636:	710c                	ld	a1,32(a0)
ffffffffc0200638:	02089793          	slli	a5,a7,0x20
ffffffffc020063c:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020063e:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200640:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200642:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0200646:	02f6f563          	bgeu	a3,a5,ffffffffc0200670 <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020064a:	00269793          	slli	a5,a3,0x2
ffffffffc020064e:	97b6                	add	a5,a5,a3
ffffffffc0200650:	078e                	slli	a5,a5,0x3
ffffffffc0200652:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200654:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200656:	406888bb          	subw	a7,a7,t1
ffffffffc020065a:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc020065e:	0026e693          	ori	a3,a3,2
ffffffffc0200662:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200664:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200668:	e194                	sd	a3,0(a1)
ffffffffc020066a:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc020066c:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc020066e:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200670:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200672:	4068083b          	subw	a6,a6,t1
ffffffffc0200676:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc020067a:	9bf5                	andi	a5,a5,-3
ffffffffc020067c:	e51c                	sd	a5,8(a0)
ffffffffc020067e:	8082                	ret
}
ffffffffc0200680:	8082                	ret
        return NULL;
ffffffffc0200682:	4501                	li	a0,0
ffffffffc0200684:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200686:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200688:	00002697          	auipc	a3,0x2
ffffffffc020068c:	d9068693          	addi	a3,a3,-624 # ffffffffc0202418 <etext+0x264>
ffffffffc0200690:	00002617          	auipc	a2,0x2
ffffffffc0200694:	d9060613          	addi	a2,a2,-624 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200698:	06a00593          	li	a1,106
ffffffffc020069c:	00002517          	auipc	a0,0x2
ffffffffc02006a0:	d9c50513          	addi	a0,a0,-612 # ffffffffc0202438 <etext+0x284>
best_fit_alloc_pages(size_t n) {
ffffffffc02006a4:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02006a6:	b1dff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006aa <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02006aa:	715d                	addi	sp,sp,-80
ffffffffc02006ac:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02006ae:	00007417          	auipc	s0,0x7
ffffffffc02006b2:	96a40413          	addi	s0,s0,-1686 # ffffffffc0207018 <free_area>
ffffffffc02006b6:	641c                	ld	a5,8(s0)
ffffffffc02006b8:	e486                	sd	ra,72(sp)
ffffffffc02006ba:	fc26                	sd	s1,56(sp)
ffffffffc02006bc:	f84a                	sd	s2,48(sp)
ffffffffc02006be:	f44e                	sd	s3,40(sp)
ffffffffc02006c0:	f052                	sd	s4,32(sp)
ffffffffc02006c2:	ec56                	sd	s5,24(sp)
ffffffffc02006c4:	e85a                	sd	s6,16(sp)
ffffffffc02006c6:	e45e                	sd	s7,8(sp)
ffffffffc02006c8:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ca:	26878963          	beq	a5,s0,ffffffffc020093c <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc02006ce:	4481                	li	s1,0
ffffffffc02006d0:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006d6:	8b09                	andi	a4,a4,2
ffffffffc02006d8:	26070663          	beqz	a4,ffffffffc0200944 <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc02006dc:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006e0:	679c                	ld	a5,8(a5)
ffffffffc02006e2:	2905                	addiw	s2,s2,1
ffffffffc02006e4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006e6:	fe8796e3          	bne	a5,s0,ffffffffc02006d2 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02006ea:	89a6                	mv	s3,s1
ffffffffc02006ec:	0ff000ef          	jal	ra,ffffffffc0200fea <nr_free_pages>
ffffffffc02006f0:	33351a63          	bne	a0,s3,ffffffffc0200a24 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006f4:	4505                	li	a0,1
ffffffffc02006f6:	0dd000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02006fa:	8a2a                	mv	s4,a0
ffffffffc02006fc:	36050463          	beqz	a0,ffffffffc0200a64 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200700:	4505                	li	a0,1
ffffffffc0200702:	0d1000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200706:	89aa                	mv	s3,a0
ffffffffc0200708:	32050e63          	beqz	a0,ffffffffc0200a44 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020070c:	4505                	li	a0,1
ffffffffc020070e:	0c5000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200712:	8aaa                	mv	s5,a0
ffffffffc0200714:	2c050863          	beqz	a0,ffffffffc02009e4 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200718:	253a0663          	beq	s4,s3,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc020071c:	24aa0463          	beq	s4,a0,ffffffffc0200964 <best_fit_check+0x2ba>
ffffffffc0200720:	24a98263          	beq	s3,a0,ffffffffc0200964 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200724:	000a2783          	lw	a5,0(s4)
ffffffffc0200728:	24079e63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc020072c:	0009a783          	lw	a5,0(s3)
ffffffffc0200730:	24079a63          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
ffffffffc0200734:	411c                	lw	a5,0(a0)
ffffffffc0200736:	24079763          	bnez	a5,ffffffffc0200984 <best_fit_check+0x2da>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073a:	00007797          	auipc	a5,0x7
ffffffffc020073e:	c167b783          	ld	a5,-1002(a5) # ffffffffc0207350 <pages>
ffffffffc0200742:	40fa0733          	sub	a4,s4,a5
ffffffffc0200746:	870d                	srai	a4,a4,0x3
ffffffffc0200748:	00003597          	auipc	a1,0x3
ffffffffc020074c:	1a85b583          	ld	a1,424(a1) # ffffffffc02038f0 <error_string+0x38>
ffffffffc0200750:	02b70733          	mul	a4,a4,a1
ffffffffc0200754:	00003617          	auipc	a2,0x3
ffffffffc0200758:	1a463603          	ld	a2,420(a2) # ffffffffc02038f8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020075c:	00007697          	auipc	a3,0x7
ffffffffc0200760:	bec6b683          	ld	a3,-1044(a3) # ffffffffc0207348 <npage>
ffffffffc0200764:	06b2                	slli	a3,a3,0xc
ffffffffc0200766:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200768:	0732                	slli	a4,a4,0xc
ffffffffc020076a:	22d77d63          	bgeu	a4,a3,ffffffffc02009a4 <best_fit_check+0x2fa>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020076e:	40f98733          	sub	a4,s3,a5
ffffffffc0200772:	870d                	srai	a4,a4,0x3
ffffffffc0200774:	02b70733          	mul	a4,a4,a1
ffffffffc0200778:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020077a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020077c:	3ed77463          	bgeu	a4,a3,ffffffffc0200b64 <best_fit_check+0x4ba>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200780:	40f507b3          	sub	a5,a0,a5
ffffffffc0200784:	878d                	srai	a5,a5,0x3
ffffffffc0200786:	02b787b3          	mul	a5,a5,a1
ffffffffc020078a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020078c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020078e:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200b44 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200792:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200794:	00043c03          	ld	s8,0(s0)
ffffffffc0200798:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc020079c:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02007a0:	e400                	sd	s0,8(s0)
ffffffffc02007a2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02007a4:	00007797          	auipc	a5,0x7
ffffffffc02007a8:	8807a223          	sw	zero,-1916(a5) # ffffffffc0207028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007ac:	027000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007b0:	36051a63          	bnez	a0,ffffffffc0200b24 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02007b4:	4585                	li	a1,1
ffffffffc02007b6:	8552                	mv	a0,s4
ffffffffc02007b8:	027000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc02007bc:	4585                	li	a1,1
ffffffffc02007be:	854e                	mv	a0,s3
ffffffffc02007c0:	01f000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc02007c4:	4585                	li	a1,1
ffffffffc02007c6:	8556                	mv	a0,s5
ffffffffc02007c8:	017000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(nr_free == 3);
ffffffffc02007cc:	4818                	lw	a4,16(s0)
ffffffffc02007ce:	478d                	li	a5,3
ffffffffc02007d0:	32f71a63          	bne	a4,a5,ffffffffc0200b04 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007d4:	4505                	li	a0,1
ffffffffc02007d6:	7fc000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007da:	89aa                	mv	s3,a0
ffffffffc02007dc:	30050463          	beqz	a0,ffffffffc0200ae4 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e0:	4505                	li	a0,1
ffffffffc02007e2:	7f0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007e6:	8aaa                	mv	s5,a0
ffffffffc02007e8:	2c050e63          	beqz	a0,ffffffffc0200ac4 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ec:	4505                	li	a0,1
ffffffffc02007ee:	7e4000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007f2:	8a2a                	mv	s4,a0
ffffffffc02007f4:	2a050863          	beqz	a0,ffffffffc0200aa4 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc02007f8:	4505                	li	a0,1
ffffffffc02007fa:	7d8000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02007fe:	28051363          	bnez	a0,ffffffffc0200a84 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200802:	4585                	li	a1,1
ffffffffc0200804:	854e                	mv	a0,s3
ffffffffc0200806:	7d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020080a:	641c                	ld	a5,8(s0)
ffffffffc020080c:	1a878c63          	beq	a5,s0,ffffffffc02009c4 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200810:	4505                	li	a0,1
ffffffffc0200812:	7c0000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200816:	52a99763          	bne	s3,a0,ffffffffc0200d44 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc020081a:	4505                	li	a0,1
ffffffffc020081c:	7b6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200820:	50051263          	bnez	a0,ffffffffc0200d24 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200824:	481c                	lw	a5,16(s0)
ffffffffc0200826:	4c079f63          	bnez	a5,ffffffffc0200d04 <best_fit_check+0x65a>
    free_page(p);
ffffffffc020082a:	854e                	mv	a0,s3
ffffffffc020082c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020082e:	01843023          	sd	s8,0(s0)
ffffffffc0200832:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200836:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020083a:	7a4000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p1);
ffffffffc020083e:	4585                	li	a1,1
ffffffffc0200840:	8556                	mv	a0,s5
ffffffffc0200842:	79c000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_page(p2);
ffffffffc0200846:	4585                	li	a1,1
ffffffffc0200848:	8552                	mv	a0,s4
ffffffffc020084a:	794000ef          	jal	ra,ffffffffc0200fde <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020084e:	4515                	li	a0,5
ffffffffc0200850:	782000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200854:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200856:	48050763          	beqz	a0,ffffffffc0200ce4 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc020085a:	651c                	ld	a5,8(a0)
ffffffffc020085c:	8b89                	andi	a5,a5,2
ffffffffc020085e:	46079363          	bnez	a5,ffffffffc0200cc4 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200862:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200864:	00043b03          	ld	s6,0(s0)
ffffffffc0200868:	00843a83          	ld	s5,8(s0)
ffffffffc020086c:	e000                	sd	s0,0(s0)
ffffffffc020086e:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200870:	762000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0200874:	42051863          	bnez	a0,ffffffffc0200ca4 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200878:	4589                	li	a1,2
ffffffffc020087a:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc020087e:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200882:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200886:	00006797          	auipc	a5,0x6
ffffffffc020088a:	7a07a123          	sw	zero,1954(a5) # ffffffffc0207028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc020088e:	750000ef          	jal	ra,ffffffffc0200fde <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200892:	8562                	mv	a0,s8
ffffffffc0200894:	4585                	li	a1,1
ffffffffc0200896:	748000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020089a:	4511                	li	a0,4
ffffffffc020089c:	736000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008a0:	3e051263          	bnez	a0,ffffffffc0200c84 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008a4:	0309b783          	ld	a5,48(s3)
ffffffffc02008a8:	8b89                	andi	a5,a5,2
ffffffffc02008aa:	3a078d63          	beqz	a5,ffffffffc0200c64 <best_fit_check+0x5ba>
ffffffffc02008ae:	0389a703          	lw	a4,56(s3)
ffffffffc02008b2:	4789                	li	a5,2
ffffffffc02008b4:	3af71863          	bne	a4,a5,ffffffffc0200c64 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008b8:	4505                	li	a0,1
ffffffffc02008ba:	718000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008be:	8a2a                	mv	s4,a0
ffffffffc02008c0:	38050263          	beqz	a0,ffffffffc0200c44 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008c4:	4509                	li	a0,2
ffffffffc02008c6:	70c000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ca:	34050d63          	beqz	a0,ffffffffc0200c24 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc02008ce:	334c1b63          	bne	s8,s4,ffffffffc0200c04 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d2:	854e                	mv	a0,s3
ffffffffc02008d4:	4595                	li	a1,5
ffffffffc02008d6:	708000ef          	jal	ra,ffffffffc0200fde <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008da:	4515                	li	a0,5
ffffffffc02008dc:	6f6000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008e0:	89aa                	mv	s3,a0
ffffffffc02008e2:	30050163          	beqz	a0,ffffffffc0200be4 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc02008e6:	4505                	li	a0,1
ffffffffc02008e8:	6ea000ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc02008ec:	2c051c63          	bnez	a0,ffffffffc0200bc4 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008f0:	481c                	lw	a5,16(s0)
ffffffffc02008f2:	2a079963          	bnez	a5,ffffffffc0200ba4 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008f6:	4595                	li	a1,5
ffffffffc02008f8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008fa:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc02008fe:	01643023          	sd	s6,0(s0)
ffffffffc0200902:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200906:	6d8000ef          	jal	ra,ffffffffc0200fde <free_pages>
    return listelm->next;
ffffffffc020090a:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020090c:	00878963          	beq	a5,s0,ffffffffc020091e <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200910:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200914:	679c                	ld	a5,8(a5)
ffffffffc0200916:	397d                	addiw	s2,s2,-1
ffffffffc0200918:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020091a:	fe879be3          	bne	a5,s0,ffffffffc0200910 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc020091e:	26091363          	bnez	s2,ffffffffc0200b84 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200922:	e0ed                	bnez	s1,ffffffffc0200a04 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200924:	60a6                	ld	ra,72(sp)
ffffffffc0200926:	6406                	ld	s0,64(sp)
ffffffffc0200928:	74e2                	ld	s1,56(sp)
ffffffffc020092a:	7942                	ld	s2,48(sp)
ffffffffc020092c:	79a2                	ld	s3,40(sp)
ffffffffc020092e:	7a02                	ld	s4,32(sp)
ffffffffc0200930:	6ae2                	ld	s5,24(sp)
ffffffffc0200932:	6b42                	ld	s6,16(sp)
ffffffffc0200934:	6ba2                	ld	s7,8(sp)
ffffffffc0200936:	6c02                	ld	s8,0(sp)
ffffffffc0200938:	6161                	addi	sp,sp,80
ffffffffc020093a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020093c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020093e:	4481                	li	s1,0
ffffffffc0200940:	4901                	li	s2,0
ffffffffc0200942:	b36d                	j	ffffffffc02006ec <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200944:	00002697          	auipc	a3,0x2
ffffffffc0200948:	b0c68693          	addi	a3,a3,-1268 # ffffffffc0202450 <etext+0x29c>
ffffffffc020094c:	00002617          	auipc	a2,0x2
ffffffffc0200950:	ad460613          	addi	a2,a2,-1324 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200954:	11000593          	li	a1,272
ffffffffc0200958:	00002517          	auipc	a0,0x2
ffffffffc020095c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202438 <etext+0x284>
ffffffffc0200960:	863ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200964:	00002697          	auipc	a3,0x2
ffffffffc0200968:	b7c68693          	addi	a3,a3,-1156 # ffffffffc02024e0 <etext+0x32c>
ffffffffc020096c:	00002617          	auipc	a2,0x2
ffffffffc0200970:	ab460613          	addi	a2,a2,-1356 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200974:	0dc00593          	li	a1,220
ffffffffc0200978:	00002517          	auipc	a0,0x2
ffffffffc020097c:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202438 <etext+0x284>
ffffffffc0200980:	843ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200984:	00002697          	auipc	a3,0x2
ffffffffc0200988:	b8468693          	addi	a3,a3,-1148 # ffffffffc0202508 <etext+0x354>
ffffffffc020098c:	00002617          	auipc	a2,0x2
ffffffffc0200990:	a9460613          	addi	a2,a2,-1388 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200994:	0dd00593          	li	a1,221
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	aa050513          	addi	a0,a0,-1376 # ffffffffc0202438 <etext+0x284>
ffffffffc02009a0:	823ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009a4:	00002697          	auipc	a3,0x2
ffffffffc02009a8:	ba468693          	addi	a3,a3,-1116 # ffffffffc0202548 <etext+0x394>
ffffffffc02009ac:	00002617          	auipc	a2,0x2
ffffffffc02009b0:	a7460613          	addi	a2,a2,-1420 # ffffffffc0202420 <etext+0x26c>
ffffffffc02009b4:	0df00593          	li	a1,223
ffffffffc02009b8:	00002517          	auipc	a0,0x2
ffffffffc02009bc:	a8050513          	addi	a0,a0,-1408 # ffffffffc0202438 <etext+0x284>
ffffffffc02009c0:	803ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009c4:	00002697          	auipc	a3,0x2
ffffffffc02009c8:	c0c68693          	addi	a3,a3,-1012 # ffffffffc02025d0 <etext+0x41c>
ffffffffc02009cc:	00002617          	auipc	a2,0x2
ffffffffc02009d0:	a5460613          	addi	a2,a2,-1452 # ffffffffc0202420 <etext+0x26c>
ffffffffc02009d4:	0f800593          	li	a1,248
ffffffffc02009d8:	00002517          	auipc	a0,0x2
ffffffffc02009dc:	a6050513          	addi	a0,a0,-1440 # ffffffffc0202438 <etext+0x284>
ffffffffc02009e0:	fe2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009e4:	00002697          	auipc	a3,0x2
ffffffffc02009e8:	adc68693          	addi	a3,a3,-1316 # ffffffffc02024c0 <etext+0x30c>
ffffffffc02009ec:	00002617          	auipc	a2,0x2
ffffffffc02009f0:	a3460613          	addi	a2,a2,-1484 # ffffffffc0202420 <etext+0x26c>
ffffffffc02009f4:	0da00593          	li	a1,218
ffffffffc02009f8:	00002517          	auipc	a0,0x2
ffffffffc02009fc:	a4050513          	addi	a0,a0,-1472 # ffffffffc0202438 <etext+0x284>
ffffffffc0200a00:	fc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == 0);
ffffffffc0200a04:	00002697          	auipc	a3,0x2
ffffffffc0200a08:	cfc68693          	addi	a3,a3,-772 # ffffffffc0202700 <etext+0x54c>
ffffffffc0200a0c:	00002617          	auipc	a2,0x2
ffffffffc0200a10:	a1460613          	addi	a2,a2,-1516 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200a14:	15200593          	li	a1,338
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	a2050513          	addi	a0,a0,-1504 # ffffffffc0202438 <etext+0x284>
ffffffffc0200a20:	fa2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a24:	00002697          	auipc	a3,0x2
ffffffffc0200a28:	a3c68693          	addi	a3,a3,-1476 # ffffffffc0202460 <etext+0x2ac>
ffffffffc0200a2c:	00002617          	auipc	a2,0x2
ffffffffc0200a30:	9f460613          	addi	a2,a2,-1548 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200a34:	11300593          	li	a1,275
ffffffffc0200a38:	00002517          	auipc	a0,0x2
ffffffffc0200a3c:	a0050513          	addi	a0,a0,-1536 # ffffffffc0202438 <etext+0x284>
ffffffffc0200a40:	f82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a44:	00002697          	auipc	a3,0x2
ffffffffc0200a48:	a5c68693          	addi	a3,a3,-1444 # ffffffffc02024a0 <etext+0x2ec>
ffffffffc0200a4c:	00002617          	auipc	a2,0x2
ffffffffc0200a50:	9d460613          	addi	a2,a2,-1580 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200a54:	0d900593          	li	a1,217
ffffffffc0200a58:	00002517          	auipc	a0,0x2
ffffffffc0200a5c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202438 <etext+0x284>
ffffffffc0200a60:	f62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a64:	00002697          	auipc	a3,0x2
ffffffffc0200a68:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202480 <etext+0x2cc>
ffffffffc0200a6c:	00002617          	auipc	a2,0x2
ffffffffc0200a70:	9b460613          	addi	a2,a2,-1612 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200a74:	0d800593          	li	a1,216
ffffffffc0200a78:	00002517          	auipc	a0,0x2
ffffffffc0200a7c:	9c050513          	addi	a0,a0,-1600 # ffffffffc0202438 <etext+0x284>
ffffffffc0200a80:	f42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a84:	00002697          	auipc	a3,0x2
ffffffffc0200a88:	b2468693          	addi	a3,a3,-1244 # ffffffffc02025a8 <etext+0x3f4>
ffffffffc0200a8c:	00002617          	auipc	a2,0x2
ffffffffc0200a90:	99460613          	addi	a2,a2,-1644 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200a94:	0f500593          	li	a1,245
ffffffffc0200a98:	00002517          	auipc	a0,0x2
ffffffffc0200a9c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0202438 <etext+0x284>
ffffffffc0200aa0:	f22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aa4:	00002697          	auipc	a3,0x2
ffffffffc0200aa8:	a1c68693          	addi	a3,a3,-1508 # ffffffffc02024c0 <etext+0x30c>
ffffffffc0200aac:	00002617          	auipc	a2,0x2
ffffffffc0200ab0:	97460613          	addi	a2,a2,-1676 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200ab4:	0f300593          	li	a1,243
ffffffffc0200ab8:	00002517          	auipc	a0,0x2
ffffffffc0200abc:	98050513          	addi	a0,a0,-1664 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ac0:	f02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ac4:	00002697          	auipc	a3,0x2
ffffffffc0200ac8:	9dc68693          	addi	a3,a3,-1572 # ffffffffc02024a0 <etext+0x2ec>
ffffffffc0200acc:	00002617          	auipc	a2,0x2
ffffffffc0200ad0:	95460613          	addi	a2,a2,-1708 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200ad4:	0f200593          	li	a1,242
ffffffffc0200ad8:	00002517          	auipc	a0,0x2
ffffffffc0200adc:	96050513          	addi	a0,a0,-1696 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ae0:	ee2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ae4:	00002697          	auipc	a3,0x2
ffffffffc0200ae8:	99c68693          	addi	a3,a3,-1636 # ffffffffc0202480 <etext+0x2cc>
ffffffffc0200aec:	00002617          	auipc	a2,0x2
ffffffffc0200af0:	93460613          	addi	a2,a2,-1740 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200af4:	0f100593          	li	a1,241
ffffffffc0200af8:	00002517          	auipc	a0,0x2
ffffffffc0200afc:	94050513          	addi	a0,a0,-1728 # ffffffffc0202438 <etext+0x284>
ffffffffc0200b00:	ec2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 3);
ffffffffc0200b04:	00002697          	auipc	a3,0x2
ffffffffc0200b08:	abc68693          	addi	a3,a3,-1348 # ffffffffc02025c0 <etext+0x40c>
ffffffffc0200b0c:	00002617          	auipc	a2,0x2
ffffffffc0200b10:	91460613          	addi	a2,a2,-1772 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200b14:	0ef00593          	li	a1,239
ffffffffc0200b18:	00002517          	auipc	a0,0x2
ffffffffc0200b1c:	92050513          	addi	a0,a0,-1760 # ffffffffc0202438 <etext+0x284>
ffffffffc0200b20:	ea2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b24:	00002697          	auipc	a3,0x2
ffffffffc0200b28:	a8468693          	addi	a3,a3,-1404 # ffffffffc02025a8 <etext+0x3f4>
ffffffffc0200b2c:	00002617          	auipc	a2,0x2
ffffffffc0200b30:	8f460613          	addi	a2,a2,-1804 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200b34:	0ea00593          	li	a1,234
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	90050513          	addi	a0,a0,-1792 # ffffffffc0202438 <etext+0x284>
ffffffffc0200b40:	e82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b44:	00002697          	auipc	a3,0x2
ffffffffc0200b48:	a4468693          	addi	a3,a3,-1468 # ffffffffc0202588 <etext+0x3d4>
ffffffffc0200b4c:	00002617          	auipc	a2,0x2
ffffffffc0200b50:	8d460613          	addi	a2,a2,-1836 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200b54:	0e100593          	li	a1,225
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0202438 <etext+0x284>
ffffffffc0200b60:	e62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b64:	00002697          	auipc	a3,0x2
ffffffffc0200b68:	a0468693          	addi	a3,a3,-1532 # ffffffffc0202568 <etext+0x3b4>
ffffffffc0200b6c:	00002617          	auipc	a2,0x2
ffffffffc0200b70:	8b460613          	addi	a2,a2,-1868 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200b74:	0e000593          	li	a1,224
ffffffffc0200b78:	00002517          	auipc	a0,0x2
ffffffffc0200b7c:	8c050513          	addi	a0,a0,-1856 # ffffffffc0202438 <etext+0x284>
ffffffffc0200b80:	e42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(count == 0);
ffffffffc0200b84:	00002697          	auipc	a3,0x2
ffffffffc0200b88:	b6c68693          	addi	a3,a3,-1172 # ffffffffc02026f0 <etext+0x53c>
ffffffffc0200b8c:	00002617          	auipc	a2,0x2
ffffffffc0200b90:	89460613          	addi	a2,a2,-1900 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200b94:	15100593          	li	a1,337
ffffffffc0200b98:	00002517          	auipc	a0,0x2
ffffffffc0200b9c:	8a050513          	addi	a0,a0,-1888 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ba0:	e22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200ba4:	00002697          	auipc	a3,0x2
ffffffffc0200ba8:	a6468693          	addi	a3,a3,-1436 # ffffffffc0202608 <etext+0x454>
ffffffffc0200bac:	00002617          	auipc	a2,0x2
ffffffffc0200bb0:	87460613          	addi	a2,a2,-1932 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200bb4:	14600593          	li	a1,326
ffffffffc0200bb8:	00002517          	auipc	a0,0x2
ffffffffc0200bbc:	88050513          	addi	a0,a0,-1920 # ffffffffc0202438 <etext+0x284>
ffffffffc0200bc0:	e02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bc4:	00002697          	auipc	a3,0x2
ffffffffc0200bc8:	9e468693          	addi	a3,a3,-1564 # ffffffffc02025a8 <etext+0x3f4>
ffffffffc0200bcc:	00002617          	auipc	a2,0x2
ffffffffc0200bd0:	85460613          	addi	a2,a2,-1964 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200bd4:	14000593          	li	a1,320
ffffffffc0200bd8:	00002517          	auipc	a0,0x2
ffffffffc0200bdc:	86050513          	addi	a0,a0,-1952 # ffffffffc0202438 <etext+0x284>
ffffffffc0200be0:	de2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200be4:	00002697          	auipc	a3,0x2
ffffffffc0200be8:	aec68693          	addi	a3,a3,-1300 # ffffffffc02026d0 <etext+0x51c>
ffffffffc0200bec:	00002617          	auipc	a2,0x2
ffffffffc0200bf0:	83460613          	addi	a2,a2,-1996 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200bf4:	13f00593          	li	a1,319
ffffffffc0200bf8:	00002517          	auipc	a0,0x2
ffffffffc0200bfc:	84050513          	addi	a0,a0,-1984 # ffffffffc0202438 <etext+0x284>
ffffffffc0200c00:	dc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c04:	00002697          	auipc	a3,0x2
ffffffffc0200c08:	abc68693          	addi	a3,a3,-1348 # ffffffffc02026c0 <etext+0x50c>
ffffffffc0200c0c:	00002617          	auipc	a2,0x2
ffffffffc0200c10:	81460613          	addi	a2,a2,-2028 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200c14:	13700593          	li	a1,311
ffffffffc0200c18:	00002517          	auipc	a0,0x2
ffffffffc0200c1c:	82050513          	addi	a0,a0,-2016 # ffffffffc0202438 <etext+0x284>
ffffffffc0200c20:	da2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c24:	00002697          	auipc	a3,0x2
ffffffffc0200c28:	a8468693          	addi	a3,a3,-1404 # ffffffffc02026a8 <etext+0x4f4>
ffffffffc0200c2c:	00001617          	auipc	a2,0x1
ffffffffc0200c30:	7f460613          	addi	a2,a2,2036 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200c34:	13600593          	li	a1,310
ffffffffc0200c38:	00002517          	auipc	a0,0x2
ffffffffc0200c3c:	80050513          	addi	a0,a0,-2048 # ffffffffc0202438 <etext+0x284>
ffffffffc0200c40:	d82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c44:	00002697          	auipc	a3,0x2
ffffffffc0200c48:	a4468693          	addi	a3,a3,-1468 # ffffffffc0202688 <etext+0x4d4>
ffffffffc0200c4c:	00001617          	auipc	a2,0x1
ffffffffc0200c50:	7d460613          	addi	a2,a2,2004 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200c54:	13500593          	li	a1,309
ffffffffc0200c58:	00001517          	auipc	a0,0x1
ffffffffc0200c5c:	7e050513          	addi	a0,a0,2016 # ffffffffc0202438 <etext+0x284>
ffffffffc0200c60:	d62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c64:	00002697          	auipc	a3,0x2
ffffffffc0200c68:	9f468693          	addi	a3,a3,-1548 # ffffffffc0202658 <etext+0x4a4>
ffffffffc0200c6c:	00001617          	auipc	a2,0x1
ffffffffc0200c70:	7b460613          	addi	a2,a2,1972 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200c74:	13300593          	li	a1,307
ffffffffc0200c78:	00001517          	auipc	a0,0x1
ffffffffc0200c7c:	7c050513          	addi	a0,a0,1984 # ffffffffc0202438 <etext+0x284>
ffffffffc0200c80:	d42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c84:	00002697          	auipc	a3,0x2
ffffffffc0200c88:	9bc68693          	addi	a3,a3,-1604 # ffffffffc0202640 <etext+0x48c>
ffffffffc0200c8c:	00001617          	auipc	a2,0x1
ffffffffc0200c90:	79460613          	addi	a2,a2,1940 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200c94:	13200593          	li	a1,306
ffffffffc0200c98:	00001517          	auipc	a0,0x1
ffffffffc0200c9c:	7a050513          	addi	a0,a0,1952 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ca0:	d22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200ca4:	00002697          	auipc	a3,0x2
ffffffffc0200ca8:	90468693          	addi	a3,a3,-1788 # ffffffffc02025a8 <etext+0x3f4>
ffffffffc0200cac:	00001617          	auipc	a2,0x1
ffffffffc0200cb0:	77460613          	addi	a2,a2,1908 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200cb4:	12600593          	li	a1,294
ffffffffc0200cb8:	00001517          	auipc	a0,0x1
ffffffffc0200cbc:	78050513          	addi	a0,a0,1920 # ffffffffc0202438 <etext+0x284>
ffffffffc0200cc0:	d02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cc4:	00002697          	auipc	a3,0x2
ffffffffc0200cc8:	96468693          	addi	a3,a3,-1692 # ffffffffc0202628 <etext+0x474>
ffffffffc0200ccc:	00001617          	auipc	a2,0x1
ffffffffc0200cd0:	75460613          	addi	a2,a2,1876 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200cd4:	11d00593          	li	a1,285
ffffffffc0200cd8:	00001517          	auipc	a0,0x1
ffffffffc0200cdc:	76050513          	addi	a0,a0,1888 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ce0:	ce2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc0200ce4:	00002697          	auipc	a3,0x2
ffffffffc0200ce8:	93468693          	addi	a3,a3,-1740 # ffffffffc0202618 <etext+0x464>
ffffffffc0200cec:	00001617          	auipc	a2,0x1
ffffffffc0200cf0:	73460613          	addi	a2,a2,1844 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200cf4:	11c00593          	li	a1,284
ffffffffc0200cf8:	00001517          	auipc	a0,0x1
ffffffffc0200cfc:	74050513          	addi	a0,a0,1856 # ffffffffc0202438 <etext+0x284>
ffffffffc0200d00:	cc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free == 0);
ffffffffc0200d04:	00002697          	auipc	a3,0x2
ffffffffc0200d08:	90468693          	addi	a3,a3,-1788 # ffffffffc0202608 <etext+0x454>
ffffffffc0200d0c:	00001617          	auipc	a2,0x1
ffffffffc0200d10:	71460613          	addi	a2,a2,1812 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200d14:	0fe00593          	li	a1,254
ffffffffc0200d18:	00001517          	auipc	a0,0x1
ffffffffc0200d1c:	72050513          	addi	a0,a0,1824 # ffffffffc0202438 <etext+0x284>
ffffffffc0200d20:	ca2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d24:	00002697          	auipc	a3,0x2
ffffffffc0200d28:	88468693          	addi	a3,a3,-1916 # ffffffffc02025a8 <etext+0x3f4>
ffffffffc0200d2c:	00001617          	auipc	a2,0x1
ffffffffc0200d30:	6f460613          	addi	a2,a2,1780 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200d34:	0fc00593          	li	a1,252
ffffffffc0200d38:	00001517          	auipc	a0,0x1
ffffffffc0200d3c:	70050513          	addi	a0,a0,1792 # ffffffffc0202438 <etext+0x284>
ffffffffc0200d40:	c82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d44:	00002697          	auipc	a3,0x2
ffffffffc0200d48:	8a468693          	addi	a3,a3,-1884 # ffffffffc02025e8 <etext+0x434>
ffffffffc0200d4c:	00001617          	auipc	a2,0x1
ffffffffc0200d50:	6d460613          	addi	a2,a2,1748 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200d54:	0fb00593          	li	a1,251
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	6e050513          	addi	a0,a0,1760 # ffffffffc0202438 <etext+0x284>
ffffffffc0200d60:	c62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d64 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d64:	1141                	addi	sp,sp,-16
ffffffffc0200d66:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d68:	14058c63          	beqz	a1,ffffffffc0200ec0 <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc0200d6c:	00259693          	slli	a3,a1,0x2
ffffffffc0200d70:	96ae                	add	a3,a3,a1
ffffffffc0200d72:	068e                	slli	a3,a3,0x3
ffffffffc0200d74:	96aa                	add	a3,a3,a0
ffffffffc0200d76:	87aa                	mv	a5,a0
ffffffffc0200d78:	00d50e63          	beq	a0,a3,ffffffffc0200d94 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d7c:	6798                	ld	a4,8(a5)
ffffffffc0200d7e:	8b0d                	andi	a4,a4,3
ffffffffc0200d80:	12071063          	bnez	a4,ffffffffc0200ea0 <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc0200d84:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d88:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d8c:	02878793          	addi	a5,a5,40
ffffffffc0200d90:	fed796e3          	bne	a5,a3,ffffffffc0200d7c <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200d94:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200d98:	00006697          	auipc	a3,0x6
ffffffffc0200d9c:	28068693          	addi	a3,a3,640 # ffffffffc0207018 <free_area>
ffffffffc0200da0:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200da2:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200da4:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc0200da8:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200daa:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dac:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200dae:	9f2d                	addw	a4,a4,a1
ffffffffc0200db0:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200db2:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200db6:	0ad78b63          	beq	a5,a3,ffffffffc0200e6c <best_fit_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc0200dba:	fe878713          	addi	a4,a5,-24
ffffffffc0200dbe:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dc2:	4801                	li	a6,0
            if (base < page) {
ffffffffc0200dc4:	00e56a63          	bltu	a0,a4,ffffffffc0200dd8 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200dc8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200dca:	06d70563          	beq	a4,a3,ffffffffc0200e34 <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200dce:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dd0:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dd4:	fee57ae3          	bgeu	a0,a4,ffffffffc0200dc8 <best_fit_free_pages+0x64>
ffffffffc0200dd8:	00080463          	beqz	a6,ffffffffc0200de0 <best_fit_free_pages+0x7c>
ffffffffc0200ddc:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200de0:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200de4:	e390                	sd	a2,0(a5)
ffffffffc0200de6:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200dea:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200dec:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200df0:	02d80463          	beq	a6,a3,ffffffffc0200e18 <best_fit_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc0200df4:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200df8:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200dfc:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e00:	9201                	srli	a2,a2,0x20
ffffffffc0200e02:	00261713          	slli	a4,a2,0x2
ffffffffc0200e06:	9732                	add	a4,a4,a2
ffffffffc0200e08:	070e                	slli	a4,a4,0x3
ffffffffc0200e0a:	971a                	add	a4,a4,t1
ffffffffc0200e0c:	02e50e63          	beq	a0,a4,ffffffffc0200e48 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e10:	00d78f63          	beq	a5,a3,ffffffffc0200e2e <best_fit_free_pages+0xca>
ffffffffc0200e14:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0200e18:	490c                	lw	a1,16(a0)
ffffffffc0200e1a:	02059613          	slli	a2,a1,0x20
ffffffffc0200e1e:	9201                	srli	a2,a2,0x20
ffffffffc0200e20:	00261693          	slli	a3,a2,0x2
ffffffffc0200e24:	96b2                	add	a3,a3,a2
ffffffffc0200e26:	068e                	slli	a3,a3,0x3
ffffffffc0200e28:	96aa                	add	a3,a3,a0
ffffffffc0200e2a:	04d70863          	beq	a4,a3,ffffffffc0200e7a <best_fit_free_pages+0x116>
}
ffffffffc0200e2e:	60a2                	ld	ra,8(sp)
ffffffffc0200e30:	0141                	addi	sp,sp,16
ffffffffc0200e32:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e34:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e36:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e38:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e3a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e3c:	02d70463          	beq	a4,a3,ffffffffc0200e64 <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0200e40:	8332                	mv	t1,a2
ffffffffc0200e42:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc0200e44:	87ba                	mv	a5,a4
ffffffffc0200e46:	b769                	j	ffffffffc0200dd0 <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e48:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e4c:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e50:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e54:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e58:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e5c:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e60:	851a                	mv	a0,t1
ffffffffc0200e62:	b77d                	j	ffffffffc0200e10 <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e64:	883e                	mv	a6,a5
ffffffffc0200e66:	e290                	sd	a2,0(a3)
ffffffffc0200e68:	87b6                	mv	a5,a3
ffffffffc0200e6a:	b769                	j	ffffffffc0200df4 <best_fit_free_pages+0x90>
}
ffffffffc0200e6c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200e6e:	e390                	sd	a2,0(a5)
ffffffffc0200e70:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e72:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e74:	ed1c                	sd	a5,24(a0)
ffffffffc0200e76:	0141                	addi	sp,sp,16
ffffffffc0200e78:	8082                	ret
            base->property += p->property;
ffffffffc0200e7a:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200e7e:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e82:	0007b803          	ld	a6,0(a5)
ffffffffc0200e86:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200e88:	9db5                	addw	a1,a1,a3
ffffffffc0200e8a:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200e8c:	9b75                	andi	a4,a4,-3
ffffffffc0200e8e:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200e92:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200e94:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200e98:	01063023          	sd	a6,0(a2)
ffffffffc0200e9c:	0141                	addi	sp,sp,16
ffffffffc0200e9e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ea0:	00002697          	auipc	a3,0x2
ffffffffc0200ea4:	87068693          	addi	a3,a3,-1936 # ffffffffc0202710 <etext+0x55c>
ffffffffc0200ea8:	00001617          	auipc	a2,0x1
ffffffffc0200eac:	57860613          	addi	a2,a2,1400 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200eb0:	09300593          	li	a1,147
ffffffffc0200eb4:	00001517          	auipc	a0,0x1
ffffffffc0200eb8:	58450513          	addi	a0,a0,1412 # ffffffffc0202438 <etext+0x284>
ffffffffc0200ebc:	b06ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200ec0:	00001697          	auipc	a3,0x1
ffffffffc0200ec4:	55868693          	addi	a3,a3,1368 # ffffffffc0202418 <etext+0x264>
ffffffffc0200ec8:	00001617          	auipc	a2,0x1
ffffffffc0200ecc:	55860613          	addi	a2,a2,1368 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200ed0:	09000593          	li	a1,144
ffffffffc0200ed4:	00001517          	auipc	a0,0x1
ffffffffc0200ed8:	56450513          	addi	a0,a0,1380 # ffffffffc0202438 <etext+0x284>
ffffffffc0200edc:	ae6ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200ee0 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200ee0:	1141                	addi	sp,sp,-16
ffffffffc0200ee2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200ee4:	c5f9                	beqz	a1,ffffffffc0200fb2 <best_fit_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0200ee6:	00259693          	slli	a3,a1,0x2
ffffffffc0200eea:	96ae                	add	a3,a3,a1
ffffffffc0200eec:	068e                	slli	a3,a3,0x3
ffffffffc0200eee:	96aa                	add	a3,a3,a0
ffffffffc0200ef0:	87aa                	mv	a5,a0
ffffffffc0200ef2:	00d50f63          	beq	a0,a3,ffffffffc0200f10 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200ef6:	6798                	ld	a4,8(a5)
ffffffffc0200ef8:	8b05                	andi	a4,a4,1
ffffffffc0200efa:	cf41                	beqz	a4,ffffffffc0200f92 <best_fit_init_memmap+0xb2>
        p->flags = 0;
ffffffffc0200efc:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200f00:	0007a823          	sw	zero,16(a5)
ffffffffc0200f04:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f08:	02878793          	addi	a5,a5,40
ffffffffc0200f0c:	fed795e3          	bne	a5,a3,ffffffffc0200ef6 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f10:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f12:	00006697          	auipc	a3,0x6
ffffffffc0200f16:	10668693          	addi	a3,a3,262 # ffffffffc0207018 <free_area>
ffffffffc0200f1a:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200f1c:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200f1e:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc0200f22:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200f24:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f26:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f28:	9db9                	addw	a1,a1,a4
ffffffffc0200f2a:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200f2c:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200f30:	04d78a63          	beq	a5,a3,ffffffffc0200f84 <best_fit_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f34:	fe878713          	addi	a4,a5,-24
ffffffffc0200f38:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f3c:	4581                	li	a1,0
            if (base < page) {
ffffffffc0200f3e:	00e56a63          	bltu	a0,a4,ffffffffc0200f52 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f42:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f44:	02d70263          	beq	a4,a3,ffffffffc0200f68 <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0200f48:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f4a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f4e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f42 <best_fit_init_memmap+0x62>
ffffffffc0200f52:	c199                	beqz	a1,ffffffffc0200f58 <best_fit_init_memmap+0x78>
ffffffffc0200f54:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f58:	6398                	ld	a4,0(a5)
}
ffffffffc0200f5a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f5c:	e390                	sd	a2,0(a5)
ffffffffc0200f5e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f60:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f62:	ed18                	sd	a4,24(a0)
ffffffffc0200f64:	0141                	addi	sp,sp,16
ffffffffc0200f66:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f68:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f6a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f6c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f6e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f70:	00d70663          	beq	a4,a3,ffffffffc0200f7c <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc0200f74:	8832                	mv	a6,a2
ffffffffc0200f76:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0200f78:	87ba                	mv	a5,a4
ffffffffc0200f7a:	bfc1                	j	ffffffffc0200f4a <best_fit_init_memmap+0x6a>
}
ffffffffc0200f7c:	60a2                	ld	ra,8(sp)
ffffffffc0200f7e:	e290                	sd	a2,0(a3)
ffffffffc0200f80:	0141                	addi	sp,sp,16
ffffffffc0200f82:	8082                	ret
ffffffffc0200f84:	60a2                	ld	ra,8(sp)
ffffffffc0200f86:	e390                	sd	a2,0(a5)
ffffffffc0200f88:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f8a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f8c:	ed1c                	sd	a5,24(a0)
ffffffffc0200f8e:	0141                	addi	sp,sp,16
ffffffffc0200f90:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200f92:	00001697          	auipc	a3,0x1
ffffffffc0200f96:	7a668693          	addi	a3,a3,1958 # ffffffffc0202738 <etext+0x584>
ffffffffc0200f9a:	00001617          	auipc	a2,0x1
ffffffffc0200f9e:	48660613          	addi	a2,a2,1158 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200fa2:	04a00593          	li	a1,74
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	49250513          	addi	a0,a0,1170 # ffffffffc0202438 <etext+0x284>
ffffffffc0200fae:	a14ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc0200fb2:	00001697          	auipc	a3,0x1
ffffffffc0200fb6:	46668693          	addi	a3,a3,1126 # ffffffffc0202418 <etext+0x264>
ffffffffc0200fba:	00001617          	auipc	a2,0x1
ffffffffc0200fbe:	46660613          	addi	a2,a2,1126 # ffffffffc0202420 <etext+0x26c>
ffffffffc0200fc2:	04700593          	li	a1,71
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	47250513          	addi	a0,a0,1138 # ffffffffc0202438 <etext+0x284>
ffffffffc0200fce:	9f4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200fd2 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200fd2:	00006797          	auipc	a5,0x6
ffffffffc0200fd6:	3867b783          	ld	a5,902(a5) # ffffffffc0207358 <pmm_manager>
ffffffffc0200fda:	6f9c                	ld	a5,24(a5)
ffffffffc0200fdc:	8782                	jr	a5

ffffffffc0200fde <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0200fde:	00006797          	auipc	a5,0x6
ffffffffc0200fe2:	37a7b783          	ld	a5,890(a5) # ffffffffc0207358 <pmm_manager>
ffffffffc0200fe6:	739c                	ld	a5,32(a5)
ffffffffc0200fe8:	8782                	jr	a5

ffffffffc0200fea <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0200fea:	00006797          	auipc	a5,0x6
ffffffffc0200fee:	36e7b783          	ld	a5,878(a5) # ffffffffc0207358 <pmm_manager>
ffffffffc0200ff2:	779c                	ld	a5,40(a5)
ffffffffc0200ff4:	8782                	jr	a5

ffffffffc0200ff6 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200ff6:	00001797          	auipc	a5,0x1
ffffffffc0200ffa:	76a78793          	addi	a5,a5,1898 # ffffffffc0202760 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200ffe:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201000:	7179                	addi	sp,sp,-48
ffffffffc0201002:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201004:	00001517          	auipc	a0,0x1
ffffffffc0201008:	79450513          	addi	a0,a0,1940 # ffffffffc0202798 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020100c:	00006417          	auipc	s0,0x6
ffffffffc0201010:	34c40413          	addi	s0,s0,844 # ffffffffc0207358 <pmm_manager>
void pmm_init(void) {
ffffffffc0201014:	f406                	sd	ra,40(sp)
ffffffffc0201016:	ec26                	sd	s1,24(sp)
ffffffffc0201018:	e44e                	sd	s3,8(sp)
ffffffffc020101a:	e84a                	sd	s2,16(sp)
ffffffffc020101c:	e052                	sd	s4,0(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020101e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201020:	92cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc0201024:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201026:	00006497          	auipc	s1,0x6
ffffffffc020102a:	34a48493          	addi	s1,s1,842 # ffffffffc0207370 <va_pa_offset>
    pmm_manager->init();
ffffffffc020102e:	679c                	ld	a5,8(a5)
ffffffffc0201030:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201032:	57f5                	li	a5,-3
ffffffffc0201034:	07fa                	slli	a5,a5,0x1e
ffffffffc0201036:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201038:	d84ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc020103c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020103e:	d88ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201042:	16050763          	beqz	a0,ffffffffc02011b0 <pmm_init+0x1ba>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201046:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201048:	00001517          	auipc	a0,0x1
ffffffffc020104c:	79850513          	addi	a0,a0,1944 # ffffffffc02027e0 <best_fit_pmm_manager+0x80>
ffffffffc0201050:	8fcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201054:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201058:	864e                	mv	a2,s3
ffffffffc020105a:	fffa0693          	addi	a3,s4,-1
ffffffffc020105e:	85ca                	mv	a1,s2
ffffffffc0201060:	00001517          	auipc	a0,0x1
ffffffffc0201064:	79850513          	addi	a0,a0,1944 # ffffffffc02027f8 <best_fit_pmm_manager+0x98>
ffffffffc0201068:	8e4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020106c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201070:	8652                	mv	a2,s4
ffffffffc0201072:	0d47ee63          	bltu	a5,s4,ffffffffc020114e <pmm_init+0x158>
ffffffffc0201076:	00007797          	auipc	a5,0x7
ffffffffc020107a:	30178793          	addi	a5,a5,769 # ffffffffc0208377 <end+0xfff>
ffffffffc020107e:	757d                	lui	a0,0xfffff
ffffffffc0201080:	8d7d                	and	a0,a0,a5
ffffffffc0201082:	8231                	srli	a2,a2,0xc
ffffffffc0201084:	00006797          	auipc	a5,0x6
ffffffffc0201088:	2cc7b223          	sd	a2,708(a5) # ffffffffc0207348 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020108c:	00006797          	auipc	a5,0x6
ffffffffc0201090:	2ca7b223          	sd	a0,708(a5) # ffffffffc0207350 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201094:	000807b7          	lui	a5,0x80
ffffffffc0201098:	002005b7          	lui	a1,0x200
ffffffffc020109c:	02f60563          	beq	a2,a5,ffffffffc02010c6 <pmm_init+0xd0>
ffffffffc02010a0:	00261593          	slli	a1,a2,0x2
ffffffffc02010a4:	00c586b3          	add	a3,a1,a2
ffffffffc02010a8:	fec007b7          	lui	a5,0xfec00
ffffffffc02010ac:	97aa                	add	a5,a5,a0
ffffffffc02010ae:	068e                	slli	a3,a3,0x3
ffffffffc02010b0:	96be                	add	a3,a3,a5
ffffffffc02010b2:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc02010b4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010b6:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f8cb0>
        SetPageReserved(pages + i);
ffffffffc02010ba:	00176713          	ori	a4,a4,1
ffffffffc02010be:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010c2:	fef699e3          	bne	a3,a5,ffffffffc02010b4 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010c6:	95b2                	add	a1,a1,a2
ffffffffc02010c8:	fec006b7          	lui	a3,0xfec00
ffffffffc02010cc:	96aa                	add	a3,a3,a0
ffffffffc02010ce:	058e                	slli	a1,a1,0x3
ffffffffc02010d0:	96ae                	add	a3,a3,a1
ffffffffc02010d2:	c02007b7          	lui	a5,0xc0200
ffffffffc02010d6:	0cf6e163          	bltu	a3,a5,ffffffffc0201198 <pmm_init+0x1a2>
ffffffffc02010da:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02010dc:	77fd                	lui	a5,0xfffff
ffffffffc02010de:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e2:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02010e4:	06b6e863          	bltu	a3,a1,ffffffffc0201154 <pmm_init+0x15e>
    
    run_slub_tests();
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02010e8:	601c                	ld	a5,0(s0)
ffffffffc02010ea:	7b9c                	ld	a5,48(a5)
ffffffffc02010ec:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02010ee:	00001517          	auipc	a0,0x1
ffffffffc02010f2:	79250513          	addi	a0,a0,1938 # ffffffffc0202880 <best_fit_pmm_manager+0x120>
ffffffffc02010f6:	856ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    slub_init();
ffffffffc02010fa:	258000ef          	jal	ra,ffffffffc0201352 <slub_init>
    cprintf("SLUB allocator initialized.\n");
ffffffffc02010fe:	00001517          	auipc	a0,0x1
ffffffffc0201102:	7a250513          	addi	a0,a0,1954 # ffffffffc02028a0 <best_fit_pmm_manager+0x140>
ffffffffc0201106:	846ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020110a:	00005597          	auipc	a1,0x5
ffffffffc020110e:	ef658593          	addi	a1,a1,-266 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201112:	00006797          	auipc	a5,0x6
ffffffffc0201116:	24b7bb23          	sd	a1,598(a5) # ffffffffc0207368 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020111a:	c02007b7          	lui	a5,0xc0200
ffffffffc020111e:	0af5e563          	bltu	a1,a5,ffffffffc02011c8 <pmm_init+0x1d2>
ffffffffc0201122:	6090                	ld	a2,0(s1)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	79c50513          	addi	a0,a0,1948 # ffffffffc02028c0 <best_fit_pmm_manager+0x160>
    satp_physical = PADDR(satp_virtual);
ffffffffc020112c:	40c58633          	sub	a2,a1,a2
ffffffffc0201130:	00006797          	auipc	a5,0x6
ffffffffc0201134:	22c7b823          	sd	a2,560(a5) # ffffffffc0207360 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201138:	814ff0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc020113c:	7402                	ld	s0,32(sp)
ffffffffc020113e:	70a2                	ld	ra,40(sp)
ffffffffc0201140:	64e2                	ld	s1,24(sp)
ffffffffc0201142:	6942                	ld	s2,16(sp)
ffffffffc0201144:	69a2                	ld	s3,8(sp)
ffffffffc0201146:	6a02                	ld	s4,0(sp)
ffffffffc0201148:	6145                	addi	sp,sp,48
    run_slub_tests();
ffffffffc020114a:	39f0006f          	j	ffffffffc0201ce8 <run_slub_tests>
    npage = maxpa / PGSIZE;
ffffffffc020114e:	c8000637          	lui	a2,0xc8000
ffffffffc0201152:	b715                	j	ffffffffc0201076 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201154:	6705                	lui	a4,0x1
ffffffffc0201156:	177d                	addi	a4,a4,-1
ffffffffc0201158:	96ba                	add	a3,a3,a4
ffffffffc020115a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020115c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201160:	02c7f063          	bgeu	a5,a2,ffffffffc0201180 <pmm_init+0x18a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201164:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201166:	fff80737          	lui	a4,0xfff80
ffffffffc020116a:	973e                	add	a4,a4,a5
ffffffffc020116c:	00271793          	slli	a5,a4,0x2
ffffffffc0201170:	97ba                	add	a5,a5,a4
ffffffffc0201172:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201174:	8d95                	sub	a1,a1,a3
ffffffffc0201176:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201178:	81b1                	srli	a1,a1,0xc
ffffffffc020117a:	953e                	add	a0,a0,a5
ffffffffc020117c:	9702                	jalr	a4
}
ffffffffc020117e:	b7ad                	j	ffffffffc02010e8 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201180:	00001617          	auipc	a2,0x1
ffffffffc0201184:	6d060613          	addi	a2,a2,1744 # ffffffffc0202850 <best_fit_pmm_manager+0xf0>
ffffffffc0201188:	07000593          	li	a1,112
ffffffffc020118c:	00001517          	auipc	a0,0x1
ffffffffc0201190:	6e450513          	addi	a0,a0,1764 # ffffffffc0202870 <best_fit_pmm_manager+0x110>
ffffffffc0201194:	82eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	69060613          	addi	a2,a2,1680 # ffffffffc0202828 <best_fit_pmm_manager+0xc8>
ffffffffc02011a0:	05f00593          	li	a1,95
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	62c50513          	addi	a0,a0,1580 # ffffffffc02027d0 <best_fit_pmm_manager+0x70>
ffffffffc02011ac:	816ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc02011b0:	00001617          	auipc	a2,0x1
ffffffffc02011b4:	60060613          	addi	a2,a2,1536 # ffffffffc02027b0 <best_fit_pmm_manager+0x50>
ffffffffc02011b8:	04700593          	li	a1,71
ffffffffc02011bc:	00001517          	auipc	a0,0x1
ffffffffc02011c0:	61450513          	addi	a0,a0,1556 # ffffffffc02027d0 <best_fit_pmm_manager+0x70>
ffffffffc02011c4:	ffffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011c8:	86ae                	mv	a3,a1
ffffffffc02011ca:	00001617          	auipc	a2,0x1
ffffffffc02011ce:	65e60613          	addi	a2,a2,1630 # ffffffffc0202828 <best_fit_pmm_manager+0xc8>
ffffffffc02011d2:	07e00593          	li	a1,126
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	5fa50513          	addi	a0,a0,1530 # ffffffffc02027d0 <best_fit_pmm_manager+0x70>
ffffffffc02011de:	fe5fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02011e2 <print_separator>:
    }
}
// ==================== 测试函数 ====================

// 辅助函数：打印分隔符
static void print_separator(const char *title) {
ffffffffc02011e2:	1101                	addi	sp,sp,-32
ffffffffc02011e4:	e04a                	sd	s2,0(sp)
ffffffffc02011e6:	892a                	mv	s2,a0
    cprintf("\n");
ffffffffc02011e8:	00001517          	auipc	a0,0x1
ffffffffc02011ec:	09850513          	addi	a0,a0,152 # ffffffffc0202280 <etext+0xcc>
static void print_separator(const char *title) {
ffffffffc02011f0:	e822                	sd	s0,16(sp)
ffffffffc02011f2:	e426                	sd	s1,8(sp)
ffffffffc02011f4:	ec06                	sd	ra,24(sp)
    cprintf("\n");
ffffffffc02011f6:	03c00413          	li	s0,60
ffffffffc02011fa:	f53fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 60; i++) cprintf("=");
ffffffffc02011fe:	00001497          	auipc	s1,0x1
ffffffffc0201202:	70248493          	addi	s1,s1,1794 # ffffffffc0202900 <best_fit_pmm_manager+0x1a0>
ffffffffc0201206:	347d                	addiw	s0,s0,-1
ffffffffc0201208:	8526                	mv	a0,s1
ffffffffc020120a:	f43fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020120e:	fc65                	bnez	s0,ffffffffc0201206 <print_separator+0x24>
    cprintf("\n%s\n", title);
ffffffffc0201210:	85ca                	mv	a1,s2
ffffffffc0201212:	00001517          	auipc	a0,0x1
ffffffffc0201216:	6f650513          	addi	a0,a0,1782 # ffffffffc0202908 <best_fit_pmm_manager+0x1a8>
ffffffffc020121a:	f33fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020121e:	03c00413          	li	s0,60
    for (int i = 0; i < 60; i++) cprintf("=");
ffffffffc0201222:	00001497          	auipc	s1,0x1
ffffffffc0201226:	6de48493          	addi	s1,s1,1758 # ffffffffc0202900 <best_fit_pmm_manager+0x1a0>
ffffffffc020122a:	347d                	addiw	s0,s0,-1
ffffffffc020122c:	8526                	mv	a0,s1
ffffffffc020122e:	f1ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201232:	fc65                	bnez	s0,ffffffffc020122a <print_separator+0x48>
    cprintf("\n");
}
ffffffffc0201234:	6442                	ld	s0,16(sp)
ffffffffc0201236:	60e2                	ld	ra,24(sp)
ffffffffc0201238:	64a2                	ld	s1,8(sp)
ffffffffc020123a:	6902                	ld	s2,0(sp)
    cprintf("\n");
ffffffffc020123c:	00001517          	auipc	a0,0x1
ffffffffc0201240:	04450513          	addi	a0,a0,68 # ffffffffc0202280 <etext+0xcc>
}
ffffffffc0201244:	6105                	addi	sp,sp,32
    cprintf("\n");
ffffffffc0201246:	f07fe06f          	j	ffffffffc020014c <cprintf>

ffffffffc020124a <kmem_cache_free.part.0>:
void kmem_cache_free(kmem_cache_t *cache, void *obj_data) {
ffffffffc020124a:	1101                	addi	sp,sp,-32
ffffffffc020124c:	e822                	sd	s0,16(sp)
    slab_header_t *slab = header->slab;
ffffffffc020124e:	ff85b403          	ld	s0,-8(a1)
void kmem_cache_free(kmem_cache_t *cache, void *obj_data) {
ffffffffc0201252:	e426                	sd	s1,8(sp)
ffffffffc0201254:	e04a                	sd	s2,0(sp)
ffffffffc0201256:	84ae                	mv	s1,a1
ffffffffc0201258:	892a                	mv	s2,a0
    cprintf("  对象头: %p, 所属Slab: %p\n", header, slab);
ffffffffc020125a:	15a1                	addi	a1,a1,-24
ffffffffc020125c:	8622                	mv	a2,s0
ffffffffc020125e:	00001517          	auipc	a0,0x1
ffffffffc0201262:	6b250513          	addi	a0,a0,1714 # ffffffffc0202910 <best_fit_pmm_manager+0x1b0>
void kmem_cache_free(kmem_cache_t *cache, void *obj_data) {
ffffffffc0201266:	ec06                	sd	ra,24(sp)
    cprintf("  对象头: %p, 所属Slab: %p\n", header, slab);
ffffffffc0201268:	ee5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (slab->cache != cache) {
ffffffffc020126c:	601c                	ld	a5,0(s0)
        cprintf("  ✗ SLUB错误: 缓存不一致, obj=%p\n", obj_data);
ffffffffc020126e:	85a6                	mv	a1,s1
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	6c850513          	addi	a0,a0,1736 # ffffffffc0202938 <best_fit_pmm_manager+0x1d8>
    if (slab->cache != cache) {
ffffffffc0201278:	0b279663          	bne	a5,s2,ffffffffc0201324 <kmem_cache_free.part.0+0xda>
    if (slab->inuse == 0) {
ffffffffc020127c:	440c                	lw	a1,8(s0)
ffffffffc020127e:	cdd1                	beqz	a1,ffffffffc020131a <kmem_cache_free.part.0+0xd0>
    cprintf("  Slab当前状态: inuse=%d/%d\n", slab->inuse, cache->objs_per_slab);
ffffffffc0201280:	02892603          	lw	a2,40(s2)
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	72450513          	addi	a0,a0,1828 # ffffffffc02029a8 <best_fit_pmm_manager+0x248>
ffffffffc020128c:	ec1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *old_freelist = slab->freelist;
ffffffffc0201290:	740c                	ld	a1,40(s0)
    slab->inuse--;
ffffffffc0201292:	441c                	lw	a5,8(s0)
    cprintf("  对象放回freelist: %p -> %p\n", old_freelist, obj_data);
ffffffffc0201294:	8626                	mv	a2,s1
    *(void **)obj_data = slab->freelist;
ffffffffc0201296:	e08c                	sd	a1,0(s1)
    slab->inuse--;
ffffffffc0201298:	37fd                	addiw	a5,a5,-1
ffffffffc020129a:	c41c                	sw	a5,8(s0)
    slab->freelist = obj_data;
ffffffffc020129c:	f404                	sd	s1,40(s0)
    cprintf("  对象放回freelist: %p -> %p\n", old_freelist, obj_data);
ffffffffc020129e:	00001517          	auipc	a0,0x1
ffffffffc02012a2:	73250513          	addi	a0,a0,1842 # ffffffffc02029d0 <best_fit_pmm_manager+0x270>
ffffffffc02012a6:	ea7fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  Slab使用计数: %d -> %d\n", slab->inuse + 1, slab->inuse);
ffffffffc02012aa:	4410                	lw	a2,8(s0)
ffffffffc02012ac:	00001517          	auipc	a0,0x1
ffffffffc02012b0:	74c50513          	addi	a0,a0,1868 # ffffffffc02029f8 <best_fit_pmm_manager+0x298>
    list_del_init(&slab->list);
ffffffffc02012b4:	01040493          	addi	s1,s0,16
    cprintf("  Slab使用计数: %d -> %d\n", slab->inuse + 1, slab->inuse);
ffffffffc02012b8:	0016059b          	addiw	a1,a2,1
ffffffffc02012bc:	e91fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc02012c0:	6c1c                	ld	a5,24(s0)
ffffffffc02012c2:	6818                	ld	a4,16(s0)
    cprintf("  从当前链表移除Slab\n");
ffffffffc02012c4:	00001517          	auipc	a0,0x1
ffffffffc02012c8:	75450513          	addi	a0,a0,1876 # ffffffffc0202a18 <best_fit_pmm_manager+0x2b8>
    prev->next = next;
ffffffffc02012cc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02012ce:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02012d0:	ec04                	sd	s1,24(s0)
ffffffffc02012d2:	e804                	sd	s1,16(s0)
ffffffffc02012d4:	e79fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (slab->inuse == 0) {
ffffffffc02012d8:	441c                	lw	a5,8(s0)
ffffffffc02012da:	efa1                	bnez	a5,ffffffffc0201332 <kmem_cache_free.part.0+0xe8>
    __list_add(elm, listelm, listelm->next);
ffffffffc02012dc:	05893703          	ld	a4,88(s2)
        list_add(&(cache->slabs_free), &(slab->list));
ffffffffc02012e0:	05090793          	addi	a5,s2,80
        cprintf("  ✓ Slab状态变化: -> free链表\n");
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	75450513          	addi	a0,a0,1876 # ffffffffc0202a38 <best_fit_pmm_manager+0x2d8>
    prev->next = next->prev = elm;
ffffffffc02012ec:	e304                	sd	s1,0(a4)
ffffffffc02012ee:	04993c23          	sd	s1,88(s2)
    elm->next = next;
ffffffffc02012f2:	ec18                	sd	a4,24(s0)
    elm->prev = prev;
ffffffffc02012f4:	e81c                	sd	a5,16(s0)
ffffffffc02012f6:	e57fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cache->num_active--;
ffffffffc02012fa:	02c92783          	lw	a5,44(s2)
}
ffffffffc02012fe:	6442                	ld	s0,16(sp)
ffffffffc0201300:	60e2                	ld	ra,24(sp)
    cache->num_active--;
ffffffffc0201302:	37fd                	addiw	a5,a5,-1
}
ffffffffc0201304:	64a2                	ld	s1,8(sp)
    cache->num_active--;
ffffffffc0201306:	02f92623          	sw	a5,44(s2)
}
ffffffffc020130a:	6902                	ld	s2,0(sp)
    cprintf("  ✓ 对象释放完成\n");
ffffffffc020130c:	00001517          	auipc	a0,0x1
ffffffffc0201310:	78450513          	addi	a0,a0,1924 # ffffffffc0202a90 <best_fit_pmm_manager+0x330>
}
ffffffffc0201314:	6105                	addi	sp,sp,32
    cprintf("  ✓ 对象释放完成\n");
ffffffffc0201316:	e37fe06f          	j	ffffffffc020014c <cprintf>
        cprintf("  ✗ SLUB错误: slab使用计数为0但尝试释放对象 %p\n", obj_data);
ffffffffc020131a:	85a6                	mv	a1,s1
ffffffffc020131c:	00001517          	auipc	a0,0x1
ffffffffc0201320:	64c50513          	addi	a0,a0,1612 # ffffffffc0202968 <best_fit_pmm_manager+0x208>
}
ffffffffc0201324:	6442                	ld	s0,16(sp)
ffffffffc0201326:	60e2                	ld	ra,24(sp)
ffffffffc0201328:	64a2                	ld	s1,8(sp)
ffffffffc020132a:	6902                	ld	s2,0(sp)
ffffffffc020132c:	6105                	addi	sp,sp,32
        cprintf("  ✗ SLUB错误: slab使用计数为0但尝试释放对象 %p\n", obj_data);
ffffffffc020132e:	e1ffe06f          	j	ffffffffc020014c <cprintf>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201332:	04893703          	ld	a4,72(s2)
        list_add(&(cache->slabs_partial), &(slab->list));
ffffffffc0201336:	04090793          	addi	a5,s2,64
        cprintf("  ✓ Slab状态变化: -> partial链表\n");
ffffffffc020133a:	00001517          	auipc	a0,0x1
ffffffffc020133e:	72650513          	addi	a0,a0,1830 # ffffffffc0202a60 <best_fit_pmm_manager+0x300>
    prev->next = next->prev = elm;
ffffffffc0201342:	e304                	sd	s1,0(a4)
ffffffffc0201344:	04993423          	sd	s1,72(s2)
    elm->next = next;
ffffffffc0201348:	ec18                	sd	a4,24(s0)
    elm->prev = prev;
ffffffffc020134a:	e81c                	sd	a5,16(s0)
ffffffffc020134c:	e01fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201350:	b76d                	j	ffffffffc02012fa <kmem_cache_free.part.0+0xb0>

ffffffffc0201352 <slub_init>:
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201352:	00002517          	auipc	a0,0x2
ffffffffc0201356:	31650513          	addi	a0,a0,790 # ffffffffc0203668 <slub_size_classes>
ffffffffc020135a:	00002817          	auipc	a6,0x2
ffffffffc020135e:	2ce80813          	addi	a6,a6,718 # ffffffffc0203628 <slub_cache_names>
ffffffffc0201362:	00006617          	auipc	a2,0x6
ffffffffc0201366:	ced60613          	addi	a2,a2,-787 # ffffffffc020704f <slub_caches+0x1f>
ffffffffc020136a:	00002317          	auipc	t1,0x2
ffffffffc020136e:	33e30313          	addi	t1,t1,830 # ffffffffc02036a8 <slub_size_classes+0x40>
void slub_init(void) {
ffffffffc0201372:	07300713          	li	a4,115
ffffffffc0201376:	00001697          	auipc	a3,0x1
ffffffffc020137a:	73a68693          	addi	a3,a3,1850 # ffffffffc0202ab0 <best_fit_pmm_manager+0x350>
ffffffffc020137e:	02000593          	li	a1,32
        if (cache->objs_per_slab < 1) cache->objs_per_slab = 1;
ffffffffc0201382:	6885                	lui	a7,0x1
ffffffffc0201384:	4e05                	li	t3,1
        char *dst = cache->name;
ffffffffc0201386:	fe160793          	addi	a5,a2,-31
        while (*src && j < sizeof(cache->name) - 1) {
ffffffffc020138a:	e701                	bnez	a4,ffffffffc0201392 <slub_init+0x40>
ffffffffc020138c:	a811                	j	ffffffffc02013a0 <slub_init+0x4e>
ffffffffc020138e:	00c78963          	beq	a5,a2,ffffffffc02013a0 <slub_init+0x4e>
            *dst++ = *src++;
ffffffffc0201392:	00e78023          	sb	a4,0(a5)
        while (*src && j < sizeof(cache->name) - 1) {
ffffffffc0201396:	0016c703          	lbu	a4,1(a3)
            *dst++ = *src++;
ffffffffc020139a:	0785                	addi	a5,a5,1
ffffffffc020139c:	0685                	addi	a3,a3,1
        while (*src && j < sizeof(cache->name) - 1) {
ffffffffc020139e:	fb65                	bnez	a4,ffffffffc020138e <slub_init+0x3c>
        *dst = '\0';
ffffffffc02013a0:	00078023          	sb	zero,0(a5)
        cache->obj_size = slub_size_classes[i];
ffffffffc02013a4:	00b630a3          	sd	a1,1(a2)
        size_t total_obj_size = sizeof(obj_header_t) + cache->obj_size;
ffffffffc02013a8:	05e1                	addi	a1,a1,24
        if (cache->objs_per_slab < 1) cache->objs_per_slab = 1;
ffffffffc02013aa:	04b8e663          	bltu	a7,a1,ffffffffc02013f6 <slub_init+0xa4>
        cache->objs_per_slab = PGSIZE / total_obj_size;
ffffffffc02013ae:	02b8d5b3          	divu	a1,a7,a1
ffffffffc02013b2:	00b624a3          	sw	a1,9(a2)
        list_init(&cache->slabs_full);
ffffffffc02013b6:	01160693          	addi	a3,a2,17
    elm->prev = elm->next = elm;
ffffffffc02013ba:	02160713          	addi	a4,a2,33
ffffffffc02013be:	03160793          	addi	a5,a2,49
ffffffffc02013c2:	00d63ca3          	sd	a3,25(a2)
ffffffffc02013c6:	00d638a3          	sd	a3,17(a2)
ffffffffc02013ca:	02e634a3          	sd	a4,41(a2)
ffffffffc02013ce:	02e630a3          	sd	a4,33(a2)
ffffffffc02013d2:	02f63ca3          	sd	a5,57(a2)
ffffffffc02013d6:	02f638a3          	sd	a5,49(a2)
        cache->num_active = 0;
ffffffffc02013da:	000626a3          	sw	zero,13(a2)
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc02013de:	0521                	addi	a0,a0,8
ffffffffc02013e0:	0821                	addi	a6,a6,8
ffffffffc02013e2:	06060613          	addi	a2,a2,96
ffffffffc02013e6:	00650b63          	beq	a0,t1,ffffffffc02013fc <slub_init+0xaa>
        const char *predefined_name = slub_cache_names[i];
ffffffffc02013ea:	00083683          	ld	a3,0(a6)
        cache->obj_size = slub_size_classes[i];
ffffffffc02013ee:	610c                	ld	a1,0(a0)
        while (*src && j < sizeof(cache->name) - 1) {
ffffffffc02013f0:	0006c703          	lbu	a4,0(a3)
ffffffffc02013f4:	bf49                	j	ffffffffc0201386 <slub_init+0x34>
        if (cache->objs_per_slab < 1) cache->objs_per_slab = 1;
ffffffffc02013f6:	01c624a3          	sw	t3,9(a2)
ffffffffc02013fa:	bf75                	j	ffffffffc02013b6 <slub_init+0x64>
}
ffffffffc02013fc:	8082                	ret

ffffffffc02013fe <slub_find_cache>:
kmem_cache_t *slub_find_cache(size_t size) {
ffffffffc02013fe:	715d                	addi	sp,sp,-80
ffffffffc0201400:	ec56                	sd	s5,24(sp)
    cprintf("\n=== slub_find_cache: 查找适合 %u 字节的缓存 ===\n", (unsigned int)size);
ffffffffc0201402:	0005059b          	sext.w	a1,a0
kmem_cache_t *slub_find_cache(size_t size) {
ffffffffc0201406:	8aaa                	mv	s5,a0
    cprintf("\n=== slub_find_cache: 查找适合 %u 字节的缓存 ===\n", (unsigned int)size);
ffffffffc0201408:	00001517          	auipc	a0,0x1
ffffffffc020140c:	6b050513          	addi	a0,a0,1712 # ffffffffc0202ab8 <best_fit_pmm_manager+0x358>
kmem_cache_t *slub_find_cache(size_t size) {
ffffffffc0201410:	e0a2                	sd	s0,64(sp)
ffffffffc0201412:	fc26                	sd	s1,56(sp)
ffffffffc0201414:	f84a                	sd	s2,48(sp)
ffffffffc0201416:	f44e                	sd	s3,40(sp)
ffffffffc0201418:	f052                	sd	s4,32(sp)
ffffffffc020141a:	e85a                	sd	s6,16(sp)
ffffffffc020141c:	e45e                	sd	s7,8(sp)
ffffffffc020141e:	e486                	sd	ra,72(sp)
ffffffffc0201420:	00002997          	auipc	s3,0x2
ffffffffc0201424:	20898993          	addi	s3,s3,520 # ffffffffc0203628 <slub_cache_names>
    cprintf("\n=== slub_find_cache: 查找适合 %u 字节的缓存 ===\n", (unsigned int)size);
ffffffffc0201428:	d25fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc020142c:	00002917          	auipc	s2,0x2
ffffffffc0201430:	23c90913          	addi	s2,s2,572 # ffffffffc0203668 <slub_size_classes>
    cprintf("\n=== slub_find_cache: 查找适合 %u 字节的缓存 ===\n", (unsigned int)size);
ffffffffc0201434:	02000493          	li	s1,32
ffffffffc0201438:	00001a17          	auipc	s4,0x1
ffffffffc020143c:	678a0a13          	addi	s4,s4,1656 # ffffffffc0202ab0 <best_fit_pmm_manager+0x350>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201440:	4401                	li	s0,0
        cprintf("  检查缓存[%d]: %s (大小: %u)\n", i, slub_cache_names[i], (unsigned int)slub_size_classes[i]);
ffffffffc0201442:	00001b17          	auipc	s6,0x1
ffffffffc0201446:	6b6b0b13          	addi	s6,s6,1718 # ffffffffc0202af8 <best_fit_pmm_manager+0x398>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc020144a:	4ba1                	li	s7,8
ffffffffc020144c:	a029                	j	ffffffffc0201456 <slub_find_cache+0x58>
        cprintf("  检查缓存[%d]: %s (大小: %u)\n", i, slub_cache_names[i], (unsigned int)slub_size_classes[i]);
ffffffffc020144e:	0009ba03          	ld	s4,0(s3)
ffffffffc0201452:	00093483          	ld	s1,0(s2)
ffffffffc0201456:	0004869b          	sext.w	a3,s1
ffffffffc020145a:	8652                	mv	a2,s4
ffffffffc020145c:	85a2                	mv	a1,s0
ffffffffc020145e:	855a                	mv	a0,s6
ffffffffc0201460:	cedfe0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (size <= slub_size_classes[i]) {
ffffffffc0201464:	0354f963          	bgeu	s1,s5,ffffffffc0201496 <slub_find_cache+0x98>
    for (int i = 0; i < SLUB_CACHE_NUM; i++) {
ffffffffc0201468:	2405                	addiw	s0,s0,1
ffffffffc020146a:	09a1                	addi	s3,s3,8
ffffffffc020146c:	0921                	addi	s2,s2,8
ffffffffc020146e:	ff7410e3          	bne	s0,s7,ffffffffc020144e <slub_find_cache+0x50>
    cprintf("  ✗ 未找到合适缓存\n");
ffffffffc0201472:	00001517          	auipc	a0,0x1
ffffffffc0201476:	6ce50513          	addi	a0,a0,1742 # ffffffffc0202b40 <best_fit_pmm_manager+0x3e0>
ffffffffc020147a:	cd3fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    return NULL;
ffffffffc020147e:	4501                	li	a0,0
}
ffffffffc0201480:	60a6                	ld	ra,72(sp)
ffffffffc0201482:	6406                	ld	s0,64(sp)
ffffffffc0201484:	74e2                	ld	s1,56(sp)
ffffffffc0201486:	7942                	ld	s2,48(sp)
ffffffffc0201488:	79a2                	ld	s3,40(sp)
ffffffffc020148a:	7a02                	ld	s4,32(sp)
ffffffffc020148c:	6ae2                	ld	s5,24(sp)
ffffffffc020148e:	6b42                	ld	s6,16(sp)
ffffffffc0201490:	6ba2                	ld	s7,8(sp)
ffffffffc0201492:	6161                	addi	sp,sp,80
ffffffffc0201494:	8082                	ret
            cprintf("  ✓ 找到合适缓存: %s\n", slub_cache_names[i]);
ffffffffc0201496:	85d2                	mv	a1,s4
ffffffffc0201498:	00001517          	auipc	a0,0x1
ffffffffc020149c:	68850513          	addi	a0,a0,1672 # ffffffffc0202b20 <best_fit_pmm_manager+0x3c0>
ffffffffc02014a0:	cadfe0ef          	jal	ra,ffffffffc020014c <cprintf>
            return &slub_caches[i];
ffffffffc02014a4:	00141513          	slli	a0,s0,0x1
ffffffffc02014a8:	942a                	add	s0,s0,a0
ffffffffc02014aa:	0416                	slli	s0,s0,0x5
ffffffffc02014ac:	00006517          	auipc	a0,0x6
ffffffffc02014b0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0207030 <slub_caches>
ffffffffc02014b4:	9522                	add	a0,a0,s0
ffffffffc02014b6:	b7e9                	j	ffffffffc0201480 <slub_find_cache+0x82>

ffffffffc02014b8 <kmem_cache_alloc>:
void *kmem_cache_alloc(kmem_cache_t *cache) {
ffffffffc02014b8:	711d                	addi	sp,sp,-96
ffffffffc02014ba:	e8a2                	sd	s0,80(sp)
    cprintf("\n=== kmem_cache_alloc: 从缓存 %s 分配对象 ===\n", cache->name);
ffffffffc02014bc:	85aa                	mv	a1,a0
void *kmem_cache_alloc(kmem_cache_t *cache) {
ffffffffc02014be:	842a                	mv	s0,a0
    cprintf("\n=== kmem_cache_alloc: 从缓存 %s 分配对象 ===\n", cache->name);
ffffffffc02014c0:	00001517          	auipc	a0,0x1
ffffffffc02014c4:	6d050513          	addi	a0,a0,1744 # ffffffffc0202b90 <best_fit_pmm_manager+0x430>
void *kmem_cache_alloc(kmem_cache_t *cache) {
ffffffffc02014c8:	ec86                	sd	ra,88(sp)
ffffffffc02014ca:	e4a6                	sd	s1,72(sp)
ffffffffc02014cc:	e0ca                	sd	s2,64(sp)
ffffffffc02014ce:	fc4e                	sd	s3,56(sp)
ffffffffc02014d0:	f852                	sd	s4,48(sp)
ffffffffc02014d2:	f456                	sd	s5,40(sp)
ffffffffc02014d4:	f05a                	sd	s6,32(sp)
ffffffffc02014d6:	ec5e                	sd	s7,24(sp)
ffffffffc02014d8:	e862                	sd	s8,16(sp)
ffffffffc02014da:	e466                	sd	s9,8(sp)
    cprintf("\n=== kmem_cache_alloc: 从缓存 %s 分配对象 ===\n", cache->name);
ffffffffc02014dc:	c71fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (!cache) {
ffffffffc02014e0:	2a040c63          	beqz	s0,ffffffffc0201798 <kmem_cache_alloc+0x2e0>
    return list->next == list;
ffffffffc02014e4:	04843983          	ld	s3,72(s0)
    if (!list_empty(&cache->slabs_partial)) {
ffffffffc02014e8:	04040793          	addi	a5,s0,64
ffffffffc02014ec:	0af98263          	beq	s3,a5,ffffffffc0201590 <kmem_cache_alloc+0xd8>
        cprintf("  ✓ 从partial链表获取Slab\n");
ffffffffc02014f0:	00001517          	auipc	a0,0x1
ffffffffc02014f4:	6f850513          	addi	a0,a0,1784 # ffffffffc0202be8 <best_fit_pmm_manager+0x488>
ffffffffc02014f8:	c55fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        slab = le2slab(le, list);
ffffffffc02014fc:	ff098493          	addi	s1,s3,-16
        source = "partial链表";
ffffffffc0201500:	00001597          	auipc	a1,0x1
ffffffffc0201504:	66058593          	addi	a1,a1,1632 # ffffffffc0202b60 <best_fit_pmm_manager+0x400>
    cprintf("  分配来源: %s, slab=%p\n", source, slab);
ffffffffc0201508:	8626                	mv	a2,s1
ffffffffc020150a:	00002517          	auipc	a0,0x2
ffffffffc020150e:	97e50513          	addi	a0,a0,-1666 # ffffffffc0202e88 <best_fit_pmm_manager+0x728>
ffffffffc0201512:	c3bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *obj_data = slab->freelist;
ffffffffc0201516:	0284b903          	ld	s2,40(s1)
    if (!obj_data) {
ffffffffc020151a:	26090863          	beqz	s2,ffffffffc020178a <kmem_cache_alloc+0x2d2>
    cprintf("  从freelist获取对象: %p\n", obj_data);
ffffffffc020151e:	85ca                	mv	a1,s2
ffffffffc0201520:	00002517          	auipc	a0,0x2
ffffffffc0201524:	9a850513          	addi	a0,a0,-1624 # ffffffffc0202ec8 <best_fit_pmm_manager+0x768>
ffffffffc0201528:	c25fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    slab->inuse++;
ffffffffc020152c:	449c                	lw	a5,8(s1)
    slab->freelist = *(void **)obj_data;
ffffffffc020152e:	00093603          	ld	a2,0(s2)
    cprintf("  更新freelist: %p -> %p\n", obj_data, slab->freelist);
ffffffffc0201532:	85ca                	mv	a1,s2
    slab->inuse++;
ffffffffc0201534:	2785                	addiw	a5,a5,1
ffffffffc0201536:	c49c                	sw	a5,8(s1)
    slab->freelist = *(void **)obj_data;
ffffffffc0201538:	f490                	sd	a2,40(s1)
    cprintf("  更新freelist: %p -> %p\n", obj_data, slab->freelist);
ffffffffc020153a:	00002517          	auipc	a0,0x2
ffffffffc020153e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0202ee8 <best_fit_pmm_manager+0x788>
ffffffffc0201542:	c0bfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  Slab使用计数: %d -> %d\n", slab->inuse - 1, slab->inuse);
ffffffffc0201546:	4490                	lw	a2,8(s1)
ffffffffc0201548:	00001517          	auipc	a0,0x1
ffffffffc020154c:	4b050513          	addi	a0,a0,1200 # ffffffffc02029f8 <best_fit_pmm_manager+0x298>
ffffffffc0201550:	fff6059b          	addiw	a1,a2,-1
ffffffffc0201554:	bf9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (slab->inuse == cache->objs_per_slab) {
ffffffffc0201558:	4498                	lw	a4,8(s1)
ffffffffc020155a:	541c                	lw	a5,40(s0)
ffffffffc020155c:	06f70e63          	beq	a4,a5,ffffffffc02015d8 <kmem_cache_alloc+0x120>
    cache->num_active++;
ffffffffc0201560:	545c                	lw	a5,44(s0)
    cprintf("  ✓ 对象分配成功: %p\n", obj_data);
ffffffffc0201562:	85ca                	mv	a1,s2
ffffffffc0201564:	00002517          	auipc	a0,0x2
ffffffffc0201568:	9d450513          	addi	a0,a0,-1580 # ffffffffc0202f38 <best_fit_pmm_manager+0x7d8>
    cache->num_active++;
ffffffffc020156c:	2785                	addiw	a5,a5,1
ffffffffc020156e:	d45c                	sw	a5,44(s0)
    cprintf("  ✓ 对象分配成功: %p\n", obj_data);
ffffffffc0201570:	bddfe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc0201574:	60e6                	ld	ra,88(sp)
ffffffffc0201576:	6446                	ld	s0,80(sp)
ffffffffc0201578:	64a6                	ld	s1,72(sp)
ffffffffc020157a:	79e2                	ld	s3,56(sp)
ffffffffc020157c:	7a42                	ld	s4,48(sp)
ffffffffc020157e:	7aa2                	ld	s5,40(sp)
ffffffffc0201580:	7b02                	ld	s6,32(sp)
ffffffffc0201582:	6be2                	ld	s7,24(sp)
ffffffffc0201584:	6c42                	ld	s8,16(sp)
ffffffffc0201586:	6ca2                	ld	s9,8(sp)
ffffffffc0201588:	854a                	mv	a0,s2
ffffffffc020158a:	6906                	ld	s2,64(sp)
ffffffffc020158c:	6125                	addi	sp,sp,96
ffffffffc020158e:	8082                	ret
ffffffffc0201590:	05843b83          	ld	s7,88(s0)
    else if (!list_empty(&cache->slabs_free)) {
ffffffffc0201594:	05040793          	addi	a5,s0,80
ffffffffc0201598:	06fb8563          	beq	s7,a5,ffffffffc0201602 <kmem_cache_alloc+0x14a>
    __list_del(listelm->prev, listelm->next);
ffffffffc020159c:	008bb783          	ld	a5,8(s7)
ffffffffc02015a0:	000bb703          	ld	a4,0(s7)
        cprintf("  ✓ 从free链表获取Slab，移动到partial链表\n");
ffffffffc02015a4:	00001517          	auipc	a0,0x1
ffffffffc02015a8:	66c50513          	addi	a0,a0,1644 # ffffffffc0202c10 <best_fit_pmm_manager+0x4b0>
        slab = le2slab(le, list);
ffffffffc02015ac:	ff0b8493          	addi	s1,s7,-16
    prev->next = next;
ffffffffc02015b0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02015b2:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02015b4:	017bb423          	sd	s7,8(s7)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015b8:	643c                	ld	a5,72(s0)
    prev->next = next->prev = elm;
ffffffffc02015ba:	0177b023          	sd	s7,0(a5)
ffffffffc02015be:	05743423          	sd	s7,72(s0)
    elm->next = next;
ffffffffc02015c2:	00fbb423          	sd	a5,8(s7)
    elm->prev = prev;
ffffffffc02015c6:	013bb023          	sd	s3,0(s7)
        cprintf("  ✓ 从free链表获取Slab，移动到partial链表\n");
ffffffffc02015ca:	b83fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        source = "free链表";
ffffffffc02015ce:	00001597          	auipc	a1,0x1
ffffffffc02015d2:	5a258593          	addi	a1,a1,1442 # ffffffffc0202b70 <best_fit_pmm_manager+0x410>
ffffffffc02015d6:	bf0d                	j	ffffffffc0201508 <kmem_cache_alloc+0x50>
    __list_del(listelm->prev, listelm->next);
ffffffffc02015d8:	6c94                	ld	a3,24(s1)
ffffffffc02015da:	6890                	ld	a2,16(s1)
        list_del_init(&slab->list);
ffffffffc02015dc:	01048713          	addi	a4,s1,16
        list_add(&(cache->slabs_full), &(slab->list));
ffffffffc02015e0:	03040793          	addi	a5,s0,48
    prev->next = next;
ffffffffc02015e4:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02015e6:	e290                	sd	a2,0(a3)
    elm->prev = elm->next = elm;
ffffffffc02015e8:	ec98                	sd	a4,24(s1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02015ea:	7c14                	ld	a3,56(s0)
        cprintf("  ✓ Slab状态变化: partial -> full\n");
ffffffffc02015ec:	00002517          	auipc	a0,0x2
ffffffffc02015f0:	91c50513          	addi	a0,a0,-1764 # ffffffffc0202f08 <best_fit_pmm_manager+0x7a8>
    prev->next = next->prev = elm;
ffffffffc02015f4:	e298                	sd	a4,0(a3)
ffffffffc02015f6:	fc18                	sd	a4,56(s0)
    elm->next = next;
ffffffffc02015f8:	ec94                	sd	a3,24(s1)
    elm->prev = prev;
ffffffffc02015fa:	e89c                	sd	a5,16(s1)
ffffffffc02015fc:	b51fe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201600:	b785                	j	ffffffffc0201560 <kmem_cache_alloc+0xa8>
        cprintf("  partial和free链表都为空，分配新Slab...\n");
ffffffffc0201602:	00001517          	auipc	a0,0x1
ffffffffc0201606:	64650513          	addi	a0,a0,1606 # ffffffffc0202c48 <best_fit_pmm_manager+0x4e8>
ffffffffc020160a:	b43fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\n=== slub_alloc_slab_page: 为缓存 %s 分配新Slab ===\n", cache->name);
ffffffffc020160e:	85a2                	mv	a1,s0
ffffffffc0201610:	00001517          	auipc	a0,0x1
ffffffffc0201614:	67050513          	addi	a0,a0,1648 # ffffffffc0202c80 <best_fit_pmm_manager+0x520>
ffffffffc0201618:	b35fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  调用 alloc_pages(1) 分配物理页...\n");
ffffffffc020161c:	00001517          	auipc	a0,0x1
ffffffffc0201620:	6a450513          	addi	a0,a0,1700 # ffffffffc0202cc0 <best_fit_pmm_manager+0x560>
ffffffffc0201624:	b29fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *page = alloc_pages(1);
ffffffffc0201628:	4505                	li	a0,1
ffffffffc020162a:	9a9ff0ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc020162e:	892a                	mv	s2,a0
    if (page == NULL) {
ffffffffc0201630:	16050c63          	beqz	a0,ffffffffc02017a8 <kmem_cache_alloc+0x2f0>
    cprintf("  ✓ 物理页分配成功: page=%p\n", page);
ffffffffc0201634:	85aa                	mv	a1,a0
ffffffffc0201636:	00001517          	auipc	a0,0x1
ffffffffc020163a:	6da50513          	addi	a0,a0,1754 # ffffffffc0202d10 <best_fit_pmm_manager+0x5b0>
ffffffffc020163e:	b0ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t total_obj_size = sizeof(obj_header_t) + cache->obj_size;
ffffffffc0201642:	7014                	ld	a3,32(s0)
    cprintf("  对象总大小: %u (头:%u + 数据:%u)\n", 
ffffffffc0201644:	4661                	li	a2,24
ffffffffc0201646:	00001517          	auipc	a0,0x1
ffffffffc020164a:	6f250513          	addi	a0,a0,1778 # ffffffffc0202d38 <best_fit_pmm_manager+0x5d8>
    size_t total_obj_size = sizeof(obj_header_t) + cache->obj_size;
ffffffffc020164e:	01868a13          	addi	s4,a3,24
    cprintf("  对象总大小: %u (头:%u + 数据:%u)\n", 
ffffffffc0201652:	000a059b          	sext.w	a1,s4
ffffffffc0201656:	2681                	sext.w	a3,a3
ffffffffc0201658:	af5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020165c:	00006697          	auipc	a3,0x6
ffffffffc0201660:	cf46b683          	ld	a3,-780(a3) # ffffffffc0207350 <pages>
ffffffffc0201664:	40d906b3          	sub	a3,s2,a3
ffffffffc0201668:	00002497          	auipc	s1,0x2
ffffffffc020166c:	2884b483          	ld	s1,648(s1) # ffffffffc02038f0 <error_string+0x38>
ffffffffc0201670:	868d                	srai	a3,a3,0x3
ffffffffc0201672:	029686b3          	mul	a3,a3,s1
ffffffffc0201676:	00002497          	auipc	s1,0x2
ffffffffc020167a:	2824b483          	ld	s1,642(s1) # ffffffffc02038f8 <nbase>
    slab_header_t *slab = (slab_header_t *)page2kva(page);
ffffffffc020167e:	00006717          	auipc	a4,0x6
ffffffffc0201682:	cca73703          	ld	a4,-822(a4) # ffffffffc0207348 <npage>
ffffffffc0201686:	96a6                	add	a3,a3,s1
ffffffffc0201688:	00c69793          	slli	a5,a3,0xc
ffffffffc020168c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020168e:	06b2                	slli	a3,a3,0xc
ffffffffc0201690:	12e7f363          	bgeu	a5,a4,ffffffffc02017b6 <kmem_cache_alloc+0x2fe>
ffffffffc0201694:	00006497          	auipc	s1,0x6
ffffffffc0201698:	cdc4b483          	ld	s1,-804(s1) # ffffffffc0207370 <va_pa_offset>
ffffffffc020169c:	94b6                	add	s1,s1,a3
    cprintf("  Slab虚拟地址: %p\n", slab);
ffffffffc020169e:	85a6                	mv	a1,s1
ffffffffc02016a0:	00001517          	auipc	a0,0x1
ffffffffc02016a4:	70850513          	addi	a0,a0,1800 # ffffffffc0202da8 <best_fit_pmm_manager+0x648>
ffffffffc02016a8:	aa5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    slab->objects_start = (char *)slab + sizeof(slab_header_t);
ffffffffc02016ac:	03048593          	addi	a1,s1,48
    list_init(&slab->list);
ffffffffc02016b0:	01048a93          	addi	s5,s1,16
    slab->objects_start = (char *)slab + sizeof(slab_header_t);
ffffffffc02016b4:	f08c                	sd	a1,32(s1)
    slab->cache = cache;
ffffffffc02016b6:	e080                	sd	s0,0(s1)
    slab->inuse = 0;
ffffffffc02016b8:	0004a423          	sw	zero,8(s1)
    elm->prev = elm->next = elm;
ffffffffc02016bc:	0154bc23          	sd	s5,24(s1)
ffffffffc02016c0:	0154b823          	sd	s5,16(s1)
    slab->freelist = NULL;
ffffffffc02016c4:	0204b423          	sd	zero,40(s1)
    cprintf("  初始化Slab: inuse=0, objects_start=%p\n", slab->objects_start);
ffffffffc02016c8:	00001517          	auipc	a0,0x1
ffffffffc02016cc:	6f850513          	addi	a0,a0,1784 # ffffffffc0202dc0 <best_fit_pmm_manager+0x660>
ffffffffc02016d0:	a7dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  开始初始化 %d 个对象...\n", cache->objs_per_slab);
ffffffffc02016d4:	540c                	lw	a1,40(s0)
ffffffffc02016d6:	00001517          	auipc	a0,0x1
ffffffffc02016da:	71a50513          	addi	a0,a0,1818 # ffffffffc0202df0 <best_fit_pmm_manager+0x690>
ffffffffc02016de:	a6ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = cache->objs_per_slab - 1; i >= 0; i--) {
ffffffffc02016e2:	541c                	lw	a5,40(s0)
ffffffffc02016e4:	fff7891b          	addiw	s2,a5,-1
ffffffffc02016e8:	87ca                	mv	a5,s2
ffffffffc02016ea:	04094963          	bltz	s2,ffffffffc020173c <kmem_cache_alloc+0x284>
ffffffffc02016ee:	03490c33          	mul	s8,s2,s4
            cprintf("    对象[%d]: header=%p, data=%p\n", i, header, obj_data);
ffffffffc02016f2:	00001b17          	auipc	s6,0x1
ffffffffc02016f6:	726b0b13          	addi	s6,s6,1830 # ffffffffc0202e18 <best_fit_pmm_manager+0x6b8>
    for (int i = cache->objs_per_slab - 1; i >= 0; i--) {
ffffffffc02016fa:	5cfd                	li	s9,-1
ffffffffc02016fc:	a801                	j	ffffffffc020170c <kmem_cache_alloc+0x254>
ffffffffc02016fe:	397d                	addiw	s2,s2,-1
ffffffffc0201700:	414c0c33          	sub	s8,s8,s4
ffffffffc0201704:	03990c63          	beq	s2,s9,ffffffffc020173c <kmem_cache_alloc+0x284>
        if (i == cache->objs_per_slab - 1 || i == 0) {
ffffffffc0201708:	541c                	lw	a5,40(s0)
ffffffffc020170a:	37fd                	addiw	a5,a5,-1
        obj_header_t *header = (obj_header_t *)((char *)slab->objects_start + i * total_obj_size);
ffffffffc020170c:	7090                	ld	a2,32(s1)
        header->obj_size = cache->obj_size;
ffffffffc020170e:	7014                	ld	a3,32(s0)
        *(void **)obj_data = slab->freelist;
ffffffffc0201710:	7498                	ld	a4,40(s1)
        obj_header_t *header = (obj_header_t *)((char *)slab->objects_start + i * total_obj_size);
ffffffffc0201712:	9662                	add	a2,a2,s8
        header->obj_size = cache->obj_size;
ffffffffc0201714:	e614                	sd	a3,8(a2)
        header->cache = cache;
ffffffffc0201716:	e200                	sd	s0,0(a2)
        header->slab = slab;
ffffffffc0201718:	ea04                	sd	s1,16(a2)
        void *obj_data = (void *)(header + 1);
ffffffffc020171a:	01860693          	addi	a3,a2,24
        *(void **)obj_data = slab->freelist;
ffffffffc020171e:	ee18                	sd	a4,24(a2)
        slab->freelist = obj_data;
ffffffffc0201720:	f494                	sd	a3,40(s1)
        if (i == cache->objs_per_slab - 1 || i == 0) {
ffffffffc0201722:	01278463          	beq	a5,s2,ffffffffc020172a <kmem_cache_alloc+0x272>
ffffffffc0201726:	fc091ce3          	bnez	s2,ffffffffc02016fe <kmem_cache_alloc+0x246>
            cprintf("    对象[%d]: header=%p, data=%p\n", i, header, obj_data);
ffffffffc020172a:	85ca                	mv	a1,s2
ffffffffc020172c:	855a                	mv	a0,s6
    for (int i = cache->objs_per_slab - 1; i >= 0; i--) {
ffffffffc020172e:	397d                	addiw	s2,s2,-1
            cprintf("    对象[%d]: header=%p, data=%p\n", i, header, obj_data);
ffffffffc0201730:	a1dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = cache->objs_per_slab - 1; i >= 0; i--) {
ffffffffc0201734:	414c0c33          	sub	s8,s8,s4
ffffffffc0201738:	fd9918e3          	bne	s2,s9,ffffffffc0201708 <kmem_cache_alloc+0x250>
    __list_add(elm, listelm, listelm->next);
ffffffffc020173c:	6c3c                	ld	a5,88(s0)
    cprintf("  ✓ Slab添加到free链表\n");
ffffffffc020173e:	00001517          	auipc	a0,0x1
ffffffffc0201742:	70250513          	addi	a0,a0,1794 # ffffffffc0202e40 <best_fit_pmm_manager+0x6e0>
    prev->next = next->prev = elm;
ffffffffc0201746:	0157b023          	sd	s5,0(a5)
ffffffffc020174a:	05543c23          	sd	s5,88(s0)
    elm->next = next;
ffffffffc020174e:	ec9c                	sd	a5,24(s1)
    elm->prev = prev;
ffffffffc0201750:	0174b823          	sd	s7,16(s1)
ffffffffc0201754:	9f9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201758:	6c9c                	ld	a5,24(s1)
ffffffffc020175a:	6898                	ld	a4,16(s1)
        cprintf("  ✓ 新Slab添加到partial链表\n");
ffffffffc020175c:	00001517          	auipc	a0,0x1
ffffffffc0201760:	70450513          	addi	a0,a0,1796 # ffffffffc0202e60 <best_fit_pmm_manager+0x700>
    prev->next = next;
ffffffffc0201764:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201766:	e398                	sd	a4,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0201768:	0154bc23          	sd	s5,24(s1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020176c:	643c                	ld	a5,72(s0)
    prev->next = next->prev = elm;
ffffffffc020176e:	0157b023          	sd	s5,0(a5)
ffffffffc0201772:	05543423          	sd	s5,72(s0)
    elm->next = next;
ffffffffc0201776:	ec9c                	sd	a5,24(s1)
    elm->prev = prev;
ffffffffc0201778:	0134b823          	sd	s3,16(s1)
ffffffffc020177c:	9d1fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        source = "新建Slab";
ffffffffc0201780:	00001597          	auipc	a1,0x1
ffffffffc0201784:	40058593          	addi	a1,a1,1024 # ffffffffc0202b80 <best_fit_pmm_manager+0x420>
ffffffffc0201788:	b341                	j	ffffffffc0201508 <kmem_cache_alloc+0x50>
        cprintf("  ✗ Slab的freelist为空\n");
ffffffffc020178a:	00001517          	auipc	a0,0x1
ffffffffc020178e:	71e50513          	addi	a0,a0,1822 # ffffffffc0202ea8 <best_fit_pmm_manager+0x748>
ffffffffc0201792:	9bbfe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0201796:	bbf9                	j	ffffffffc0201574 <kmem_cache_alloc+0xbc>
        cprintf("  ✗ 缓存指针为空\n");
ffffffffc0201798:	00001517          	auipc	a0,0x1
ffffffffc020179c:	43050513          	addi	a0,a0,1072 # ffffffffc0202bc8 <best_fit_pmm_manager+0x468>
ffffffffc02017a0:	9adfe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc02017a4:	4901                	li	s2,0
ffffffffc02017a6:	b3f9                	j	ffffffffc0201574 <kmem_cache_alloc+0xbc>
        cprintf("  ✗ 分配Slab页失败\n");
ffffffffc02017a8:	00001517          	auipc	a0,0x1
ffffffffc02017ac:	54850513          	addi	a0,a0,1352 # ffffffffc0202cf0 <best_fit_pmm_manager+0x590>
ffffffffc02017b0:	99dfe0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (!slab) return NULL;
ffffffffc02017b4:	b3c1                	j	ffffffffc0201574 <kmem_cache_alloc+0xbc>
    slab_header_t *slab = (slab_header_t *)page2kva(page);
ffffffffc02017b6:	00001617          	auipc	a2,0x1
ffffffffc02017ba:	5b260613          	addi	a2,a2,1458 # ffffffffc0202d68 <best_fit_pmm_manager+0x608>
ffffffffc02017be:	07300593          	li	a1,115
ffffffffc02017c2:	00001517          	auipc	a0,0x1
ffffffffc02017c6:	5ce50513          	addi	a0,a0,1486 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc02017ca:	9f9fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02017ce <kmalloc>:
void *kmalloc(size_t size) {
ffffffffc02017ce:	7179                	addi	sp,sp,-48
ffffffffc02017d0:	e84a                	sd	s2,16(sp)
    cprintf("\n=== kmalloc请求: %u 字节 ===\n", (unsigned int)size);
ffffffffc02017d2:	0005091b          	sext.w	s2,a0
void *kmalloc(size_t size) {
ffffffffc02017d6:	ec26                	sd	s1,24(sp)
    cprintf("\n=== kmalloc请求: %u 字节 ===\n", (unsigned int)size);
ffffffffc02017d8:	85ca                	mv	a1,s2
void *kmalloc(size_t size) {
ffffffffc02017da:	84aa                	mv	s1,a0
    cprintf("\n=== kmalloc请求: %u 字节 ===\n", (unsigned int)size);
ffffffffc02017dc:	00001517          	auipc	a0,0x1
ffffffffc02017e0:	7f450513          	addi	a0,a0,2036 # ffffffffc0202fd0 <best_fit_pmm_manager+0x870>
void *kmalloc(size_t size) {
ffffffffc02017e4:	f406                	sd	ra,40(sp)
ffffffffc02017e6:	f022                	sd	s0,32(sp)
ffffffffc02017e8:	e44e                	sd	s3,8(sp)
    cprintf("\n=== kmalloc请求: %u 字节 ===\n", (unsigned int)size);
ffffffffc02017ea:	963fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (size == 0) {
ffffffffc02017ee:	0e048163          	beqz	s1,ffffffffc02018d0 <kmalloc+0x102>
    if (size > SLUB_MAX_OBJ_SIZE) {
ffffffffc02017f2:	6405                	lui	s0,0x1
ffffffffc02017f4:	0a947463          	bgeu	s0,s1,ffffffffc020189c <kmalloc+0xce>
        size_t page_count = (total_size + PGSIZE - 1) / PGSIZE;
ffffffffc02017f8:	045d                	addi	s0,s0,23
ffffffffc02017fa:	9426                	add	s0,s0,s1
ffffffffc02017fc:	8031                	srli	s0,s0,0xc
        cprintf("  大对象分配，使用物理页分配器\n");
ffffffffc02017fe:	00002517          	auipc	a0,0x2
ffffffffc0201802:	82250513          	addi	a0,a0,-2014 # ffffffffc0203020 <best_fit_pmm_manager+0x8c0>
ffffffffc0201806:	947fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  计算所需页数: %u 页 (总大小: %u)\n", 
ffffffffc020180a:	0004099b          	sext.w	s3,s0
ffffffffc020180e:	0184861b          	addiw	a2,s1,24
ffffffffc0201812:	85ce                	mv	a1,s3
ffffffffc0201814:	00002517          	auipc	a0,0x2
ffffffffc0201818:	83c50513          	addi	a0,a0,-1988 # ffffffffc0203050 <best_fit_pmm_manager+0x8f0>
ffffffffc020181c:	931fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        struct Page *page = alloc_pages(page_count);
ffffffffc0201820:	8522                	mv	a0,s0
ffffffffc0201822:	fb0ff0ef          	jal	ra,ffffffffc0200fd2 <alloc_pages>
ffffffffc0201826:	842a                	mv	s0,a0
        if (!page) {
ffffffffc0201828:	c561                	beqz	a0,ffffffffc02018f0 <kmalloc+0x122>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020182a:	00006697          	auipc	a3,0x6
ffffffffc020182e:	b266b683          	ld	a3,-1242(a3) # ffffffffc0207350 <pages>
ffffffffc0201832:	40d506b3          	sub	a3,a0,a3
ffffffffc0201836:	00002417          	auipc	s0,0x2
ffffffffc020183a:	0ba43403          	ld	s0,186(s0) # ffffffffc02038f0 <error_string+0x38>
ffffffffc020183e:	868d                	srai	a3,a3,0x3
ffffffffc0201840:	028686b3          	mul	a3,a3,s0
ffffffffc0201844:	00002417          	auipc	s0,0x2
ffffffffc0201848:	0b443403          	ld	s0,180(s0) # ffffffffc02038f8 <nbase>
        void *addr = page2kva(page);
ffffffffc020184c:	00006717          	auipc	a4,0x6
ffffffffc0201850:	afc73703          	ld	a4,-1284(a4) # ffffffffc0207348 <npage>
ffffffffc0201854:	96a2                	add	a3,a3,s0
ffffffffc0201856:	00c69793          	slli	a5,a3,0xc
ffffffffc020185a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020185c:	06b2                	slli	a3,a3,0xc
ffffffffc020185e:	0ae7f163          	bgeu	a5,a4,ffffffffc0201900 <kmalloc+0x132>
ffffffffc0201862:	00006797          	auipc	a5,0x6
ffffffffc0201866:	b0e7b783          	ld	a5,-1266(a5) # ffffffffc0207370 <va_pa_offset>
ffffffffc020186a:	96be                	add	a3,a3,a5
        void *obj_data = header + 1;
ffffffffc020186c:	01868413          	addi	s0,a3,24
        header->cache = NULL;  // 关键：大对象的cache设为NULL
ffffffffc0201870:	0006b023          	sd	zero,0(a3)
        header->obj_size = size;
ffffffffc0201874:	e684                	sd	s1,8(a3)
        header->slab = NULL;   // 关键：大对象的slab设为NULL
ffffffffc0201876:	0006b823          	sd	zero,16(a3)
        cprintf("  ✓ 大对象分配成功: size=%u, pages=%u, header=%p, data=%p\n", 
ffffffffc020187a:	8722                	mv	a4,s0
ffffffffc020187c:	864e                	mv	a2,s3
ffffffffc020187e:	85ca                	mv	a1,s2
ffffffffc0201880:	00002517          	auipc	a0,0x2
ffffffffc0201884:	82850513          	addi	a0,a0,-2008 # ffffffffc02030a8 <best_fit_pmm_manager+0x948>
ffffffffc0201888:	8c5fe0ef          	jal	ra,ffffffffc020014c <cprintf>
}
ffffffffc020188c:	70a2                	ld	ra,40(sp)
ffffffffc020188e:	8522                	mv	a0,s0
ffffffffc0201890:	7402                	ld	s0,32(sp)
ffffffffc0201892:	64e2                	ld	s1,24(sp)
ffffffffc0201894:	6942                	ld	s2,16(sp)
ffffffffc0201896:	69a2                	ld	s3,8(sp)
ffffffffc0201898:	6145                	addi	sp,sp,48
ffffffffc020189a:	8082                	ret
        cprintf("  小对象分配，查找合适缓存...\n");
ffffffffc020189c:	00002517          	auipc	a0,0x2
ffffffffc02018a0:	85450513          	addi	a0,a0,-1964 # ffffffffc02030f0 <best_fit_pmm_manager+0x990>
ffffffffc02018a4:	8a9fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        kmem_cache_t *cache = slub_find_cache(size);
ffffffffc02018a8:	8526                	mv	a0,s1
ffffffffc02018aa:	b55ff0ef          	jal	ra,ffffffffc02013fe <slub_find_cache>
ffffffffc02018ae:	842a                	mv	s0,a0
        if (!cache) {
ffffffffc02018b0:	c905                	beqz	a0,ffffffffc02018e0 <kmalloc+0x112>
        cprintf("  使用缓存: %s\n", cache->name);
ffffffffc02018b2:	85aa                	mv	a1,a0
ffffffffc02018b4:	00002517          	auipc	a0,0x2
ffffffffc02018b8:	89450513          	addi	a0,a0,-1900 # ffffffffc0203148 <best_fit_pmm_manager+0x9e8>
ffffffffc02018bc:	891fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return kmem_cache_alloc(cache);
ffffffffc02018c0:	8522                	mv	a0,s0
}
ffffffffc02018c2:	7402                	ld	s0,32(sp)
ffffffffc02018c4:	70a2                	ld	ra,40(sp)
ffffffffc02018c6:	64e2                	ld	s1,24(sp)
ffffffffc02018c8:	6942                	ld	s2,16(sp)
ffffffffc02018ca:	69a2                	ld	s3,8(sp)
ffffffffc02018cc:	6145                	addi	sp,sp,48
        return kmem_cache_alloc(cache);
ffffffffc02018ce:	b6ed                	j	ffffffffc02014b8 <kmem_cache_alloc>
        cprintf("  请求大小为0，返回NULL\n");
ffffffffc02018d0:	00001517          	auipc	a0,0x1
ffffffffc02018d4:	72850513          	addi	a0,a0,1832 # ffffffffc0202ff8 <best_fit_pmm_manager+0x898>
ffffffffc02018d8:	875fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc02018dc:	4401                	li	s0,0
ffffffffc02018de:	b77d                	j	ffffffffc020188c <kmalloc+0xbe>
            cprintf("  ✗ 找不到合适缓存: size=%u\n", (unsigned int)size);
ffffffffc02018e0:	85ca                	mv	a1,s2
ffffffffc02018e2:	00002517          	auipc	a0,0x2
ffffffffc02018e6:	83e50513          	addi	a0,a0,-1986 # ffffffffc0203120 <best_fit_pmm_manager+0x9c0>
ffffffffc02018ea:	863fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            return NULL;
ffffffffc02018ee:	bf79                	j	ffffffffc020188c <kmalloc+0xbe>
            cprintf("  ✗ 大对象分配失败: size=%u\n", (unsigned int)size);
ffffffffc02018f0:	85ca                	mv	a1,s2
ffffffffc02018f2:	00001517          	auipc	a0,0x1
ffffffffc02018f6:	78e50513          	addi	a0,a0,1934 # ffffffffc0203080 <best_fit_pmm_manager+0x920>
ffffffffc02018fa:	853fe0ef          	jal	ra,ffffffffc020014c <cprintf>
            return NULL;
ffffffffc02018fe:	b779                	j	ffffffffc020188c <kmalloc+0xbe>
        void *addr = page2kva(page);
ffffffffc0201900:	00001617          	auipc	a2,0x1
ffffffffc0201904:	46860613          	addi	a2,a2,1128 # ffffffffc0202d68 <best_fit_pmm_manager+0x608>
ffffffffc0201908:	13400593          	li	a1,308
ffffffffc020190c:	00001517          	auipc	a0,0x1
ffffffffc0201910:	48450513          	addi	a0,a0,1156 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201914:	8affe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201918 <kfree>:
void kfree(void *obj_data) {
ffffffffc0201918:	1101                	addi	sp,sp,-32
ffffffffc020191a:	e822                	sd	s0,16(sp)
    cprintf("\n=== kfree请求: 释放对象 %p ===\n", obj_data);
ffffffffc020191c:	85aa                	mv	a1,a0
void kfree(void *obj_data) {
ffffffffc020191e:	842a                	mv	s0,a0
    cprintf("\n=== kfree请求: 释放对象 %p ===\n", obj_data);
ffffffffc0201920:	00002517          	auipc	a0,0x2
ffffffffc0201924:	84050513          	addi	a0,a0,-1984 # ffffffffc0203160 <best_fit_pmm_manager+0xa00>
void kfree(void *obj_data) {
ffffffffc0201928:	ec06                	sd	ra,24(sp)
ffffffffc020192a:	e426                	sd	s1,8(sp)
ffffffffc020192c:	e04a                	sd	s2,0(sp)
    cprintf("\n=== kfree请求: 释放对象 %p ===\n", obj_data);
ffffffffc020192e:	81ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  对象指针为NULL，忽略\n");
ffffffffc0201932:	00002517          	auipc	a0,0x2
ffffffffc0201936:	85650513          	addi	a0,a0,-1962 # ffffffffc0203188 <best_fit_pmm_manager+0xa28>
    if (!obj_data) {
ffffffffc020193a:	10040c63          	beqz	s0,ffffffffc0201a52 <kfree+0x13a>
    cprintf("  对象头信息: cache=%p, slab=%p, obj_size=%u\n",
ffffffffc020193e:	ff042683          	lw	a3,-16(s0)
ffffffffc0201942:	ff843603          	ld	a2,-8(s0)
ffffffffc0201946:	fe843583          	ld	a1,-24(s0)
ffffffffc020194a:	00002517          	auipc	a0,0x2
ffffffffc020194e:	85e50513          	addi	a0,a0,-1954 # ffffffffc02031a8 <best_fit_pmm_manager+0xa48>
ffffffffc0201952:	ffafe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (header->cache == NULL && header->slab == NULL) {
ffffffffc0201956:	fe843783          	ld	a5,-24(s0)
ffffffffc020195a:	cfb9                	beqz	a5,ffffffffc02019b8 <kfree+0xa0>
    cprintf("  SLUB对象释放\n");
ffffffffc020195c:	00002517          	auipc	a0,0x2
ffffffffc0201960:	95c50513          	addi	a0,a0,-1700 # ffffffffc02032b8 <best_fit_pmm_manager+0xb58>
ffffffffc0201964:	fe8fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    if (header->cache != NULL) {
ffffffffc0201968:	fe843583          	ld	a1,-24(s0)
ffffffffc020196c:	0e058a63          	beqz	a1,ffffffffc0201a60 <kfree+0x148>
        cprintf("  找到所属缓存: %s\n", header->cache->name);
ffffffffc0201970:	00002517          	auipc	a0,0x2
ffffffffc0201974:	96050513          	addi	a0,a0,-1696 # ffffffffc02032d0 <best_fit_pmm_manager+0xb70>
ffffffffc0201978:	fd4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        kmem_cache_free(header->cache, obj_data);
ffffffffc020197c:	fe843483          	ld	s1,-24(s0)
    cprintf("\n=== kmem_cache_free: 释放对象到缓存 %s ===\n", cache->name);
ffffffffc0201980:	00001517          	auipc	a0,0x1
ffffffffc0201984:	5d850513          	addi	a0,a0,1496 # ffffffffc0202f58 <best_fit_pmm_manager+0x7f8>
ffffffffc0201988:	85a6                	mv	a1,s1
ffffffffc020198a:	fc2fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  释放对象: %p\n", obj_data);
ffffffffc020198e:	85a2                	mv	a1,s0
ffffffffc0201990:	00001517          	auipc	a0,0x1
ffffffffc0201994:	60050513          	addi	a0,a0,1536 # ffffffffc0202f90 <best_fit_pmm_manager+0x830>
ffffffffc0201998:	fb4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  ✗ 缓存或对象指针为空\n");
ffffffffc020199c:	00001517          	auipc	a0,0x1
ffffffffc02019a0:	60c50513          	addi	a0,a0,1548 # ffffffffc0202fa8 <best_fit_pmm_manager+0x848>
    if (!cache || !obj_data) {
ffffffffc02019a4:	c4dd                	beqz	s1,ffffffffc0201a52 <kfree+0x13a>
ffffffffc02019a6:	85a2                	mv	a1,s0
}
ffffffffc02019a8:	6442                	ld	s0,16(sp)
ffffffffc02019aa:	60e2                	ld	ra,24(sp)
ffffffffc02019ac:	6902                	ld	s2,0(sp)
ffffffffc02019ae:	8526                	mv	a0,s1
ffffffffc02019b0:	64a2                	ld	s1,8(sp)
ffffffffc02019b2:	6105                	addi	sp,sp,32
ffffffffc02019b4:	897ff06f          	j	ffffffffc020124a <kmem_cache_free.part.0>
    if (header->cache == NULL && header->slab == NULL) {
ffffffffc02019b8:	ff843783          	ld	a5,-8(s0)
ffffffffc02019bc:	f3c5                	bnez	a5,ffffffffc020195c <kfree+0x44>
        cprintf("  大对象释放\n");
ffffffffc02019be:	00002517          	auipc	a0,0x2
ffffffffc02019c2:	82250513          	addi	a0,a0,-2014 # ffffffffc02031e0 <best_fit_pmm_manager+0xa80>
ffffffffc02019c6:	f86fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        size_t total_size = sizeof(obj_header_t) + header->obj_size;
ffffffffc02019ca:	ff043583          	ld	a1,-16(s0)
        size_t page_count = (total_size + PGSIZE - 1) / PGSIZE;
ffffffffc02019ce:	6485                	lui	s1,0x1
ffffffffc02019d0:	04dd                	addi	s1,s1,23
ffffffffc02019d2:	94ae                	add	s1,s1,a1
ffffffffc02019d4:	80b1                	srli	s1,s1,0xc
        cprintf("  大对象信息: 总大小=%u, 页数=%u\n", 
ffffffffc02019d6:	0004891b          	sext.w	s2,s1
ffffffffc02019da:	864a                	mv	a2,s2
ffffffffc02019dc:	25e1                	addiw	a1,a1,24
ffffffffc02019de:	00002517          	auipc	a0,0x2
ffffffffc02019e2:	81a50513          	addi	a0,a0,-2022 # ffffffffc02031f8 <best_fit_pmm_manager+0xa98>
ffffffffc02019e6:	f66fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    obj_header_t *header = (obj_header_t *)obj_data - 1;
ffffffffc02019ea:	1421                	addi	s0,s0,-24
        struct Page *page = kva2page(header);
ffffffffc02019ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02019f0:	0af46063          	bltu	s0,a5,ffffffffc0201a90 <kfree+0x178>
ffffffffc02019f4:	00006697          	auipc	a3,0x6
ffffffffc02019f8:	97c6b683          	ld	a3,-1668(a3) # ffffffffc0207370 <va_pa_offset>
ffffffffc02019fc:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc02019fe:	8031                	srli	s0,s0,0xc
ffffffffc0201a00:	00006797          	auipc	a5,0x6
ffffffffc0201a04:	9487b783          	ld	a5,-1720(a5) # ffffffffc0207348 <npage>
ffffffffc0201a08:	06f47863          	bgeu	s0,a5,ffffffffc0201a78 <kfree+0x160>
    return &pages[PPN(pa) - nbase];
ffffffffc0201a0c:	00002797          	auipc	a5,0x2
ffffffffc0201a10:	eec7b783          	ld	a5,-276(a5) # ffffffffc02038f8 <nbase>
ffffffffc0201a14:	8c1d                	sub	s0,s0,a5
ffffffffc0201a16:	00241793          	slli	a5,s0,0x2
ffffffffc0201a1a:	943e                	add	s0,s0,a5
ffffffffc0201a1c:	040e                	slli	s0,s0,0x3
ffffffffc0201a1e:	00006797          	auipc	a5,0x6
ffffffffc0201a22:	9327b783          	ld	a5,-1742(a5) # ffffffffc0207350 <pages>
ffffffffc0201a26:	943e                	add	s0,s0,a5
            cprintf("  ✗ 大对象释放失败: 无法找到对应的物理页\n");
ffffffffc0201a28:	00002517          	auipc	a0,0x2
ffffffffc0201a2c:	85050513          	addi	a0,a0,-1968 # ffffffffc0203278 <best_fit_pmm_manager+0xb18>
        if (page) {
ffffffffc0201a30:	c00d                	beqz	s0,ffffffffc0201a52 <kfree+0x13a>
            cprintf("  找到对应物理页: %p, 释放 %u 页\n", 
ffffffffc0201a32:	864a                	mv	a2,s2
ffffffffc0201a34:	85a2                	mv	a1,s0
ffffffffc0201a36:	00001517          	auipc	a0,0x1
ffffffffc0201a3a:	7f250513          	addi	a0,a0,2034 # ffffffffc0203228 <best_fit_pmm_manager+0xac8>
ffffffffc0201a3e:	f0efe0ef          	jal	ra,ffffffffc020014c <cprintf>
            free_pages(page, page_count);
ffffffffc0201a42:	8522                	mv	a0,s0
ffffffffc0201a44:	85a6                	mv	a1,s1
ffffffffc0201a46:	d98ff0ef          	jal	ra,ffffffffc0200fde <free_pages>
            cprintf("  ✓ 大对象释放完成\n");
ffffffffc0201a4a:	00002517          	auipc	a0,0x2
ffffffffc0201a4e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0203258 <best_fit_pmm_manager+0xaf8>
}
ffffffffc0201a52:	6442                	ld	s0,16(sp)
ffffffffc0201a54:	60e2                	ld	ra,24(sp)
ffffffffc0201a56:	64a2                	ld	s1,8(sp)
ffffffffc0201a58:	6902                	ld	s2,0(sp)
ffffffffc0201a5a:	6105                	addi	sp,sp,32
            cprintf("  ✓ 大对象释放完成\n");
ffffffffc0201a5c:	ef0fe06f          	j	ffffffffc020014c <cprintf>
        cprintf("  ✗ SLUB警告: 无法释放未知对象 %p\n", obj_data);
ffffffffc0201a60:	85a2                	mv	a1,s0
}
ffffffffc0201a62:	6442                	ld	s0,16(sp)
ffffffffc0201a64:	60e2                	ld	ra,24(sp)
ffffffffc0201a66:	64a2                	ld	s1,8(sp)
ffffffffc0201a68:	6902                	ld	s2,0(sp)
        cprintf("  ✗ SLUB警告: 无法释放未知对象 %p\n", obj_data);
ffffffffc0201a6a:	00002517          	auipc	a0,0x2
ffffffffc0201a6e:	88650513          	addi	a0,a0,-1914 # ffffffffc02032f0 <best_fit_pmm_manager+0xb90>
}
ffffffffc0201a72:	6105                	addi	sp,sp,32
        cprintf("  ✗ SLUB警告: 无法释放未知对象 %p\n", obj_data);
ffffffffc0201a74:	ed8fe06f          	j	ffffffffc020014c <cprintf>
        panic("pa2page called with invalid pa");
ffffffffc0201a78:	00001617          	auipc	a2,0x1
ffffffffc0201a7c:	dd860613          	addi	a2,a2,-552 # ffffffffc0202850 <best_fit_pmm_manager+0xf0>
ffffffffc0201a80:	07000593          	li	a1,112
ffffffffc0201a84:	00001517          	auipc	a0,0x1
ffffffffc0201a88:	dec50513          	addi	a0,a0,-532 # ffffffffc0202870 <best_fit_pmm_manager+0x110>
ffffffffc0201a8c:	f36fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        struct Page *page = kva2page(header);
ffffffffc0201a90:	86a2                	mv	a3,s0
ffffffffc0201a92:	00001617          	auipc	a2,0x1
ffffffffc0201a96:	d9660613          	addi	a2,a2,-618 # ffffffffc0202828 <best_fit_pmm_manager+0xc8>
ffffffffc0201a9a:	16700593          	li	a1,359
ffffffffc0201a9e:	00001517          	auipc	a0,0x1
ffffffffc0201aa2:	2f250513          	addi	a0,a0,754 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201aa6:	f1cfe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201aaa <test_basic_functionality>:

void test_basic_functionality(void) {
ffffffffc0201aaa:	1101                	addi	sp,sp,-32
    print_separator("测试1: 基本功能测试");
ffffffffc0201aac:	00002517          	auipc	a0,0x2
ffffffffc0201ab0:	87450513          	addi	a0,a0,-1932 # ffffffffc0203320 <best_fit_pmm_manager+0xbc0>
void test_basic_functionality(void) {
ffffffffc0201ab4:	ec06                	sd	ra,24(sp)
ffffffffc0201ab6:	e822                	sd	s0,16(sp)
ffffffffc0201ab8:	e426                	sd	s1,8(sp)
ffffffffc0201aba:	e04a                	sd	s2,0(sp)
    print_separator("测试1: 基本功能测试");
ffffffffc0201abc:	f26ff0ef          	jal	ra,ffffffffc02011e2 <print_separator>
    
    cprintf("\n1. 分配32字节对象:\n");
ffffffffc0201ac0:	00002517          	auipc	a0,0x2
ffffffffc0201ac4:	88050513          	addi	a0,a0,-1920 # ffffffffc0203340 <best_fit_pmm_manager+0xbe0>
ffffffffc0201ac8:	e84fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *ptr1 = kmalloc(32);
ffffffffc0201acc:	02000513          	li	a0,32
ffffffffc0201ad0:	cffff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
    assert(ptr1 != NULL);
ffffffffc0201ad4:	c525                	beqz	a0,ffffffffc0201b3c <test_basic_functionality+0x92>
ffffffffc0201ad6:	842a                	mv	s0,a0
    
    cprintf("\n2. 分配64字节对象:\n");
ffffffffc0201ad8:	00002517          	auipc	a0,0x2
ffffffffc0201adc:	89850513          	addi	a0,a0,-1896 # ffffffffc0203370 <best_fit_pmm_manager+0xc10>
ffffffffc0201ae0:	e6cfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *ptr2 = kmalloc(64);
ffffffffc0201ae4:	04000513          	li	a0,64
ffffffffc0201ae8:	ce7ff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201aec:	892a                	mv	s2,a0
    assert(ptr2 != NULL);
ffffffffc0201aee:	c559                	beqz	a0,ffffffffc0201b7c <test_basic_functionality+0xd2>
    
    cprintf("\n3. 分配128字节对象:\n");
ffffffffc0201af0:	00002517          	auipc	a0,0x2
ffffffffc0201af4:	8b050513          	addi	a0,a0,-1872 # ffffffffc02033a0 <best_fit_pmm_manager+0xc40>
ffffffffc0201af8:	e54fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *ptr3 = kmalloc(128);
ffffffffc0201afc:	08000513          	li	a0,128
ffffffffc0201b00:	ccfff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201b04:	84aa                	mv	s1,a0
    assert(ptr3 != NULL);
ffffffffc0201b06:	c939                	beqz	a0,ffffffffc0201b5c <test_basic_functionality+0xb2>
    
    cprintf("\n4. 释放对象:\n");
ffffffffc0201b08:	00002517          	auipc	a0,0x2
ffffffffc0201b0c:	8c850513          	addi	a0,a0,-1848 # ffffffffc02033d0 <best_fit_pmm_manager+0xc70>
ffffffffc0201b10:	e3cfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    kfree(ptr1);
ffffffffc0201b14:	8522                	mv	a0,s0
ffffffffc0201b16:	e03ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    kfree(ptr2);
ffffffffc0201b1a:	854a                	mv	a0,s2
ffffffffc0201b1c:	dfdff0ef          	jal	ra,ffffffffc0201918 <kfree>
    kfree(ptr3);
ffffffffc0201b20:	8526                	mv	a0,s1
ffffffffc0201b22:	df7ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    
    cprintf("基本功能测试通过\n");
}
ffffffffc0201b26:	6442                	ld	s0,16(sp)
ffffffffc0201b28:	60e2                	ld	ra,24(sp)
ffffffffc0201b2a:	64a2                	ld	s1,8(sp)
ffffffffc0201b2c:	6902                	ld	s2,0(sp)
    cprintf("基本功能测试通过\n");
ffffffffc0201b2e:	00002517          	auipc	a0,0x2
ffffffffc0201b32:	8ba50513          	addi	a0,a0,-1862 # ffffffffc02033e8 <best_fit_pmm_manager+0xc88>
}
ffffffffc0201b36:	6105                	addi	sp,sp,32
    cprintf("基本功能测试通过\n");
ffffffffc0201b38:	e14fe06f          	j	ffffffffc020014c <cprintf>
    assert(ptr1 != NULL);
ffffffffc0201b3c:	00002697          	auipc	a3,0x2
ffffffffc0201b40:	82468693          	addi	a3,a3,-2012 # ffffffffc0203360 <best_fit_pmm_manager+0xc00>
ffffffffc0201b44:	00001617          	auipc	a2,0x1
ffffffffc0201b48:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0202420 <etext+0x26c>
ffffffffc0201b4c:	18c00593          	li	a1,396
ffffffffc0201b50:	00001517          	auipc	a0,0x1
ffffffffc0201b54:	24050513          	addi	a0,a0,576 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201b58:	e6afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(ptr3 != NULL);
ffffffffc0201b5c:	00002697          	auipc	a3,0x2
ffffffffc0201b60:	86468693          	addi	a3,a3,-1948 # ffffffffc02033c0 <best_fit_pmm_manager+0xc60>
ffffffffc0201b64:	00001617          	auipc	a2,0x1
ffffffffc0201b68:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0202420 <etext+0x26c>
ffffffffc0201b6c:	19400593          	li	a1,404
ffffffffc0201b70:	00001517          	auipc	a0,0x1
ffffffffc0201b74:	22050513          	addi	a0,a0,544 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201b78:	e4afe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(ptr2 != NULL);
ffffffffc0201b7c:	00002697          	auipc	a3,0x2
ffffffffc0201b80:	81468693          	addi	a3,a3,-2028 # ffffffffc0203390 <best_fit_pmm_manager+0xc30>
ffffffffc0201b84:	00001617          	auipc	a2,0x1
ffffffffc0201b88:	89c60613          	addi	a2,a2,-1892 # ffffffffc0202420 <etext+0x26c>
ffffffffc0201b8c:	19000593          	li	a1,400
ffffffffc0201b90:	00001517          	auipc	a0,0x1
ffffffffc0201b94:	20050513          	addi	a0,a0,512 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201b98:	e2afe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201b9c <test_boundary_conditions>:

void test_boundary_conditions(void) {
ffffffffc0201b9c:	1101                	addi	sp,sp,-32
    print_separator("测试2: 边界条件测试");
ffffffffc0201b9e:	00002517          	auipc	a0,0x2
ffffffffc0201ba2:	86a50513          	addi	a0,a0,-1942 # ffffffffc0203408 <best_fit_pmm_manager+0xca8>
void test_boundary_conditions(void) {
ffffffffc0201ba6:	ec06                	sd	ra,24(sp)
ffffffffc0201ba8:	e822                	sd	s0,16(sp)
ffffffffc0201baa:	e426                	sd	s1,8(sp)
ffffffffc0201bac:	e04a                	sd	s2,0(sp)
    print_separator("测试2: 边界条件测试");
ffffffffc0201bae:	e34ff0ef          	jal	ra,ffffffffc02011e2 <print_separator>
    
    cprintf("\n1. 测试极小对象(1B, 8B):\n");
ffffffffc0201bb2:	00002517          	auipc	a0,0x2
ffffffffc0201bb6:	87650513          	addi	a0,a0,-1930 # ffffffffc0203428 <best_fit_pmm_manager+0xcc8>
ffffffffc0201bba:	d92fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *tiny1 = kmalloc(1);
ffffffffc0201bbe:	4505                	li	a0,1
ffffffffc0201bc0:	c0fff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201bc4:	84aa                	mv	s1,a0
    void *tiny2 = kmalloc(8);
ffffffffc0201bc6:	4521                	li	a0,8
ffffffffc0201bc8:	c07ff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201bcc:	842a                	mv	s0,a0
    kfree(tiny1);
ffffffffc0201bce:	8526                	mv	a0,s1
ffffffffc0201bd0:	d49ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    kfree(tiny2);
ffffffffc0201bd4:	8522                	mv	a0,s0
ffffffffc0201bd6:	d43ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    
    cprintf("\n2. 测试边界大小(1023B, 1024B, 1025B):\n");
ffffffffc0201bda:	00002517          	auipc	a0,0x2
ffffffffc0201bde:	87650513          	addi	a0,a0,-1930 # ffffffffc0203450 <best_fit_pmm_manager+0xcf0>
ffffffffc0201be2:	d6afe0ef          	jal	ra,ffffffffc020014c <cprintf>
    void *b1 = kmalloc(1023);
ffffffffc0201be6:	3ff00513          	li	a0,1023
ffffffffc0201bea:	be5ff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201bee:	892a                	mv	s2,a0
    void *b2 = kmalloc(1024);
ffffffffc0201bf0:	40000513          	li	a0,1024
ffffffffc0201bf4:	bdbff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201bf8:	84aa                	mv	s1,a0
    void *b3 = kmalloc(1025);
ffffffffc0201bfa:	40100513          	li	a0,1025
ffffffffc0201bfe:	bd1ff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201c02:	842a                	mv	s0,a0
    kfree(b1);
ffffffffc0201c04:	854a                	mv	a0,s2
ffffffffc0201c06:	d13ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    kfree(b2);
ffffffffc0201c0a:	8526                	mv	a0,s1
ffffffffc0201c0c:	d0dff0ef          	jal	ra,ffffffffc0201918 <kfree>
    kfree(b3);
ffffffffc0201c10:	8522                	mv	a0,s0
ffffffffc0201c12:	d07ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    
    cprintf("边界条件测试通过\n");
}
ffffffffc0201c16:	6442                	ld	s0,16(sp)
ffffffffc0201c18:	60e2                	ld	ra,24(sp)
ffffffffc0201c1a:	64a2                	ld	s1,8(sp)
ffffffffc0201c1c:	6902                	ld	s2,0(sp)
    cprintf("边界条件测试通过\n");
ffffffffc0201c1e:	00002517          	auipc	a0,0x2
ffffffffc0201c22:	86250513          	addi	a0,a0,-1950 # ffffffffc0203480 <best_fit_pmm_manager+0xd20>
}
ffffffffc0201c26:	6105                	addi	sp,sp,32
    cprintf("边界条件测试通过\n");
ffffffffc0201c28:	d24fe06f          	j	ffffffffc020014c <cprintf>

ffffffffc0201c2c <test_bulk_operations>:

void test_bulk_operations(void) {
ffffffffc0201c2c:	7119                	addi	sp,sp,-128
    print_separator("测试3: 批量操作测试");
ffffffffc0201c2e:	00002517          	auipc	a0,0x2
ffffffffc0201c32:	87250513          	addi	a0,a0,-1934 # ffffffffc02034a0 <best_fit_pmm_manager+0xd40>
void test_bulk_operations(void) {
ffffffffc0201c36:	fc86                	sd	ra,120(sp)
ffffffffc0201c38:	f8a2                	sd	s0,112(sp)
ffffffffc0201c3a:	f4a6                	sd	s1,104(sp)
ffffffffc0201c3c:	f0ca                	sd	s2,96(sp)
ffffffffc0201c3e:	ecce                	sd	s3,88(sp)
ffffffffc0201c40:	e8d2                	sd	s4,80(sp)
    print_separator("测试3: 批量操作测试");
ffffffffc0201c42:	da0ff0ef          	jal	ra,ffffffffc02011e2 <print_separator>
    
    cprintf("\n1. 批量相同大小对象:\n");
ffffffffc0201c46:	00002517          	auipc	a0,0x2
ffffffffc0201c4a:	87a50513          	addi	a0,a0,-1926 # ffffffffc02034c0 <best_fit_pmm_manager+0xd60>
ffffffffc0201c4e:	848a                	mv	s1,sp
ffffffffc0201c50:	cfcfe0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201c54:	8926                	mv	s2,s1
    const int NUM_OBJECTS = 10;  // 减少数量以便观察
    void *objects[NUM_OBJECTS];
    
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201c56:	4401                	li	s0,0
        cprintf("\n--- 分配第%d个对象 ---\n", i + 1);
ffffffffc0201c58:	00002997          	auipc	s3,0x2
ffffffffc0201c5c:	88898993          	addi	s3,s3,-1912 # ffffffffc02034e0 <best_fit_pmm_manager+0xd80>
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201c60:	4a29                	li	s4,10
        cprintf("\n--- 分配第%d个对象 ---\n", i + 1);
ffffffffc0201c62:	2405                	addiw	s0,s0,1
ffffffffc0201c64:	85a2                	mv	a1,s0
ffffffffc0201c66:	854e                	mv	a0,s3
ffffffffc0201c68:	ce4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
        objects[i] = kmalloc(64);
ffffffffc0201c6c:	04000513          	li	a0,64
ffffffffc0201c70:	b5fff0ef          	jal	ra,ffffffffc02017ce <kmalloc>
ffffffffc0201c74:	00a93023          	sd	a0,0(s2)
        assert(objects[i] != NULL);
ffffffffc0201c78:	c921                	beqz	a0,ffffffffc0201cc8 <test_bulk_operations+0x9c>
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201c7a:	0921                	addi	s2,s2,8
ffffffffc0201c7c:	ff4413e3          	bne	s0,s4,ffffffffc0201c62 <test_bulk_operations+0x36>
    }
    
    cprintf("\n2. 批量释放对象:\n");
ffffffffc0201c80:	00002517          	auipc	a0,0x2
ffffffffc0201c84:	89850513          	addi	a0,a0,-1896 # ffffffffc0203518 <best_fit_pmm_manager+0xdb8>
ffffffffc0201c88:	cc4fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201c8c:	4401                	li	s0,0
        cprintf("\n--- 释放第%d个对象 ---\n", i + 1);
ffffffffc0201c8e:	00002997          	auipc	s3,0x2
ffffffffc0201c92:	8aa98993          	addi	s3,s3,-1878 # ffffffffc0203538 <best_fit_pmm_manager+0xdd8>
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201c96:	4929                	li	s2,10
        cprintf("\n--- 释放第%d个对象 ---\n", i + 1);
ffffffffc0201c98:	2405                	addiw	s0,s0,1
ffffffffc0201c9a:	85a2                	mv	a1,s0
ffffffffc0201c9c:	854e                	mv	a0,s3
ffffffffc0201c9e:	caefe0ef          	jal	ra,ffffffffc020014c <cprintf>
        kfree(objects[i]);
ffffffffc0201ca2:	6088                	ld	a0,0(s1)
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201ca4:	04a1                	addi	s1,s1,8
        kfree(objects[i]);
ffffffffc0201ca6:	c73ff0ef          	jal	ra,ffffffffc0201918 <kfree>
    for (int i = 0; i < NUM_OBJECTS; i++) {
ffffffffc0201caa:	ff2417e3          	bne	s0,s2,ffffffffc0201c98 <test_bulk_operations+0x6c>
    }
    
    cprintf("批量操作测试通过\n");
}
ffffffffc0201cae:	7446                	ld	s0,112(sp)
ffffffffc0201cb0:	70e6                	ld	ra,120(sp)
ffffffffc0201cb2:	74a6                	ld	s1,104(sp)
ffffffffc0201cb4:	7906                	ld	s2,96(sp)
ffffffffc0201cb6:	69e6                	ld	s3,88(sp)
ffffffffc0201cb8:	6a46                	ld	s4,80(sp)
    cprintf("批量操作测试通过\n");
ffffffffc0201cba:	00002517          	auipc	a0,0x2
ffffffffc0201cbe:	89e50513          	addi	a0,a0,-1890 # ffffffffc0203558 <best_fit_pmm_manager+0xdf8>
}
ffffffffc0201cc2:	6109                	addi	sp,sp,128
    cprintf("批量操作测试通过\n");
ffffffffc0201cc4:	c88fe06f          	j	ffffffffc020014c <cprintf>
        assert(objects[i] != NULL);
ffffffffc0201cc8:	00002697          	auipc	a3,0x2
ffffffffc0201ccc:	83868693          	addi	a3,a3,-1992 # ffffffffc0203500 <best_fit_pmm_manager+0xda0>
ffffffffc0201cd0:	00000617          	auipc	a2,0x0
ffffffffc0201cd4:	75060613          	addi	a2,a2,1872 # ffffffffc0202420 <etext+0x26c>
ffffffffc0201cd8:	1bc00593          	li	a1,444
ffffffffc0201cdc:	00001517          	auipc	a0,0x1
ffffffffc0201ce0:	0b450513          	addi	a0,a0,180 # ffffffffc0202d90 <best_fit_pmm_manager+0x630>
ffffffffc0201ce4:	cdefe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201ce8 <run_slub_tests>:

// 主测试函数
void run_slub_tests(void) {
ffffffffc0201ce8:	1141                	addi	sp,sp,-16
    cprintf("\n\n");
ffffffffc0201cea:	00002517          	auipc	a0,0x2
ffffffffc0201cee:	88e50513          	addi	a0,a0,-1906 # ffffffffc0203578 <best_fit_pmm_manager+0xe18>
void run_slub_tests(void) {
ffffffffc0201cf2:	e406                	sd	ra,8(sp)
    cprintf("\n\n");
ffffffffc0201cf4:	c58fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    print_separator("开始 SLUB 分配器测试");
ffffffffc0201cf8:	00002517          	auipc	a0,0x2
ffffffffc0201cfc:	88850513          	addi	a0,a0,-1912 # ffffffffc0203580 <best_fit_pmm_manager+0xe20>
ffffffffc0201d00:	ce2ff0ef          	jal	ra,ffffffffc02011e2 <print_separator>
    // 运行各个测试
    test_basic_functionality();
ffffffffc0201d04:	da7ff0ef          	jal	ra,ffffffffc0201aaa <test_basic_functionality>
    test_boundary_conditions();
ffffffffc0201d08:	e95ff0ef          	jal	ra,ffffffffc0201b9c <test_boundary_conditions>
    test_bulk_operations();
ffffffffc0201d0c:	f21ff0ef          	jal	ra,ffffffffc0201c2c <test_bulk_operations>
    
    print_separator("所有 SLUB 测试完成");
}
ffffffffc0201d10:	60a2                	ld	ra,8(sp)
    print_separator("所有 SLUB 测试完成");
ffffffffc0201d12:	00002517          	auipc	a0,0x2
ffffffffc0201d16:	88e50513          	addi	a0,a0,-1906 # ffffffffc02035a0 <best_fit_pmm_manager+0xe40>
}
ffffffffc0201d1a:	0141                	addi	sp,sp,16
    print_separator("所有 SLUB 测试完成");
ffffffffc0201d1c:	cc6ff06f          	j	ffffffffc02011e2 <print_separator>

ffffffffc0201d20 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201d20:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201d24:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201d26:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201d2a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201d2c:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201d30:	f022                	sd	s0,32(sp)
ffffffffc0201d32:	ec26                	sd	s1,24(sp)
ffffffffc0201d34:	e84a                	sd	s2,16(sp)
ffffffffc0201d36:	f406                	sd	ra,40(sp)
ffffffffc0201d38:	e44e                	sd	s3,8(sp)
ffffffffc0201d3a:	84aa                	mv	s1,a0
ffffffffc0201d3c:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201d3e:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201d42:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201d44:	03067e63          	bgeu	a2,a6,ffffffffc0201d80 <printnum+0x60>
ffffffffc0201d48:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201d4a:	00805763          	blez	s0,ffffffffc0201d58 <printnum+0x38>
ffffffffc0201d4e:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201d50:	85ca                	mv	a1,s2
ffffffffc0201d52:	854e                	mv	a0,s3
ffffffffc0201d54:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201d56:	fc65                	bnez	s0,ffffffffc0201d4e <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d58:	1a02                	slli	s4,s4,0x20
ffffffffc0201d5a:	00002797          	auipc	a5,0x2
ffffffffc0201d5e:	94e78793          	addi	a5,a5,-1714 # ffffffffc02036a8 <slub_size_classes+0x40>
ffffffffc0201d62:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201d66:	9a3e                	add	s4,s4,a5
}
ffffffffc0201d68:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d6a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201d6e:	70a2                	ld	ra,40(sp)
ffffffffc0201d70:	69a2                	ld	s3,8(sp)
ffffffffc0201d72:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d74:	85ca                	mv	a1,s2
ffffffffc0201d76:	87a6                	mv	a5,s1
}
ffffffffc0201d78:	6942                	ld	s2,16(sp)
ffffffffc0201d7a:	64e2                	ld	s1,24(sp)
ffffffffc0201d7c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201d7e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201d80:	03065633          	divu	a2,a2,a6
ffffffffc0201d84:	8722                	mv	a4,s0
ffffffffc0201d86:	f9bff0ef          	jal	ra,ffffffffc0201d20 <printnum>
ffffffffc0201d8a:	b7f9                	j	ffffffffc0201d58 <printnum+0x38>

ffffffffc0201d8c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201d8c:	7119                	addi	sp,sp,-128
ffffffffc0201d8e:	f4a6                	sd	s1,104(sp)
ffffffffc0201d90:	f0ca                	sd	s2,96(sp)
ffffffffc0201d92:	ecce                	sd	s3,88(sp)
ffffffffc0201d94:	e8d2                	sd	s4,80(sp)
ffffffffc0201d96:	e4d6                	sd	s5,72(sp)
ffffffffc0201d98:	e0da                	sd	s6,64(sp)
ffffffffc0201d9a:	fc5e                	sd	s7,56(sp)
ffffffffc0201d9c:	f06a                	sd	s10,32(sp)
ffffffffc0201d9e:	fc86                	sd	ra,120(sp)
ffffffffc0201da0:	f8a2                	sd	s0,112(sp)
ffffffffc0201da2:	f862                	sd	s8,48(sp)
ffffffffc0201da4:	f466                	sd	s9,40(sp)
ffffffffc0201da6:	ec6e                	sd	s11,24(sp)
ffffffffc0201da8:	892a                	mv	s2,a0
ffffffffc0201daa:	84ae                	mv	s1,a1
ffffffffc0201dac:	8d32                	mv	s10,a2
ffffffffc0201dae:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201db0:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201db4:	5b7d                	li	s6,-1
ffffffffc0201db6:	00002a97          	auipc	s5,0x2
ffffffffc0201dba:	926a8a93          	addi	s5,s5,-1754 # ffffffffc02036dc <slub_size_classes+0x74>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201dbe:	00002b97          	auipc	s7,0x2
ffffffffc0201dc2:	afab8b93          	addi	s7,s7,-1286 # ffffffffc02038b8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201dc6:	000d4503          	lbu	a0,0(s10)
ffffffffc0201dca:	001d0413          	addi	s0,s10,1
ffffffffc0201dce:	01350a63          	beq	a0,s3,ffffffffc0201de2 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201dd2:	c121                	beqz	a0,ffffffffc0201e12 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201dd4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201dd6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201dd8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201dda:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201dde:	ff351ae3          	bne	a0,s3,ffffffffc0201dd2 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201de2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201de6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201dea:	4c81                	li	s9,0
ffffffffc0201dec:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201dee:	5c7d                	li	s8,-1
ffffffffc0201df0:	5dfd                	li	s11,-1
ffffffffc0201df2:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201df6:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201df8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201dfc:	0ff5f593          	zext.b	a1,a1
ffffffffc0201e00:	00140d13          	addi	s10,s0,1
ffffffffc0201e04:	04b56263          	bltu	a0,a1,ffffffffc0201e48 <vprintfmt+0xbc>
ffffffffc0201e08:	058a                	slli	a1,a1,0x2
ffffffffc0201e0a:	95d6                	add	a1,a1,s5
ffffffffc0201e0c:	4194                	lw	a3,0(a1)
ffffffffc0201e0e:	96d6                	add	a3,a3,s5
ffffffffc0201e10:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201e12:	70e6                	ld	ra,120(sp)
ffffffffc0201e14:	7446                	ld	s0,112(sp)
ffffffffc0201e16:	74a6                	ld	s1,104(sp)
ffffffffc0201e18:	7906                	ld	s2,96(sp)
ffffffffc0201e1a:	69e6                	ld	s3,88(sp)
ffffffffc0201e1c:	6a46                	ld	s4,80(sp)
ffffffffc0201e1e:	6aa6                	ld	s5,72(sp)
ffffffffc0201e20:	6b06                	ld	s6,64(sp)
ffffffffc0201e22:	7be2                	ld	s7,56(sp)
ffffffffc0201e24:	7c42                	ld	s8,48(sp)
ffffffffc0201e26:	7ca2                	ld	s9,40(sp)
ffffffffc0201e28:	7d02                	ld	s10,32(sp)
ffffffffc0201e2a:	6de2                	ld	s11,24(sp)
ffffffffc0201e2c:	6109                	addi	sp,sp,128
ffffffffc0201e2e:	8082                	ret
            padc = '0';
ffffffffc0201e30:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201e32:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e36:	846a                	mv	s0,s10
ffffffffc0201e38:	00140d13          	addi	s10,s0,1
ffffffffc0201e3c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201e40:	0ff5f593          	zext.b	a1,a1
ffffffffc0201e44:	fcb572e3          	bgeu	a0,a1,ffffffffc0201e08 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201e48:	85a6                	mv	a1,s1
ffffffffc0201e4a:	02500513          	li	a0,37
ffffffffc0201e4e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201e50:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201e54:	8d22                	mv	s10,s0
ffffffffc0201e56:	f73788e3          	beq	a5,s3,ffffffffc0201dc6 <vprintfmt+0x3a>
ffffffffc0201e5a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201e5e:	1d7d                	addi	s10,s10,-1
ffffffffc0201e60:	ff379de3          	bne	a5,s3,ffffffffc0201e5a <vprintfmt+0xce>
ffffffffc0201e64:	b78d                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201e66:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201e6a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201e6e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201e70:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201e74:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201e78:	02d86463          	bltu	a6,a3,ffffffffc0201ea0 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201e7c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201e80:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201e84:	0186873b          	addw	a4,a3,s8
ffffffffc0201e88:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201e8c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201e8e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201e92:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201e94:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201e98:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201e9c:	fed870e3          	bgeu	a6,a3,ffffffffc0201e7c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ea0:	f40ddce3          	bgez	s11,ffffffffc0201df8 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ea4:	8de2                	mv	s11,s8
ffffffffc0201ea6:	5c7d                	li	s8,-1
ffffffffc0201ea8:	bf81                	j	ffffffffc0201df8 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201eaa:	fffdc693          	not	a3,s11
ffffffffc0201eae:	96fd                	srai	a3,a3,0x3f
ffffffffc0201eb0:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201eb4:	00144603          	lbu	a2,1(s0)
ffffffffc0201eb8:	2d81                	sext.w	s11,s11
ffffffffc0201eba:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201ebc:	bf35                	j	ffffffffc0201df8 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201ebe:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ec2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201ec6:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ec8:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201eca:	bfd9                	j	ffffffffc0201ea0 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201ecc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ece:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ed2:	01174463          	blt	a4,a7,ffffffffc0201eda <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201ed6:	1a088e63          	beqz	a7,ffffffffc0202092 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201eda:	000a3603          	ld	a2,0(s4)
ffffffffc0201ede:	46c1                	li	a3,16
ffffffffc0201ee0:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201ee2:	2781                	sext.w	a5,a5
ffffffffc0201ee4:	876e                	mv	a4,s11
ffffffffc0201ee6:	85a6                	mv	a1,s1
ffffffffc0201ee8:	854a                	mv	a0,s2
ffffffffc0201eea:	e37ff0ef          	jal	ra,ffffffffc0201d20 <printnum>
            break;
ffffffffc0201eee:	bde1                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201ef0:	000a2503          	lw	a0,0(s4)
ffffffffc0201ef4:	85a6                	mv	a1,s1
ffffffffc0201ef6:	0a21                	addi	s4,s4,8
ffffffffc0201ef8:	9902                	jalr	s2
            break;
ffffffffc0201efa:	b5f1                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201efc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201efe:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201f02:	01174463          	blt	a4,a7,ffffffffc0201f0a <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201f06:	18088163          	beqz	a7,ffffffffc0202088 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201f0a:	000a3603          	ld	a2,0(s4)
ffffffffc0201f0e:	46a9                	li	a3,10
ffffffffc0201f10:	8a2e                	mv	s4,a1
ffffffffc0201f12:	bfc1                	j	ffffffffc0201ee2 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201f14:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201f18:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201f1a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201f1c:	bdf1                	j	ffffffffc0201df8 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201f1e:	85a6                	mv	a1,s1
ffffffffc0201f20:	02500513          	li	a0,37
ffffffffc0201f24:	9902                	jalr	s2
            break;
ffffffffc0201f26:	b545                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201f28:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201f2c:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201f2e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201f30:	b5e1                	j	ffffffffc0201df8 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201f32:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201f34:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201f38:	01174463          	blt	a4,a7,ffffffffc0201f40 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201f3c:	14088163          	beqz	a7,ffffffffc020207e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201f40:	000a3603          	ld	a2,0(s4)
ffffffffc0201f44:	46a1                	li	a3,8
ffffffffc0201f46:	8a2e                	mv	s4,a1
ffffffffc0201f48:	bf69                	j	ffffffffc0201ee2 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201f4a:	03000513          	li	a0,48
ffffffffc0201f4e:	85a6                	mv	a1,s1
ffffffffc0201f50:	e03e                	sd	a5,0(sp)
ffffffffc0201f52:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201f54:	85a6                	mv	a1,s1
ffffffffc0201f56:	07800513          	li	a0,120
ffffffffc0201f5a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201f5c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201f5e:	6782                	ld	a5,0(sp)
ffffffffc0201f60:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201f62:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201f66:	bfb5                	j	ffffffffc0201ee2 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201f68:	000a3403          	ld	s0,0(s4)
ffffffffc0201f6c:	008a0713          	addi	a4,s4,8
ffffffffc0201f70:	e03a                	sd	a4,0(sp)
ffffffffc0201f72:	14040263          	beqz	s0,ffffffffc02020b6 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201f76:	0fb05763          	blez	s11,ffffffffc0202064 <vprintfmt+0x2d8>
ffffffffc0201f7a:	02d00693          	li	a3,45
ffffffffc0201f7e:	0cd79163          	bne	a5,a3,ffffffffc0202040 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f82:	00044783          	lbu	a5,0(s0)
ffffffffc0201f86:	0007851b          	sext.w	a0,a5
ffffffffc0201f8a:	cf85                	beqz	a5,ffffffffc0201fc2 <vprintfmt+0x236>
ffffffffc0201f8c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f90:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f94:	000c4563          	bltz	s8,ffffffffc0201f9e <vprintfmt+0x212>
ffffffffc0201f98:	3c7d                	addiw	s8,s8,-1
ffffffffc0201f9a:	036c0263          	beq	s8,s6,ffffffffc0201fbe <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201f9e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201fa0:	0e0c8e63          	beqz	s9,ffffffffc020209c <vprintfmt+0x310>
ffffffffc0201fa4:	3781                	addiw	a5,a5,-32
ffffffffc0201fa6:	0ef47b63          	bgeu	s0,a5,ffffffffc020209c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201faa:	03f00513          	li	a0,63
ffffffffc0201fae:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201fb0:	000a4783          	lbu	a5,0(s4)
ffffffffc0201fb4:	3dfd                	addiw	s11,s11,-1
ffffffffc0201fb6:	0a05                	addi	s4,s4,1
ffffffffc0201fb8:	0007851b          	sext.w	a0,a5
ffffffffc0201fbc:	ffe1                	bnez	a5,ffffffffc0201f94 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201fbe:	01b05963          	blez	s11,ffffffffc0201fd0 <vprintfmt+0x244>
ffffffffc0201fc2:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201fc4:	85a6                	mv	a1,s1
ffffffffc0201fc6:	02000513          	li	a0,32
ffffffffc0201fca:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201fcc:	fe0d9be3          	bnez	s11,ffffffffc0201fc2 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201fd0:	6a02                	ld	s4,0(sp)
ffffffffc0201fd2:	bbd5                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201fd4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201fd6:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201fda:	01174463          	blt	a4,a7,ffffffffc0201fe2 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201fde:	08088d63          	beqz	a7,ffffffffc0202078 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201fe2:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201fe6:	0a044d63          	bltz	s0,ffffffffc02020a0 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201fea:	8622                	mv	a2,s0
ffffffffc0201fec:	8a66                	mv	s4,s9
ffffffffc0201fee:	46a9                	li	a3,10
ffffffffc0201ff0:	bdcd                	j	ffffffffc0201ee2 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201ff2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ff6:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201ff8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ffa:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201ffe:	8fb5                	xor	a5,a5,a3
ffffffffc0202000:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202004:	02d74163          	blt	a4,a3,ffffffffc0202026 <vprintfmt+0x29a>
ffffffffc0202008:	00369793          	slli	a5,a3,0x3
ffffffffc020200c:	97de                	add	a5,a5,s7
ffffffffc020200e:	639c                	ld	a5,0(a5)
ffffffffc0202010:	cb99                	beqz	a5,ffffffffc0202026 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0202012:	86be                	mv	a3,a5
ffffffffc0202014:	00001617          	auipc	a2,0x1
ffffffffc0202018:	6c460613          	addi	a2,a2,1732 # ffffffffc02036d8 <slub_size_classes+0x70>
ffffffffc020201c:	85a6                	mv	a1,s1
ffffffffc020201e:	854a                	mv	a0,s2
ffffffffc0202020:	0ce000ef          	jal	ra,ffffffffc02020ee <printfmt>
ffffffffc0202024:	b34d                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202026:	00001617          	auipc	a2,0x1
ffffffffc020202a:	6a260613          	addi	a2,a2,1698 # ffffffffc02036c8 <slub_size_classes+0x60>
ffffffffc020202e:	85a6                	mv	a1,s1
ffffffffc0202030:	854a                	mv	a0,s2
ffffffffc0202032:	0bc000ef          	jal	ra,ffffffffc02020ee <printfmt>
ffffffffc0202036:	bb41                	j	ffffffffc0201dc6 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0202038:	00001417          	auipc	s0,0x1
ffffffffc020203c:	68840413          	addi	s0,s0,1672 # ffffffffc02036c0 <slub_size_classes+0x58>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202040:	85e2                	mv	a1,s8
ffffffffc0202042:	8522                	mv	a0,s0
ffffffffc0202044:	e43e                	sd	a5,8(sp)
ffffffffc0202046:	0fc000ef          	jal	ra,ffffffffc0202142 <strnlen>
ffffffffc020204a:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020204e:	01b05b63          	blez	s11,ffffffffc0202064 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202052:	67a2                	ld	a5,8(sp)
ffffffffc0202054:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202058:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020205a:	85a6                	mv	a1,s1
ffffffffc020205c:	8552                	mv	a0,s4
ffffffffc020205e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202060:	fe0d9ce3          	bnez	s11,ffffffffc0202058 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202064:	00044783          	lbu	a5,0(s0)
ffffffffc0202068:	00140a13          	addi	s4,s0,1
ffffffffc020206c:	0007851b          	sext.w	a0,a5
ffffffffc0202070:	d3a5                	beqz	a5,ffffffffc0201fd0 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202072:	05e00413          	li	s0,94
ffffffffc0202076:	bf39                	j	ffffffffc0201f94 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0202078:	000a2403          	lw	s0,0(s4)
ffffffffc020207c:	b7ad                	j	ffffffffc0201fe6 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020207e:	000a6603          	lwu	a2,0(s4)
ffffffffc0202082:	46a1                	li	a3,8
ffffffffc0202084:	8a2e                	mv	s4,a1
ffffffffc0202086:	bdb1                	j	ffffffffc0201ee2 <vprintfmt+0x156>
ffffffffc0202088:	000a6603          	lwu	a2,0(s4)
ffffffffc020208c:	46a9                	li	a3,10
ffffffffc020208e:	8a2e                	mv	s4,a1
ffffffffc0202090:	bd89                	j	ffffffffc0201ee2 <vprintfmt+0x156>
ffffffffc0202092:	000a6603          	lwu	a2,0(s4)
ffffffffc0202096:	46c1                	li	a3,16
ffffffffc0202098:	8a2e                	mv	s4,a1
ffffffffc020209a:	b5a1                	j	ffffffffc0201ee2 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020209c:	9902                	jalr	s2
ffffffffc020209e:	bf09                	j	ffffffffc0201fb0 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02020a0:	85a6                	mv	a1,s1
ffffffffc02020a2:	02d00513          	li	a0,45
ffffffffc02020a6:	e03e                	sd	a5,0(sp)
ffffffffc02020a8:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02020aa:	6782                	ld	a5,0(sp)
ffffffffc02020ac:	8a66                	mv	s4,s9
ffffffffc02020ae:	40800633          	neg	a2,s0
ffffffffc02020b2:	46a9                	li	a3,10
ffffffffc02020b4:	b53d                	j	ffffffffc0201ee2 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02020b6:	03b05163          	blez	s11,ffffffffc02020d8 <vprintfmt+0x34c>
ffffffffc02020ba:	02d00693          	li	a3,45
ffffffffc02020be:	f6d79de3          	bne	a5,a3,ffffffffc0202038 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02020c2:	00001417          	auipc	s0,0x1
ffffffffc02020c6:	5fe40413          	addi	s0,s0,1534 # ffffffffc02036c0 <slub_size_classes+0x58>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02020ca:	02800793          	li	a5,40
ffffffffc02020ce:	02800513          	li	a0,40
ffffffffc02020d2:	00140a13          	addi	s4,s0,1
ffffffffc02020d6:	bd6d                	j	ffffffffc0201f90 <vprintfmt+0x204>
ffffffffc02020d8:	00001a17          	auipc	s4,0x1
ffffffffc02020dc:	5e9a0a13          	addi	s4,s4,1513 # ffffffffc02036c1 <slub_size_classes+0x59>
ffffffffc02020e0:	02800513          	li	a0,40
ffffffffc02020e4:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02020e8:	05e00413          	li	s0,94
ffffffffc02020ec:	b565                	j	ffffffffc0201f94 <vprintfmt+0x208>

ffffffffc02020ee <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020ee:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02020f0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020f4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02020f6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02020f8:	ec06                	sd	ra,24(sp)
ffffffffc02020fa:	f83a                	sd	a4,48(sp)
ffffffffc02020fc:	fc3e                	sd	a5,56(sp)
ffffffffc02020fe:	e0c2                	sd	a6,64(sp)
ffffffffc0202100:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0202102:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202104:	c89ff0ef          	jal	ra,ffffffffc0201d8c <vprintfmt>
}
ffffffffc0202108:	60e2                	ld	ra,24(sp)
ffffffffc020210a:	6161                	addi	sp,sp,80
ffffffffc020210c:	8082                	ret

ffffffffc020210e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc020210e:	4781                	li	a5,0
ffffffffc0202110:	00005717          	auipc	a4,0x5
ffffffffc0202114:	f0073703          	ld	a4,-256(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202118:	88ba                	mv	a7,a4
ffffffffc020211a:	852a                	mv	a0,a0
ffffffffc020211c:	85be                	mv	a1,a5
ffffffffc020211e:	863e                	mv	a2,a5
ffffffffc0202120:	00000073          	ecall
ffffffffc0202124:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0202126:	8082                	ret

ffffffffc0202128 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202128:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020212c:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc020212e:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0202130:	cb81                	beqz	a5,ffffffffc0202140 <strlen+0x18>
        cnt ++;
ffffffffc0202132:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0202134:	00a707b3          	add	a5,a4,a0
ffffffffc0202138:	0007c783          	lbu	a5,0(a5)
ffffffffc020213c:	fbfd                	bnez	a5,ffffffffc0202132 <strlen+0xa>
ffffffffc020213e:	8082                	ret
    }
    return cnt;
}
ffffffffc0202140:	8082                	ret

ffffffffc0202142 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202142:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202144:	e589                	bnez	a1,ffffffffc020214e <strnlen+0xc>
ffffffffc0202146:	a811                	j	ffffffffc020215a <strnlen+0x18>
        cnt ++;
ffffffffc0202148:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020214a:	00f58863          	beq	a1,a5,ffffffffc020215a <strnlen+0x18>
ffffffffc020214e:	00f50733          	add	a4,a0,a5
ffffffffc0202152:	00074703          	lbu	a4,0(a4)
ffffffffc0202156:	fb6d                	bnez	a4,ffffffffc0202148 <strnlen+0x6>
ffffffffc0202158:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020215a:	852e                	mv	a0,a1
ffffffffc020215c:	8082                	ret

ffffffffc020215e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020215e:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202162:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202166:	cb89                	beqz	a5,ffffffffc0202178 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0202168:	0505                	addi	a0,a0,1
ffffffffc020216a:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020216c:	fee789e3          	beq	a5,a4,ffffffffc020215e <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202170:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202174:	9d19                	subw	a0,a0,a4
ffffffffc0202176:	8082                	ret
ffffffffc0202178:	4501                	li	a0,0
ffffffffc020217a:	bfed                	j	ffffffffc0202174 <strcmp+0x16>

ffffffffc020217c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020217c:	c20d                	beqz	a2,ffffffffc020219e <strncmp+0x22>
ffffffffc020217e:	962e                	add	a2,a2,a1
ffffffffc0202180:	a031                	j	ffffffffc020218c <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202182:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202184:	00e79a63          	bne	a5,a4,ffffffffc0202198 <strncmp+0x1c>
ffffffffc0202188:	00b60b63          	beq	a2,a1,ffffffffc020219e <strncmp+0x22>
ffffffffc020218c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202190:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202192:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0202196:	f7f5                	bnez	a5,ffffffffc0202182 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202198:	40e7853b          	subw	a0,a5,a4
}
ffffffffc020219c:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020219e:	4501                	li	a0,0
ffffffffc02021a0:	8082                	ret

ffffffffc02021a2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02021a2:	ca01                	beqz	a2,ffffffffc02021b2 <memset+0x10>
ffffffffc02021a4:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02021a6:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02021a8:	0785                	addi	a5,a5,1
ffffffffc02021aa:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02021ae:	fec79de3          	bne	a5,a2,ffffffffc02021a8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02021b2:	8082                	ret
