#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} WFW120P
//TODO Descri��o:
LOCALIZA��O : Function A120GRAVA - Fun��o respons�vel pela grava��o do Pedido de Compras e 
Autoriza��o de Entrega.
EM QUE PONTO : Ap�s a grava��o dos itens do pedido de compras, no final da condi��o que gera o 
Bloqueio do PC na tabela SCR, pode ser usado para manipular os dados gravados 
do pedido de compras na tabela SC7, como tamb�m o seu bloqueio tabela SCR, 
recebe como parametro  afilial e numero do pedido.
@author PROTHEUS
@since 13/09/2019
@version undefined
@example
(examples)
@see (links_or_references)
/*/
user function WFW120P()


	Local cPedido  :=  PARAMIXB
	dBselectArea('SC7')
	SC7->(dbSetOrder(1))
	If SC7->(dbSeek(xFilial("SC7") + cPedido))//Codigo do usuario ...

		dBselectArea('SCR')
		SCR->(dbSetOrder(1))
		If SCR->(dbSeek(xFilial("SC7") + cPedido)) .And. SCR->CR_TIPO  = 'PC'//Codigo do usuario ...
			If ExistBlock("COMW03M")
				ExecBlock("COMW03M",.f.,.f.,{cPedido})
			EndIf
		EndIf
	EndIf

return