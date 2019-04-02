

.data

text1: 		.asciiz "Podaj wartosc rzeczywista stalej c: "
text2: 		.asciiz "Podaj wartosc urojona stalej c: "
text3:		.asciiz "\n"
text4:		.asciiz "koniec sukces"
text5:		.asciiz "koniec porazka"
floatZero:	.float 0.0
floatTwo:	.float 2.0
floatFour:	.float 4.0
precision:	.word 20 
.text
##########################################################
# $f1 = 0.0
# $f2 = 4.0
# #f31 = 2.0
# $f3 - c rzeczywiste
# $f4 - c urojone
# $f5 - p rzeczywiste
# $f6 - p urojone
# $s1 - maksymalna iloœc obiegów pêtli (1000)

main:
	lwc1 $f1, floatZero
	lwc1 $f2, floatFour
	lwc1 $f31, floatTwo
	
   	la $a0,text1
   	li $v0,4
   	syscall
   	
   	li $v0, 6
   	syscall
   	movf.s $f3, $f0
   	
   	la $a0,text2
   	li $v0,4
   	syscall
   	
   	li $v0, 6
   	syscall
   	movf.s $f4, $f0
   	
 #  	add.s $f12, $f3, $f1
 # 	li $v0, 2
 #  	syscall
   	
 #  	add.s $f12, $f3, $f2
 #  	li $v0, 2
 #  	syscall
   	
   	lw $s1, precision				#dokladnosc algorytmu (maksymalna ilosc obejsc petli)
   	
 ################################################
 # $f7 - wartosc rzeczywista aktualnego piksela
 # $f8 - wartosc urojona aktualnego piksela
 # $f9 - wartosc kwadratu czesci rzeczywistej
 # $f10 - wartosc kwadratu czesci urojonej
 # $f11 - wartosc kwadratu modulu liczby
 # $f13 - rejestr pomocniczy 
 # $f14 -  kolejny rejestr pomocniczy
 # $f15 POMOC SPR
 
   BeforeAlgorithm:
   	movf.s $f7, $f1				#tu wstawic wartosc rzeczywista sprawdzanego piksela
   	movf.s $f8, $f1				#tu wstawic wartosc urojona sprawdzanego piksela
   	
   	
   Algorithm:
   	blez $s1, EndAlgorithmSuccess		#jesli $s1 == 0 wyjdz z petli
   	mul.s $f9, $f7, $f7			#ustawiam $f9 na kwadrat $f7
   	mul.s $f10, $f8, $f8			#ustawiam $f10 na kwadrat $f8
   	add.s $f11, $f9, $f10			#kwadrat modulu
   	c.le.s $f11, $f2			#sprawdzenie czy kwadrat modulu nie jest wiekszy niz 4, jesli tak ustawia code na 0
   	bc1f EndAlgorithmFailure		#jesli code == 0 wyjdz z petli, jesli code == 1 idzie dalej
   	subi $s1, $s1, 1			#zmniejszenie licznika
   	
   	#nowa wartosc rzeczywita Zr^2-Zu^2
   	sub.s $f13, $f10, $f11
   	
   	#nowa wartosc urojona Zr*Zu*2
   	mul.s $f14, $f7, $f8
   	mul.s $f14, $f14, $f31
   	
   	#podmiana na nowe wartosci rzeczywiste i urojone
   	movf.s $f7, $f13
   	movf.s $f8, $f14
   	
   	#dodanie c do sprawdzanego punktu
   	add.s $f7, $f7, $f3
   	add.s $f8, $f8, $f4
   	
   	#################################
   	#sprawdzanie wartosci
   	movf.s $f15, $f1
   	add.s $f12, $f15, $f11
   	li $v0, 2
   	syscall
   	la $a0,text3
   	li $v0,4
   	syscall
   	################################
   	
   	j Algorithm
   	
   EndAlgorithmSuccess:
   	lw $s1, precision
   	
   	la $a0,text4
   	li $v0,4
   	syscall
   	j END
   	
   EndAlgorithmFailure:
   	lw $s1, precision
   	
   	la $a0,text5
   	li $v0,4
   	syscall
   
   END:

   exit:	
	# syscall exit programu:
	li $v0, 10
	syscall
