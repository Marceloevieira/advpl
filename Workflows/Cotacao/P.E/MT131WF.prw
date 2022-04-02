#include 'protheus.ch'
#include 'parmtype.ch'


/*/{Protheus.doc} MT131WF
//TODO Este ponto de entrada tem o objetivo de permitir a customização de workflow baseado nas informações de cotações 
//     que estão sendo geradas pela rotina em execução.
//     Ex.: Possibilita preparar um e-mail customizado para os fornecedores contendo os itens a serem cotados para que 
//          possa ser respondido pelo próprio fornecedor selecionado.
//     LOCALIZAÇÃO: Function A131Proces - Rotina de processamento da solicitacoes de compra que devem gerar cotacao.
@author Marcelo Evangelista
@since 02/03/2018
@version undefined
@example
(examples)
@see (links_or_references)
/*/
user function MT131WF()


	Local aRet  := PARAMIXB[1] 
	Local aRet2 := PARAMIXB[2]

	If ExistBlock("COMW01M")
		ExecBlock("COMW01M",.T.,.T.,{aRet,aRet2})
	EndIf

return