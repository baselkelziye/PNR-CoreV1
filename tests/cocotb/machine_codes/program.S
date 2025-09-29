
program.bin:     file format binary


Disassembly of section .data:

00000000 <.data>:
   0:	00000093          	addi	ra,zero,0
   4:	10000113          	addi	sp,zero,256
   8:	00a00193          	addi	gp,zero,10
   c:	00900213          	addi	tp,zero,9
  10:	00200313          	addi	t1,zero,2
  14:	00610023          	sb	t1,0(sp)
  18:	00100313          	addi	t1,zero,1
  1c:	006100a3          	sb	t1,1(sp)
  20:	00300313          	addi	t1,zero,3
  24:	00610123          	sb	t1,2(sp)
  28:	00500313          	addi	t1,zero,5
  2c:	006101a3          	sb	t1,3(sp)
  30:	00400313          	addi	t1,zero,4
  34:	00610223          	sb	t1,4(sp)
  38:	00700313          	addi	t1,zero,7
  3c:	006102a3          	sb	t1,5(sp)
  40:	00600313          	addi	t1,zero,6
  44:	00610323          	sb	t1,6(sp)
  48:	00b00313          	addi	t1,zero,11
  4c:	006103a3          	sb	t1,7(sp)
  50:	00900313          	addi	t1,zero,9
  54:	00610423          	sb	t1,8(sp)
  58:	00800313          	addi	t1,zero,8
  5c:	006104a3          	sb	t1,9(sp)
  60:	04328463          	beq	t0,gp,0xa8
  64:	00000093          	addi	ra,zero,0
  68:	02408c63          	beq	ra,tp,0xa0
  6c:	002083b3          	add	t2,ra,sp
  70:	00038403          	lb	s0,0(t2)
  74:	00138713          	addi	a4,t2,1
  78:	00070483          	lb	s1,0(a4)
  7c:	00945863          	bge	s0,s1,0x8c
  80:	00838023          	sb	s0,0(t2)
  84:	00970023          	sb	s1,0(a4)
  88:	00000863          	beq	zero,zero,0x98
  8c:	00900533          	add	a0,zero,s1
  90:	00870023          	sb	s0,0(a4)
  94:	00a38023          	sb	a0,0(t2)
  98:	00108093          	addi	ra,ra,1
  9c:	fc0006e3          	beq	zero,zero,0x68
  a0:	00128293          	addi	t0,t0,1
  a4:	fa000ee3          	beq	zero,zero,0x60
