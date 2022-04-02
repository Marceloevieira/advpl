#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} M110STTS
//TODO LOCALIZAÇÃO   :  Function A110Inclui, A110Altera,  e A110Deleta responsaveis pela inclusão, alteração, 
//					 	exclusão e cópia das Solicitações de Compras. 
//
//	   EM QUE PONTO :  Após a gravação da Solicitação pela função A110Grava em inclusão, alteração e exclusão , 
//			    	   localizado fora da transação possibilitando assim a inclusao de interface após a gravação de todas as solicitações.
@author Marcelo Evangelista
@since 23/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function M110STTS()

	Local cNumSol	:= Paramixb[1]
	Local nOpt		:= Paramixb[2]
	Local oProcess  := nil


	//--------------------------------------------------------------+
	// Inclusao ou alteraçao                                        |
	//--------------------------------------------------------------+
	If (nOpt == 1 .OR. nOpt == 2)  .and. ExistBlock("COMW02M")
		
		ExecBlock("COMW02M",.F.,.F.,{cNumSol})	

	EndIf

Return