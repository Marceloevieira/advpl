#include 'protheus.ch'
#include 'parmtype.ch'

user function COMA02M()

	Local aArea  := GetArea()
	Local aScs   := PARAMIXB[1]
	Local cNumSc :=  aScs[1,2]


	DbSelectArea("SC1")
	SC1->(DbSetOrder(1))

	//--------------------------------------------------------------+
	//  Tratativa para enviar por numero de sc                      |
	//--------------------------------------------------------------+
	While !Empty(cNumSc) 

		If aScan(aScs,{|x| x[2] == cNumSc }) > 0
			If SC1->(MsSeek(xFilial("SC1") + cNumSc) )
				ExecBlock("COMW02M",.F.,.F.,{cNumSc})	
			EndIf
			cNumSc := soma1(cNumSc)
		Else
			cNumSc := ""
			Exit
		EndIf

	EndDo

	RestArea(aArea)
return