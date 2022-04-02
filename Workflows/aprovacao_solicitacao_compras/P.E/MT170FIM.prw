#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT170FIM
//TODO LOCALIZA��O : Function A170POINT() - Respons�vel por gerar as solicita��es de compra.

//     EM QUE PONTO : � executado ao t�rmino da gera��o das solicita��es de compras.
@author PROTHEUS
@since 17/08/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
User Function MT170FIM( )

	Local aScs   := PARAMIXB[1]

	If Len(aScs) > 0 .And. ExistBlock("COMA02M")

		ExecBlock("COMA02M",.F.,.F.,{aScs} )	
	EndIf	



Return Nil