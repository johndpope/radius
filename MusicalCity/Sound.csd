<CsoundSynthesizer>
<CsOptions>
-o dac -b128 -B1024
</CsOptions>
<CsInstruments>
sr      =   44100
ksmps   =   32  
nchnls  =   2
0dbfs   =   1
instr 1 
    kfreq1 init 330
    kfreq2 init 331
    kfreq1 chnget "SineFreq1"
    kfreq2 chnget "SineFreq2"
    a1 oscil 0.5, kfreq1
    a2 oscil 0.5, kfreq2
    outs a1, a2
endin
</CsInstruments>
<CsScore>
;   start   dur     
i1  0       86400   
</CsScore>
</CsoundSynthesizer>