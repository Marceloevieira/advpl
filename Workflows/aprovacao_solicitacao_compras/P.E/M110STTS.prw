#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} M110STTS
//TODO LOCALIZA��O   :  Function A110Inclui, A110Altera,  e A110Deleta responsaveis pela inclus�o, altera��o, 
//					 	exclus�o e c�pia das Solicita��es de Compras. 
//
//	   EM QUE PONTO :  Ap�s a grava��o da Solicita��o pela fun��o A110Grava em inclus�o, altera��o e exclus�o , 
//			    	   localizado fora da transa��o possibilitando assim a inclusao de interface ap�s a grava��o de todas as solicita��es.
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
	// Inclusao ou altera�ao                                        |
	//--------------------------------------------------------------+
	If (nOpt == 1 .OR. nOpt == 2)  .and. ExistBlock("COMW02M")
		
		ExecBlock("COMW02M",.F.,.F.,{cNumSol})	

	EndIf

Return