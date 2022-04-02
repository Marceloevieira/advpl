#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT120BRW
//TODO 
LOCALIZA��O : Function MATA120 - Fun��o do Pedido de Compras e Autoriza��o de Entrega.

EM QUE PONTO : Ap�s a montagem do Filtro da tabela SC7 e antes da execu��o da Mbrowse do PC, 
utilizado para adicionar mais op��es no aRotina.
@author PROTHEUS
@since 13/09/2019
@version undefined
@example
(examples)
@see (links_or_references)
/*/
user function MT120BRW()

	If ExistBlock("COMW03M")
		AAdd( aRotina, { "Env. Email Aprovador"   , "EXECBLOCK('COMW03M',.T.,.T.)"   , 0 , 1 } )
	Endif

return