#include "rwmake.ch"        
#include "TbiConn.ch"
#include "TbiCode.ch"

/*/{Protheus.doc} MT130WF

Este ponto de entrada tem o objetivo de permitir a customiza��o de workflow baseado nas informa��es de cota��es 
que est�o sendo geradas pela rotina em execu��o.

Ex.: Possibilita preparar um e-mail customizado para os fornecedores contendo os itens a serem cotados 
para que possa ser respondido pelo pr�prio fornecedor selecionado.

LOCALIZA��O: Function A130Proces - Rotina de processamento da solicitacoes de compra que devem gerar cotacao.

@author Marcelo Evangelista
@since 02/03/2018
@version 1.0
/*/

User Function MT130WF()

	Local aRet  := PARAMIXB[1] 
	Local aRet2 := PARAMIXB[2]

	If ExistBlock("COMW01M")
		ExecBlock("COMW01M",.T.,.T.,{aRet,aRet2})
	EndIf

Return 


