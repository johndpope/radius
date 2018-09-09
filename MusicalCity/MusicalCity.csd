<CsoundSynthesizer>
<CsOptions>
-o dac -m0d
</CsOptions>
<CsInstruments>

sr		=	44100
ksmps	=	32	
nchnls 	=	2
0dbfs	=	1


; ****************************************
; 		INITIALIZATION INSTRUMENT   
; ****************************************

instr 1
	giMasterNodesNum = 3
	giSubNodesNum = 10
	giFreeNodesNum = 3

	gkMasterNodes[] init giMasterNodesNum
	giMetroTempos[] init giMasterNodesNum 
	gkMetronomes[] init giMasterNodesNum

	; Rows: Amount of subnodes 
	; Columns: Id, Master/parent-node id
	gkSubNodes[][] init giSubNodesNum, 2
	gkFreeNodes[] init giFreeNodesNum

	gkNodesPlaying[] init giMasterNodesNum+giSubNodesNum+giFreeNodesNum

 	; *************************
 	; INSTANTIATE MAIN NODES 
	; *************************
	icount = 0
 	until (icount == giMasterNodesNum) do
 		gkMasterNodes[icount] = 0
 		gkNodesPlaying[icount] = 0
 		giMetroTempos[icount] = 95
 		gkMetronomes[icount] = 0
 		prints ""
 		icount += 1
 	od

 	; *************************
 	; INSTANTIATE SUB NODES 
	; *************************
	icount = 0
 	until (icount == giSubNodesNum) do
 		gkSubNodes[icount][0] = 0
 		gkSubNodes[icount][1] = 0		
 		gkNodesPlaying[giMasterNodesNum+icount] = 0
 		icount += 1
 	od
 	; *************************
 	; INSTANTIATE FREE NODES 
	; *************************
 	icount = 0
 	until (icount == giFreeNodesNum) do
 		gkFreeNodes[icount] = 0	
 		gkNodesPlaying[giMasterNodesNum+giFreeNodesNum+icount] = 0
 		icount += 1
 	od


			 	; *************************
			 	; TEST VALUES
				; *************************

			 		giMetroTempos[0] = 116
					giMetroTempos[1] = 80
					giMetroTempos[2] = 130
					
					gkSubNodes[3][1] = 1 
					gkSubNodes[4][1] = 1 
					gkSubNodes[5][1] = 1 

					gkSubNodes[6][1] = 2 
					gkSubNodes[7][1] = 2 
					gkSubNodes[8][1] = 2 

				; *************************


 	; *************************
 	; START METRONOMES 
	; *************************

	icount = 0
	until icount == giMasterNodesNum do
		instrNum = 100+((icount+1) * 0.1)
		print instrNum
		event_i "i", instrNum, 0, -1, giMetroTempos[icount], icount
		icount += 1
	od

endin

; ****************************************
; 		PERFORMANCE INSTRUMENT   
; ****************************************

;gihandle OSCinit 9999

instr 10
 	; *************************
 	; OSC TESTING 
	; *************************
/*
	kNode1 init 0
	kNode2 init 0
	kNode3 init 0
	kNode4 init 0
	kNode5 init 0
	kNode6 init 0
	kNode7 init 0
	kNode8 init 0

	k1  OSClisten gihandle, "/node1/amp", "f", kNode1 
	k2  OSClisten gihandle, "/node2/amp", "f", kNode2
	k3  OSClisten gihandle, "/node3/amp", "f", kNode3
	k4  OSClisten gihandle, "/node4/amp", "f", kNode4
	k5  OSClisten gihandle, "/node5/amp", "f", kNode5
	k6  OSClisten gihandle, "/node6/amp", "f", kNode6
	k7  OSClisten gihandle, "/node7/amp", "f", kNode7
	k8  OSClisten gihandle, "/node8/amp", "f", kNode8

	gkMasterNodes[0] = kNode1
	gkMasterNodes[1] = kNode2

	gkSubNodes[0][0] = kNode3
	gkSubNodes[1][0] = kNode4
	gkSubNodes[2][0] = kNode5
	gkSubNodes[3][0] = kNode6
	gkSubNodes[4][0] = kNode7

	gkFreeNodes[0] = kNode8
*/


	gkMasterNodes[0]  chnget "nodeAmp1"
	gkMasterNodes[1]  chnget "nodeAmp2"
	gkMasterNodes[2]  chnget "nodeAmp3"

	; ADIBA
	gkSubNodes[0][0]  chnget "nodeAmp4"
	gkSubNodes[1][0]  chnget "nodeAmp5"
	gkSubNodes[2][0]  chnget "nodeAmp6"
	gkSubNodes[3][0]  chnget "nodeAmp7"

	; TIM
	gkSubNodes[4][0]  chnget "nodeAmp8"
	gkSubNodes[5][0]  chnget "nodeAmp9"
	gkSubNodes[6][0]  chnget "nodeAmp10"

	; BERNT
	gkSubNodes[7][0]  chnget "nodeAmp11"
	gkSubNodes[8][0]  chnget "nodeAmp12"
	gkSubNodes[9][0]  chnget "nodeAmp13"

	gkFreeNodes[0]  chnget "nodeAmp14"
	gkFreeNodes[1]  chnget "nodeAmp15"
	gkFreeNodes[2]  chnget "nodeAmp16"

	; *************************

	; LOOP THROUGH MAIN NODES

	kcount = 0 
	until (kcount == giMasterNodesNum) do 	
		kInstrNum = 2 + (kcount * 0.01)
		if gkMasterNodes[kcount] > 0 && gkNodesPlaying[kcount] == 0 then
			if gkMetronomes[kcount] == 1 then ;&& changed(gkMetronomes[kcount]) == 1 then 
				event "i", kInstrNum, 0, -1, kcount+1
				printks "Playing zone #%d\n", 0, kcount+1
				gkNodesPlaying[kcount] = 1 
			endif
		elseif gkMasterNodes[kcount] <= 0 && gkNodesPlaying[kcount] == 1 then 
			if gkMetronomes[kcount] == 1 && changed(gkMetronomes[kcount]) == 1 then 
				event "i", kInstrNum * -1, 0, 1, kcount+1
				printks "Stopping zone #%d\n", 0, kcount+1
				gkNodesPlaying[kcount] = 0 
			endif
		endif
		kcount += 1
	od

	; LOOP THROUGH SUB NODES

	kcount = 0
	until (kcount == giSubNodesNum) do
		kNodeIdx = (giMasterNodesNum + kcount)
		kInstrNum = 3 + (kNodeIdx * 0.01)

		if gkSubNodes[kcount][0] > 0 && gkNodesPlaying[kNodeIdx] == 0 then
			if gkMetronomes[gkSubNodes[kcount][1]] == 1 then 
				event "i", kInstrNum, 0, -1, kNodeIdx+1, kcount
				printks "Playing zone #%d\n", 0, kNodeIdx+1
				gkNodesPlaying[kNodeIdx] = 1 
			endif
		elseif gkSubNodes[kcount][0] <= 0 && gkNodesPlaying[kNodeIdx] == 1 then
			if gkMetronomes[gkSubNodes[kcount][1]] == 1 then 
				event "i", kInstrNum * -1, 0, 1, kNodeIdx+1, kcount
				printks "Stopping zone #%d\n", 0, kNodeIdx+1
				gkNodesPlaying[kNodeIdx] = 0 
			endif
		endif
		kcount += 1
	od

	; LOOP THROUGH FREE NODES	
	kcount = 0
	until (kcount == giFreeNodesNum) do
		kNodeIdx = (giMasterNodesNum + giSubNodesNum + kcount)
		kInstrNum = 4 + (kNodeIdx * 0.01)
		if gkFreeNodes[kcount] > 0 && gkNodesPlaying[kNodeIdx] == 0 then 
			event "i", kInstrNum, 0, -1, kNodeIdx+1, kcount
			printks "Playing zone #%d\n", 0, kNodeIdx+1
			gkNodesPlaying[kNodeIdx] = 1
		elseif gkFreeNodes[kcount] <= 0 && gkNodesPlaying[kNodeIdx] == 1 then
			event "i", kInstrNum * -1, 0, 1, kNodeIdx+1, kcount
			printks "Stopping zone #%d\n", 0, kNodeIdx+1
			gkNodesPlaying[kNodeIdx] = 0 
		endif
		kcount += 1
	od

endin 

; *****************************
; 		SAMPLE PLAYER - MASTER 
; *****************************

instr 2
	kattack linseg 0, 0.2, 1

	ilength = ftlen(p4)
	kamp = gkMasterNodes[p4-1]
	kamp limit kamp, 0, 1
	kamp *= kattack
	kamp port kamp, 0.1

	;------- complex envelope block ------
	xtratim 0.1;extra-time, i.e. release dur
	krel init 0
	krel release ;outputs release-stage flag (0 or 1 values)
	if (krel == 1) then
		reinit rel ;if in release-stage goto release section
	endif

	aL,aR flooper2 1, 1, 0, (ilength/sr)/2, 0.025, p4

	 ;--------- release section --------
	 rel:
	 if krel == 1 then	 
		 krelAmp linseg 1, .1, 0
		 kamp = kamp*krelAmp
	 endif

	outs aL*kamp, aR*kamp
endin

; *****************************
; 		SAMPLE PLAYER - SUB 
; *****************************

instr 3
	kSUBZONE_GAIN = 0.75

	kattack linseg 0, 1, 1

	ilength = ftlen(p4)
	kamp = gkSubNodes[p5][0]
	kamp limit kamp, 0, 1
	kamp *= kattack

	aL,aR flooper2 1, 1, 0, (ilength/sr)/2, 0.025, p4

	 ;--------- release section --------

	xtratim 1;extra-time, i.e. release dur
	krel init 0
	krel release ;outputs release-stage flag (0 or 1 values)

	if krel == 1 then	 
		krelAmp linseg 1, 1, 0
		kamp = kamp*krelAmp
	endif

	kamp port kamp, 1
	kamp *= kSUBZONE_GAIN

	outs aL*kamp, aR*kamp
endin


; *****************************
; 		SAMPLE PLAYER - FREE 
; *****************************

instr 4
	kattack linseg 0, 5, 1

	ilength = ftlen(p4)
	
	kamp = 0.75 * kattack

	aL,aR flooper2 1, 1, 0, (ilength/sr)/2, 0.5, p4

	 ;--------- release section --------

	xtratim 5;extra-time, i.e. release dur
	krel init 0
	krel release ;outputs release-stage flag (0 or 1 values)

	if krel == 1 then	 
		krelAmp linseg 1, 5, 0
		kamp = kamp*krelAmp
	endif

	outs aL*kamp, aR*kamp
endin

 	
; *************************
; 		METRONOME  
; *************************

instr 100 

;	setksmps 1

	iBPM = p4
	iBPM_in_Seconds = iBPM/60
	iMetroNum = p5

	prints "Starting metronome #%d at %d BPM\n", iMetroNum, iBPM 

	kPulse metro iBPM_in_Seconds, 0
	gkMetronomes[iMetroNum] = kPulse
;	kQuarterPulse metro iBPM_in_Seconds*4, 0

	; METRONOME SOUND
/*
	if iMetroNum == 1 then 
		schedkwhen kPulse, 0, 0, 101, 0, 0.2, iMetroNum
		printk2 kQuarterPulse, iMetroNum*10
	endif 
*/
endin 

; *************************
; 	METRONOME SOUND (DEBUG)
; *************************
instr 101
	asig oscil 1, 400
	aenv linseg 0, 0.01, 0.8, 0.05, 0
	asig *= aenv
	outs asig, asig 
	;ichnl = p4
	;outch ichnl+1, asig  
endin

</CsInstruments>
<CsScore>

; 	start	dur	 	
i1	0		1
i10 1 		86400	

f1 0 0 1 "CH-116BPM-Main-PINK.wav" 0 0 0 
f2 0 0 1 "MTF_Ambient_80bpm_Pink.wav" 0 0 0 
f3 0 0 1 "House-130BPM-Pink.wav" 0 0 0 

f4 0 0 1 "CH-116BPM-Vocal-BLUE1.wav" 0 0 0 
f5 0 0 1 "CH-116BPM-Trumpet-BLUE2.wav" 0 0 0 
f6 0 0 1 "CH-116BPM-Siren-BLUE3.wav" 0 0 0 
f7 0 0 1 "CH-116BPM-Kick-BLUE4.wav" 0 0 0 

f8 0 0 1 "MTF_Ambient_80bpm_Blue_1.wav" 0 0 0 
f9 0 0 1 "MTF_Ambient_80bpm_Blue_2.wav" 0 0 0 
f10 0 0 1 "MTF_Ambient_80bpm_Blue_3.wav" 0 0 0 

f11 0 0 1 "House-130BPM-Perk-Blue1.wav" 0 0 0 
f12 0 0 1 "House-130BPM-Grinder-Blue2.wav" 0 0 0 
f13 0 0 1 "House-130BPM-Lead-Blue3.wav" 0 0 0 

f14 0 0 1 "MTF_Green_1.wav" 0 0 0 
f15 0 0 1 "MTF_Green_2.wav" 0 0 0 
f16 0 0 1 "MTF_Green_3.wav" 0 0 0 


</CsScore>
</CsoundSynthesizer>
