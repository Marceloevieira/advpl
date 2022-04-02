#Include 'Protheus.ch'

/*/{Protheus.doc} MT150ROT

LOCALIZAÇÃO : Function MATA150 - Função da atualização de cotações. EM QUE PONTO : No inico da rotina e antes da execução da Mbrowse da cotação, 
utilizado para adicionar mais opções no aRotina.

@author Marcelo Evangelista
@since 18/08/2015
@version 1.0
/*/

User Function MT150ROT()

	If ExistBlock("COMW01M")
		AAdd( aRotina, { "Env. Email Forn."   , "EXECBLOCK('COMW01M',.T.,.T.)"   , 0 , 1 } )
	Endif

Return ( aRotina )