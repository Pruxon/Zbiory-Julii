.data

text1: 			.asciiz "Podaj wartosc rzeczywista stalej c: "
text2: 			.asciiz "Podaj wartosc urojona stalej c: "
text3:			.asciiz "\n"
text4:			.asciiz "koniec sukces\n"
text5:			.asciiz "koniec porazka\n"
fileName:		.asciiz "Julia.bmp"
fileErrorMsg:		.asciiz "Blad pliku\n"
floatZero:		.float 0.0
floatOne:		.float 1.0
floatTwo:		.float 2.0
floatFour:		.float 4.0
floatPixel: 		.float 0.0078125
floatRowCounter:	.float -257.0			#jeden wiecej bo taki kodzik sobie napisalem :p
floatInRowCounter:	.float -257.0
floatMAX:		.float 256.0
precision:		.word 32 
buffer: 		.space 0xC123C			#obrazek 513x513 wiec 514*513*3+54        

.text
#################################################
# $f1 = 0.0
# $f2 = 4.0
# #f31 = 2.0
# $f30 = 1.0
# $f3 - c rzeczywiste
# $f4 - c urojone
# $f5 - p rzeczywiste
# $f6 - p urojone
# $s1 - maksymalna ilo�c obieg�w p�tli (precision)
# $t1 - adres bufora
#################################################

main:
#wczytywanie wartosci stalej c
	lwc1 $f1, floatZero
	lwc1 $f2, floatFour
	lwc1 $f31, floatTwo
	lwc1 $f30, floatOne
	
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
   	
   	lw $s1, precision				#dokladnosc algorytmu (maksymalna ilosc obejsc petli)
   	la $t1, buffer

#################################################
# $t2 - iterator po bajtach headera
# $t7 - pomocniczy
# $t8 - adres headera

# https://en.wikipedia.org/wiki/BMP_file_format#Example_1
#################################################

prepareBMPHeader:
		
   	move $t8, $t1 #zapamietanie adresu tablicy headera 
	move $t2, $t1 
	
	li $t7, 0x42
	sb $t7, ($t2)
	addi $t2, $t2, 1
	
	li $t7, 0x4D
	sb $t7, ($t2)
	addi $t2, $t2, 1
	
	#File Size
	li $t7, 0x0C
	sb $t7, ($t2)
	addi $t2, $t2, 1
	li $t7, 0x12
	sb $t7, ($t2)
	addi $t2, $t2, 1
	li $t7, 0x3C
	sb $t7, ($t2)
	addi $t2, $t2 2
   	
   	#przeskoczenie 4 bajt�w, tak m�wi wikipedia
   	addi $t2, $t2, 4
   	
   	#offset of pixel array
   	li $t7, 0x36
	sb $t7, ($t2)
	addi $t2, $t2, 4
	
	#bity w headerze
	li $t7, 0x28
	sb $t7, ($t2)
	addi $t2, $t2, 4
	
	#szerokosc obrazka
	li $t7, 0x01
	sb $t7, ($t2)
	addi $t2, $t2, 1
	li $t7, 0x02
	sb $t7, ($t2)
	addi $t2, $t2, 3
	
	#wysokosc obrazka
	li $t7, 0x01
	sb $t7, ($t2)
	addi $t2, $t2, 1
	li $t7, 0x02
	sb $t7, ($t2)
	addi $t2, $t2, 3
	
   	#numbler of color planes
	li $t7, 0x01
	sb $t7, ($t2)
	addi $t2, $t2, 2
	
	#number of bits per pixel
	li $t7, 0x18
	sb $t7, ($t2)
	addi $t2, $t2, 2
	
	#pozniej same zera
	addi $t2, $t2, 24
   	
   	#addi $t1, $t1, 54
#################################################
# $f16 - licznik rz�d�w
# $f17 - licznik w rz�dzie
# $f18 - max obiegow
# $f30 = 1.0
# $f29 = pixelValue
#################################################
   
   BeforeRow:
   	lwc1 $f16, floatRowCounter
   	lwc1 $f17, floatInRowCounter
   	lwc1 $f18, floatMAX
   	lwc1 $f29, floatPixel
   	lwc1 $f19, floatInRowCounter
   	
   	#przejscie przez wszystkie wiersze
   GoThroughEveryRow:
   	add.s $f16, $f16, $f30
   	c.le.s $f16, $f18
   	bc1f END
   	
   	#add.s $f12, $f1, $f16
   	#li $v0, 2
   	#syscall
   	#la $a0,text4
   	#li $v0,4
   	#syscall
   	############################ sprawdzic ten code - DEFAULT CHYBA FALSE i po exitFailure ustawiac na defaultowy
   	#dopisac przejscia przez wiersze i ustawianie kolorow i zapis do pliku
   	add.s $f17, $f1, $f19
   	
   	#przejscie przez wiersz
   ForEveryRow:
   	
   	add.s $f17, $f17, $f30
   	c.le.s $f17, $f18
   	bc1f Padding
   	mul.s $f7, $f17, $f29
   	mul.s $f8, $f16, $f29
   
   	
   	#add.s $f12, $f1, $f17
   	#li $v0, 2
   	#syscall
   	#la $a0,text5
   	#li $v0,4
   	#syscall
   	
 ################################################
 # $f7 - real value of actual pixel
 # $f8 - imaginary value of actual pixel
 # $f9 - wartosc kwadratu czesci rzeczywistej
 # $f10 - wartosc kwadratu czesci urojonej
 # $f11 - wartosc kwadratu modulu liczby
 # $f13 - auxiliary register  Zr^2-Zu^2
 # $f14 -  next auxiliary register  Zr*Zu*2
 # $f15 POMOC SPR
 # $s2 - licznik koloru
 #################################################
 
   BeforeAlgorithm:
   	#movf.s $f7, $f5				#tu wstawic wartosc rzeczywista sprawdzanego piksela
   	#movf.s $f8, $f6				#tu wstawic wartosc urojona sprawdzanego piksela
   	add $s1, $zero, $zero
   	
   Algorithm:
   	blez $s1, EndAlgorithmSuccess		#jesli $s1 == 0 wyjdz z petli
   	mul.s $f9, $f7, $f7			#ustawiam $f9 na kwadrat $f7
   	mul.s $f10, $f8, $f8			#ustawiam $f10 na kwadrat $f8
   	add.s $f11, $f9, $f10			#kwadrat modulu
   	c.le.s $f11, $f2			#sprawdzenie czy kwadrat modulu nie jest wiekszy niz 4, jesli tak ustawia code na true
   	bc1f EndAlgorithmFailure		#jesli code == true wyjdz z petli, jesli code == 1 idzie dalej
   	subi $s1, $s1, 1			#zmniejszenie licznika
   	
   	#nowa wartosc rzeczywita Zr^2-Zu^2
   	sub.s $f13, $f9, $f10
   	
   	#nowa wartosc urojona Zr*Zu*2
   	mul.s $f14, $f7, $f8
   	mul.s $f14, $f14, $f31
   	
   	#podmiana na nowe wartosci rzeczywiste i urojone
   	sub.s $f7, $f7, $f7
   	sub.s $f8, $f8, $f8
	add.s $f7, $f7, $f13
	add.s $f8, $f8, $f14
   	
   	
   	#dodanie c do sprawdzanego punktu
   	add.s $f7, $f7, $f3
   	add.s $f8, $f8, $f4
   	
   	#################################
   	#sprawdzanie wartosci
   	#movf.s $f15, $f1
   	#add.s $f12, $f15, $f11
   	#li $v0, 2
   	#syscall
   	#la $a0,text3
   	#li $v0,4
   	#syscall
   	################################
   	
   	addi $s2, $s2, 1
   	
   	j Algorithm
   	
   EndAlgorithmSuccess:
   	lw $s1, precision
   	
   	sll $s2, $s2, 3
   	
   	sb $s2, ($t1)
	sb $s2, 1($t1)
	sb $s2, 2($t1)
	addi $t1, $t1, 3
   	
   	j ForEveryRow
   	
   EndAlgorithmFailure:
   	lw $s1, precision
   	c.le.s $f1, $f2				#ustawienie z powrotem coproc code 0 na false
   	
   	sb $s2, ($t1)
	sb $s2, 1($t1)
	sb $s2, 2($t1)
	addi $t1, $t1, 3
   	
   	j ForEveryRow
   	
   Padding:
   	addi $t1, $t1, 1
   	b GoThroughEveryRow
   
   END:
   
   	
   
   saveTofile:
	##############################################################
	#t0 - adres tablicy przechowujacej tablice pixeli
	#t1 - 
	#t2
	#t3
	#t4
	#t5
	#t6
	#t7 - 
	#t8 - adres buforu headera
	#t9 - deskryptor pliku
	##############################################################
	
	#syscall 13 open file
	la $a0, fileName
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $t9, $v0  #skopiowanie deskryptora pliku do t9
	
	#jesli nie otwarzono pliku to skok do fileError
	bltz $v0, fileError
	
	#syscall write to file
	move $a0, $t9
	move $a1, $t8
	li $a2, 54
	li $v0, 15
	syscall
	
	#syscall write to file
	move $a0, $t9
	move $a1, $t1
	li $a2, 791046
	li $v0, 15
	syscall
	
	#syscall close file
	move $a0, $t0
	li $v0, 16
	syscall

	b exit
	
fileError:
		
	#syscall print msg
	la $a0, fileErrorMsg
	li $v0, 4
	syscall
   
   
   
   

   exit:	
	# syscall exit programu:
	li $v0, 10
	syscall
