#include 'protheus.ch'
#include 'parmtype.ch'

user function MTA110MNU()

	If ExistBlock("COMW02M")
		aAdd(aRotina, {"Reenviar email aprovador","ExecBlock('COMW02M',.F.,.F.,{SC1->C1_NUM})", 0 , 7, 0, nil})	
	EndIf
	
return